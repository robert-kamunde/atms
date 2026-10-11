import 'package:flutter/foundation.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import 'token_claims.dart';

/// The signed-in person: Firebase uid, token claims and user document.
@immutable
class UserSession {
  const UserSession({
    required this.uid,
    required this.orgId,
    required this.claims,
    required this.user,
  });

  final String uid;
  final String orgId;
  final TokenClaims claims;
  final AppUser user;

  @override
  bool operator ==(Object other) =>
      other is UserSession &&
      other.uid == uid &&
      other.orgId == orgId &&
      other.claims == claims &&
      other.user == user;

  @override
  int get hashCode => Object.hash(uid, orgId, claims, user);

  @override
  String toString() => 'UserSession(uid: $uid, orgId: $orgId)';
}

/// Why the user is on the sign-in screen.
enum SignOutReason {
  /// The session reached its maximum age (30 days, 7 for admins).
  sessionExpired,
}

/// Why the user cannot use the app.
enum NotAllowedReason {
  /// The number or email was never added by an administrator.
  notInvited,

  /// An administrator deactivated the account.
  deactivated,
}

/// Where the user is in the sign-in journey. Drives the router guard
/// (`lib/core/routing/route_guard.dart`).
@immutable
sealed class AuthState {
  const AuthState();
}

/// Still working out the state (start-up, or loading the user's profile).
final class AuthUnknown extends AuthState {
  const AuthUnknown({this.waitingForConnection = false});

  /// True when the profile cannot be loaded because the phone is offline
  /// and nothing is cached yet.
  final bool waitingForConnection;

  @override
  bool operator ==(Object other) =>
      other is AuthUnknown &&
      other.waitingForConnection == waitingForConnection;

  @override
  int get hashCode => waitingForConnection.hashCode;
}

/// Firebase options are missing or Firebase failed to start.
final class AuthNotConfigured extends AuthState {
  const AuthNotConfigured();
}

final class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.reason});

  /// Set when the app signed the user out by itself, to explain why.
  final SignOutReason? reason;

  @override
  bool operator ==(Object other) =>
      other is AuthSignedOut && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

/// Signed in (or refused at sign-in), but not allowed in: not invited
/// (spec 4.1: "Ask your administrator to add you.") or deactivated.
final class AuthNotInvited extends AuthState {
  const AuthNotInvited({this.reason = NotAllowedReason.notInvited});

  final NotAllowedReason reason;

  @override
  bool operator ==(Object other) =>
      other is AuthNotInvited && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

/// Base of the states where the person is a member: onboarding steps and
/// fully signed in. [session] is null only in tests that need a role and
/// no data.
sealed class AuthMember extends AuthState {
  const AuthMember(this.role, {this.session});

  final UserRole role;
  final UserSession? session;
}

/// First sign-in: must pick a language (spec 4.1 step 4).
final class AuthNeedsLanguage extends AuthMember {
  const AuthNeedsLanguage(super.role, {super.session});

  @override
  bool operator ==(Object other) =>
      other is AuthNeedsLanguage &&
      other.role == role &&
      other.session == session;

  @override
  int get hashCode => Object.hash('language', role, session);
}

/// Must accept the privacy notice (Tanzania PDPA 2022).
final class AuthNeedsConsent extends AuthMember {
  const AuthNeedsConsent(super.role, {super.session});

  @override
  bool operator ==(Object other) =>
      other is AuthNeedsConsent &&
      other.role == role &&
      other.session == session;

  @override
  int get hashCode => Object.hash('consent', role, session);
}

/// Must be asked about notification permission.
final class AuthNeedsNotificationPermission extends AuthMember {
  const AuthNeedsNotificationPermission(super.role, {super.session});

  @override
  bool operator ==(Object other) =>
      other is AuthNeedsNotificationPermission &&
      other.role == role &&
      other.session == session;

  @override
  int get hashCode => Object.hash('notifications', role, session);
}

final class AuthSignedIn extends AuthMember {
  const AuthSignedIn(super.role, {super.session, this.adminVerifiedUntil});

  /// Until when the admin second factor is valid (from the token claim).
  /// Admin screens need it in the future (D-01); admins without it keep
  /// staff-level access to their own tasks.
  final DateTime? adminVerifiedUntil;

  bool isAdminVerifiedAt(DateTime now) =>
      role == UserRole.admin &&
      adminVerifiedUntil != null &&
      adminVerifiedUntil!.isAfter(now);

  @override
  bool operator ==(Object other) =>
      other is AuthSignedIn &&
      other.role == role &&
      other.session == session &&
      other.adminVerifiedUntil == adminVerifiedUntil;

  @override
  int get hashCode => Object.hash(role, session, adminVerifiedUntil);
}
