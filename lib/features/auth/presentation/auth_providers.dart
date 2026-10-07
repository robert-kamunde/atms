import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/bootstrap.dart';
import '../../../core/config/config_providers.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/user_role.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';

/// The auth repository. Only created when a sign-in action is used, so the
/// app never touches `FirebaseAuth.instance` when Firebase is not set up.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

/// Holds the sign-in journey state for the router guard.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => _initialState();

  AuthState _initialState() {
    return switch (ref.watch(bootstrapResultProvider)) {
      BootstrapNotConfigured() ||
      BootstrapFailed() => const AuthNotConfigured(),
      // NOT IMPLEMENTED (Sprint 1): subscribe to
      // `authRepository.watchUserId()`, load `orgs/{org}/users/{uid}`,
      // apply `isSessionExpired`, then emit NotInvited / Needs* / SignedIn.
      BootstrapReady() => const AuthSignedOut(),
    };
  }

  /// Development-only shortcut to see the signed-in screens for a role
  /// without Firebase and without any data.
  ///
  /// MOCK/TEMPORARY: exists so the Sprint 0 clickable skeleton can be
  /// reviewed with future users (spec 7, Sprint 0 demo). It only works in
  /// debug builds with `ATMS_ENV=dev`; it never loads or invents data. Remove
  /// once Sprint 1 sign-in works against the emulator.
  void startDeveloperPreview(UserRole role) {
    if (!isDeveloperPreviewAllowed(ref.read(appConfigProvider))) {
      AppLogger.warning('Developer preview refused outside debug/dev');
      return;
    }
    state = AuthSignedIn(role, isDeveloperPreview: true);
  }

  /// Called after Firebase sign-in succeeds.
  void onFirebaseSignedIn() {
    // NOT IMPLEMENTED (Sprint 1): resolve the user document; until then the
    // state stays "unknown" and the loading screen offers sign out.
    AppLogger.info('Firebase sign-in done; profile lookup is Sprint 1');
    state = const AuthUnknown();
  }

  /// Onboarding steps (spec 4.1 step 4). In Sprint 0 these only move the
  /// in-memory state; NOT IMPLEMENTED (Sprint 1): persist each choice
  /// (language and consent timestamp) on the user document.
  void completeLanguageStep() {
    if (state case AuthNeedsLanguage(:final role)) {
      state = AuthNeedsConsent(role);
    }
  }

  void completeConsentStep() {
    if (state case AuthNeedsConsent(:final role)) {
      state = AuthNeedsNotificationPermission(role);
    }
  }

  void completeNotificationStep() {
    if (state case AuthNeedsNotificationPermission(:final role)) {
      state = AuthSignedIn(role);
    }
  }

  Future<void> signOut() async {
    final current = state;
    if (current is AuthSignedIn && current.isDeveloperPreview) {
      state = _initialState();
      return;
    }
    if (current is! AuthNotConfigured) {
      await ref.read(authRepositoryProvider).signOut();
    }
    state = _initialState();
  }
}

/// True only in debug builds of the dev environment.
bool isDeveloperPreviewAllowed(AppConfig config) =>
    kDebugMode && config.environment == AppEnvironment.dev;

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Role of the signed-in user, or null when not signed in.
final currentRoleProvider = Provider<UserRole?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return switch (auth) {
    AuthSignedIn(:final role) ||
    AuthNeedsLanguage(:final role) ||
    AuthNeedsConsent(:final role) ||
    AuthNeedsNotificationPermission(:final role) => role,
    _ => null,
  };
});

/// The phone verification in progress (between the phone and code screens).
@immutable
class PendingPhoneVerification {
  const PendingPhoneVerification({
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
}

class PendingPhoneVerificationController
    extends Notifier<PendingPhoneVerification?> {
  @override
  PendingPhoneVerification? build() => null;

  void set(PendingPhoneVerification? value) => state = value;
}

final pendingPhoneVerificationProvider =
    NotifierProvider<
      PendingPhoneVerificationController,
      PendingPhoneVerification?
    >(PendingPhoneVerificationController.new);
