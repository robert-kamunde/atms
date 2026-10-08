/**
 * Caller checks for callable functions. They mirror the Security Rules (isMember,
 * isVerifiedAdmin in firestore.rules) so both layers agree: the orgId claim, an active user
 * document, a fresh session and, for admin powers, a current second-factor claim.
 */
import type { Firestore } from 'firebase-admin/firestore';
import { AtmsError, ErrorCode } from '../shared/errors';
import type { Role } from '../shared/model';
import { isAdminVerified, isSessionFresh, type AtmsClaims } from './session';

export interface Caller {
  uid: string;
  orgId: string;
  role: Role;
  claims: AtmsClaims;
}

interface CallerAuthLike {
  uid: string;
  token: Record<string, unknown>;
}

export async function requireMember(db: Firestore, auth: CallerAuthLike | undefined, nowMs: number): Promise<Caller> {
  if (!auth) throw new AtmsError('unauthenticated', ErrorCode.unauthenticated, 'Please sign in.');
  const orgId = auth.token.orgId;
  if (typeof orgId !== 'string' || orgId.length === 0) {
    throw new AtmsError('permission-denied', ErrorCode.notInvited, 'Ask your administrator to add you.');
  }
  const snap = await db.doc(`orgs/${orgId}/users/${auth.uid}`).get();
  if (!snap.exists) throw new AtmsError('permission-denied', ErrorCode.notInvited, 'Ask your administrator to add you.');
  const user = snap.data() as { role: Role; active: boolean };
  if (user.active !== true) throw new AtmsError('permission-denied', ErrorCode.accountDeactivated, 'This account is deactivated.');
  const claims: AtmsClaims = {
    orgId,
    auth_time: typeof auth.token.auth_time === 'number' ? auth.token.auth_time : undefined,
    adminVerifiedUntil: typeof auth.token.adminVerifiedUntil === 'number' ? auth.token.adminVerifiedUntil : undefined,
  };
  if (!isSessionFresh(claims, user.role, Math.floor(nowMs / 1000))) {
    throw new AtmsError('unauthenticated', ErrorCode.sessionExpired, 'Please sign in again.');
  }
  return { uid: auth.uid, orgId, role: user.role, claims };
}

/** An admin, second factor not needed (for sending and checking the second-factor code). */
export async function requireAdmin(db: Firestore, auth: CallerAuthLike | undefined, nowMs: number): Promise<Caller> {
  const caller = await requireMember(db, auth, nowMs);
  if (caller.role !== 'admin') throw new AtmsError('permission-denied', ErrorCode.permissionDenied, 'Only administrators can do this.');
  return caller;
}

/** An admin who has passed the second factor (adminVerifiedUntil in the future). */
export async function requireVerifiedAdmin(db: Firestore, auth: CallerAuthLike | undefined, nowMs: number): Promise<Caller> {
  const caller = await requireAdmin(db, auth, nowMs);
  if (!isAdminVerified(caller.claims, caller.role, Math.floor(nowMs / 1000))) {
    throw new AtmsError('permission-denied', ErrorCode.adminVerificationRequired, 'Confirm the code sent to your e-mail first.');
  }
  return caller;
}
