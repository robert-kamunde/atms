import 'package:atms/app.dart';
import 'package:atms/core/routing/app_router.dart';
import 'package:atms/core/routing/route_guard.dart';
import 'package:atms/core/routing/route_names.dart';
import 'package:atms/features/auth/domain/auth_state.dart';
import 'package:atms/features/auth/presentation/auth_providers.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/pump_app.dart';

String? redirect(AuthState auth, String path) =>
    guardRedirect(auth, Uri.parse(path));

void main() {
  group('guardRedirect (pure)', () {
    test('signed-out user is sent to phone sign-in', () {
      expect(
        redirect(const AuthSignedOut(), RoutePaths.tasks),
        RoutePaths.signInPhone,
      );
      expect(
        redirect(const AuthSignedOut(), RoutePaths.adminUsers),
        RoutePaths.signInPhone,
      );
      expect(redirect(const AuthSignedOut(), RoutePaths.signInEmail), isNull);
      expect(redirect(const AuthSignedOut(), RoutePaths.signInCode), isNull);
    });

    test('staff cannot open admin or team routes', () {
      const staff = AuthSignedIn(UserRole.staff);
      expect(redirect(staff, RoutePaths.adminUsers), RoutePaths.tasks);
      expect(redirect(staff, '/admin/users/u1'), RoutePaths.tasks);
      expect(redirect(staff, RoutePaths.adminVerify), RoutePaths.tasks);
      expect(redirect(staff, RoutePaths.teamTasks), RoutePaths.tasks);
      expect(redirect(staff, RoutePaths.reports), RoutePaths.tasks);
      expect(redirect(staff, RoutePaths.approvals), isNull);
      expect(redirect(staff, '/tasks/abc'), isNull);
    });

    test('manager can open team routes but not admin', () {
      const manager = AuthSignedIn(UserRole.manager);
      expect(redirect(manager, RoutePaths.teamTasks), isNull);
      expect(redirect(manager, RoutePaths.reports), isNull);
      expect(redirect(manager, RoutePaths.adminUsers), RoutePaths.tasks);
    });

    test('admin can open everything', () {
      const admin = AuthSignedIn(UserRole.admin);
      for (final path in [
        RoutePaths.adminUsers,
        '/admin/users/u1',
        RoutePaths.adminAudit,
        '/admin/templates/t1',
        RoutePaths.adminVerify,
        RoutePaths.teamTasks,
        RoutePaths.reports,
      ]) {
        expect(redirect(admin, path), isNull, reason: path);
      }
    });

    test('pre-sign-in states go to their own screen', () {
      expect(
        redirect(const AuthNotConfigured(), RoutePaths.tasks),
        RoutePaths.setupMissing,
      );
      expect(
        redirect(const AuthNotInvited(), RoutePaths.tasks),
        RoutePaths.notInvited,
      );
      expect(
        redirect(const AuthUnknown(), RoutePaths.tasks),
        RoutePaths.loading,
      );
      expect(
        redirect(const AuthNeedsLanguage(UserRole.staff), RoutePaths.tasks),
        RoutePaths.onboardingLanguage,
      );
      expect(
        redirect(const AuthNeedsConsent(UserRole.staff), RoutePaths.tasks),
        RoutePaths.onboardingConsent,
      );
      expect(
        redirect(
          const AuthNeedsNotificationPermission(UserRole.staff),
          RoutePaths.tasks,
        ),
        RoutePaths.onboardingNotifications,
      );
    });

    test('signed-in user leaving sign-in screens lands on tasks', () {
      expect(
        redirect(const AuthSignedIn(UserRole.staff), RoutePaths.signInPhone),
        RoutePaths.tasks,
      );
      expect(
        redirect(const AuthSignedIn(UserRole.staff), '/'),
        RoutePaths.tasks,
      );
    });
  });

  group('router in the running app', () {
    Future<GoRouter> pumpApp(
      WidgetTester tester,
      List<Override> overrides,
    ) async {
      await tester.pumpWidget(
        ProviderScope(overrides: overrides, child: const AtmsApp()),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AtmsApp)),
      );
      return container.read(routerProvider);
    }

    String location(GoRouter router) =>
        router.routerDelegate.currentConfiguration.uri.path;

    Future<void> go(WidgetTester tester, GoRouter router, String path) async {
      router.go(path);
      await tester.pumpAndSettle();
    }

    testWidgets('app without Firebase shows setup-missing', (tester) async {
      final router = await pumpApp(tester, const []);
      expect(location(router), RoutePaths.setupMissing);
      expect(
        find.text(l10nFor(testLocales.first).setupMissingTitle),
        findsOneWidget,
      );
    });

    testWidgets('signed-out user is redirected to sign-in', (tester) async {
      final router = await pumpApp(tester, [
        authControllerProvider.overrideWithBuild(
          (ref, n) => const AuthSignedOut(),
        ),
      ]);
      expect(location(router), RoutePaths.signInPhone);
      await go(tester, router, RoutePaths.adminUsers);
      expect(location(router), RoutePaths.signInPhone);
    });

    testWidgets('staff cannot open /admin/users', (tester) async {
      final router = await pumpApp(tester, [signedInAs(UserRole.staff)]);
      expect(location(router), RoutePaths.tasks);
      await go(tester, router, RoutePaths.adminUsers);
      expect(location(router), RoutePaths.tasks);
    });

    testWidgets('manager can open /team-tasks', (tester) async {
      final router = await pumpApp(tester, [signedInAs(UserRole.manager)]);
      await go(tester, router, RoutePaths.teamTasks);
      expect(location(router), RoutePaths.teamTasks);
      expect(
        find.text(l10nFor(testLocales.first).teamTasksTitle),
        findsWidgets,
      );
    });

    testWidgets('admin can open /admin/users and a user detail', (
      tester,
    ) async {
      final router = await pumpApp(tester, [signedInAs(UserRole.admin)]);
      await go(tester, router, RoutePaths.adminUsers);
      expect(location(router), RoutePaths.adminUsers);
      await go(tester, router, RoutePaths.adminUserDetailFor('u1'));
      expect(location(router), '/admin/users/u1');
    });

    testWidgets('every signed-in route renders for admin', (tester) async {
      final router = await pumpApp(tester, [signedInAs(UserRole.admin)]);
      for (final path in [
        RoutePaths.tasks,
        RoutePaths.approvals,
        RoutePaths.dashboard,
        RoutePaths.notifications,
        RoutePaths.more,
        RoutePaths.taskNew,
        RoutePaths.taskDetailFor('t1'),
        RoutePaths.taskEditFor('t1'),
        RoutePaths.workflowStart,
        RoutePaths.teamTasks,
        RoutePaths.reports,
        RoutePaths.adminDepartments,
        RoutePaths.adminUsers,
        RoutePaths.adminReportingTree,
        RoutePaths.adminTemplates,
        RoutePaths.adminTemplateDetailFor('tpl1'),
        RoutePaths.adminSettings,
        RoutePaths.adminAudit,
        RoutePaths.adminVerify,
      ]) {
        await go(tester, router, path);
        expect(location(router), path);
        expect(tester.takeException(), isNull, reason: path);
      }
    });

    testWidgets('unknown route shows not found', (tester) async {
      final router = await pumpApp(tester, [signedInAs(UserRole.staff)]);
      await go(tester, router, '/no-such-page');
      expect(
        find.text(l10nFor(testLocales.first).errorNotFound),
        findsOneWidget,
      );
    });

    testWidgets('bottom navigation switches tabs', (tester) async {
      await pumpApp(tester, [signedInAs(UserRole.staff)]);
      final l10n = l10nFor(testLocales.first);
      await tester.tap(find.text(l10n.navDashboard));
      await tester.pumpAndSettle();
      expect(find.text(l10n.dashDueToday), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      // Staff see no admin or team links.
      expect(find.text(l10n.adminUsersTitle), findsNothing);
      expect(find.text(l10n.teamTasksTitle), findsNothing);
    });
  });
}
