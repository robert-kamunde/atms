import '../localization/generated/app_localizations.dart';
import 'app_failure.dart';
import 'server_error_code.dart';

/// Turns an [AppFailure] into a short, friendly, localized sentence.
///
/// Permission-denied and not-found deliberately return the same text
/// (spec 4.8: "Anyone else gets 'not found', as if the task does not exist").
String failureMessage(AppFailure failure, AppLocalizations l10n) {
  return switch (failure) {
    NetworkFailure() => l10n.errorNetwork,
    ConnectionRequiredFailure() => l10n.errorConnectionRequired,
    AccountDeactivatedFailure() => l10n.errorAccountDeactivated,
    ServerFailure() => serverErrorMessage(failure, l10n),
    PermissionDeniedFailure() || NotFoundFailure() => l10n.errorNotFound,
    UnauthenticatedFailure() => l10n.errorUnauthenticated,
    NotInvitedFailure() => l10n.errorNotInvited,
    SessionExpiredFailure() => l10n.errorSessionExpired,
    TooManyAttemptsFailure() => l10n.errorTooManyAttempts,
    ValidationFailure(:final reason) => switch (reason) {
      ValidationReason.invalidPhoneNumber => l10n.errorInvalidPhone,
      ValidationReason.invalidCode => l10n.errorInvalidCode,
      ValidationReason.invalidEmail => l10n.errorInvalidEmail,
      ValidationReason.wrongCredentials => l10n.errorWrongCredentials,
      ValidationReason.invalidInput => l10n.errorInvalidInput,
    },
    ConflictFailure(:final alreadyApprovedBy, :final at) =>
      (alreadyApprovedBy != null && at != null)
          ? l10n.errorConflictAlreadyApproved(
              alreadyApprovedBy,
              formatClockTime(at),
            )
          : l10n.errorConflict,
    UnknownFailure() => l10n.errorUnknown,
  };
}

/// Message for a business error named by a Cloud Function.
String serverErrorMessage(ServerFailure failure, AppLocalizations l10n) =>
    switch (failure.serverCode) {
      ServerErrorCode.notInvited => l10n.errorNotInvited,
      ServerErrorCode.accountDeactivated => l10n.errorAccountDeactivated,
      ServerErrorCode.sessionExpired => l10n.errorSessionExpired,
      ServerErrorCode.unauthenticated => l10n.errorUnauthenticated,
      ServerErrorCode.permissionDenied => l10n.errorPermissionDenied,
      ServerErrorCode.adminVerificationRequired =>
        l10n.errorAdminVerificationRequired,
      ServerErrorCode.notFound ||
      ServerErrorCode.taskNotFound => l10n.errorNotFound,
      ServerErrorCode.assigneeNotAllowed => l10n.errorAssigneeNotAllowed,
      ServerErrorCode.assigneeInactive => l10n.errorAssigneeInactive,
      ServerErrorCode.taskClosed => l10n.errorTaskClosed,
      ServerErrorCode.validation => l10n.errorInvalidInput,
      ServerErrorCode.internal => l10n.errorUnknown,
      ServerErrorCode.reportingLoop => l10n.errorReportingLoop,
      ServerErrorCode.supervisorInvalid => l10n.errorSupervisorInvalid,
      ServerErrorCode.topPersonRequiresSupervisor =>
        l10n.errorTopPersonRequiresSupervisor,
      ServerErrorCode.departmentInvalid => l10n.errorDepartmentInvalid,
      ServerErrorCode.phoneInUse => l10n.errorPhoneInUse,
      ServerErrorCode.emailInUse => l10n.errorEmailInUse,
      ServerErrorCode.emailCannotBeRemoved => l10n.errorEmailCannotBeRemoved,
      ServerErrorCode.selfDemotion => l10n.errorSelfDemotion,
      ServerErrorCode.selfDeactivation => l10n.errorSelfDeactivation,
      ServerErrorCode.lastAdmin => l10n.errorLastAdmin,
      ServerErrorCode.treeBusy => l10n.errorTreeBusy,
      ServerErrorCode.adminEmailMissing => l10n.errorAdminEmailMissing,
      ServerErrorCode.codeInvalid => switch (failure.attemptsLeft) {
        final int left => l10n.errorAdminCodeWrongAttempts(left),
        null => l10n.errorAdminCodeWrong,
      },
      ServerErrorCode.codeExpired => l10n.errorAdminCodeExpired,
      ServerErrorCode.codeAttemptsExceeded =>
        l10n.errorAdminCodeTooManyAttempts,
      ServerErrorCode.codeRateLimited => l10n.errorRateLimited,
      ServerErrorCode.providerUnavailable => l10n.errorProviderUnavailable,
      ServerErrorCode.smsCapReached => l10n.errorSmsCapReached,
    };

/// 24-hour clock time (e.g. `10:42`), the format used in Tanzania in both
/// languages. Does not depend on intl date data being loaded.
String formatClockTime(DateTime time) {
  final local = time.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

/// Why the server refused to assign a new task (`assignmentError`, A-01),
/// in friendly words. Unknown codes get a general sentence.
String assignmentErrorMessage(String? code, AppLocalizations l10n) {
  final serverCode = ServerErrorCode.tryParse(code);
  if (serverCode == null) return l10n.assignmentRejectedGeneric;
  return serverErrorMessage(ServerFailure(serverCode), l10n);
}
