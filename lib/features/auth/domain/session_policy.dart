import '../../../shared/models/user_role.dart';

/// How long a session may last before the user must sign in again
/// (spec 4.1 rules).
abstract final class SessionPolicy {
  /// Staff and managers: 30 days, so they are not asked for codes every day.
  static const Duration standardMaxAge = Duration(days: 30);

  /// Admins: 7 days.
  static const Duration adminMaxAge = Duration(days: 7);

  static Duration maxAgeFor(UserRole role) => switch (role) {
    UserRole.admin => adminMaxAge,
    UserRole.manager || UserRole.staff => standardMaxAge,
  };
}

/// True when a session that started at [authTime] is too old for [role] at
/// [now]. A session exactly at the limit is expired.
///
/// An [authTime] in the future (phone clock wrong) is treated as not
/// expired here; the server-side token check is the real enforcement.
///
/// NOT IMPLEMENTED (Sprint 1): call this on app start and resume, with
/// `authTime` from the ID token's `auth_time` claim, and sign the user out
/// when it returns true. Server-side checks belong in Security Rules /
/// Functions (`request.auth.token.auth_time`).
bool isSessionExpired({
  required DateTime authTime,
  required UserRole role,
  required DateTime now,
}) {
  final age = now.difference(authTime);
  if (age.isNegative) return false;
  return age >= SessionPolicy.maxAgeFor(role);
}
