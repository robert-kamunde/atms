/**
 * Builds audit entries (orgs/{org}/audit/{entryId}) in the shape of the contract. Only server
 * code writes them (the rules refuse every app write). viewerIds and confidential are copied
 * from the task after the change so the rules can decide who reads each entry (A-15).
 */
import { FieldValue, type Firestore, type Timestamp, type Transaction } from 'firebase-admin/firestore';
import { paths } from '../auth/deps';
import type { AuditAction, AuditChange } from './audit';

export interface AuditDoc {
  taskId: string | null;
  actorId: string;
  action: AuditAction;
  before: Record<string, unknown> | null;
  after: Record<string, unknown> | null;
  at: Timestamp | FieldValue;
  madeOffline: boolean;
  viewerIds: string[];
  confidential: boolean;
  /** [deviation] user entries only: whose account changed (taskId is null for them). */
  subjectUid?: string;
}

export function taskAuditDoc(
  taskId: string,
  actorId: string,
  change: AuditChange,
  task: { viewerIds: readonly string[]; confidential: boolean },
  opts: { at?: Timestamp | null; madeOffline?: boolean } = {},
): AuditDoc {
  return {
    taskId,
    actorId,
    action: change.action,
    before: change.before,
    after: change.after,
    at: opts.at ?? FieldValue.serverTimestamp(),
    madeOffline: opts.madeOffline ?? false,
    viewerIds: [...task.viewerIds],
    confidential: task.confidential === true,
  };
}

/**
 * User entries (user_added, user_updated, user_deactivated): taskId null and viewerIds empty,
 * so only verified admins read them. Written inside the caller's transaction, so the entry
 * exists exactly when the change does.
 */
export function writeUserAudit(
  tx: Transaction,
  db: Firestore,
  org: string,
  actorId: string,
  action: Extract<AuditAction, 'user_added' | 'user_updated' | 'user_deactivated'>,
  subjectUid: string,
  change: { before: Record<string, unknown> | null; after: Record<string, unknown> },
): void {
  const entry: AuditDoc = {
    taskId: null,
    actorId,
    action,
    before: change.before,
    after: change.after,
    at: FieldValue.serverTimestamp(),
    madeOffline: false,
    viewerIds: [],
    confidential: false,
    subjectUid,
  };
  tx.create(db.collection(paths.audit(org)).doc(), entry);
}
