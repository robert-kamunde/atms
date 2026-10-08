/**
 * sendAdminCode and verifyAdminCode (D-01, docs/SPRINT1_CONTRACT.md): the admin second factor.
 * A 6-digit code is e-mailed to the admin's contact address and stored only as a salted hash in
 * `secure/` (unreadable by any app). A correct code sets the `adminVerifiedUntil` claim.
 */
import { AtmsError, ErrorCode } from '../shared/errors';
import { log } from '../shared/logger';
import type { Language, User, UserContact } from '../shared/model';
import { requireAdmin } from '../security/caller';
import {
  canSendCode, checkCode, CODE_TTL_MS, generateCode, hashCode, MAX_ATTEMPTS, newSalt, recentSends,
  verifiedUntilSeconds, type StoredAdminCode, type VerifyOutcome,
} from './adminCode';
import { paths, type CallerAuth, type Deps } from './deps';
import { adminCodeEmail, maskEmail } from './messages';
import { validateCodeInput, validateEmptyInput } from './validation';

export async function sendAdminCode(deps: Deps, callerAuth: CallerAuth | undefined, data: unknown): Promise<{ maskedEmail: string; expiresAt: number }> {
  const caller = await requireAdmin(deps.db, callerAuth, deps.now());
  validateEmptyInput(data);
  const db = deps.db;
  const org = caller.orgId;

  const [userSnap, contactSnap] = await db.getAll(db.doc(paths.user(org, caller.uid)), db.doc(paths.contact(org, caller.uid)));
  const email = (contactSnap.data() as UserContact | undefined)?.email ?? null;
  if (!email) {
    throw new AtmsError('failed-precondition', ErrorCode.adminEmailMissing, 'Your account has no e-mail address for the admin code. Ask another administrator to add one.');
  }
  const language: Language = (userSnap.data() as User).language === 'sw' ? 'sw' : 'en';
  const provider = deps.email(); // before storing a code, so a missing provider does not use up the hourly limit

  const code = generateCode();
  const nowMs = deps.now();
  const expiresAtMs = nowMs + CODE_TTL_MS;
  const ref = db.doc(paths.adminCode(org, caller.uid));
  await db.runTransaction(async (tx) => {
    const stored = (await tx.get(ref)).data() as StoredAdminCode | undefined;
    const recent = recentSends(stored?.sentAtMs ?? [], nowMs);
    if (!canSendCode(recent, nowMs)) {
      throw new AtmsError('resource-exhausted', ErrorCode.codeRateLimited, 'Too many codes requested. Try again later.');
    }
    const salt = newSalt();
    tx.set(ref, { hash: hashCode(code, salt), salt, expiresAtMs, attempts: 0, sentAtMs: [...recent, nowMs] } satisfies StoredAdminCode);
  });

  const result = await provider.send(adminCodeEmail(language, email, code, CODE_TTL_MS / 60_000));
  if (!result.ok) {
    log.error('admin_code_email_failed', { orgId: org, uid: caller.uid, provider: provider.name, providerError: result.errorCode });
    throw new AtmsError('unavailable', ErrorCode.providerUnavailable, 'The code could not be sent. Try again later.');
  }
  log.info('admin_code_sent', { orgId: org, uid: caller.uid, provider: provider.name });
  return { maskedEmail: maskEmail(email), expiresAt: expiresAtMs };
}

export async function verifyAdminCode(deps: Deps, callerAuth: CallerAuth | undefined, data: unknown): Promise<{ verifiedUntil: number }> {
  const caller = await requireAdmin(deps.db, callerAuth, deps.now());
  const { code } = validateCodeInput(data);
  const db = deps.db;
  const org = caller.orgId;
  const ref = db.doc(paths.adminCode(org, caller.uid));
  const nowMs = deps.now();

  // The attempt is recorded before answering, so the limit holds even if the caller retries fast.
  const { outcome, attempts } = await db.runTransaction(async (tx) => {
    const stored = (await tx.get(ref)).data() as StoredAdminCode | undefined;
    const outcome: VerifyOutcome = checkCode(stored, code, nowMs);
    let attempts = stored?.attempts ?? 0;
    if (outcome === 'wrong') {
      attempts += 1;
      tx.update(ref, { attempts });
    } else if (outcome === 'ok') {
      tx.update(ref, { hash: null }); // single use
    }
    return { outcome, attempts };
  });

  switch (outcome) {
    case 'ok':
      break;
    case 'no-code':
      throw new AtmsError('failed-precondition', ErrorCode.codeInvalid, 'Ask for a new code.', { attemptsLeft: 0 });
    case 'expired':
      throw new AtmsError('deadline-exceeded', ErrorCode.codeExpired, 'This code has expired. Ask for a new one.');
    case 'attempts-exceeded':
      throw new AtmsError('resource-exhausted', ErrorCode.codeAttemptsExceeded, 'Too many wrong codes. Ask for a new one.');
    case 'wrong':
      log.warn('admin_code_wrong', { orgId: org, uid: caller.uid, attempts });
      throw new AtmsError('invalid-argument', ErrorCode.codeInvalid, 'That code is not right.', { attemptsLeft: Math.max(0, MAX_ATTEMPTS - attempts) });
  }

  const until = verifiedUntilSeconds(nowMs, caller.claims.auth_time as number);
  await deps.auth.setCustomUserClaims(caller.uid, { orgId: org, adminVerifiedUntil: until });
  log.info('admin_verified', { orgId: org, uid: caller.uid, until });
  return { verifiedUntil: until * 1000 };
}
