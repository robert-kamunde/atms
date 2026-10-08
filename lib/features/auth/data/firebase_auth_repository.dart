import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/utils/logger.dart';
import '../domain/auth_repository.dart';
import '../domain/token_claims.dart';

/// [AuthRepository] backed by Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  static const Duration _smsTimeout = Duration(seconds: 60);

  @override
  Stream<String?> watchUserId() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<TokenClaims?> currentClaims({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final token = await user.getIdTokenResult(forceRefresh);
      return TokenClaims.fromClaims(
        token.claims,
        authTimeFallback: token.authTime,
      );
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }

  @override
  Future<PhoneVerificationResult> startPhoneVerification(
    String phoneNumber, {
    int? resendToken,
    void Function(AppFailure failure)? onAutoSignInFailed,
  }) {
    final completer = Completer<PhoneVerificationResult>();

    void fail(Object error, StackTrace stackTrace) {
      final failure = mapError(error, stackTrace);
      if (!completer.isCompleted) {
        completer.completeError(failure);
      } else {
        AppLogger.warning(
          'Automatic phone sign-in failed after the code was sent',
          context: {'errorCode': failure.code},
        );
        onAutoSignInFailed?.call(failure);
      }
    }

    _auth
        .verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: _smsTimeout,
          forceResendingToken: resendToken,
          verificationCompleted: (credential) async {
            // Android auto-retrieval or instant verification: sign in
            // straight away, even if the code screen is already open.
            try {
              await _auth.signInWithCredential(credential);
              if (!completer.isCompleted) {
                completer.complete(const PhoneAutoVerified());
              }
            } catch (error, stackTrace) {
              fail(error, stackTrace);
            }
          },
          verificationFailed: (error) => fail(error, StackTrace.current),
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
        .catchError(fail);
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
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') {
        // Deliberately reported as sent: the screen must not reveal which
        // emails have accounts. Logged without the address.
        AppLogger.info('Password reset requested for an unknown email');
        return;
      }
      throw mapFirebaseAuthException(error);
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
