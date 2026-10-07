import 'package:flutter/foundation.dart';

/// Why a [ValidationFailure] happened. Each reason has its own friendly
/// message in the ARB files.
enum ValidationReason {
  invalidPhoneNumber,
  invalidCode,
  invalidEmail,
  wrongCredentials,
  invalidInput,
}

/// Every error the UI can show. Raw Firebase errors never reach widgets:
/// they are converted with `mapFirebaseException` / `mapFirebaseAuthException`
/// in `failure_mapper.dart` and shown with `failureMessage` in
/// `failure_messages.dart`.
///
/// [PermissionDeniedFailure] and [NotFoundFailure] are kept apart for logs
/// and tests, but users always see the same "not found" message so that a
/// confidential task is indistinguishable from a task that does not exist
/// (spec 4.8).
@immutable
sealed class AppFailure implements Exception {
  const AppFailure({this.code});

  /// The original error code (e.g. `permission-denied`), for logs only.
  /// Never shown to users.
  final String? code;

  @override
  String toString() => '$runtimeType(code: $code)';
}

/// No connection, or the server could not be reached in time.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.code});
}

/// Security rules refused the request. Shown as "not found".
final class PermissionDeniedFailure extends AppFailure {
  const PermissionDeniedFailure({super.code});
}

/// The document does not exist. Same message as [PermissionDeniedFailure].
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.code});
}

/// The user is not signed in (or the token is no longer valid).
final class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure({super.code});
}

/// The phone number or email has not been added by an administrator, or the
/// account was deactivated.
final class NotInvitedFailure extends AppFailure {
  const NotInvitedFailure({super.code});
}

/// The session is older than the session policy allows, or the code expired.
final class SessionExpiredFailure extends AppFailure {
  const SessionExpiredFailure({super.code});
}

/// Too many attempts (e.g. SMS codes). Added beyond the Sprint 0 brief
/// because Firebase Auth reports it often on shared phones.
final class TooManyAttemptsFailure extends AppFailure {
  const TooManyAttemptsFailure({super.code});
}

/// The input was not accepted.
final class ValidationFailure extends AppFailure {
  const ValidationFailure(this.reason, {super.code});

  final ValidationReason reason;

  @override
  String toString() => 'ValidationFailure(reason: ${reason.name}, code: $code)';
}

/// Someone else changed the same thing first. For workflow steps the server
/// fills [alreadyApprovedBy] and [at] (spec 4.9 step 5:
/// "This step was already approved by Asha at 10:42.").
final class ConflictFailure extends AppFailure {
  const ConflictFailure({this.alreadyApprovedBy, this.at, super.code});

  final String? alreadyApprovedBy;
  final DateTime? at;

  @override
  String toString() =>
      'ConflictFailure(code: $code, hasActor: '
      '${alreadyApprovedBy != null}, at: $at)';
}

/// Anything else. Logged in full; the user sees a generic message.
final class UnknownFailure extends AppFailure {
  const UnknownFailure({super.code, this.cause});

  final Object? cause;
}
