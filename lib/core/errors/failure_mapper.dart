import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';
import 'app_failure.dart';
import 'server_error_code.dart';

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
  // Sign-in only works online: nothing is kept on the phone.
  'network-request-failed': _connectionRequired,
  'timeout': _connectionRequired,
  'user-not-found': _notInvited,
  'user-disabled': _deactivated,
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
AppFailure _connectionRequired(String code) =>
    ConnectionRequiredFailure(code: code);
AppFailure _permissionDenied(String code) =>
    PermissionDeniedFailure(code: code);
AppFailure _notFound(String code) => NotFoundFailure(code: code);
AppFailure _unauthenticated(String code) => UnauthenticatedFailure(code: code);
AppFailure _notInvited(String code) => NotInvitedFailure(code: code);
AppFailure _deactivated(String code) => AccountDeactivatedFailure(code: code);
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
  if (exception is FirebaseFunctionsException) {
    return mapFunctionsException(exception);
  }
  final builder = firestoreCodeMap[exception.code];
  if (builder != null) return builder(exception.code);
  AppLogger.warning(
    'Unmapped Firebase error code',
    context: {'plugin': exception.plugin, 'errorCode': exception.code},
  );
  return UnknownFailure(code: exception.code, cause: exception);
}

/// Maps the `details` of a callable error (`details.code`, plus
/// `details.attemptsLeft` and `details.field` when present) to an
/// [AppFailure].
AppFailure mapServerErrorCode(
  ServerErrorCode code, {
  int? attemptsLeft,
  String? field,
}) => switch (code) {
  ServerErrorCode.notInvited => NotInvitedFailure(code: code.wireValue),
  ServerErrorCode.accountDeactivated => AccountDeactivatedFailure(
    code: code.wireValue,
  ),
  ServerErrorCode.sessionExpired => SessionExpiredFailure(code: code.wireValue),
  ServerErrorCode.unauthenticated => UnauthenticatedFailure(
    code: code.wireValue,
  ),
  ServerErrorCode.notFound => NotFoundFailure(code: code.wireValue),
  ServerErrorCode.internal => UnknownFailure(code: code.wireValue),
  _ => ServerFailure(code, attemptsLeft: attemptsLeft, field: field),
};

/// Maps an error from a callable Cloud Function. The server's
/// `details.code` wins; otherwise the gRPC status decides. A timeout or an
/// unreachable server becomes [ConnectionRequiredFailure], because callables
/// only work online and nothing was saved on the phone.
AppFailure mapFunctionsException(FirebaseFunctionsException exception) {
  final details = exception.details;
  if (details is Map) {
    final serverCode = ServerErrorCode.tryParse(details['code']);
    if (serverCode != null) {
      final attemptsLeft = details['attemptsLeft'];
      final field = details['field'];
      return mapServerErrorCode(
        serverCode,
        attemptsLeft: attemptsLeft is num ? attemptsLeft.toInt() : null,
        field: field is String ? field : null,
      );
    }
  }
  switch (exception.code) {
    case 'unavailable' || 'deadline-exceeded' || 'cancelled':
      return ConnectionRequiredFailure(code: exception.code);
  }
  final builder = firestoreCodeMap[exception.code];
  if (builder != null) return builder(exception.code);
  AppLogger.warning(
    'Unmapped Functions error code',
    context: {'errorCode': exception.code},
  );
  return UnknownFailure(code: exception.code, cause: exception);
}

/// Text that Identity Platform puts in the error when a blocking function
/// refuses a sign-in (docs/SPRINT1_CONTRACT.md, "Blocking functions").
const String blockingFunctionMarker = 'BLOCKING_FUNCTION_ERROR_RESPONSE';

/// Message keys the blocking functions use. `beforeUserCreated` refuses
/// unknown numbers with [notInvitedMarker]; `beforeUserSignedIn` refuses
/// deactivated users with [deactivatedMarker] and unknown ones with
/// [notInvitedMarker].
const String notInvitedMarker = 'not-invited';
const String deactivatedMarker = 'account-deactivated';

/// Recognises a blocking-function refusal from its message, whatever error
/// code the platform used (`internal-error`, `unknown`, ...).
AppFailure? _blockingFunctionRefusal(FirebaseAuthException exception) {
  final message = exception.message ?? '';
  if (message.contains(notInvitedMarker)) {
    return NotInvitedFailure(code: exception.code);
  }
  if (message.contains(deactivatedMarker)) {
    return AccountDeactivatedFailure(code: exception.code);
  }
  if (message.contains(blockingFunctionMarker)) {
    // A refusal without a known key: the only other refusal is for a
    // deactivated account, but "ask your administrator" is right for both.
    return NotInvitedFailure(code: exception.code);
  }
  return null;
}

/// Maps a [FirebaseAuthException] to an [AppFailure].
AppFailure mapFirebaseAuthException(FirebaseAuthException exception) {
  final refusal = _blockingFunctionRefusal(exception);
  if (refusal != null) return refusal;
  final builder = authCodeMap[exception.code];
  if (builder != null) return builder(exception.code);
  AppLogger.warning(
    'Unmapped Firebase Auth error code',
    context: {'errorCode': exception.code},
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
