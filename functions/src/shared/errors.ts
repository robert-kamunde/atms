/**
 * Error codes returned to the app. The app maps each code to a friendly, translated
 * message; raw Firebase errors are never shown (master instructions, "Error handling").
 */
import type { FunctionsErrorCode } from 'firebase-functions/v2/https';

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
