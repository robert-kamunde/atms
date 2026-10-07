import 'dart:async';
import 'dart:io';

import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/core/errors/failure_mapper.dart';
import 'package:atms/core/errors/failure_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

FirebaseException fs(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

FirebaseAuthException auth(String code) => FirebaseAuthException(code: code);

void main() {
  group('Firestore codes', () {
    const expected = <String, Type>{
      'unavailable': NetworkFailure,
      'deadline-exceeded': NetworkFailure,
      'permission-denied': PermissionDeniedFailure,
      'not-found': NotFoundFailure,
      'object-not-found': NotFoundFailure,
      'unauthenticated': UnauthenticatedFailure,
      'unauthorized': PermissionDeniedFailure,
      'already-exists': ConflictFailure,
      'aborted': ConflictFailure,
      'failed-precondition': ConflictFailure,
      'invalid-argument': ValidationFailure,
      'out-of-range': ValidationFailure,
      'resource-exhausted': TooManyAttemptsFailure,
      'retry-limit-exceeded': NetworkFailure,
    };

    test('the test table covers every mapped code', () {
      expect(expected.keys.toSet(), firestoreCodeMap.keys.toSet());
    });

    for (final entry in expected.entries) {
      test('${entry.key} -> ${entry.value}', () {
        final failure = mapFirebaseException(fs(entry.key));
        expect(failure.runtimeType, entry.value);
        expect(failure.code, entry.key);
      });
    }

    test('unknown code -> UnknownFailure', () {
      expect(mapFirebaseException(fs('data-loss')), isA<UnknownFailure>());
    });
  });

  group('Auth codes', () {
    const expected = <String, Type>{
      'network-request-failed': NetworkFailure,
      'timeout': NetworkFailure,
      'user-not-found': NotInvitedFailure,
      'user-disabled': NotInvitedFailure,
      'invalid-phone-number': ValidationFailure,
      'missing-phone-number': ValidationFailure,
      'invalid-verification-code': ValidationFailure,
      'missing-verification-code': ValidationFailure,
      'invalid-verification-id': SessionExpiredFailure,
      'code-expired': SessionExpiredFailure,
      'session-expired': SessionExpiredFailure,
      'user-token-expired': SessionExpiredFailure,
      'requires-recent-login': SessionExpiredFailure,
      'invalid-email': ValidationFailure,
      'wrong-password': ValidationFailure,
      'invalid-credential': ValidationFailure,
      'invalid-login-credentials': ValidationFailure,
      'too-many-requests': TooManyAttemptsFailure,
      'quota-exceeded': TooManyAttemptsFailure,
      'operation-not-allowed': UnknownFailure,
    };

    test('the test table covers every mapped code', () {
      expect(expected.keys.toSet(), authCodeMap.keys.toSet());
    });

    for (final entry in expected.entries) {
      test('${entry.key} -> ${entry.value}', () {
        expect(
          mapFirebaseAuthException(auth(entry.key)).runtimeType,
          entry.value,
        );
        // Auth exceptions passed to the generic mapper use the auth table.
        expect(mapFirebaseException(auth(entry.key)).runtimeType, entry.value);
      });
    }

    test('validation reasons', () {
      ValidationReason reason(String code) =>
          (mapFirebaseAuthException(auth(code)) as ValidationFailure).reason;
      expect(
        reason('invalid-phone-number'),
        ValidationReason.invalidPhoneNumber,
      );
      expect(reason('invalid-verification-code'), ValidationReason.invalidCode);
      expect(reason('invalid-email'), ValidationReason.invalidEmail);
      expect(reason('wrong-password'), ValidationReason.wrongCredentials);
    });
  });

  group('mapError', () {
    test('passes AppFailure through', () {
      const f = NetworkFailure();
      expect(mapError(f), same(f));
    });

    test('socket and timeout errors are network failures', () {
      expect(mapError(const SocketException('x')), isA<NetworkFailure>());
      expect(mapError(TimeoutException('x')), isA<NetworkFailure>());
    });

    test('anything else is UnknownFailure', () {
      expect(mapError(StateError('x')), isA<UnknownFailure>());
    });
  });

  group('friendly messages', () {
    for (final locale in testLocales) {
      final l10n = l10nFor(locale);

      test('[$locale] permission-denied and not-found look the same', () {
        final denied = failureMessage(
          mapFirebaseException(fs('permission-denied')),
          l10n,
        );
        final missing = failureMessage(
          mapFirebaseException(fs('not-found')),
          l10n,
        );
        expect(denied, missing);
        expect(denied, l10n.errorNotFound);
      });

      test('[$locale] every failure has a non-empty message without codes', () {
        final failures = <AppFailure>[
          const NetworkFailure(code: 'unavailable'),
          const PermissionDeniedFailure(code: 'permission-denied'),
          const NotFoundFailure(code: 'not-found'),
          const UnauthenticatedFailure(code: 'unauthenticated'),
          const NotInvitedFailure(code: 'user-not-found'),
          const SessionExpiredFailure(code: 'code-expired'),
          const TooManyAttemptsFailure(code: 'too-many-requests'),
          for (final r in ValidationReason.values)
            ValidationFailure(r, code: 'x-code'),
          const ConflictFailure(code: 'aborted'),
          const UnknownFailure(code: 'data-loss'),
        ];
        for (final f in failures) {
          final message = failureMessage(f, l10n);
          expect(message, isNotEmpty);
          expect(message, isNot(contains(f.code!)));
        }
      });

      test('[$locale] conflict names who approved and when', () {
        final message = failureMessage(
          ConflictFailure(
            alreadyApprovedBy: 'Asha',
            at: DateTime(2026, 10, 5, 10, 42),
          ),
          l10n,
        );
        expect(message, contains('Asha'));
        expect(message, contains('10:42'));
      });
    }
  });
}
