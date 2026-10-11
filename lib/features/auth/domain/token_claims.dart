import 'package:flutter/foundation.dart';

/// The parts of the Firebase ID token the app uses. They are set only by
/// Cloud Functions (custom claims) and Firebase Auth (`auth_time`); the app
/// reads them to decide which screen to show. The Security Rules and the
/// functions check the same claims on the server, so a modified app gains
/// nothing (ARCHITECTURE section 4).
@immutable
class TokenClaims {
  const TokenClaims({this.authTime, this.orgId, this.adminVerifiedUntil});

  /// Parses the claims map of an ID token (`IdTokenResult.claims`).
  ///
  /// * `auth_time`: seconds since epoch of the last real sign-in. Firebase
  ///   also exposes it as `IdTokenResult.authTime`; pass that as
  ///   [authTimeFallback] in case the map lacks it.
  /// * `orgId`: set by `adminUpsertUser` when an admin adds the person.
  /// * `adminVerifiedUntil`: seconds since epoch, set by `verifyAdminCode`.
  ///
  /// Wrong types are ignored (treated as absent), never thrown: a missing
  /// claim must lead to the safe screen, not a crash.
  factory TokenClaims.fromClaims(
    Map<String, Object?>? claims, {
    DateTime? authTimeFallback,
  }) {
    final map = claims ?? const <String, Object?>{};
    final orgId = map['orgId'];
    return TokenClaims(
      authTime: _secondsToUtc(map['auth_time']) ?? authTimeFallback?.toUtc(),
      orgId: orgId is String && orgId.isNotEmpty ? orgId : null,
      adminVerifiedUntil: _secondsToUtc(map['adminVerifiedUntil']),
    );
  }

  /// When the user last really signed in (not a token refresh).
  final DateTime? authTime;

  /// The organisation the user belongs to. Null means not invited.
  final String? orgId;

  /// Until when the admin second factor is valid.
  final DateTime? adminVerifiedUntil;

  bool isAdminVerifiedAt(DateTime now) {
    final until = adminVerifiedUntil;
    return until != null && until.isAfter(now);
  }

  TokenClaims withoutAdminVerification() =>
      TokenClaims(authTime: authTime, orgId: orgId);

  static DateTime? _secondsToUtc(Object? raw) => raw is num
      ? DateTime.fromMillisecondsSinceEpoch((raw * 1000).round(), isUtc: true)
      : null;

  @override
  bool operator ==(Object other) =>
      other is TokenClaims &&
      other.authTime == authTime &&
      other.orgId == orgId &&
      other.adminVerifiedUntil == adminVerifiedUntil;

  @override
  int get hashCode => Object.hash(authTime, orgId, adminVerifiedUntil);

  @override
  String toString() =>
      'TokenClaims(orgId: $orgId, authTime: $authTime, '
      'adminVerifiedUntil: $adminVerifiedUntil)';
}
