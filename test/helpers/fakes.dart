import 'dart:async';

import 'package:atms/core/config/bootstrap.dart';
import 'package:atms/core/config/config_providers.dart';
import 'package:atms/core/config/firebase_providers.dart';
import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/core/services/callable_client.dart';
import 'package:atms/core/services/offline_write.dart';
import 'package:atms/features/auth/domain/auth_repository.dart';
import 'package:atms/features/auth/domain/auth_state.dart';
import 'package:atms/features/auth/domain/notification_permission.dart';
import 'package:atms/features/auth/domain/token_claims.dart';
import 'package:atms/features/auth/presentation/auth_providers.dart';
import 'package:atms/shared/models/app_user.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';

/// Fixed "now" for tests: 8 Oct 2026, 12:00 UTC.
final DateTime testNow = DateTime.utc(2026, 10, 8, 12);

const String testOrg = 'org1';

/// In-memory [AuthRepository]: tests push user ids and set claims.
class FakeAuthRepository implements AuthRepository {
  final StreamController<String?> userIds =
      StreamController<String?>.broadcast();
  TokenClaims? claims;
  TokenClaims? refreshedClaims;
  AppFailure? claimsFailure;
  int forceRefreshCount = 0;
  int signOutCount = 0;
  String? resetEmail;

  void signIn(String uid) => userIds.add(uid);

  @override
  Stream<String?> watchUserId() => userIds.stream;

  @override
  Future<TokenClaims?> currentClaims({bool forceRefresh = false}) async {
    if (claimsFailure case final failure?) throw failure;
    if (forceRefresh) {
      forceRefreshCount++;
      claims = refreshedClaims ?? claims;
    }
    return claims;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    userIds.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async => resetEmail = email;

  // Phone and email sign-in are mocked separately where needed.
  @override
  Future<PhoneVerificationResult> startPhoneVerification(
    String phoneNumber, {
    int? resendToken,
    void Function(AppFailure failure)? onAutoSignInFailed,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) => throw UnimplementedError();

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();
}

class FakeNotificationPermission implements NotificationPermissionService {
  FakeNotificationPermission({this.needs = false});

  bool needs;
  int requests = 0;

  @override
  Future<bool> needsPrompt() async => needs;

  @override
  Future<bool> request() async {
    requests++;
    needs = false;
    return true;
  }
}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCallableClient extends Mock implements CallableClient {}

/// Claims of a fresh session in [testOrg].
TokenClaims claimsFor({
  Duration age = const Duration(hours: 1),
  DateTime? adminVerifiedUntil,
  String? orgId = testOrg,
}) => TokenClaims(
  authTime: testNow.subtract(age),
  orgId: orgId,
  adminVerifiedUntil: adminVerifiedUntil,
);

AppUser userFixture({
  String id = 'u1',
  String name = 'Asha',
  UserRole role = UserRole.staff,
  String deptId = 'finance',
  String? supervisorId = 'u2',
  bool active = true,
  String? consentVersion,
  String language = 'en',
}) => AppUser(
  id: id,
  orgId: testOrg,
  name: name,
  role: role,
  deptId: deptId,
  supervisorId: supervisorId,
  active: active,
  consentVersion: consentVersion,
  language: language,
);

Future<void> seedUser(FakeFirebaseFirestore db, AppUser user) => db
    .collection('orgs')
    .doc(testOrg)
    .collection('users')
    .doc(user.id)
    .set(user.toMap());

/// [AuthController] that starts in [initial] and records the calls the
/// screens make instead of doing them.
class RecordingAuthController extends AuthController {
  RecordingAuthController(this.initial, {this.failure, this.afterAdminVerify});

  final AuthState initial;

  /// Thrown by the onboarding steps when set.
  final AppFailure? failure;

  /// State after `onAdminVerified`.
  final AuthState? afterAdminVerify;

  final List<String> calls = [];

  @override
  AuthState build() => initial;

  Future<void> _record(String call) async {
    calls.add(call);
    if (failure case final f?) throw f;
  }

  @override
  Future<void> completeLanguageStep(Locale locale) =>
      _record('language:${locale.languageCode}');

  @override
  Future<void> completeConsentStep() => _record('consent');

  @override
  Future<void> completeNotificationStep({required bool allow}) async =>
      calls.add('notifications:$allow');

  @override
  Future<void> onAdminVerified() async {
    calls.add('adminVerified');
    if (afterAdminVerify case final next?) state = next;
  }

  @override
  Future<WriteOutcome?> changeLanguage(Locale locale) async {
    calls.add('changeLanguage:${locale.languageCode}');
    return WriteOutcome.saved;
  }

  @override
  Future<void> signOut() async => calls.add('signOut');
}

/// Overrides for a fully wired `AuthController` over fakes.
List<Override> authOverrides({
  required FakeAuthRepository auth,
  required FakeFirebaseFirestore db,
  FakeNotificationPermission? notifications,
}) => [
  bootstrapResultProvider.overrideWithValue(const BootstrapReady()),
  authRepositoryProvider.overrideWithValue(auth),
  firestoreProvider.overrideWithValue(db),
  notificationPermissionProvider.overrideWithValue(
    notifications ?? FakeNotificationPermission(),
  ),
  clockProvider.overrideWithValue(() => testNow),
];

/// Override with a signed-in session (role, user and claims) in [testOrg].
Override signedInSession(AppUser user, {DateTime? adminVerifiedUntil}) =>
    authControllerProvider.overrideWithBuild(
      (ref, notifier) => AuthSignedIn(
        user.role,
        adminVerifiedUntil: adminVerifiedUntil,
        session: UserSession(
          uid: user.id,
          orgId: testOrg,
          claims: claimsFor(adminVerifiedUntil: adminVerifiedUntil),
          user: user,
        ),
      ),
    );

/// Waits for queued microtasks and stream events.
Future<void> settle() => Future<void>.delayed(Duration.zero);

ProviderContainer containerWith(List<Override> overrides) {
  final container = ProviderContainer(overrides: overrides);
  return container;
}
