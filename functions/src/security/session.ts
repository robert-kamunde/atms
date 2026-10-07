/**
 * Session and admin second-factor checks used by callable functions. They mirror the
 * Security Rules (firestore.rules: sessionFresh, isVerifiedAdmin) so both layers agree.
 */
import type { Role } from '../shared/model';

export const SESSION_DAYS: Record<Role, number> = { admin: 7, manager: 30, staff: 30 };
const DAY_SECONDS = 86_400;

export interface AtmsClaims {
  orgId?: string;
  auth_time?: number; // seconds since epoch of the last real sign-in
  adminVerifiedUntil?: number; // seconds since epoch
}

export function isSessionFresh(claims: AtmsClaims, role: Role, nowSeconds: number): boolean {
  if (typeof claims.auth_time !== 'number') return false;
  return claims.auth_time > nowSeconds - SESSION_DAYS[role] * DAY_SECONDS;
}

export function isAdminVerified(claims: AtmsClaims, role: Role, nowSeconds: number): boolean {
  return role === 'admin'
    && isSessionFresh(claims, role, nowSeconds)
    && typeof claims.adminVerifiedUntil === 'number'
    && claims.adminVerifiedUntil > nowSeconds;
}
