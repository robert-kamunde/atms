/// Error codes the Cloud Functions return in `HttpsError.details.code`
/// (`functions/src/shared/errors.ts`, docs/SPRINT1_CONTRACT.md).
///
/// Each code has a friendly, translated message (`failure_messages.dart`).
/// Codes the app does not know fall back to the gRPC status mapping in
/// `failure_mapper.dart`. The workflow codes (`not-step-owner`, ...) are
/// mapped when the workflow screens are built (Sprint 3).
enum ServerErrorCode {
  notInvited('not-invited'),
  accountDeactivated('account-deactivated'),
  sessionExpired('session-expired'),
  unauthenticated('unauthenticated'),
  permissionDenied('permission-denied'),
  adminVerificationRequired('admin-verification-required'),
  notFound('not-found'),
  validation('validation'),
  internal('internal'),

  // User management (adminUpsertUser, deactivateUser).
  reportingLoop('reporting-loop'),
  supervisorInvalid('supervisor-invalid'),
  topPersonRequiresSupervisor('top-person-requires-supervisor'),
  departmentInvalid('department-invalid'),
  phoneInUse('phone-in-use'),
  emailInUse('email-in-use'),
  emailCannotBeRemoved('email-cannot-be-removed'),
  selfDemotion('self-demotion'),
  selfDeactivation('self-deactivation'),
  lastAdmin('last-admin'),

  /// Another change to the reporting tree is running; safe to retry.
  treeBusy('tree-busy'),

  // Admin second factor (sendAdminCode, verifyAdminCode).
  adminEmailMissing('admin-email-missing'),
  codeInvalid('code-invalid'),
  codeExpired('code-expired'),
  codeAttemptsExceeded('code-attempts-exceeded'),
  codeRateLimited('code-rate-limited'),

  // Tasks (onTaskCreated, reassignTask; docs/SPRINT2_CONTRACT.md).
  /// The creator may not assign one of the people (spec 2 matrix).
  assigneeNotAllowed('assignee-not-allowed'),

  /// One of the people is deactivated or not in the organisation.
  assigneeInactive('assignee-inactive'),

  /// The task does not exist or the caller cannot read it (shown as "not
  /// found", A-17).
  taskNotFound('task-not-found'),

  /// The task is finished or cancelled (or is a workflow task).
  taskClosed('task-closed'),

  /// The SMS or email provider is down.
  providerUnavailable('provider-unavailable'),
  smsCapReached('sms-cap-reached');

  const ServerErrorCode(this.wireValue);

  /// The exact string in `HttpsError.details.code`.
  final String wireValue;

  /// The code for [raw], or null when the app does not know it.
  static ServerErrorCode? tryParse(Object? raw) {
    for (final code in values) {
      if (code.wireValue == raw) return code;
    }
    return null;
  }
}
