/**
 * Identity Platform blocking functions (D-02, docs/SPRINT1_CONTRACT.md). Every account is
 * created by adminUpsertUser through the Admin SDK, which does not run blocking functions, so
 * any account creation that reaches beforeUserCreated came from the app and is refused: an
 * unknown phone number is turned away before an account exists. Sign-in is refused for users
 * who are not (or no longer) active members of an organisation.
 */
import type { Firestore } from 'firebase-admin/firestore';
import { ErrorCode } from '../shared/errors';
import type { User } from '../shared/model';
import { paths } from './deps';

export type BlockingDecision = 'allow' | typeof ErrorCode.notInvited | typeof ErrorCode.accountDeactivated;

export function beforeCreateDecision(): BlockingDecision {
  return ErrorCode.notInvited;
}

export async function beforeSignInDecision(
  db: Firestore,
  user: { uid: string; customClaims?: Record<string, unknown> },
): Promise<BlockingDecision> {
  const orgId = user.customClaims?.orgId;
  if (typeof orgId !== 'string' || orgId.length === 0) return ErrorCode.notInvited;
  const snap = await db.doc(paths.user(orgId, user.uid)).get();
  if (!snap.exists) return ErrorCode.notInvited;
  return (snap.data() as User).active === true ? 'allow' : ErrorCode.accountDeactivated;
}
