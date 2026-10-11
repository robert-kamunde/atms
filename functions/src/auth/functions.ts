/**
 * Cloud Functions wrappers for Sprint 1. They only extract the caller, choose providers and map
 * errors; the logic lives in the handler modules, which take their dependencies as arguments.
 * App Check is in monitor mode (D-04): a missing token is logged, never refused.
 */
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { defineSecret, defineString } from 'firebase-functions/params';
import { onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { beforeUserCreated, beforeUserSignedIn, HttpsError } from 'firebase-functions/v2/identity';
import { EmulatorEmailProvider } from '../notifications/email/emulatorProvider';
import type { EmailProvider } from '../notifications/email/provider';
import { BeemSmsProvider, beemConfigProblems } from '../notifications/sms/beemProvider';
import { EmulatorSmsProvider } from '../notifications/sms/emulatorProvider';
import type { SmsProvider } from '../notifications/sms/provider';
import { currentProjectId, isEmulatorProject, REGION } from '../shared/config';
import { AtmsError, ErrorCode } from '../shared/errors';
import { toHttpsError } from '../shared/httpsErrors';
import { log } from '../shared/logger';
import { scrubText } from '../shared/redact';
import { sendAdminCode, verifyAdminCode } from './adminCodeHandlers';
import { beforeCreateDecision, beforeSignInDecision } from './blocking';
import { deactivateUser } from './deactivateUser';
import type { CallerAuth, Deps } from './deps';
import { adminUpsertUser } from './upsertUser';

/** Link in the invitation SMS (set per project in functions/.env.<projectId>). */
const APP_DOWNLOAD_URL = defineString('APP_DOWNLOAD_URL', { description: 'Download link sent in the invitation SMS' });

/** SMS through Beem (D-09); sender name per project in functions/.env.<projectId>, keys in Secret Manager. */
const SMS_SENDER_ID = defineString('SMS_SENDER_ID', { default: '', description: 'Approved SMS sender name, for example ATMS' });
const BEEM_API_KEY = defineSecret('BEEM_API_KEY');
const BEEM_SECRET_KEY = defineSecret('BEEM_SECRET_KEY');

let sms: SmsProvider | undefined;
let email: EmailProvider | undefined;

function smsProvider(): SmsProvider {
  if (sms) return sms;
  const id = currentProjectId();
  if (isEmulatorProject(id)) {
    sms = new EmulatorSmsProvider(id);
    return sms;
  }
  const config = { apiKey: BEEM_API_KEY.value(), secretKey: BEEM_SECRET_KEY.value(), senderId: SMS_SENDER_ID.value() };
  const problems = beemConfigProblems(config);
  if (problems.length > 0) {
    log.error('sms_not_configured', { missing: problems.join(',') });
    throw new AtmsError('failed-precondition', ErrorCode.providerUnavailable, 'No SMS provider is configured yet (D-09).');
  }
  sms = new BeemSmsProvider(config);
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

function callable<O>(
  name: string,
  handler: (d: Deps, caller: CallerAuth | undefined, data: unknown) => Promise<O>,
  secrets: ReturnType<typeof defineSecret>[] = [],
) {
  return onCall({ region: REGION, enforceAppCheck: false, secrets }, async (req: CallableRequest<unknown>) => {
    if (!req.app) log.warn('app_check_missing', { fn: name });
    const caller = req.auth ? { uid: req.auth.uid, token: req.auth.token as unknown as Record<string, unknown> } : undefined;
    try {
      return await handler(deps(), caller, req.data);
    } catch (err) {
      throw toHttpsError(err, name);
    }
  });
}

export const adminUpsertUserFn = callable('adminUpsertUser', adminUpsertUser, [BEEM_API_KEY, BEEM_SECRET_KEY]);
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
