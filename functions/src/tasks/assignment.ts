/**
 * Who may assign whom, who sees a task, and when a shared task is complete (PDD 2 permission
 * matrix, PDD 4.3, 4.8; DECISIONS A-01, A-02, D-06). Pure functions: the triggers and the
 * reassignTask callable feed them what they read in a transaction, and they are unit tested
 * without Firestore.
 */
import { ErrorCode } from '../shared/errors';
import { ACTIVE_STATUSES, type Role, type TaskStatus } from '../shared/model';

/** The person assigning: role, and for admins whether the second factor was valid at the time. */
export interface Assigner {
  uid: string;
  role: Role;
  adminVerified: boolean;
}

/** What the checks need to know about a user (undefined when the user document is missing). */
export interface PersonFacts {
  active: boolean;
  managerChain: readonly string[];
}

/**
 * Creation rule (PDD 2, A-01): staff assign only themselves; managers themselves and anyone with
 * the manager in their managerChain; verified admins anyone in the organisation. An admin whose
 * second factor was not valid has no admin power and is treated like a manager (own reporting
 * tree), never like an admin.
 */
export function mayAssign(assigner: Assigner, assigneeUid: string, assignee: PersonFacts): boolean {
  if (assigneeUid === assigner.uid) return true;
  switch (assigner.role) {
    case 'staff':
      return false;
    case 'manager':
      return assignee.managerChain.includes(assigner.uid);
    case 'admin':
      return assigner.adminVerified || assignee.managerChain.includes(assigner.uid);
  }
}

/** True when the admin's second-factor record covered the moment `atMs`. */
export function adminVerifiedAt(record: { verifiedUntilMs?: unknown } | undefined, atMs: number): boolean {
  return typeof record?.verifiedUntilMs === 'number' && record.verifiedUntilMs > atMs;
}

export interface AssignmentCheck {
  assigner: Assigner;
  assigneeIds: readonly string[];
  participantIds: readonly string[];
  /** Users of the organisation, by uid; a missing entry means no such user in this org. */
  people: ReadonlyMap<string, PersonFacts | undefined>;
  deptActive: boolean;
}

/**
 * Returns null when the assignment is allowed, otherwise the ErrorCode the creator sees.
 * Order: shape, department, inactive people, then permission.
 */
export function checkAssignment(c: AssignmentCheck): ErrorCode | null {
  if (c.assigneeIds.length < 1 || c.assigneeIds.length > 50 || new Set(c.assigneeIds).size !== c.assigneeIds.length) {
    return ErrorCode.validation;
  }
  if (c.participantIds.length > 50) return ErrorCode.validation;
  if (!c.deptActive) return ErrorCode.departmentInvalid;
  for (const uid of [...c.assigneeIds, ...c.participantIds]) {
    if (c.people.get(uid)?.active !== true) return ErrorCode.assigneeInactive;
  }
  for (const uid of c.assigneeIds) {
    if (!mayAssign(c.assigner, uid, c.people.get(uid) as PersonFacts)) return ErrorCode.assigneeNotAllowed;
  }
  return null;
}

export interface VisibilityFacts {
  creatorId: string;
  assigneeIds: readonly string[];
  participantIds?: readonly string[];
  confidential: boolean;
}

/**
 * viewerIds (SPRINT2_CONTRACT "Task creation"): creator + assignees + participants, plus every
 * assignee's managerChain for non-confidential tasks. Confidential tasks never add managers;
 * people with confidential access for the department read them through the rules instead.
 */
export function computeViewerIds(task: VisibilityFacts, chains: ReadonlyMap<string, readonly string[]>): string[] {
  const out = new Set<string>([task.creatorId, ...task.assigneeIds, ...(task.participantIds ?? [])]);
  if (!task.confidential) {
    for (const a of task.assigneeIds) for (const m of chains.get(a) ?? []) out.add(m);
  }
  return [...out];
}

export function sameIds(a: readonly string[] | undefined, b: readonly string[]): boolean {
  return !!a && a.length === b.length && a.every((v, i) => v === b[i]);
}

export interface CompletionFacts {
  status: TaskStatus;
  templateId?: string | null;
  assignmentState?: string;
  deleted?: boolean;
  completionMode: 'all' | 'any';
  assigneeIds: readonly string[];
  completedByIds: readonly string[];
  needsCheck?: boolean;
}

/**
 * A-02 / D-06: the status the server moves a simple task to once its assignees have finished
 * through completedByIds (every current assignee for 'all', any one of them for 'any'), or null
 * when nothing should change.
 */
export function completionStatus(t: CompletionFacts): 'done' | 'awaiting_check' | null {
  if ((t.templateId ?? null) !== null || t.assignmentState !== 'assigned' || t.deleted === true) return null;
  if (!ACTIVE_STATUSES.includes(t.status)) return null;
  if (t.assigneeIds.length === 0) return null;
  const finished = new Set(t.completedByIds);
  const complete = t.completionMode === 'any'
    ? t.assigneeIds.some((a) => finished.has(a))
    : t.assigneeIds.every((a) => finished.has(a));
  if (!complete) return null;
  return t.needsCheck === true ? 'awaiting_check' : 'done';
}
