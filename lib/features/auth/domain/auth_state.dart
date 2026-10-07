import 'package:flutter/foundation.dart';

import '../../../shared/models/user_role.dart';

/// Where the user is in the sign-in journey. Drives the router guard
/// (`lib/core/routing/route_guard.dart`).
@immutable
sealed class AuthState {
  const AuthState();
}

/// Still working out the state (start-up, or loading the user's profile).
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// Firebase options are missing or Firebase failed to start.
final class AuthNotConfigured extends AuthState {
  const AuthNotConfigured();
}

final class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

/// Signed in with Firebase, but no active user document exists for this
/// phone/email (spec 4.1: "Ask your administrator to add you.").
final class AuthNotInvited extends AuthState {
  const AuthNotInvited();
}

/// First sign-in: must pick a language (spec 4.1 step 4).
final class AuthNeedsLanguage extends AuthState {
  const AuthNeedsLanguage(this.role);

  final UserRole role;
}

/// Must accept the privacy notice (Tanzania PDPA 2022).
final class AuthNeedsConsent extends AuthState {
  const AuthNeedsConsent(this.role);

  final UserRole role;
}

/// Must be asked about notification permission.
final class AuthNeedsNotificationPermission extends AuthState {
  const AuthNeedsNotificationPermission(this.role);

  final UserRole role;
}

final class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.role, {this.isDeveloperPreview = false});

  final UserRole role;

  /// True when entered through the development-only role preview (no
  /// Firebase session, no data). See `AuthController.startDeveloperPreview`.
  final bool isDeveloperPreview;

  @override
  bool operator ==(Object other) =>
      other is AuthSignedIn &&
      other.role == role &&
      other.isDeveloperPreview == isDeveloperPreview;

  @override
  int get hashCode => Object.hash(role, isDeveloperPreview);
}
