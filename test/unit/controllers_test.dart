import 'dart:async';

import 'package:atms/core/config/firebase_providers.dart';
import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/core/errors/server_error_code.dart';
import 'package:atms/core/services/offline_write.dart';
import 'package:atms/features/auth/domain/admin_verification_repository.dart';
import 'package:atms/features/auth/domain/auth_repository.dart';
import 'package:atms/features/auth/domain/auth_state.dart';
import 'package:atms/features/auth/presentation/auth_providers.dart';
import 'package:atms/features/departments/presentation/department_providers.dart';
import 'package:atms/features/organisation/presentation/org_providers.dart';
import 'package:atms/features/users/domain/user_repositories.dart';
import 'package:atms/features/users/presentation/user_providers.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

class _MockAdminVerification extends Mock
    implements AdminVerificationRepository {}

class _MockUserAdmin extends Mock implements UserAdminRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const UserDraft(
        name: 'x',
        phone: null,
        email: null,
        role: UserRole.staff,
        deptId: 'd',
        supervisorId: null,
        jobRole: null,
        language: 'en',
        confidentialDepts: [],
      ),
    );
  });

  group('awaitOfflineCapableWrite', () {
    test('a confirmed write is saved', () async {
      expect(
        await awaitOfflineCapableWrite(Future.value(), writeName: 't'),
        WriteOutcome.saved,
      );
    });

    test('no answer in time means saved on the phone; a later refusal is '
        'reported', () async {
      final write = Completer<void>();
      AppFailure? late;
      lateWriteFailureHandler = (f) => late = f;
      addTearDown(() => lateWriteFailureHandler = null);
      final outcome = await awaitOfflineCapableWrite(
        write.future,
        writeName: 't',
        wait: const Duration(milliseconds: 10),
      );
      expect(outcome, WriteOutcome.savedOnPhone);
      write.completeError(Exception('refused'));
      await settle();
      expect(late, isA<UnknownFailure>());
    });

    test('an immediate refusal throws an AppFailure', () {
      expect(
        awaitOfflineCapableWrite(
          Future<void>.error(const PermissionDeniedFailure()),
          writeName: 't',
        ),
        throwsA(isA<PermissionDeniedFailure>()),
      );
    });
  });

  group('PhoneSignInController', () {
    late MockAuthRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(() => testNow),
          authControllerProvider.overrideWithBuild(
            (ref, n) =>
                const AuthSignedOut(reason: SignOutReason.sessionExpired),
          ),
        ],
      );
      container.listen(authControllerProvider, (_, _) {});
    });
    tearDown(() => container.dispose());

    PhoneSignInController controller() =>
        container.read(phoneSignInControllerProvider.notifier);

    void answer(Future<PhoneVerificationResult> Function() result) => when(
      () => repo.startPhoneVerification(
        any(),
        resendToken: any(named: 'resendToken'),
        onAutoSignInFailed: any(named: 'onAutoSignInFailed'),
      ),
    ).thenAnswer((_) => result());

    test('sending a code stores the pending verification and clears the '
        'sign-out reason', () async {
      answer(
        () async => const PhoneVerificationCodeSent(
          verificationId: 'v1',
          resendToken: 7,
        ),
      );
      expect(await controller().sendCode('+255712345678'), isTrue);
      final pending = container.read(phoneSignInControllerProvider)!;
      expect(pending.verificationId, 'v1');
      expect(pending.sentAt, testNow);
      expect(container.read(authControllerProvider), const AuthSignedOut());
    });

    test('Android auto-verification needs no code screen', () async {
      answer(() async => const PhoneAutoVerified());
      expect(await controller().sendCode('+255712345678'), isFalse);
      expect(container.read(phoneSignInControllerProvider), isNull);
    });

    test('resend passes the resend token', () async {
      answer(
        () async => const PhoneVerificationCodeSent(
          verificationId: 'v1',
          resendToken: 7,
        ),
      );
      await controller().sendCode('+255712345678');
      await controller().resendCode();
      verify(
        () => repo.startPhoneVerification(
          '+255712345678',
          resendToken: 7,
          onAutoSignInFailed: any(named: 'onAutoSignInFailed'),
        ),
      ).called(1);
    });

    test('a not-invited refusal moves to the not-invited screen', () async {
      answer(() async => throw const NotInvitedFailure());
      await expectLater(
        controller().sendCode('+255712345678'),
        throwsA(isA<NotInvitedFailure>()),
      );
      expect(container.read(authControllerProvider), const AuthNotInvited());
    });

    test('a refused late auto sign-in also shows the screen', () async {
      void Function(AppFailure)? onLate;
      when(
        () => repo.startPhoneVerification(
          any(),
          resendToken: any(named: 'resendToken'),
          onAutoSignInFailed: any(named: 'onAutoSignInFailed'),
        ),
      ).thenAnswer((invocation) async {
        onLate =
            invocation.namedArguments[#onAutoSignInFailed]
                as void Function(AppFailure)?;
        return const PhoneVerificationCodeSent(verificationId: 'v1');
      });
      await controller().sendCode('+255712345678');
      onLate!(const AccountDeactivatedFailure());
      expect(
        container.read(authControllerProvider),
        const AuthNotInvited(reason: NotAllowedReason.deactivated),
      );
      onLate!(const NetworkFailure());
      expect(
        container.read(phoneSignInControllerProvider)?.autoSignInFailure,
        isA<NetworkFailure>(),
      );
    });

    test('confirm without a pending verification is a session expiry', () {
      expect(
        controller().confirmCode('123456'),
        throwsA(isA<SessionExpiredFailure>()),
      );
    });
  });

  group('AdminVerifyController', () {
    late _MockAdminVerification repo;
    late FakeAuthRepository auth;
    late FakeFirebaseFirestore db;
    late ProviderContainer container;

    setUp(() async {
      repo = _MockAdminVerification();
      auth = FakeAuthRepository()..claims = claimsFor();
      db = FakeFirebaseFirestore();
      await seedUser(
        db,
        userFixture(role: UserRole.admin, consentVersion: '2026-10'),
      );
      container = ProviderContainer(
        overrides: [
          ...authOverrides(auth: auth, db: db),
          adminVerificationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      container.listen(authControllerProvider, (_, _) {});
      container.listen(adminVerifyControllerProvider, (_, _) {});
      auth.signIn('u1');
      for (var i = 0; i < 5; i++) {
        await settle();
      }
    });
    tearDown(() => container.dispose());

    test('send, verify, then the refreshed claim unlocks admin', () async {
      when(() => repo.sendAdminCode()).thenAnswer(
        (_) async => AdminCodeSent(
          maskedEmail: 'i***@org.tz',
          expiresAt: testNow.add(const Duration(minutes: 10)),
        ),
      );
      when(() => repo.verifyAdminCode('123456'))
          .thenAnswer((_) async => testNow.add(const Duration(hours: 12)));
      auth.refreshedClaims = claimsFor(
        adminVerifiedUntil: testNow.add(const Duration(hours: 12)),
      );
      final controller = container.read(adminVerifyControllerProvider.notifier);
      await controller.sendCode();
      expect(container.read(adminVerifyControllerProvider).sent, isNotNull);
      await controller.verify('123456');
      expect(auth.forceRefreshCount, 1);
      final state = container.read(authControllerProvider) as AuthSignedIn;
      expect(state.isAdminVerifiedAt(testNow), isTrue);
      expect(container.read(adminVerifyControllerProvider).busy, isFalse);
    });

    test('a wrong code is reported and nothing changes', () async {
      when(
        () => repo.verifyAdminCode(any()),
      ).thenThrow(ServerFailure(ServerErrorCode.codeInvalid, attemptsLeft: 2));
      await expectLater(
        container.read(adminVerifyControllerProvider.notifier).verify('000000'),
        throwsA(isA<ServerFailure>()),
      );
      expect(auth.forceRefreshCount, 0);
    });
  });

  group('UserEditor', () {
    late _MockUserAdmin repo;
    late FakeAuthRepository auth;
    late ProviderContainer container;

    setUp(() async {
      repo = _MockUserAdmin();
      auth = FakeAuthRepository()
        ..claims = claimsFor(
          adminVerifiedUntil: testNow.add(const Duration(hours: 1)),
        );
      final db = FakeFirebaseFirestore();
      await seedUser(
        db,
        userFixture(role: UserRole.admin, consentVersion: '2026-10'),
      );
      container = ProviderContainer(
        overrides: [
          ...authOverrides(auth: auth, db: db),
          userAdminRepositoryProvider.overrideWithValue(repo),
        ],
      );
      container.listen(authControllerProvider, (_, _) {});
      auth.signIn('u1');
      for (var i = 0; i < 5; i++) {
        await settle();
      }
    });
    tearDown(() => container.dispose());

    test(
      'admin-verification-required sends the admin back to the check',
      () async {
        when(
          () => repo.upsertUser(any()),
        ).thenThrow(ServerFailure(ServerErrorCode.adminVerificationRequired));
        expect(
          (container.read(authControllerProvider) as AuthSignedIn)
              .isAdminVerifiedAt(testNow),
          isTrue,
        );
        await expectLater(
          container
              .read(userEditorProvider.notifier)
              .save(
                const UserDraft(
                  name: 'B',
                  phone: '+255712345678',
                  email: null,
                  role: UserRole.staff,
                  deptId: 'd',
                  supervisorId: 'u1',
                  jobRole: null,
                  language: 'sw',
                  confidentialDepts: [],
                ),
              ),
          throwsA(isA<ServerFailure>()),
        );
        expect(
          (container.read(authControllerProvider) as AuthSignedIn)
              .isAdminVerifiedAt(testNow),
          isFalse,
        );
      },
    );

    test('a session-expired error signs the admin out', () async {
      when(() => repo.deactivateUser('u5'))
          .thenThrow(const SessionExpiredFailure());
      await expectLater(
        container.read(userEditorProvider.notifier).deactivate('u5'),
        throwsA(isA<SessionExpiredFailure>()),
      );
      expect(
        container.read(authControllerProvider),
        const AuthSignedOut(reason: SignOutReason.sessionExpired),
      );
    });
  });

  group('paged lists', () {
    late FakeFirebaseFirestore db;
    late ProviderContainer container;

    setUp(() async {
      db = FakeFirebaseFirestore();
      for (var i = 0; i < 23; i++) {
        await db
            .collection('orgs')
            .doc(testOrg)
            .collection('departments')
            .doc('d$i')
            .set({
              'name': 'Dept ${i.toString().padLeft(2, '0')}',
              'active': true,
            });
      }
      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          signedInSession(userFixture(role: UserRole.admin)),
        ],
      );
      container.listen(departmentListProvider, (_, _) {});
    });
    tearDown(() => container.dispose());

    test('loads 20, then the rest on demand', () async {
      await settle();
      await settle();
      var state = container.read(departmentListProvider);
      expect(state.items, hasLength(20));
      expect(state.hasMore, isTrue);
      await container.read(departmentListProvider.notifier).loadMore();
      state = container.read(departmentListProvider);
      expect(state.items, hasLength(23));
      expect(state.hasMore, isFalse);
    });

    test('signed out: a friendly failure, no query', () async {
      final signedOut = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(db)],
      );
      addTearDown(signedOut.dispose);
      signedOut.listen(departmentListProvider, (_, _) {});
      await settle();
      expect(
        signedOut.read(departmentListProvider).failure,
        isA<UnauthenticatedFailure>(),
      );
    });

    test('department writes work and refresh the list', () async {
      await settle();
      final outcome = await container
          .read(departmentEditorProvider.notifier)
          .save(name: 'AAA First');
      expect(outcome, WriteOutcome.saved);
      await container.read(departmentListProvider.notifier).refresh();
      expect(
        container.read(departmentListProvider).items.first.name,
        'AAA First',
      );
    });
  });

  group('reporting tree', () {
    late FakeFirebaseFirestore db;
    late ProviderContainer container;

    setUp(() async {
      db = FakeFirebaseFirestore();
      await seedUser(
        db,
        userFixture(id: 'top', name: 'Neema', supervisorId: null),
      );
      await seedUser(
        db,
        userFixture(id: 'm', name: 'John', supervisorId: 'top', active: false),
      );
      await seedUser(db, userFixture(id: 's', name: 'Asha', supervisorId: 'm'));
      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          signedInSession(userFixture(role: UserRole.admin)),
        ],
      );
      container.listen(reportingTreeProvider, (_, _) {});
    });
    tearDown(() => container.dispose());

    test(
      'expands lazily and flags people under an inactive supervisor',
      () async {
        await settle();
        await settle();
        var rows = flattenReportingTree(container.read(reportingTreeProvider));
        expect(rows.whereType<TreePersonRow>().map((r) => r.user.id), ['top']);

        final controller = container.read(reportingTreeProvider.notifier);
        await controller.toggle('top');
        await controller.toggle('m');
        rows = flattenReportingTree(container.read(reportingTreeProvider));
        final people = rows.whereType<TreePersonRow>().toList();
        expect(people.map((r) => (r.user.id, r.depth)), [
          ('top', 0),
          ('m', 1),
          ('s', 2),
        ]);
        expect(people[1].supervisorInactive, isFalse);
        expect(people[2].supervisorInactive, isTrue);

        await controller.toggle('top');
        rows = flattenReportingTree(container.read(reportingTreeProvider));
        expect(rows.whereType<TreePersonRow>(), hasLength(1));
      },
    );
  });
}
