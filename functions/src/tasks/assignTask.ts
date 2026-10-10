/**
 * onTaskCreated (A-01, SPRINT2_CONTRACT "Task creation"): the app creates a task as a pending
 * request that only the creator can see; this check decides, on the server, whether the creator
 * may assign those people. On success the task becomes `assigned` with its viewerIds; otherwise
 * `rejected` with an ErrorCode the creator sees. The same check runs again when the creator
 * resubmits a rejected task (see taskUpdated.ts).
 */
import { FieldValue, Timestamp, type DocumentData, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { paths } from '../auth/deps';
import { auditEntryId, createdSnapshot, isMadeOffline, SYSTEM_ACTOR, type AuditChange } from '../audit/audit';
import { taskAuditDoc, type AuditDoc } from '../audit/writer';
import type { ErrorCode } from '../shared/errors';
import { log } from '../shared/logger';
import type { Department, Task, User } from '../shared/model';
import { adminVerifiedAt, checkAssignment, computeViewerIds, type Assigner } from './assignment';
import type { TaskDeps } from './deps';
import { chainsOf, readPeople } from './people';

export interface AssignmentOutcome {
  error: ErrorCode | null;
  /** viewerIds after the check: the computed list when assigned, [creator] when rejected. */
  viewerIds: string[];
}

/**
 * Reads everything the check needs (creator, their admin verification record, department,
 * assignees and participants) inside `tx` and decides. Reads only.
 * @param atMs when the creator acted (the server time of the create or resubmit write).
 */
export async function assignmentOutcome(tx: Transaction, db: Firestore, org: string, task: Task, atMs: number): Promise<AssignmentOutcome> {
  const assigneeIds = Array.isArray(task.assigneeIds) ? task.assigneeIds : [];
  const participantIds = Array.isArray(task.participantIds) ? task.participantIds : [];
  const creatorSnap = await tx.get(db.doc(paths.user(org, task.creatorId)));
  const creator = creatorSnap.data() as User | undefined;
  const rejected = (error: ErrorCode): AssignmentOutcome => ({ error, viewerIds: [task.creatorId] });
  if (!creator || creator.active !== true) return rejected('assignee-not-allowed');

  let adminVerified = false;
  if (creator.role === 'admin') {
    const rec = await tx.get(db.doc(paths.adminVerification(org, task.creatorId)));
    adminVerified = adminVerifiedAt(rec.data(), atMs);
  }
  const deptSnap = typeof task.deptId === 'string' && task.deptId.length > 0 && !task.deptId.includes('/')
    ? await tx.get(db.doc(paths.dept(org, task.deptId)))
    : null;
  const deptActive = (deptSnap?.data() as Department | undefined)?.active === true;
  const people = await readPeople(tx, db, org, [...assigneeIds, ...participantIds].filter((u) => typeof u === 'string' && u.length > 0 && !u.includes('/')));

  const assigner: Assigner = { uid: task.creatorId, role: creator.role, adminVerified };
  const error = checkAssignment({ assigner, assigneeIds, participantIds, people, deptActive });
  if (error) return rejected(error);
  return { error: null, viewerIds: computeViewerIds({ ...task, assigneeIds, participantIds }, chainsOf(people)) };
}

/** The task update and audit entries for an outcome (applied by the caller after its reads). */
export function outcomeWrites(task: Task, outcome: AssignmentOutcome): { update: DocumentData; change: AuditChange } {
  if (outcome.error === null) {
    return {
      update: { assignmentState: 'assigned', viewerIds: outcome.viewerIds, assignmentError: FieldValue.delete() },
      change: { action: 'task_assigned', before: { assignmentState: 'pending' }, after: { assignmentState: 'assigned', assigneeIds: task.assigneeIds } },
    };
  }
  return {
    update: { assignmentState: 'rejected', assignmentError: outcome.error, viewerIds: outcome.viewerIds },
    change: { action: 'task_rejected', before: { assignmentState: 'pending' }, after: { assignmentState: 'rejected', assignmentError: outcome.error } },
  };
}

function millis(v: unknown, fallback: number): number {
  return v instanceof Timestamp ? v.toMillis() : fallback;
}

export type CreatedResult = 'missing' | 'not-pending' | 'workflow-deferred' | 'discarded' | 'assigned' | 'rejected';

/** Handler for onDocumentCreated(orgs/{org}/tasks/{taskId}). Idempotent: a retry finds the task no longer pending. */
export async function handleTaskCreated(deps: TaskDeps, ev: { org: string; taskId: string; eventId: string }): Promise<CreatedResult> {
  const { db } = deps;
  const ref = db.doc(paths.task(ev.org, ev.taskId));
  const audit = db.collection(paths.audit(ev.org));
  const result = await db.runTransaction(async (tx): Promise<CreatedResult> => {
    const snap = await tx.get(ref);
    if (!snap.exists) return 'missing';
    const task = snap.data() as Task;
    if (task.assignmentState !== 'pending') return 'not-pending';
    if ((task.templateId ?? null) !== null) {
      // TODO(Sprint 3, workflows): pin the template version, assign step 1 and fill viewerIds (A-01, A-05).
      return 'workflow-deferred';
    }
    const createdRef = audit.doc(auditEntryId(ev.eventId, 'task_created'));
    const createdExists = (await tx.get(createdRef)).exists;
    const createdEntry = (viewerIds: string[]): AuditDoc => taskAuditDoc(
      ev.taskId, task.creatorId, { action: 'task_created', before: null, after: createdSnapshot(task as unknown as Record<string, unknown>) },
      { viewerIds, confidential: task.confidential },
      { at: task.createdAt instanceof Timestamp ? task.createdAt : null, madeOffline: isMadeOffline(null, task as unknown as Record<string, unknown>) },
    );

    if (task.deleted === true) {
      // Discarded by the creator before the check ran: record the creation only; the discard has its own entry.
      if (!createdExists) tx.create(createdRef, createdEntry([task.creatorId]));
      return 'discarded';
    }

    const outcome = await assignmentOutcome(tx, db, ev.org, task, millis(task.createdAt, deps.now()));
    const { update, change } = outcomeWrites(task, outcome);
    const outcomeRef = audit.doc(auditEntryId(ev.eventId, change.action));
    const outcomeExists = (await tx.get(outcomeRef)).exists;
    tx.update(ref, update);
    if (!createdExists) tx.create(createdRef, createdEntry(outcome.viewerIds));
    if (!outcomeExists) tx.create(outcomeRef, taskAuditDoc(ev.taskId, SYSTEM_ACTOR, change, { viewerIds: outcome.viewerIds, confidential: task.confidential }));
    return outcome.error === null ? 'assigned' : 'rejected';
  });
  log.info('task_assignment_checked', { orgId: ev.org, taskId: ev.taskId, result });
  return result;
}
