import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/bootstrap.dart';
import '../../../core/config/config_providers.dart';
import '../../../core/config/firebase_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/callable_client.dart';
import '../../../core/services/offline_write.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../../users/data/firestore_user_repositories.dart';
import '../../users/domain/user_repositories.dart';
import '../data/firebase_auth_repository.dart';
import '../data/functions_admin_verification_repository.dart';
import '../data/messaging_notification_permission.dart';
import '../domain/admin_verification_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/notification_permission.dart';
import '../domain/session_policy.dart';
import '../domain/token_claims.dart';

/// The auth repository. Only created when used, so the app never touches
/// `FirebaseAuth.instance` when Firebase is not set up.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(ref.watch(firebaseAuthProvider)),
);

/// The signed-in person's own user document.
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => FirestoreUserProfileRepository(ref.watch(firestoreProvider)),
);

final notificationPermissionProvider = Provider<NotificationPermissionService>(
  (ref) => MessagingNotificationPermission(ref.watch(messagingProvider)),
);

/// Online-only callable functions in `africa-south1`.
final callableClientProvider = Provider<CallableClient>(
  (ref) => CallableClient(ref.watch(functionsProvider)),
);

final adminVerificationRepositoryProvider =
    Provider<AdminVerificationRepository>(
      (ref) => FunctionsAdminVerificationRepository(
        ref.watch(callableClientProvider),
      ),
    );

/// True for failures that mean "this person may not sign in" (the
/// blocking functions refused, or the account is deactivated).
bool isSignInRefusal(AppFailure failure) =>
    failure is NotInvitedFailure || failure is AccountDeactivatedFailure;

/// Holds the sign-in journey state for the router guard.
///
/// Flow: Firebase user -> ID token claims (`orgId`, `auth_time`,
/// `adminVerifiedUntil`) -> own user document -> session policy ->
/// onboarding (language, consent, notifications) -> signed in.
///
/// Nothing here is a security decision: the Security Rules and Cloud
/// Functions check the same claims and documents on the server.
class AuthController extends Notifier<AuthState> {
  StreamSubscription<String?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;
  Timer? _sessionTimer;
  Timer? _retryTimer;

  /// Increases on every Firebase user change so late async results of an
  /// earlier user are ignored.
  int _generation = 0;

  String? _uid;
  TokenClaims? _claims;
  AppUser? _user;
  String? _appliedLanguage;
  bool _languageConfirmed = false;
  String? _consentAcceptedLocally;
  bool? _needsNotificationPrompt;
  bool _notificationStepDone = false;
  SignOutReason? _pendingSignOutReason;

  static const Duration _retryDelay = Duration(seconds: 10);

  @override
  AuthState build() {
    _resetSession();
    if (ref.watch(bootstrapResultProvider) is! BootstrapReady) {
      return const AuthNotConfigured();
    }
    final repo = ref.watch(authRepositoryProvider);
    _authSub = repo.watchUserId().listen(
      _onUserId,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'Auth state stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    ref.onDispose(() {
      unawaited(_authSub?.cancel());
      _resetSession();
    });
    return const AuthUnknown();
  }

  DateTime _now() => ref.read(clockProvider)();

  void _resetSession() {
    _generation++;
    unawaited(_profileSub?.cancel());
    _profileSub = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _uid = null;
    _claims = null;
    _user = null;
    _languageConfirmed = false;
    _consentAcceptedLocally = null;
    _needsNotificationPrompt = null;
    _notificationStepDone = false;
  }

  void _onUserId(String? uid) {
    _resetSession();
    if (uid == null) {
      state = AuthSignedOut(reason: _pendingSignOutReason);
      return;
    }
    _pendingSignOutReason = null;
    _uid = uid;
    state = const AuthUnknown();
    unawaited(_loadClaims(_generation));
  }

  void _retryLater(void Function() action) {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, action);
  }

  Future<void> _loadClaims(int generation) async {
    final TokenClaims? claims;
    try {
      claims = await ref.read(authRepositoryProvider).currentClaims();
    } on AppFailure catch (failure) {
      if (!ref.mounted || generation != _generation) return;
      if (failure is SessionExpiredFailure ||
          failure is UnauthenticatedFailure) {
        // The refresh token was revoked (for example the account was
        // deactivated): the person must sign in again.
        await expireSession();
        return;
      }
      AppLogger.warning(
        'Could not read token claims; retrying',
        context: {'errorCode': failure.code},
      );
      state = AuthUnknown(
        waitingForConnection:
            failure is NetworkFailure || failure is ConnectionRequiredFailure,
      );
      _retryLater(() => unawaited(_loadClaims(generation)));
      return;
    }
    if (!ref.mounted || generation != _generation) return;
    if (claims == null) {
      state = AuthSignedOut(reason: _pendingSignOutReason);
      return;
    }
    if (claims.orgId == null) {
      // Signed in to Firebase but never added by an admin (only possible
      // without the D-02 blocking function, e.g. an old stray account).
      state = const AuthNotInvited();
      return;
    }
    _claims = claims;
    _subscribeProfile(generation);
  }

  void _subscribeProfile(int generation) {
    final claims = _claims;
    final uid = _uid;
    if (claims == null || uid == null) return;
    unawaited(_profileSub?.cancel());
    _profileSub = ref
        .read(userProfileRepositoryProvider)
        .watchUser(orgId: claims.orgId!, uid: uid)
        .listen(
          (user) {
            if (!ref.mounted || generation != _generation) return;
            _user = user;
            _recompute();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!ref.mounted || generation != _generation) return;
            final failure = mapError(error, stackTrace);
            if (failure is PermissionDeniedFailure) {
              // The rules refuse the person's own document only when they
              // are no longer an active member.
              state = const AuthNotInvited(
                reason: NotAllowedReason.deactivated,
              );
              return;
            }
            AppLogger.warning(
              'Profile stream failed; retrying',
              context: {'errorCode': failure.code},
            );
            if (_user == null) {
              state = AuthUnknown(
                waitingForConnection: failure is NetworkFailure,
              );
            }
            _retryLater(() => _subscribeProfile(generation));
          },
        );
  }

  /// Works out the state from the loaded claims and user document.
  void _recompute() {
    final claims = _claims;
    final uid = _uid;
    final user = _user;
    if (claims == null || uid == null) return;
    if (user == null) {
      state = const AuthNotInvited();
      return;
    }
    if (!user.active) {
      state = const AuthNotInvited(reason: NotAllowedReason.deactivated);
      return;
    }
    final authTime = claims.authTime;
    if (authTime == null ||
        isSessionExpired(authTime: authTime, role: user.role, now: _now())) {
      unawaited(expireSession());
      return;
    }
    _applyLanguage(user.language);
    final session = UserSession(
      uid: uid,
      orgId: claims.orgId!,
      claims: claims,
      user: user,
    );
    final consent = _consentAcceptedLocally ?? user.consentVersion;
    if (consent == null && !_languageConfirmed) {
      state = AuthNeedsLanguage(user.role, session: session);
      return;
    }
    if (consent != AppConstants.consentVersion) {
      state = AuthNeedsConsent(user.role, session: session);
      return;
    }
    if (!_notificationStepDone) {
      final needs = _needsNotificationPrompt;
      if (needs == null) {
        unawaited(_checkNotificationPrompt(_generation));
        return;
      }
      if (needs) {
        state = AuthNeedsNotificationPermission(user.role, session: session);
        return;
      }
    }
    state = AuthSignedIn(
      user.role,
      session: session,
      adminVerifiedUntil: claims.adminVerifiedUntil,
    );
    _sessionTimer ??= Timer.periodic(
      AppConstants.sessionCheckInterval,
      (_) => checkSession(),
    );
  }

  Future<void> _checkNotificationPrompt(int generation) async {
    var needs = false;
    try {
      needs = await ref.read(notificationPermissionProvider).needsPrompt();
    } catch (error, stackTrace) {
      // Not being able to ask must not block sign-in.
      AppLogger.warning(
        'Could not read notification permission',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!ref.mounted || generation != _generation) return;
    _needsNotificationPrompt = needs;
    if (!needs) _notificationStepDone = true;
    _recompute();
  }

  /// Uses the language stored on the user document when it changes there
  /// (another device, or the admin's choice before the first sign-in).
  void _applyLanguage(String code) {
    if (_appliedLanguage == code) return;
    _appliedLanguage = code;
    ref.read(localeProvider.notifier).setLocale(AppLocales.fromCode(code));
  }

  /// The signed-in session, if any.
  UserSession? get _session => switch (state) {
    AuthMember(:final session) => session,
    _ => null,
  };

  /// Onboarding step 1: stores the chosen language on the user document.
  /// Works offline (queued on the phone). Throws an `AppFailure` if the
  /// server refuses.
  Future<void> completeLanguageStep(Locale locale) async {
    final session = _session;
    if (state is! AuthNeedsLanguage || session == null) return;
    ref.read(localeProvider.notifier).setLocale(locale);
    _appliedLanguage = locale.languageCode;
    await awaitOfflineCapableWrite(
      ref
          .read(userProfileRepositoryProvider)
          .updateLanguage(
            orgId: session.orgId,
            uid: session.uid,
            language: locale.languageCode,
          ),
      writeName: 'language',
    );
    if (!ref.mounted) return;
    _languageConfirmed = true;
    _recompute();
  }

  /// Onboarding step 2: records consent (version and server time).
  Future<void> completeConsentStep() async {
    final session = _session;
    if (state is! AuthNeedsConsent || session == null) return;
    await awaitOfflineCapableWrite(
      ref
          .read(userProfileRepositoryProvider)
          .acceptConsent(
            orgId: session.orgId,
            uid: session.uid,
            version: AppConstants.consentVersion,
          ),
      writeName: 'consent',
    );
    if (!ref.mounted) return;
    _consentAcceptedLocally = AppConstants.consentVersion;
    _recompute();
  }

  /// Onboarding step 3: asks the phone for notification permission when
  /// [allow] is true. A refusal or error never blocks the app.
  Future<void> completeNotificationStep({required bool allow}) async {
    if (state is! AuthNeedsNotificationPermission) return;
    if (allow) {
      try {
        final granted = await ref
            .read(notificationPermissionProvider)
            .request();
        AppLogger.info(
          'Notification permission answered',
          context: {'granted': granted},
        );
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Notification permission request failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (!ref.mounted) return;
    _notificationStepDone = true;
    _recompute();
  }

  /// Changes the app language and stores it on the user document when
  /// signed in. Returns how the write went (it works offline).
  Future<WriteOutcome?> changeLanguage(Locale locale) async {
    ref.read(localeProvider.notifier).setLocale(locale);
    _appliedLanguage = locale.languageCode;
    final session = _session;
    if (session == null) return null;
    return awaitOfflineCapableWrite(
      ref
          .read(userProfileRepositoryProvider)
          .updateLanguage(
            orgId: session.orgId,
            uid: session.uid,
            language: locale.languageCode,
          ),
      writeName: 'language',
    );
  }

  /// After `verifyAdminCode` succeeds: fetch a fresh ID token so the new
  /// `adminVerifiedUntil` claim is used (contract).
  Future<void> onAdminVerified() async {
    final claims = await ref
        .read(authRepositoryProvider)
        .currentClaims(forceRefresh: true);
    if (!ref.mounted || claims == null) return;
    _claims = claims;
    _recompute();
  }

  /// The server said the admin second factor is no longer valid: drop the
  /// claim locally so the guard asks for a new code.
  void markAdminVerificationExpired() {
    final claims = _claims;
    if (claims == null) return;
    _claims = claims.withoutAdminVerification();
    _recompute();
  }

  /// Re-checks the session policy (called on resume and periodically) and
  /// asks the router to re-check the current route (an admin second factor
  /// may have expired).
  void checkSession() {
    if (_user != null) _recompute();
    ref.read(routeRefreshProvider.notifier).bump();
  }

  /// Signs out because the session is too old (30 days, 7 for admins);
  /// the sign-in screen explains why.
  Future<void> expireSession() async {
    AppLogger.info('Session expired; signing out');
    _pendingSignOutReason = SignOutReason.sessionExpired;
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AppFailure catch (failure) {
      AppLogger.error(
        'Sign-out after session expiry failed',
        context: {'errorCode': failure.code},
      );
    }
    if (!ref.mounted) return;
    _resetSession();
    state = const AuthSignedOut(reason: SignOutReason.sessionExpired);
  }

  /// A blocking function refused the sign-in (not invited / deactivated).
  /// Shows the "ask your administrator" screen. Returns true if [failure]
  /// was such a refusal.
  bool showSignInRefused(AppFailure failure) {
    switch (failure) {
      case NotInvitedFailure():
        state = const AuthNotInvited();
        return true;
      case AccountDeactivatedFailure():
        state = const AuthNotInvited(reason: NotAllowedReason.deactivated);
        return true;
      default:
        return false;
    }
  }

  /// Forgets why the user was signed out (they are signing in again).
  void clearSignOutReason() {
    _pendingSignOutReason = null;
    if (state case AuthSignedOut(reason: != null)) {
      state = const AuthSignedOut();
    }
  }

  Future<void> signOut() async {
    if (state is AuthNotConfigured) return;
    _pendingSignOutReason = null;
    await ref.read(authRepositoryProvider).signOut();
    if (!ref.mounted) return;
    _resetSession();
    state = const AuthSignedOut();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Bumped to make the router re-check the current route without an auth
/// change (app resumed, periodic session check).
class RouteRefreshController extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final routeRefreshProvider = NotifierProvider<RouteRefreshController, int>(
  RouteRefreshController.new,
);

/// Role of the signed-in user, or null when not signed in.
final currentRoleProvider = Provider<UserRole?>((ref) {
  return switch (ref.watch(authControllerProvider)) {
    AuthMember(:final role) => role,
    _ => null,
  };
});

/// The signed-in session (uid, organisation, claims, user document).
final currentSessionProvider = Provider<UserSession?>((ref) {
  return switch (ref.watch(authControllerProvider)) {
    AuthMember(:final session) => session,
    _ => null,
  };
});

/// The organisation of the signed-in user. Org-scoped repositories throw
/// [UnauthenticatedFailure] without it, so no query runs signed out.
String requireOrgId(Ref ref) {
  final orgId = ref.watch(currentSessionProvider.select((s) => s?.orgId));
  if (orgId == null) throw const UnauthenticatedFailure();
  return orgId;
}

/// The phone verification in progress (between the phone and code screens).
@immutable
class PendingPhoneVerification {
  const PendingPhoneVerification({
    required this.phoneNumber,
    required this.verificationId,
    required this.sentAt,
    this.resendToken,
    this.autoSignInFailure,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  /// When the last code was sent (for the resend countdown).
  final DateTime sentAt;

  /// Set when Android's automatic sign-in failed after the code was sent.
  final AppFailure? autoSignInFailure;

  PendingPhoneVerification copyWith({
    String? verificationId,
    int? resendToken,
    DateTime? sentAt,
    AppFailure? autoSignInFailure,
  }) => PendingPhoneVerification(
    phoneNumber: phoneNumber,
    verificationId: verificationId ?? this.verificationId,
    resendToken: resendToken ?? this.resendToken,
    sentAt: sentAt ?? this.sentAt,
    autoSignInFailure: autoSignInFailure,
  );
}

/// Phone sign-in (spec 4.1 step 3): send code, resend, confirm.
///
/// Methods throw `AppFailure`. Refusals by the blocking functions
/// (not invited, deactivated) also move the auth state to the "ask your
/// administrator" screen.
class PhoneSignInController extends Notifier<PendingPhoneVerification?> {
  @override
  PendingPhoneVerification? build() => null;

  AuthController get _auth => ref.read(authControllerProvider.notifier);

  AppFailure _handle(Object error, StackTrace stackTrace) {
    final failure = mapError(error, stackTrace);
    if (ref.mounted) _auth.showSignInRefused(failure);
    return failure;
  }

  void _onAutoSignInFailed(AppFailure failure) {
    if (!ref.mounted) return;
    if (_auth.showSignInRefused(failure)) return;
    final pending = state;
    if (pending != null) {
      state = pending.copyWith(autoSignInFailure: failure);
    }
  }

  /// Sends the SMS code to [phoneNumber] (E.164). Returns true when the
  /// user must type the code, false when Android signed them in already.
  Future<bool> sendCode(String phoneNumber) async {
    _auth.clearSignOutReason();
    final PhoneVerificationResult result;
    try {
      result = await ref
          .read(authRepositoryProvider)
          .startPhoneVerification(
            phoneNumber,
            onAutoSignInFailed: _onAutoSignInFailed,
          );
    } catch (error, stackTrace) {
      throw _handle(error, stackTrace);
    }
    if (!ref.mounted) return false;
    switch (result) {
      case PhoneVerificationCodeSent(:final verificationId, :final resendToken):
        state = PendingPhoneVerification(
          phoneNumber: phoneNumber,
          verificationId: verificationId,
          resendToken: resendToken,
          sentAt: ref.read(clockProvider)(),
        );
        return true;
      case PhoneAutoVerified():
        state = null;
        return false;
    }
  }

  /// Sends a new code to the same number.
  Future<void> resendCode() async {
    final pending = state;
    if (pending == null) return;
    final PhoneVerificationResult result;
    try {
      result = await ref
          .read(authRepositoryProvider)
          .startPhoneVerification(
            pending.phoneNumber,
            resendToken: pending.resendToken,
            onAutoSignInFailed: _onAutoSignInFailed,
          );
    } catch (error, stackTrace) {
      throw _handle(error, stackTrace);
    }
    if (!ref.mounted) return;
    switch (result) {
      case PhoneVerificationCodeSent(:final verificationId, :final resendToken):
        state = pending.copyWith(
          verificationId: verificationId,
          resendToken: resendToken,
          sentAt: ref.read(clockProvider)(),
        );
      case PhoneAutoVerified():
        state = null;
    }
  }

  /// Signs in with the typed code.
  Future<void> confirmCode(String code) async {
    final pending = state;
    if (pending == null) {
      throw const SessionExpiredFailure(code: 'no-pending-verification');
    }
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmSmsCode(
            verificationId: pending.verificationId,
            smsCode: code,
          );
    } catch (error, stackTrace) {
      throw _handle(error, stackTrace);
    }
    if (ref.mounted) state = null;
  }

  void clear() => state = null;
}

final phoneSignInControllerProvider =
    NotifierProvider<PhoneSignInController, PendingPhoneVerification?>(
      PhoneSignInController.new,
    );

/// Email fallback (spec 4.1): sign in, or ask for a password email.
class EmailSignInController extends Notifier<void> {
  @override
  void build() {}

  /// Throws `AppFailure`; refusals also show the "ask your
  /// administrator" screen.
  Future<void> signIn({required String email, required String password}) async {
    final auth = ref.read(authControllerProvider.notifier)
      ..clearSignOutReason();
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);
    } catch (error, stackTrace) {
      final failure = mapError(error, stackTrace);
      if (ref.mounted) auth.showSignInRefused(failure);
      throw failure;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
}

final emailSignInControllerProvider =
    NotifierProvider<EmailSignInController, void>(EmailSignInController.new);

/// State of the admin second-factor screen.
@immutable
class AdminVerifyState {
  const AdminVerifyState({this.sent, this.sentAt, this.busy = false});

  /// The last code sent, or null before the first one.
  final AdminCodeSent? sent;
  final DateTime? sentAt;
  final bool busy;

  AdminVerifyState copyWith({
    AdminCodeSent? sent,
    DateTime? sentAt,
    bool? busy,
  }) => AdminVerifyState(
    sent: sent ?? this.sent,
    sentAt: sentAt ?? this.sentAt,
    busy: busy ?? this.busy,
  );
}

/// Admin second factor (D-01): send the email code, verify it, then
/// refresh the ID token so the `adminVerifiedUntil` claim is used.
class AdminVerifyController extends Notifier<AdminVerifyState> {
  @override
  AdminVerifyState build() => const AdminVerifyState();

  Future<T> _run<T>(Future<T> Function() action) async {
    state = state.copyWith(busy: true);
    try {
      return await action();
    } catch (error, stackTrace) {
      final failure = mapError(error, stackTrace);
      if (failure is SessionExpiredFailure && ref.mounted) {
        await ref.read(authControllerProvider.notifier).expireSession();
      }
      throw failure;
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  Future<void> sendCode() => _run(() async {
    final sent = await ref
        .read(adminVerificationRepositoryProvider)
        .sendAdminCode();
    if (ref.mounted) {
      state = state.copyWith(sent: sent, sentAt: ref.read(clockProvider)());
    }
  });

  Future<void> verify(String code) => _run(() async {
    await ref.read(adminVerificationRepositoryProvider).verifyAdminCode(code);
    if (!ref.mounted) return;
    await ref.read(authControllerProvider.notifier).onAdminVerified();
  });
}

final adminVerifyControllerProvider =
    NotifierProvider.autoDispose<AdminVerifyController, AdminVerifyState>(
      AdminVerifyController.new,
    );
