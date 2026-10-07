import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';
import 'app_failure.dart';

/// Firestore / Storage / Functions error codes and the failure each becomes.
///
/// Codes follow `FirebaseException.code` (gRPC status names in kebab case).
const Map<String, AppFailure Function(String code)> firestoreCodeMap = {
  'unavailable': _network,
  'deadline-exceeded': _network,
  'permission-denied': _permissionDenied,
  'not-found': _notFound,
  'object-not-found': _notFound, // Cloud Storage
  'unauthenticated': _unauthenticated,
  'unauthorized': _permissionDenied, // Cloud Storage
  'already-exists': _conflict,
  'aborted': _conflict,
  'failed-precondition': _conflict,
  'invalid-argument': _invalidInput,
  'out-of-range': _invalidInput,
  'resource-exhausted': _tooManyAttempts,
  'retry-limit-exceeded': _network, // Cloud Storage
};

/// Firebase Auth error codes and the failure each becomes.
const Map<String, AppFailure Function(String code)> authCodeMap = {
  'network-request-failed': _network,
  'timeout': _network,
  'user-not-found': _notInvited,
  'user-disabled': _notInvited,
  'invalid-phone-number': _invalidPhone,
  'missing-phone-number': _invalidPhone,
  'invalid-verification-code': _invalidCode,
  'missing-verification-code': _invalidCode,
  'invalid-verification-id': _sessionExpired,
  'code-expired': _sessionExpired,
  'session-expired': _sessionExpired,
  'user-token-expired': _sessionExpired,
  'requires-recent-login': _sessionExpired,
  'invalid-email': _invalidEmail,
  'wrong-password': _wrongCredentials,
  'invalid-credential': _wrongCredentials,
  'invalid-login-credentials': _wrongCredentials,
  'too-many-requests': _tooManyAttempts,
  'quota-exceeded': _tooManyAttempts,
  'operation-not-allowed': _unknown,
};

AppFailure _network(String code) => NetworkFailure(code: code);
AppFailure _permissionDenied(String code) =>
    PermissionDeniedFailure(code: code);
AppFailure _notFound(String code) => NotFoundFailure(code: code);
AppFailure _unauthenticated(String code) => UnauthenticatedFailure(code: code);
AppFailure _notInvited(String code) => NotInvitedFailure(code: code);
AppFailure _sessionExpired(String code) => SessionExpiredFailure(code: code);
AppFailure _tooManyAttempts(String code) => TooManyAttemptsFailure(code: code);
AppFailure _conflict(String code) => ConflictFailure(code: code);
AppFailure _invalidInput(String code) =>
    ValidationFailure(ValidationReason.invalidInput, code: code);
AppFailure _invalidPhone(String code) =>
    ValidationFailure(ValidationReason.invalidPhoneNumber, code: code);
AppFailure _invalidCode(String code) =>
    ValidationFailure(ValidationReason.invalidCode, code: code);
AppFailure _invalidEmail(String code) =>
    ValidationFailure(ValidationReason.invalidEmail, code: code);
AppFailure _wrongCredentials(String code) =>
    ValidationFailure(ValidationReason.wrongCredentials, code: code);
AppFailure _unknown(String code) => UnknownFailure(code: code);

/// Maps a Firestore / Storage / Functions [FirebaseException] to an
/// [AppFailure]. Unknown codes become [UnknownFailure] and are logged.
AppFailure mapFirebaseException(FirebaseException exception) {
  if (exception is FirebaseAuthException) {
    return mapFirebaseAuthException(exception);
  }
  final builder = firestoreCodeMap[exception.code];
  if (builder != null) return builder(exception.code);
  AppLogger.warning(
    'Unmapped Firebase error code',
    context: {'plugin': exception.plugin, 'code': exception.code},
  );
  return UnknownFailure(code: exception.code, cause: exception);
}

/// Maps a [FirebaseAuthException] to an [AppFailure].
AppFailure mapFirebaseAuthException(FirebaseAuthException exception) {
  final builder = authCodeMap[exception.code];
  if (builder != null) return builder(exception.code);
  AppLogger.warning(
    'Unmapped Firebase Auth error code',
    context: {'code': exception.code},
  );
  return UnknownFailure(code: exception.code, cause: exception);
}

/// Maps any thrown object to an [AppFailure]. Use in every `catch` that
/// reaches the UI so raw errors are never displayed.
AppFailure mapError(Object error, [StackTrace? stackTrace]) {
  final failure = switch (error) {
    AppFailure() => error,
    FirebaseAuthException() => mapFirebaseAuthException(error),
    FirebaseException() => mapFirebaseException(error),
    SocketException() || TimeoutException() => const NetworkFailure(),
    _ => UnknownFailure(cause: error),
  };
  if (failure is UnknownFailure) {
    AppLogger.error(
      'Unexpected error mapped to UnknownFailure',
      context: {'type': error.runtimeType.toString()},
      error: error,
      stackTrace: stackTrace,
    );
  }
  return failure;
}
