import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/utils/logger.dart';
import '../domain/auth_repository.dart';

/// [AuthRepository] backed by Firebase Authentication.
///
/// Skeleton for Sprint 0: the calls are real Firebase calls, but the
/// invitation check, user-profile lookup, session policy enforcement and
/// FCM token registration are Sprint 1 (see `AuthController`).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  static const Duration _smsTimeout = Duration(seconds: 60);

  @override
  Stream<String?> watchUserId() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<DateTime?> currentAuthTime() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final token = await user.getIdTokenResult();
      return token.authTime;
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }

  @override
  Future<PhoneVerificationResult> startPhoneVerification(
    String phoneNumber, {
    int? resendToken,
  }) {
    final completer = Completer<PhoneVerificationResult>();
    _auth
        .verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: _smsTimeout,
          forceResendingToken: resendToken,
          verificationCompleted: (credential) async {
            // Android auto-retrieval: sign in straight away.
            try {
              await _auth.signInWithCredential(credential);
              if (!completer.isCompleted) {
                completer.complete(const PhoneAutoVerified());
              }
            } catch (error, stackTrace) {
              if (!completer.isCompleted) {
                completer.completeError(mapError(error, stackTrace));
              }
            }
          },
          verificationFailed: (error) {
            if (!completer.isCompleted) {
              completer.completeError(mapFirebaseAuthException(error));
            }
          },
          codeSent: (verificationId, token) {
            if (!completer.isCompleted) {
              completer.complete(
                PhoneVerificationCodeSent(
                  verificationId: verificationId,
                  resendToken: token,
                ),
              );
            }
          },
          codeAutoRetrievalTimeout: (_) {
            // Nothing to do: the user types the code manually.
          },
        )
        .catchError((Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(mapError(error, stackTrace));
          } else {
            AppLogger.warning(
              'Phone verification error after completion',
              error: error,
              stackTrace: stackTrace,
            );
          }
        });
    return completer.future;
  }

  @override
  Future<void> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }
}
