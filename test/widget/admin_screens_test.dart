import 'package:atms/core/config/firebase_providers.dart';
import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/core/errors/failure_messages.dart';
import 'package:atms/core/errors/server_error_code.dart';
import 'package:atms/features/departments/presentation/departments_screen.dart';
import 'package:atms/features/organisation/domain/org_settings.dart';
import 'package:atms/features/organisation/presentation/org_settings_screen.dart';
import 'package:atms/features/organisation/presentation/reporting_tree_screen.dart';
import 'package:atms/features/users/domain/user_repositories.dart';
import 'package:atms/features/users/presentation/admin_user_detail_screen.dart';
import 'package:atms/features/users/presentation/admin_users_screen.dart';
import 'package:atms/features/users/presentation/user_providers.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

class _MockUserAdmin extends Mock implements UserAdminRepository {}

final _admin = userFixture(
  id: 'admin',
  name: 'Imani',
  role: UserRole.admin,
  supervisorId: 'top',
  consentVersion: 'x',
);

Future<void> _seedDepartment(
  FakeFirebaseFirestore db,
  String id,
  String name, {
  String? headUserId,
  bool active = true,
}) => db.collection('orgs').doc(testOrg).collection('departments').doc(id).set({
  'name': name,
  'headUserId': headUserId,
  'active': active,
});

Future<Map<String, dynamic>?> _read(
  FakeFirebaseFirestore db,
  String path,
) async => (await db.doc('orgs/$testOrg/$path').get()).data();

Future<Map<String, dynamic>?> _readOrg(FakeFirebaseFirestore db) async =>
    (await db.doc('orgs/$testOrg').get()).data();

/// Scrolls the screen's main list until [finder] is built and visible.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(ListView).first,
    const Offset(0, -200),
  );
  await tester.pumpAndSettle();
}

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

  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await seedUser(db, _admin);
  });

  List<Override> overrides([List<Override> extra = const []]) => [
    signedInSession(_admin, adminVerifiedUntil: farFuture),
    firestoreProvider.overrideWithValue(db),
    clockProvider.overrideWithValue(() => testNow),
    ...extra,
  ];

  for (final locale in testLocales) {
    final l10n = l10nFor(locale);

    group('DepartmentsScreen [$locale]', () {
      setUp(() async {
        await seedUser(db, userFixture(id: 'u2', name: 'Juma'));
        await _seedDepartment(db, 'finance', 'Finance', headUserId: 'u2');
        await _seedDepartment(db, 'old', 'Old unit', active: false);
      });

      testWidgets('lists departments with heads and inactive ones', (
        tester,
      ) async {
        await pumpLocalized(
          tester,
          const DepartmentsScreen(),
          locale: locale,
          overrides: overrides(),
        );
        expect(find.text(l10n.adminDepartmentsTitle), findsOneWidget);
        expect(find.text('Finance'), findsOneWidget);
        expect(find.text(l10n.departmentHead('Juma')), findsOneWidget);
        expect(find.text('Old unit'), findsOneWidget);
        expect(find.text(l10n.labelInactive), findsOneWidget);
      });

      testWidgets('add: the name is required, then the department is saved', (
        tester,
      ) async {
        await pumpLocalized(
          tester,
          const DepartmentsScreen(),
          locale: locale,
          overrides: overrides(),
        );
        await tester.tap(find.byKey(const Key('addDepartmentButton')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.departmentCreateTitle), findsOneWidget);
        await tester.tap(find.byKey(const Key('saveDepartmentButton')));
        await tester.pump();
        expect(find.text(l10n.validationNameRequired), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('departmentNameField')),
          '  Procurement ',
        );
        await tester.tap(find.byKey(const Key('saveDepartmentButton')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.savedMessage), findsOneWidget);
        expect(find.text('Procurement'), findsOneWidget);
        final snap = await db
            .collection('orgs/$testOrg/departments')
            .where('name', isEqualTo: 'Procurement')
            .get();
        final data = snap.docs.single.data();
        expect(data['active'], isTrue);
        expect(data['headUserId'], isNull);
        expect(data.keys.toSet(), {
          'name',
          'headUserId',
          'active',
          'createdAt',
          'updatedAt',
        });
      });

      testWidgets('deactivate asks first', (tester) async {
        await pumpLocalized(
          tester,
          const DepartmentsScreen(),
          locale: locale,
          overrides: overrides(),
        );
        await tester.tap(find.byKey(const ValueKey('deptMenu-finance')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.actionDeactivate).last);
        await tester.pumpAndSettle();
        expect(
          find.text(l10n.deactivateDepartmentMessage('Finance')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('confirmDeactivateButton')));
        await tester.pumpAndSettle();
        expect((await _read(db, 'departments/finance'))!['active'], isFalse);
        expect(find.text(l10n.labelInactive), findsNWidgets(2));
      });
    });

    group('AdminUsersScreen [$locale]', () {
      setUp(() async {
        await seedUser(
          db,
          userFixture(id: 'top', name: 'Zawadi', supervisorId: null),
        );
        await seedUser(
          db,
          userFixture(
            id: 'u2',
            name: 'Juma',
            supervisorId: 'top',
            active: false,
          ),
        );
        await seedUser(
          db,
          userFixture(id: 'u1', name: 'Asha', supervisorId: 'u2'),
        );
      });

      Future<void> pump(WidgetTester tester) => pumpLocalizedRouter(
        tester,
        const AdminUsersScreen(),
        locale: locale,
        otherPaths: ['/admin/users/new'],
        overrides: overrides(),
      );

      testWidgets('flags inactive people and inactive supervisors', (
        tester,
      ) async {
        await pump(tester);
        expect(find.text(l10n.adminUsersTitle), findsOneWidget);
        for (final name in ['Asha', 'Imani', 'Juma', 'Zawadi']) {
          expect(find.text(name), findsOneWidget);
        }
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('user-u2')),
            matching: find.text(l10n.labelInactive),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('user-u1')),
            matching: find.text(l10n.labelSupervisorInactive),
          ),
          findsOneWidget,
        );
      });

      testWidgets('search filters the loaded people', (tester) async {
        await pump(tester);
        await tester.enterText(find.byKey(const Key('userSearchField')), 'zaw');
        await tester.pump();
        expect(find.text('Zawadi'), findsOneWidget);
        expect(find.text('Asha'), findsNothing);
        // Everyone is loaded, so there is no "load more to search" note.
        expect(find.text(l10n.searchLoadedOnlyNote), findsNothing);
      });

      testWidgets('add opens the new-person editor', (tester) async {
        await pump(tester);
        await tester.tap(find.byKey(const Key('addUserButton')));
        await tester.pumpAndSettle();
        expect(find.text(stubPage('/admin/users/new')), findsOneWidget);
      });
    });

    group('AdminUserDetailScreen [$locale]', () {
      late _MockUserAdmin admin;

      setUp(() async {
        admin = _MockUserAdmin();
        await _seedDepartment(db, 'finance', 'Finance');
        await seedUser(
          db,
          userFixture(id: 'top', name: 'Zawadi', supervisorId: null),
        );
        await seedUser(
          db,
          userFixture(id: 'u1', name: 'Asha', supervisorId: 'top'),
        );
        await db.doc('orgs/$testOrg/users/u1/private/contact').set({
          'phone': '+255712345678',
          'email': 'asha@wizara.go.tz',
        });
      });

      Future<void> pump(WidgetTester tester, {String? userId}) =>
          pumpLocalizedRouter(
            tester,
            AdminUserDetailScreen(userId: userId),
            locale: locale,
            otherPaths: ['/admin/users'],
            overrides: overrides([
              userAdminRepositoryProvider.overrideWithValue(admin),
            ]),
          );

      testWidgets('new person: required fields', (tester) async {
        await pump(tester);
        expect(find.text(l10n.userCreateTitle), findsOneWidget);
        await _scrollTo(tester, find.byKey(const Key('saveUserButton')));
        await tester.tap(find.byKey(const Key('saveUserButton')));
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.text(l10n.validationNameRequired),
          find.byType(ListView).first,
          const Offset(0, 200),
        );
        expect(find.text(l10n.validationNameRequired), findsOneWidget);
        expect(find.text(l10n.validationPhoneOrEmail), findsOneWidget);
        verifyNever(() => admin.upsertUser(any()));
      });

      testWidgets('new person without a supervisor: warns before saving', (
        tester,
      ) async {
        when(() => admin.upsertUser(any())).thenAnswer(
          (_) async => const UpsertUserResult(uid: 'new', created: true),
        );
        await pump(tester);
        await tester.enterText(find.byKey(const Key('userNameField')), 'Neema');
        await tester.enterText(
          find.byKey(const Key('userPhoneField')),
          '0754 000 111',
        );
        await tester.tap(find.byKey(const Key('userDepartmentTile')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Finance'));
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.byKey(const Key('saveUserButton')));
        await tester.tap(find.byKey(const Key('saveUserButton')));
        await tester.pumpAndSettle();
        expect(
          find.text(l10n.topPersonWarningMessage('Neema')),
          findsOneWidget,
        );
        await tester.tap(find.text(l10n.actionCancel));
        await tester.pumpAndSettle();
        verifyNever(() => admin.upsertUser(any()));
        // Closing the dialog gives focus back to a field, which scrolls up.
        await _scrollTo(tester, find.byKey(const Key('saveUserButton')));

        await tester.tap(find.byKey(const Key('saveUserButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirmTopPersonButton')));
        await tester.pumpAndSettle();
        final draft =
            verify(() => admin.upsertUser(captureAny())).captured.single
                as UserDraft;
        expect(draft.toCallableData(), {
          'name': 'Neema',
          'phone': '+255754000111',
          'email': null,
          'role': 'staff',
          'deptId': 'finance',
          'supervisorId': null,
          'jobRole': null,
          'language': 'sw',
          'confidentialDepts': <String>[],
        });
        expect(find.text(stubPage('/admin/users')), findsOneWidget);
        expect(find.text(l10n.userAddedMessage), findsOneWidget);
      });

      testWidgets('existing person: email cannot be removed', (tester) async {
        await pump(tester, userId: 'u1');
        expect(find.text('Asha'), findsWidgets);
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('userPhoneField')))
              .controller!
              .text,
          '0712 345 678',
        );
        await tester.enterText(find.byKey(const Key('userEmailField')), '');
        await _scrollTo(tester, find.byKey(const Key('saveUserButton')));
        await tester.tap(find.byKey(const Key('saveUserButton')));
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.byKey(const Key('userEmailField')),
          find.byType(ListView).first,
          const Offset(0, 200),
        );
        expect(find.text(l10n.errorEmailCannotBeRemoved), findsOneWidget);
        verifyNever(() => admin.upsertUser(any()));
      });

      testWidgets('existing person with a supervisor saves without warning, '
          'and server errors are shown', (tester) async {
        when(
          () => admin.upsertUser(any()),
        ).thenThrow(ServerFailure(ServerErrorCode.phoneInUse, field: 'phone'));
        await pump(tester, userId: 'u1');
        await _scrollTo(tester, find.byKey(const Key('saveUserButton')));
        await tester.tap(find.byKey(const Key('saveUserButton')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.topPersonWarningTitle), findsNothing);
        final draft =
            verify(() => admin.upsertUser(captureAny())).captured.single
                as UserDraft;
        expect(draft.uid, 'u1');
        expect(draft.email, 'asha@wizara.go.tz');
        expect(draft.supervisorId, 'top');
        expect(
          find.text(
            failureMessage(ServerFailure(ServerErrorCode.phoneInUse), l10n),
          ),
          findsOneWidget,
        );
      });

      testWidgets('deactivate asks first', (tester) async {
        when(() => admin.deactivateUser('u1')).thenAnswer((_) async => 3);
        await pump(tester, userId: 'u1');
        await _scrollTo(tester, find.byKey(const Key('deactivateUserButton')));
        await tester.tap(find.byKey(const Key('deactivateUserButton')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.deactivateUserMessage('Asha')), findsOneWidget);
        await tester.tap(find.byKey(const Key('confirmDeactivateButton')));
        await tester.pumpAndSettle();
        verify(() => admin.deactivateUser('u1')).called(1);
        expect(find.text(l10n.userDeactivatedMessage(3)), findsOneWidget);
      });

      testWidgets('admins cannot deactivate themselves here', (tester) async {
        await pump(tester, userId: 'admin');
        await _scrollTo(tester, find.byKey(const Key('saveUserButton')));
        expect(find.byKey(const Key('deactivateUserButton')), findsNothing);
      });

      testWidgets('a missing person shows a friendly error', (tester) async {
        await pump(tester, userId: 'nobody');
        expect(
          find.text(failureMessage(const NotFoundFailure(), l10n)),
          findsOneWidget,
        );
        expect(find.text(l10n.actionRetry), findsOneWidget);
      });
    });

    group('ReportingTreeScreen [$locale]', () {
      testWidgets('expands people and flags inactive supervisors', (
        tester,
      ) async {
        await seedUser(
          db,
          userFixture(id: 'top', name: 'Zawadi', supervisorId: null),
        );
        await seedUser(
          db,
          userFixture(
            id: 'u2',
            name: 'Juma',
            supervisorId: 'top',
            active: false,
          ),
        );
        await seedUser(
          db,
          userFixture(id: 'u1', name: 'Asha', supervisorId: 'u2'),
        );
        await pumpLocalized(
          tester,
          const ReportingTreeScreen(),
          locale: locale,
          overrides: overrides(),
        );
        expect(find.text(l10n.adminReportingTreeTitle), findsOneWidget);
        expect(find.text('Zawadi'), findsOneWidget);
        expect(find.text('Juma'), findsNothing);
        await tester.tap(find.text('Zawadi'));
        await tester.pumpAndSettle();
        expect(find.text('Juma'), findsOneWidget);
        expect(find.text(l10n.labelInactive), findsOneWidget);
        await tester.tap(find.text('Juma'));
        await tester.pumpAndSettle();
        expect(find.text('Asha'), findsOneWidget);
        expect(find.text(l10n.labelSupervisorInactive), findsOneWidget);
        // Indented one level deeper than its supervisor.
        expect(
          tester.getTopLeft(find.text('Asha')).dx,
          greaterThan(tester.getTopLeft(find.text('Juma')).dx),
        );
      });

      testWidgets('empty organisation', (tester) async {
        await db.doc('orgs/$testOrg/users/admin').delete();
        await pumpLocalized(
          tester,
          const ReportingTreeScreen(),
          locale: locale,
          overrides: overrides(),
        );
        expect(find.text(l10n.reportingTreeEmptyTitle), findsOneWidget);
      });
    });

    group('OrgSettingsScreen [$locale]', () {
      setUp(() async {
        await db.doc('orgs/$testOrg').set({
          'name': 'Wizara',
          'timezone': OrgSettings.defaultTimezone,
          'workingHoursEnabled': true,
          'workingHours': {
            'start': '08:00',
            'end': '17:00',
            'days': [1, 2, 3, 4, 5],
          },
          'reminderHours': [24, 1],
          'escalationHours': 24,
          'escalationMaxLevel': 2,
          'smsEnabled': false,
          'smsMonthlyCap': 10000,
        });
      });

      Future<void> pump(WidgetTester tester) => pumpLocalized(
        tester,
        const OrgSettingsScreen(),
        locale: locale,
        overrides: overrides(),
      );

      testWidgets('saves only the changed fields', (tester) async {
        await pump(tester);
        expect(find.text(l10n.adminSettingsTitle), findsOneWidget);
        expect(
          find.text(l10n.timeZoneEastAfrica(OrgSettings.defaultTimezone)),
          findsOneWidget,
        );
        await _scrollTo(tester, find.byKey(const Key('escalationHoursField')));
        await tester.enterText(
          find.byKey(const Key('escalationHoursField')),
          '12',
        );
        await _scrollTo(tester, find.byKey(const Key('saveSettingsButton')));
        await tester.tap(find.byKey(const Key('saveSettingsButton')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.savedMessage), findsOneWidget);
        final org = (await _readOrg(db))!;
        expect(org['escalationHours'], 12);
        expect(org['updatedAt'], isNotNull);
        expect(org['smsMonthlyCap'], 10000);
      });

      testWidgets('nothing changed: nothing is written', (tester) async {
        await pump(tester);
        await _scrollTo(tester, find.byKey(const Key('saveSettingsButton')));
        await tester.tap(find.byKey(const Key('saveSettingsButton')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.noChangesMessage), findsOneWidget);
        expect((await _readOrg(db))!['updatedAt'], isNull);
      });

      testWidgets('out-of-range values are refused', (tester) async {
        await pump(tester);
        await _scrollTo(tester, find.byKey(const Key('escalationLevelsField')));
        await tester.enterText(
          find.byKey(const Key('escalationLevelsField')),
          '${OrgSettings.maxEscalationLevel + 1}',
        );
        await _scrollTo(tester, find.byKey(const Key('saveSettingsButton')));
        await tester.tap(find.byKey(const Key('saveSettingsButton')));
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.byKey(const Key('escalationLevelsField')),
          find.byType(ListView).first,
          const Offset(0, 200),
        );
        expect(
          find.text(
            l10n.validationWholeNumberRange(1, OrgSettings.maxEscalationLevel),
          ),
          findsOneWidget,
        );
        expect((await _readOrg(db))!['updatedAt'], isNull);
      });
    });
  }
}
