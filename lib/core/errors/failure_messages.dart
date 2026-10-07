import '../localization/generated/app_localizations.dart';
import 'app_failure.dart';

/// Turns an [AppFailure] into a short, friendly, localized sentence.
///
/// Permission-denied and not-found deliberately return the same text
/// (spec 4.8: "Anyone else gets 'not found', as if the task does not exist").
String failureMessage(AppFailure failure, AppLocalizations l10n) {
  return switch (failure) {
    NetworkFailure() => l10n.errorNetwork,
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

/// 24-hour clock time (e.g. `10:42`), the format used in Tanzania in both
/// languages. Does not depend on intl date data being loaded.
String formatClockTime(DateTime time) {
  final local = time.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}
