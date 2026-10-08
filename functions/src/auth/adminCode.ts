/**
 * Admin second factor (D-01): pure helpers for the e-mailed 6-digit code. The code is stored
 * only as a salted SHA-256 hash; checks are constant-time; limits are 10 minutes per code,
 * 5 verify attempts per code and 5 codes per hour per admin.
 */
import { createHash, randomBytes, randomInt, timingSafeEqual } from 'crypto';
import { SESSION_DAYS } from '../security/session';

export const CODE_TTL_MS = 10 * 60_000;
export const MAX_ATTEMPTS = 5;
export const MAX_CODES_PER_HOUR = 5;
export const HOUR_MS = 3_600_000;
export const VERIFIED_FOR_SECONDS = 12 * 3600;

export interface StoredAdminCode {
  hash: string | null; // null once used or exhausted
  salt: string;
  expiresAtMs: number;
  attempts: number;
  sentAtMs: number[]; // send times within the last hour, for the rate limit
}

export function generateCode(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, '0');
}

export function newSalt(): string {
  return randomBytes(16).toString('hex');
}

export function hashCode(code: string, salt: string): string {
  return createHash('sha256').update(`${salt}:${code}`).digest('hex');
}

/** Constant-time comparison of a candidate code with the stored hash. */
export function codeMatches(candidate: string, salt: string, storedHash: string): boolean {
  const a = Buffer.from(hashCode(candidate, salt), 'hex');
  const b = Buffer.from(storedHash, 'hex');
  return a.length === b.length && timingSafeEqual(a, b);
}

/** Send times still inside the one-hour window. */
export function recentSends(sentAtMs: readonly number[], nowMs: number): number[] {
  return sentAtMs.filter((t) => t > nowMs - HOUR_MS && t <= nowMs);
}

export function canSendCode(sentAtMs: readonly number[], nowMs: number): boolean {
  return recentSends(sentAtMs, nowMs).length < MAX_CODES_PER_HOUR;
}

export type VerifyOutcome = 'ok' | 'no-code' | 'expired' | 'attempts-exceeded' | 'wrong';

/** Decides a verify attempt. The caller stores `attempts + 1` on 'wrong' and clears the hash on 'ok'. */
export function checkCode(stored: StoredAdminCode | undefined, candidate: string, nowMs: number): VerifyOutcome {
  if (!stored || !stored.hash) return 'no-code';
  if (stored.attempts >= MAX_ATTEMPTS) return 'attempts-exceeded';
  if (nowMs >= stored.expiresAtMs) return 'expired';
  return codeMatches(candidate, stored.salt, stored.hash) ? 'ok' : 'wrong';
}

/**
 * The adminVerifiedUntil claim, in epoch seconds: 12 hours from now, never past the end of the
 * 7-day admin session that started at auth_time.
 */
export function verifiedUntilSeconds(nowMs: number, authTimeSeconds: number): number {
  const now = Math.floor(nowMs / 1000);
  return Math.min(now + VERIFIED_FOR_SECONDS, authTimeSeconds + SESSION_DAYS.admin * 86_400);
}
