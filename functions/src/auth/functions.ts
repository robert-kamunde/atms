/**
 * Cloud Functions wrappers for Sprint 1. They only extract the caller, choose providers and map
 * errors; the logic lives in the handler modules, which take their dependencies as arguments.
 * App Check is in monitor mode (D-04): a missing token is logged, never refused.
 */
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { defineString } from 'firebase-functions/params';
import { onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { beforeUserCreated, beforeUserSignedIn, HttpsError } from 'firebase-functions/v2/identity';
import { EmulatorEmailProvider } from '../notifications/email/emulatorProvider';
import type { EmailProvider } from '../notifications/email/provider';
import { EmulatorSmsProvider } from '../notifications/sms/emulatorProvider';
import type { SmsProvider } from '../notifications/sms/provider';
import { currentProjectId, isEmulatorProject, REGION } from '../shared/config';
import { AtmsError, ErrorCode, toHttpsError } from '../shared/errors';
import { log } from '../shared/logger';
import { scrubText } from '../shared/redact';
import { sendAdminCode, verifyAdminCode } from './adminCodeHandlers';
import { beforeCreateDecision, beforeSignInDecision } from './blocking';
import { deactivateUser } from './deactivateUser';
import type { CallerAuth, Deps } from './deps';
import { adminUpsertUser } from './upsertUser';

/** Link in the invitation SMS (set per project in functions/.env.<projectId>). */
const APP_DOWNLOAD_URL = defineString('APP_DOWNLOAD_URL', { description: 'Download link sent in the invitation SMS' });

let sms: SmsProvider | undefined;
let email: EmailProvider | undefined;

function smsProvider(): SmsProvider {
  const id = currentProjectId();
  // The real provider arrives with D-09 (Sprint 4); until then only the emulator can send.
  if (!isEmulatorProject(id)) throw new AtmsError('failed-precondition', ErrorCode.providerUnavailable, 'No SMS provider is configured yet (D-09).');
  sms ??= new EmulatorSmsProvider(id);
  return sms;
}

function emailProvider(): EmailProvider {
  const id = currentProjectId();
  // The real provider arrives with D-08; until then only the emulator can send.
  if (!isEmulatorProject(id)) throw new AtmsError('failed-precondition', ErrorCode.providerUnavailable, 'No e-mail provider is configured yet (D-08).');
  // MOCK/TEMPORARY: in the emulator, e-mails land in the top-level `emulatorOutbox` collection
  // (no rule allows any app to read it) so a developer can read the admin code in the Emulator UI.
  email ??= new EmulatorEmailProvider(id, async (m) => {
    await getFirestore().collection('emulatorOutbox').add({ ...m, createdAt: new Date() });
  });
  return email;
}

function deps(): Deps {
  return {
    db: getFirestore(),
    auth: getAuth(),
    sms: smsProvider,
    email: emailProvider,
    now: () => Date.now(),
    appDownloadUrl: () => APP_DOWNLOAD_URL.value(),
  };
}

function callable<O>(name: string, handler: (d: Deps, caller: CallerAuth | undefined, data: unknown) => Promise<O>) {
  return onCall({ region: REGION, enforceAppCheck: false }, async (req: CallableRequest<unknown>) => {
    if (!req.app) log.warn('app_check_missing', { fn: name });
    const caller = req.auth ? { uid: req.auth.uid, token: req.auth.token as unknown as Record<string, unknown> } : undefined;
    try {
      return await handler(deps(), caller, req.data);
    } catch (err) {
      throw toHttpsError(err, name);
    }
  });
}

export const adminUpsertUserFn = callable('adminUpsertUser', adminUpsertUser);
export const deactivateUserFn = callable('deactivateUser', deactivateUser);
export const sendAdminCodeFn = callable('sendAdminCode', sendAdminCode);
export const verifyAdminCodeFn = callable('verifyAdminCode', verifyAdminCode);

export const beforeUserCreatedFn = beforeUserCreated({ region: REGION }, () => {
  log.warn('blocked_sign_up');
  throw new HttpsError('permission-denied', beforeCreateDecision());
});

export const beforeUserSignedInFn = beforeUserSignedIn({ region: REGION }, async (event) => {
  let decision;
  try {
    decision = await beforeSignInDecision(getFirestore(), { uid: event.data?.uid ?? '', customClaims: event.data?.customClaims });
  } catch (err) {
    // Fail closed: if membership cannot be checked, the sign-in is refused.
    log.error('before_sign_in_failed', { uid: event.data?.uid, error: scrubText(String((err as Error)?.message ?? err)) });
    throw new HttpsError('unavailable', ErrorCode.internal);
  }
  if (decision !== 'allow') {
    log.warn('blocked_sign_in', { uid: event.data?.uid, reason: decision });
    throw new HttpsError('permission-denied', decision);
  }
});
