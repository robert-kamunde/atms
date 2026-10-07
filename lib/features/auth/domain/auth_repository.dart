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
/// Whether a signed-in Firebase user is *invited* (has an active user
/// document) is decided by the user profile lookup (Sprint 1), not here.
abstract interface class AuthRepository {
  /// Firebase user id of the current user, or null when signed out.
  Stream<String?> watchUserId();

  /// When the current session was created (for the session policy).
  Future<DateTime?> currentAuthTime();

  /// Sends a 6-digit code by SMS to [phoneNumber] (E.164, e.g. +2557...).
  Future<PhoneVerificationResult> startPhoneVerification(
    String phoneNumber, {
    int? resendToken,
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

  Future<void> signOut();
}
