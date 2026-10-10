/**
 * Audit log logic (PDD 4.11, A-15, SPRINT2_CONTRACT "Audit"): which actions a task write
 * contains, what each entry records, whether the change was made offline, and the
 * deterministic entry ids that make trigger retries write nothing twice. Pure functions, unit
 * tested without Firestore.
 */

export type AuditAction =
  | 'task_created' | 'task_assigned' | 'task_rejected' | 'task_reassigned' | 'status_changed'
  | 'deadline_changed' | 'task_edited' | 'task_cancelled' | 'task_deleted' | 'task_completed_by'
  | 'check_returned' | 'user_added' | 'user_updated' | 'user_deactivated';

/** Actor id for changes the server makes on its own (completion, assignment checks). */
export const SYSTEM_ACTOR = 'system';

/** A change is offline when the client's clock is more than this behind the server's commit time. */
export const OFFLINE_THRESHOLD_MS = 60_000;

export interface AuditChange {
  action: AuditAction;
  before: Record<string, unknown> | null;
  after: Record<string, unknown> | null;
}

type Doc = Record<string, unknown>;

interface TimestampLike {
  toMillis(): number;
}

function isTimestamp(v: unknown): v is TimestampLike {
  return typeof v === 'object' && v !== null && typeof (v as TimestampLike).toMillis === 'function';
}

/** Deep equality for Firestore values (Timestamps, arrays, maps, primitives). */
export function sameValue(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (isTimestamp(a) && isTimestamp(b)) return a.toMillis() === b.toMillis();
  if (Array.isArray(a) && Array.isArray(b)) return a.length === b.length && a.every((v, i) => sameValue(v, b[i]));
  if (a && b && typeof a === 'object' && typeof b === 'object' && !Array.isArray(a) && !Array.isArray(b)) {
    const ka = Object.keys(a as Doc);
    const kb = Object.keys(b as Doc);
    return ka.length === kb.length && ka.every((k) => sameValue((a as Doc)[k], (b as Doc)[k]));
  }
  return false;
}

/** Field names whose value differs between two versions of a document. */
export function changedKeys(before: Doc, after: Doc): Set<string> {
  const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
  return new Set([...keys].filter((k) => !sameValue(before[k], after[k])));
}

/**
 * madeOffline (contract): the write carried a clientUpdatedAt (a new value, not one left over
 * from an earlier write) more than 60 seconds older than the server's commit time.
 */
export function isMadeOffline(before: Doc | null, after: Doc): boolean {
  const client = after.clientUpdatedAt;
  const server = after.updatedAt ?? after.createdAt;
  if (!isTimestamp(client) || !isTimestamp(server)) return false;
  if (before && sameValue(before.clientUpdatedAt, client)) return false;
  return server.toMillis() - client.toMillis() > OFFLINE_THRESHOLD_MS;
}

/** Entry id derived from the trigger event id and the action, so a retried event rewrites nothing. */
export function auditEntryId(eventId: string, action: string): string {
  return `${eventId.replace(/[^A-Za-z0-9_-]/g, '_')}-${action}`;
}

/**
 * Fields only Cloud Functions change (the rules refuse them from the app). A write that changes
 * any of them was made by a server function, which writes its own audit entry.
 */
export const SERVER_FIELDS = [
  'assignmentState', 'assignmentError', 'viewerIds', 'assigneeIds', 'reassignmentNeeded', 'reassignmentReason',
  'templateVersion', 'currentStep', 'stepDeadline', 'escalationLevel', 'overdue', 'remindersSent',
  'creatorId', 'deptId', 'confidential', 'participantIds', 'templateId',
] as const;

const EDIT_FIELDS = ['title', 'description', 'priority', 'needsCheck'] as const;
const RESUBMIT_FIELDS = ['title', 'description', 'priority', 'deadline', 'assigneeIds', 'completionMode', 'needsCheck'] as const;

/** The fields recorded for task_created. */
const CREATED_FIELDS = [
  'title', 'description', 'priority', 'deadline', 'status', 'assigneeIds', 'participantIds', 'deptId',
  'confidential', 'completionMode', 'needsCheck', 'templateId',
] as const;

function pick(doc: Doc, keys: readonly string[]): Doc {
  const out: Doc = {};
  for (const k of keys) if (doc[k] !== undefined) out[k] = doc[k];
  return out;
}

function pickChanged(before: Doc, after: Doc, keys: readonly string[]): { before: Doc; after: Doc } | null {
  const changed = keys.filter((k) => !sameValue(before[k], after[k]));
  if (changed.length === 0) return null;
  const b: Doc = {};
  const a: Doc = {};
  for (const k of changed) {
    b[k] = before[k] ?? null;
    a[k] = after[k] ?? null;
  }
  return { before: b, after: a };
}

export function createdSnapshot(task: Doc): Doc {
  return pick(task, CREATED_FIELDS);
}

/** True when this write is the creator resubmitting a rejected task (rejected -> pending). */
export function isResubmission(before: Doc, after: Doc): boolean {
  return before.assignmentState === 'rejected' && after.assignmentState === 'pending' && after.updatedBy !== SYSTEM_ACTOR;
}

/**
 * The actions in one write made from the app, one entry each. Writes made by server functions
 * (updatedBy 'system', or any server-only field changed) return nothing: those functions audit
 * themselves. A resubmission is recorded as task_edited; its assignment result is audited by
 * the assignment check.
 */
export function classifyTaskUpdate(before: Doc, after: Doc): AuditChange[] {
  if (after.updatedBy === SYSTEM_ACTOR) return [];
  if (isResubmission(before, after)) {
    const d = pickChanged(before, after, RESUBMIT_FIELDS);
    return d ? [{ action: 'task_edited', ...d }] : [];
  }
  const changed = changedKeys(before, after);
  if (SERVER_FIELDS.some((f) => changed.has(f))) return [];

  const out: AuditChange[] = [];
  if (changed.has('deleted') && after.deleted === true) {
    out.push({ action: 'task_deleted', before: { deleted: before.deleted ?? false }, after: { deleted: true } });
  }
  if (changed.has('status')) {
    const from = before.status;
    const to = after.status;
    if (to === 'cancelled') {
      out.push({ action: 'task_cancelled', before: { status: from }, after: { status: to, cancelReason: after.cancelReason ?? null } });
    } else if (from === 'awaiting_check' && to === 'in_progress') {
      out.push({ action: 'check_returned', before: { status: from }, after: { status: to, returnReason: after.returnReason ?? null } });
    } else {
      const a: Doc = { status: to };
      if (to === 'blocked') a.blockedReason = after.blockedReason ?? null;
      out.push({ action: 'status_changed', before: { status: from }, after: a });
    }
  }
  if (changed.has('completedByIds')) {
    const prev = new Set((before.completedByIds as string[] | undefined) ?? []);
    const added = ((after.completedByIds as string[] | undefined) ?? []).filter((u) => !prev.has(u));
    if (added.length > 0) {
      out.push({ action: 'task_completed_by', before: { completedByIds: before.completedByIds ?? [] }, after: { completedByIds: after.completedByIds } });
    }
  }
  if (changed.has('deadline')) {
    out.push({ action: 'deadline_changed', before: { deadline: before.deadline ?? null }, after: { deadline: after.deadline ?? null } });
  }
  const edit = pickChanged(before, after, EDIT_FIELDS);
  if (edit) out.push({ action: 'task_edited', ...edit });
  return out;
}

/** Fields of a user recorded by user_added and user_updated (contact details included: only verified admins read these entries). */
export const USER_AUDIT_FIELDS = [
  'name', 'role', 'deptId', 'supervisorId', 'jobRole', 'language', 'confidentialDepts', 'active', 'phone', 'email',
] as const;

/** before/after of a user change, or null when nothing recorded changed. */
export function userAuditDiff(before: Doc | null, after: Doc): { before: Doc | null; after: Doc } | null {
  if (!before) return { before: null, after: pick(after, USER_AUDIT_FIELDS) };
  const d = pickChanged(before, after, USER_AUDIT_FIELDS);
  return d ? { before: d.before, after: d.after } : null;
}
