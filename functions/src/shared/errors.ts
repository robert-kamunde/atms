/**
 * Error codes returned to the app. The app maps each code to a friendly, translated
 * message; raw Firebase errors are never shown (master instructions, "Error handling").
 */
export const ErrorCode = {
  notInvited: 'not-invited',
  sessionExpired: 'session-expired',
  adminVerificationRequired: 'admin-verification-required',
  notFound: 'not-found', // also used when access is denied, so confidential tasks look absent
  notStepOwner: 'not-step-owner',
  stepAlreadyMoved: 'step-already-moved',
  missingComment: 'missing-comment',
  invalidTargetStep: 'invalid-target-step',
  roleHasNoMembers: 'role-has-no-members',
  reportingLoop: 'reporting-loop',
  smsCapReached: 'sms-cap-reached',
  validation: 'validation',
  internal: 'internal',
} as const;
export type ErrorCode = (typeof ErrorCode)[keyof typeof ErrorCode];
