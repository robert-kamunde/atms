import 'package:flutter/foundation.dart';

/// Result of `sendAdminCode`.
@immutable
class AdminCodeSent {
  const AdminCodeSent({required this.maskedEmail, required this.expiresAt});

  /// The admin's email with most characters hidden, e.g. `i***@org.tz`.
  final String maskedEmail;

  /// When the code stops working (10 minutes after sending).
  final DateTime expiresAt;
}

/// The admin second factor (D-01): a 6-digit code sent by email by the
/// `sendAdminCode` callable and checked by `verifyAdminCode`, which sets the
/// `adminVerifiedUntil` claim. Implementations throw `AppFailure` only.
abstract interface class AdminVerificationRepository {
  Future<AdminCodeSent> sendAdminCode();

  /// Returns when the verification stops being valid. The caller must then
  /// refresh the ID token so the new claim is used (contract).
  Future<DateTime> verifyAdminCode(String code);
}
