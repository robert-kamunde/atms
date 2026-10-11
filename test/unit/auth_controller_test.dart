import 'package:atms/core/constants/app_constants.dart';
import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/core/localization/locale_provider.dart';
import 'package:atms/features/auth/domain/auth_state.dart';
import 'package:atms/features/auth/presentation/auth_providers.dart';
import 'package:atms/features/users/domain/user_repositories.dart';
import 'package:atms/shared/models/app_user.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

/// Profile repository whose read of the person's own document is refused
/// (the rules refuse it once the account is deactivated).
class _RefusedProfileRepository implements UserProfileRepository {
  @override
  Stream<AppUser?> watchUser({required String orgId, required String uid}) =>
      Stream.error(const PermissionDeniedFailure());

  @override
  Future<void> updateLanguage({
    required String orgId,
    required String uid,
    required String language,
  }) => throw UnimplementedError();

  @override
  Future<void> acceptConsent({
    required String orgId,
    required String uid,
    required String version,
  }) => throw UnimplementedError();
}

void main() {
  late FakeAuthRepository auth;
  late FakeFirebaseFirestore db;
  late FakeNotificationPermission notifications;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository();
    db = FakeFirebaseFirestore();
    notifications = FakeNotificationPermission();
    container = ProviderContainer(
      overrides: authOverrides(
        auth: auth,
        db: db,
        notifications: notifications,
      ),
    );
    // Keep the controller alive for the whole test.
    container.listen(authControllerProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  AuthState state() => container.read(authControllerProvider);
  AuthController controller() =>
      container.read(authControllerProvider.notifier);

  Future<void> signIn(String uid) async {
    auth.signIn(uid);
    for (var i = 0; i < 5; i++) {
      await settle();
    }
  }

  Future<Map<String, dynamic>?> readUser(String uid) async =>
      (await db
              .collection('orgs')
              .doc(testOrg)
              .collection('users')
              .doc(uid)
              .get())
          .data();

  test('starts unknown, then signed out when there is no user', () async {
    expect(state(), const AuthUnknown());
    auth.userIds.add(null);
    await settle();
    expect(state(), const AuthSignedOut());
  });

  test('without an orgId claim the user is not invited', () async {
    auth.claims = claimsFor(orgId: null);
    await signIn('u1');
    expect(state(), const AuthNotInvited());
  });

  test('without a user document the user is not invited', () async {
    auth.claims = claimsFor();
    await signIn('u1');
    expect(state(), const AuthNotInvited());
  });

  test('a deactivated user sees the deactivated message', () async {
    auth.claims = claimsFor();
    await seedUser(db, userFixture(active: false, consentVersion: 'x'));
    await signIn('u1');
    expect(state(), const AuthNotInvited(reason: NotAllowedReason.deactivated));
  });

  test('a returning user is signed in with their role', () async {
    auth.claims = claimsFor();
    await seedUser(
      db,
      userFixture(consentVersion: AppConstants.consentVersion, language: 'sw'),
    );
    await signIn('u1');
    final s = state();
    expect(s, isA<AuthSignedIn>());
    expect((s as AuthSignedIn).role, UserRole.staff);
    expect(s.session?.orgId, testOrg);
    // The language stored on the user document is applied.
    expect(container.read(localeProvider), AppLocales.swahili);
  });

  group('session policy (30 days, 7 for admins)', () {
    test('staff session of 31 days is signed out with a reason', () async {
      auth.claims = claimsFor(age: const Duration(days: 31));
      await seedUser(
        db,
        userFixture(consentVersion: AppConstants.consentVersion),
      );
      await signIn('u1');
      expect(
        state(),
        const AuthSignedOut(reason: SignOutReason.sessionExpired),
      );
      expect(auth.signOutCount, 1);
    });

    test('staff session of 8 days is fine', () async {
      auth.claims = claimsFor(age: const Duration(days: 8));
      await seedUser(
        db,
        userFixture(consentVersion: AppConstants.consentVersion),
      );
      await signIn('u1');
      expect(state(), isA<AuthSignedIn>());
    });

    test('admin session of 8 days is signed out', () async {
      auth.claims = claimsFor(age: const Duration(days: 8));
      await seedUser(
        db,
        userFixture(
          role: UserRole.admin,
          consentVersion: AppConstants.consentVersion,
        ),
      );
      await signIn('u1');
      expect(
        state(),
        const AuthSignedOut(reason: SignOutReason.sessionExpired),
      );
    });

    test('the reason is cleared when signing in again', () async {
      auth.claims = claimsFor(age: const Duration(days: 40));
      await seedUser(
        db,
        userFixture(consentVersion: AppConstants.consentVersion),
      );
      await signIn('u1');
      controller().clearSignOutReason();
      expect(state(), const AuthSignedOut());
    });

    test('a revoked token signs out', () async {
      auth.claimsFailure = const SessionExpiredFailure(
        code: 'user-token-expired',
      );
      await signIn('u1');
      expect(
        state(),
        const AuthSignedOut(reason: SignOutReason.sessionExpired),
      );
    });
  });

  test('first sign-in goes through language, consent and notifications, '
      'writing only the allowed fields', () async {
    auth.claims = claimsFor();
    notifications.needs = true;
    await seedUser(db, userFixture(language: 'en'));
    await signIn('u1');
    expect(state(), isA<AuthNeedsLanguage>());

    await controller().completeLanguageStep(AppLocales.swahili);
    await settle();
    expect((await readUser('u1'))!['language'], 'sw');
    expect(container.read(localeProvider), AppLocales.swahili);
    expect(state(), isA<AuthNeedsConsent>());

    await controller().completeConsentStep();
    await settle();
    final doc = (await readUser('u1'))!;
    expect(doc['consentVersion'], AppConstants.consentVersion);
    expect(doc['consentAcceptedAt'], isNotNull);
    expect(state(), isA<AuthNeedsNotificationPermission>());

    await controller().completeNotificationStep(allow: true);
    expect(notifications.requests, 1);
    expect(state(), isA<AuthSignedIn>());
  });

  test('"not now" on notifications still lands on My Tasks', () async {
    auth.claims = claimsFor();
    notifications.needs = true;
    await seedUser(
      db,
      userFixture(consentVersion: AppConstants.consentVersion),
    );
    await signIn('u1');
    expect(state(), isA<AuthNeedsNotificationPermission>());
    await controller().completeNotificationStep(allow: false);
    expect(notifications.requests, 0);
    expect(state(), isA<AuthSignedIn>());
  });

  test('an old consent version asks for consent again', () async {
    auth.claims = claimsFor();
    await seedUser(db, userFixture(consentVersion: 'old'));
    await signIn('u1');
    expect(state(), isA<AuthNeedsConsent>());
  });

  group('admin second factor', () {
    setUp(() async {
      await seedUser(
        db,
        userFixture(
          role: UserRole.admin,
          consentVersion: AppConstants.consentVersion,
        ),
      );
    });

    test('claim parsed into the signed-in state', () async {
      final until = testNow.add(const Duration(hours: 12));
      auth.claims = claimsFor(adminVerifiedUntil: until);
      await signIn('u1');
      final s = state() as AuthSignedIn;
      expect(s.adminVerifiedUntil, until);
      expect(s.isAdminVerifiedAt(testNow), isTrue);
    });

    test('onAdminVerified forces a token refresh', () async {
      auth.claims = claimsFor();
      await signIn('u1');
      expect((state() as AuthSignedIn).isAdminVerifiedAt(testNow), isFalse);
      auth.refreshedClaims = claimsFor(
        adminVerifiedUntil: testNow.add(const Duration(hours: 12)),
      );
      await controller().onAdminVerified();
      expect(auth.forceRefreshCount, 1);
      expect((state() as AuthSignedIn).isAdminVerifiedAt(testNow), isTrue);
    });

    test('markAdminVerificationExpired drops the claim', () async {
      auth.claims = claimsFor(
        adminVerifiedUntil: testNow.add(const Duration(hours: 1)),
      );
      await signIn('u1');
      controller().markAdminVerificationExpired();
      expect((state() as AuthSignedIn).adminVerifiedUntil, isNull);
    });
  });

  test('blocking-function refusals show the right screen', () {
    expect(controller().showSignInRefused(const NotInvitedFailure()), isTrue);
    expect(state(), const AuthNotInvited());
    expect(
      controller().showSignInRefused(const AccountDeactivatedFailure()),
      isTrue,
    );
    expect(state(), const AuthNotInvited(reason: NotAllowedReason.deactivated));
    expect(controller().showSignInRefused(const NetworkFailure()), isFalse);
  });

  test('signing out returns to the sign-in screen', () async {
    auth.claims = claimsFor();
    await seedUser(
      db,
      userFixture(consentVersion: AppConstants.consentVersion),
    );
    await signIn('u1');
    await controller().signOut();
    await settle();
    expect(state(), const AuthSignedOut());
    expect(container.read(currentSessionProvider), isNull);
  });

  test(
    'a refused read of the own profile shows the deactivated message',
    () async {
      final refused = ProviderContainer(
        overrides: [
          ...authOverrides(auth: auth, db: db, notifications: notifications),
          userProfileRepositoryProvider.overrideWithValue(
            _RefusedProfileRepository(),
          ),
        ],
      );
      addTearDown(refused.dispose);
      refused.listen(authControllerProvider, (_, _) {});
      auth.claims = claimsFor();
      auth.signIn('u1');
      for (var i = 0; i < 5; i++) {
        await settle();
      }
      expect(
        refused.read(authControllerProvider),
        const AuthNotInvited(reason: NotAllowedReason.deactivated),
      );
    },
  );
}
