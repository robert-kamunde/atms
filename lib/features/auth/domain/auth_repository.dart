import '../../../core/errors/app_failure.dart';
import 'token_claims.dart';

/// Result of starting phone verification.
sealed class PhoneVerificationResult {
  const PhoneVerificationResult();
}

/// An SMS code was sent; the user must type it.
final class PhoneVerificationCodeSent extends PhoneVerificationResult {
  const PhoneVerificationCodeSent({
    required this.verificationId,
    this.resendToken,
  });

  final String verificationId;
  final int? resendToken;
}

/// Android verified the number automatically and the user is signed in.
final class PhoneAutoVerified extends PhoneVerificationResult {
  const PhoneAutoVerified();
}

/// Sign-in operations. Implementations throw `AppFailure` only, never raw
/// Firebase errors.
///
/// Whether a signed-in Firebase user is *invited* (has the `orgId` claim
/// and an active user document) is decided by `AuthController`, not here.
abstract interface class AuthRepository {
  /// Firebase user id of the current user, or null when signed out.
  Stream<String?> watchUserId();

  /// Claims of the current ID token. With [forceRefresh] a new token is
  /// fetched from the server (needed after `verifyAdminCode`, which changes
  /// the claims). Returns null when signed out.
  Future<TokenClaims?> currentClaims({bool forceRefresh = false});

  /// Sends a 6-digit code by SMS to [phoneNumber] (E.164, e.g. +2557...).
  ///
  /// On Android the code may be read automatically, even after the future
  /// completed with [PhoneVerificationCodeSent]; the user is then signed in
  /// without typing it. If that late automatic sign-in fails (for example
  /// the number was not invited), [onAutoSignInFailed] receives the failure.
  Future<PhoneVerificationResult> startPhoneVerification(
    String phoneNumber, {
    int? resendToken,
    void Function(AppFailure failure)? onAutoSignInFailed,
  });

  /// Signs in with the code the user typed.
  Future<void> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  });

  /// Email and password fallback for staff without a reliable SIM.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sends a "set a new password" email. Accounts created by an admin with
  /// an email start with a random password, so this is how such a person
  /// sets their first password (docs/SPRINT1_CONTRACT.md).
  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}
