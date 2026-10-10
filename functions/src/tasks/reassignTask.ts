/**
 * reassignTask (SPRINT2_CONTRACT "Callables", PDD 2 "Reassign a task"): the creator, a manager
 * above every current and new assignee, or a verified admin (non-confidential tasks) gives a
 * simple open task to other people. The new assignees must pass the same assignment rule as at
 * creation, for the caller. One transaction: assignees, completedByIds (kept only for people who
 * stay), viewerIds, the reassignment flag and one `task_reassigned` audit entry.
 */
import { FieldValue } from 'firebase-admin/firestore';
import { paths, type CallerAuth } from '../auth/deps';
import { taskAuditDoc } from '../audit/writer';
import { requireMember } from '../security/caller';
import { isAdminVerified } from '../security/session';
import { AtmsError, ErrorCode, validationError } from '../shared/errors';
import { log } from '../shared/logger';
import { OPEN_STATUSES, type Task, type User } from '../shared/model';
import { computeViewerIds, mayAssign, type Assigner } from './assignment';
import type { TaskDeps } from './deps';
import { chainsOf, readPeople } from './people';

const DOC_ID = /^[A-Za-z0-9_-]{1,128}$/;

export interface ReassignInput {
  taskId: string;
  assigneeIds: string[];
}

export function validateReassignInput(data: unknown): ReassignInput {
  if (typeof data !== 'object' || data === null || Array.isArray(data)) throw validationError('input', 'input must be an object');
  const d = data as Record<string, unknown>;
  for (const k of Object.keys(d)) if (k !== 'taskId' && k !== 'assigneeIds') throw validationError(k, `unknown field ${k}`);
  if (typeof d.taskId !== 'string' || !DOC_ID.test(d.taskId)) throw validationError('taskId', 'taskId must be a valid id');
  const ids = d.assigneeIds;
  if (!Array.isArray(ids) || ids.length < 1 || ids.length > 50) throw validationError('assigneeIds', 'assigneeIds must hold 1 to 50 people');
  for (const id of ids) if (typeof id !== 'string' || !DOC_ID.test(id)) throw validationError('assigneeIds', 'assigneeIds must be valid ids');
  if (new Set(ids).size !== ids.length) throw validationError('assigneeIds', 'assigneeIds must not repeat');
  return { taskId: d.taskId, assigneeIds: ids as string[] };
}

const notFound = () => new AtmsError('not-found', ErrorCode.taskNotFound, 'Task not found.');

export async function reassignTask(deps: TaskDeps, callerAuth: CallerAuth | undefined, data: unknown): Promise<{ ok: true }> {
  const caller = await requireMember(deps.db, callerAuth, deps.now());
  const input = validateReassignInput(data);
  const { db } = deps;
  const org = caller.orgId;
  const ref = db.doc(paths.task(org, input.taskId));
  const verifiedAdmin = isAdminVerified(caller.claims, caller.role, Math.floor(deps.now() / 1000));

  await db.runTransaction(async (tx) => {
    const [snap, meSnap] = await tx.getAll(ref, db.doc(paths.user(org, caller.uid)));
    if (!snap.exists) throw notFound();
    const task = snap.data() as Task;
    const me = meSnap.data() as User;

    // Same read rule as firestore.rules canReadTaskData: an unreadable task looks absent.
    const assigned = task.assignmentState === 'assigned';
    const canRead = task.deleted !== true && (
      (task.viewerIds ?? []).includes(caller.uid)
      || (task.confidential !== true && verifiedAdmin)
      || (task.confidential === true && (me.confidentialDepts ?? []).includes(task.deptId))
      || (assigned && task.assigneeIds.includes(caller.uid))
    );
    if (!canRead) throw notFound();
    if ((task.templateId ?? null) !== null) throw validationError('taskId', 'Workflow tasks are reassigned with the workflow (Sprint 3).');
    // Pending tasks wait for the assignment check; rejected tasks are resubmitted by their creator.
    if (!assigned) throw validationError('taskId', 'This task is not assigned yet.');
    if (!OPEN_STATUSES.includes(task.status)) throw new AtmsError('failed-precondition', ErrorCode.taskClosed, 'This task is finished or cancelled.');

    const people = await readPeople(tx, db, org, [...task.assigneeIds, ...input.assigneeIds]);
    const isCreator = task.creatorId === caller.uid;
    const managerAboveAll = caller.role !== 'staff'
      && [...task.assigneeIds, ...input.assigneeIds].every((a) => people.get(a)?.managerChain.includes(caller.uid) === true);
    const adminForTask = verifiedAdmin && task.confidential !== true;
    if (!isCreator && !managerAboveAll && !adminForTask) {
      throw new AtmsError('permission-denied', ErrorCode.permissionDenied, 'You cannot reassign this task.');
    }

    for (const a of input.assigneeIds) {
      if (people.get(a)?.active !== true) throw new AtmsError('failed-precondition', ErrorCode.assigneeInactive, 'Choose active people.', { field: 'assigneeIds' });
    }
    const assigner: Assigner = { uid: caller.uid, role: caller.role, adminVerified: verifiedAdmin };
    for (const a of input.assigneeIds) {
      if (!mayAssign(assigner, a, people.get(a)!)) {
        throw new AtmsError('permission-denied', ErrorCode.assigneeNotAllowed, 'You cannot assign this person.', { field: 'assigneeIds' });
      }
    }

    const keep = new Set(input.assigneeIds);
    const completedByIds = (task.completedByIds ?? []).filter((u) => keep.has(u));
    const viewerIds = computeViewerIds({ ...task, assigneeIds: input.assigneeIds }, chainsOf(people));
    tx.update(ref, {
      assigneeIds: input.assigneeIds,
      completedByIds,
      viewerIds,
      reassignmentNeeded: FieldValue.delete(),
      reassignmentReason: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: caller.uid,
    });
    tx.create(db.collection(paths.audit(org)).doc(), taskAuditDoc(input.taskId, caller.uid, {
      action: 'task_reassigned',
      before: { assigneeIds: task.assigneeIds },
      after: { assigneeIds: input.assigneeIds },
    }, { viewerIds, confidential: task.confidential }));
  });
  log.info('task_reassigned', { orgId: org, taskId: input.taskId, by: caller.uid, assignees: input.assigneeIds.length });
  return { ok: true };
}
