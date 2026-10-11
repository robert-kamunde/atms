/**
 * onTaskUpdated: one trigger for every task update, run as one transaction so a retried event
 * writes nothing twice (entry ids come from the event id, and every state change is re-checked
 * against the current task).
 *
 * - Audit (PDD 4.11): one entry per action the app made in this write (audit/audit.ts).
 * - Resubmission: the creator moved a rejected task back to pending; the assignment check runs
 *   again (A-01).
 * - Completion (A-02, D-06): when completedByIds or the assignees changed and every current
 *   assignee (or, in 'any' mode, one of them) has finished, the server sets `done`, or
 *   `awaiting_check` when the creator checks the work.
 * - Return (D-06): when the creator returns a task from awaiting_check, completedByIds is cleared
 *   so each assignee confirms again (otherwise a shared task could never be finished again).
 */
import { FieldValue, Timestamp, type DocumentData, type DocumentReference } from 'firebase-admin/firestore';
import { paths } from '../auth/deps';
import {
  auditEntryId, classifyTaskUpdate, isMadeOffline, isResubmission, sameValue, SYSTEM_ACTOR, type AuditChange,
} from '../audit/audit';
import { taskAuditDoc, type AuditDoc } from '../audit/writer';
import { log } from '../shared/logger';
import type { Task } from '../shared/model';
import { completionStatus } from './assignment';
import { assignmentOutcome, outcomeWrites } from './assignTask';
import type { TaskDeps } from './deps';

export interface TaskUpdatedEvent {
  org: string;
  taskId: string;
  eventId: string;
  before: Record<string, unknown>;
  after: Record<string, unknown>;
}

export interface TaskUpdatedResult {
  entries: string[];
  completedTo: 'done' | 'awaiting_check' | null;
  resubmission: 'assigned' | 'rejected' | null;
  completedByReset: boolean;
}

export async function handleTaskUpdated(deps: TaskDeps, ev: TaskUpdatedEvent): Promise<TaskUpdatedResult> {
  const { db } = deps;
  const ref = db.doc(paths.task(ev.org, ev.taskId));
  const audit = db.collection(paths.audit(ev.org));
  const clientChanges = classifyTaskUpdate(ev.before, ev.after);
  const actor = typeof ev.after.updatedBy === 'string' ? ev.after.updatedBy : SYSTEM_ACTOR;
  const clientAt = ev.after.updatedAt instanceof Timestamp ? ev.after.updatedAt : null;
  const madeOffline = isMadeOffline(ev.before, ev.after);

  const result = await db.runTransaction(async (tx): Promise<TaskUpdatedResult> => {
    const res: TaskUpdatedResult = { entries: [], completedTo: null, resubmission: null, completedByReset: false };
    const snap = await tx.get(ref);
    if (!snap.exists) return res;
    const current = snap.data() as Task;
    let viewerIds = Array.isArray(current.viewerIds) ? current.viewerIds : [];
    const update: DocumentData = {};
    const planned: { ref: DocumentReference; doc: () => AuditDoc }[] = [];

    // Resubmitted rejected task: run the assignment check again (only once: it must still be pending).
    if (isResubmission(ev.before, ev.after) && current.assignmentState === 'pending' && current.deleted !== true
      && (current.templateId ?? null) === null) {
      const atMs = clientAt ? clientAt.toMillis() : deps.now();
      const outcome = await assignmentOutcome(tx, db, ev.org, current, atMs);
      const w = outcomeWrites(current, outcome);
      Object.assign(update, w.update);
      viewerIds = outcome.viewerIds;
      res.resubmission = outcome.error === null ? 'assigned' : 'rejected';
      planned.push({ ref: audit.doc(auditEntryId(ev.eventId, w.change.action)), doc: () => taskAuditDoc(ev.taskId, SYSTEM_ACTOR, w.change, { viewerIds, confidential: current.confidential }) });
    }

    // Entries for what the app changed, with the task's viewers after the change.
    for (const change of clientChanges) {
      planned.unshift({
        ref: audit.doc(auditEntryId(ev.eventId, change.action)),
        doc: () => taskAuditDoc(ev.taskId, actor, change, { viewerIds, confidential: current.confidential }, { at: clientAt, madeOffline }),
      });
      if (change.action === 'deadline_changed') {
        // TODO(Sprint 4, notifications): notify the assignees that the deadline changed (PDD 4.3 step 5).
        // No notification is sent in Sprint 2.
      }
    }

    // Completion of a shared task.
    const completionInputsChanged = !sameValue(ev.before.completedByIds, ev.after.completedByIds)
      || !sameValue(ev.before.assigneeIds, ev.after.assigneeIds);
    const to = completionInputsChanged ? completionStatus(current) : null;
    if (to) {
      update.status = to;
      update.updatedAt = FieldValue.serverTimestamp();
      update.updatedBy = SYSTEM_ACTOR;
      res.completedTo = to;
      const change: AuditChange = { action: 'status_changed', before: { status: current.status }, after: { status: to } };
      planned.push({
        ref: audit.doc(auditEntryId(ev.eventId, 'status_changed_by_system')),
        doc: () => taskAuditDoc(ev.taskId, SYSTEM_ACTOR, change, { viewerIds, confidential: current.confidential }),
      });
    }

    // A returned task starts its completion again.
    const returned = clientChanges.some((c) => c.action === 'check_returned');
    if (returned && current.status === 'in_progress' && (current.completedByIds?.length ?? 0) > 0) {
      update.completedByIds = [];
      update.updatedAt = FieldValue.serverTimestamp();
      update.updatedBy = SYSTEM_ACTOR;
      res.completedByReset = true;
    }

    const existing = planned.length > 0 ? await tx.getAll(...planned.map((p) => p.ref)) : [];
    if (Object.keys(update).length > 0) tx.update(ref, update);
    planned.forEach((p, i) => {
      if (existing[i].exists) return;
      tx.create(p.ref, p.doc());
      res.entries.push(p.ref.id);
    });
    return res;
  });
  if (result.entries.length > 0 || result.completedTo || result.resubmission || result.completedByReset) {
    log.info('task_update_processed', {
      orgId: ev.org, taskId: ev.taskId, entries: result.entries.length, completedTo: result.completedTo,
      resubmission: result.resubmission, completedByReset: result.completedByReset,
    });
  }
  return result;
}
