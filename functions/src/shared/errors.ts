/**
 * Error codes returned to the app. The app maps each code to a friendly, translated
 * message; raw Firebase errors are never shown (master instructions, "Error handling").
 */
import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';
import { log } from './logger';
import { scrubText } from './redact';

export const ErrorCode = {
  notInvited: 'not-invited',
  accountDeactivated: 'account-deactivated',
  unauthenticated: 'unauthenticated',
  sessionExpired: 'session-expired',
  permissionDenied: 'permission-denied',
  adminVerificationRequired: 'admin-verification-required',
  notFound: 'not-found', // also used when access is denied, so confidential tasks look absent
  notStepOwner: 'not-step-owner',
  stepAlreadyMoved: 'step-already-moved',
  missingComment: 'missing-comment',
  invalidTargetStep: 'invalid-target-step',
  roleHasNoMembers: 'role-has-no-members',
  reportingLoop: 'reporting-loop',
  supervisorInvalid: 'supervisor-invalid', // missing, inactive, the user themself, or another org
  topPersonRequiresSupervisor: 'top-person-requires-supervisor',
  departmentInvalid: 'department-invalid', // missing or inactive
  phoneInUse: 'phone-in-use',
  emailInUse: 'email-in-use',
  emailCannotBeRemoved: 'email-cannot-be-removed',
  selfDemotion: 'self-demotion',
  selfDeactivation: 'self-deactivation',
  lastAdmin: 'last-admin',
  treeBusy: 'tree-busy', // a large reporting-tree update is in progress; retry shortly
  adminEmailMissing: 'admin-email-missing',
  codeInvalid: 'code-invalid',
  codeExpired: 'code-expired',
  codeAttemptsExceeded: 'code-attempts-exceeded',
  codeRateLimited: 'code-rate-limited',
  providerUnavailable: 'provider-unavailable',
  smsCapReached: 'sms-cap-reached',
  validation: 'validation',
  internal: 'internal',
} as const;
export type ErrorCode = (typeof ErrorCode)[keyof typeof ErrorCode];

/**
 * An expected, user-facing failure. Handlers throw it; the callable wrapper turns it into
 * an HttpsError with `details.code` for the app's failure mapper.
 */
export class AtmsError extends Error {
  constructor(
    readonly httpsCode: FunctionsErrorCode,
    readonly code: ErrorCode,
    message: string,
    readonly details: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = 'AtmsError';
  }
}

export const validationError = (field: string, message: string) =>
  new AtmsError('invalid-argument', ErrorCode.validation, message, { field });

/**
 * Converts anything thrown by a handler into an HttpsError. Expected failures are logged as
 * warnings; anything else is logged as an error (scrubbed of contact details) and returned to
 * the app as `internal`, never with its raw message.
 */
export function toHttpsError(err: unknown, fn: string): HttpsError {
  if (err instanceof AtmsError) {
    log.warn('callable_refused', { fn, code: err.code, ...err.details });
    return new HttpsError(err.httpsCode, err.message, { ...err.details, code: err.code });
  }
  if (err instanceof HttpsError) {
    log.warn('callable_refused', { fn, httpsCode: err.code });
    return err;
  }
  const e = err as { name?: string; code?: unknown; message?: string; stack?: string };
  log.error('callable_failed', {
    fn,
    errorName: e?.name,
    errorCode: typeof e?.code === 'string' ? e.code : undefined,
    errorMessage: scrubText(String(e?.message ?? err)),
  });
  return new HttpsError('internal', 'Something went wrong. Please try again.', { code: ErrorCode.internal });
}
