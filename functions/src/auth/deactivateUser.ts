/**
 * deactivateUser (docs/SPRINT1_CONTRACT.md, PDD 4.1 "When a user leaves"): a verified admin
 * deactivates a user. The rules refuse the user at once (they check `active`), refresh tokens
 * are revoked so the app is signed out within the hour, and the user's open tasks are flagged
 * for reassignment. People who report to them keep that supervisor until an admin changes it.
 */
import { FieldPath } from 'firebase-admin/firestore';
import { AtmsError, ErrorCode } from '../shared/errors';
import { log } from '../shared/logger';
import { scrubText } from '../shared/redact';
import type { Task, User } from '../shared/model';
import { requireVerifiedAdmin } from '../security/caller';
import { paths, type CallerAuth, type Deps } from './deps';
import { validateUidInput } from './validation';

const TASK_PAGE = 200;
const OPEN_STATUSES = new Set(['todo', 'in_progress', 'blocked']);
export const REASSIGNMENT_REASON_DEACTIVATED = 'user_deactivated';

export async function deactivateUser(deps: Deps, callerAuth: CallerAuth | undefined, data: unknown): Promise<{ flaggedTaskCount: number }> {
  const caller = await requireVerifiedAdmin(deps.db, callerAuth, deps.now());
  const { uid } = validateUidInput(data);
  const org = caller.orgId;
  const db = deps.db;
  if (uid === caller.uid) {
    throw new AtmsError('failed-precondition', ErrorCode.selfDeactivation, 'You cannot deactivate yourself.');
  }

  await db.runTransaction(async (tx) => {
    const ref = db.doc(paths.user(org, uid));
    const snap = await tx.get(ref);
    if (!snap.exists) throw new AtmsError('not-found', ErrorCode.notFound, 'User not found.');
    const user = snap.data() as User;
    if (user.role === 'admin' && user.active) {
      const admins = await tx.get(db.collection(paths.users(org)).where('role', '==', 'admin').where('active', '==', true).limit(2));
      if (admins.size <= 1) throw new AtmsError('failed-precondition', ErrorCode.lastAdmin, 'The last administrator cannot be deactivated.');
    }
    tx.update(ref, { active: false });
  });

  try {
    await deps.auth.revokeRefreshTokens(uid);
  } catch (err) {
    // A user document without an Auth account has no session to end; anything else is a real failure.
    if ((err as { code?: string })?.code !== 'auth/user-not-found') throw err;
    log.warn('deactivate_user_no_auth_account', { orgId: org, uid });
  }

  const flaggedTaskCount = await flagOpenTasks(deps, org, uid);
  // TODO(Sprint 4, notifications): tell the user's supervisor that these tasks need reassigning.
  log.info('user_deactivated', { orgId: org, uid, by: caller.uid, flaggedTaskCount });
  return { flaggedTaskCount };
}

/** Flags the user's open tasks in pages, so a user with thousands of tasks never needs one huge read. */
export async function flagOpenTasks(deps: Deps, org: string, uid: string): Promise<number> {
  const db = deps.db;
  let flagged = 0;
  let last: string | null = null;
  for (;;) {
    let q = db.collection(paths.tasks(org)).where('assigneeIds', 'array-contains', uid).orderBy(FieldPath.documentId()).limit(TASK_PAGE);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    const open = page.docs.filter((d) => {
      const t = d.data() as Partial<Task>;
      return OPEN_STATUSES.has(t.status as string) && t.deleted !== true;
    });
    if (open.length > 0) {
      const batch = db.batch();
      for (const d of open) batch.update(d.ref, { reassignmentNeeded: true, reassignmentReason: REASSIGNMENT_REASON_DEACTIVATED });
      try {
        await batch.commit();
      } catch (err) {
        log.error('flag_tasks_failed', { orgId: org, uid, flagged, error: scrubText(String((err as Error)?.message ?? err)) });
        throw err;
      }
      flagged += open.length;
    }
    if (page.size < TASK_PAGE) break;
    last = page.docs[page.size - 1].id;
  }
  return flagged;
}
