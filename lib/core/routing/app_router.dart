// NAVIGATION_MAP
// ---------------------------------------------------------------------------
// Route                      | Who can open it                 | Sprint
// ---------------------------|---------------------------------|-----------
// /loading                   | anyone while auth state unknown | 0 (UI), 1
// /setup-missing             | app built without Firebase opts | 0
// /sign-in/phone             | signed out                      | 0 UI, 1
// /sign-in/code              | signed out                      | 0 UI, 1
// /sign-in/email             | signed out (fallback)           | 0 UI, 1
// /not-invited               | signed in, no user document     | 0 UI, 1
// /onboarding/language       | first sign-in                   | 0 UI, 1
// /onboarding/consent        | first sign-in (PDPA 2022)       | 0 UI, 1
// /onboarding/notifications  | first sign-in                   | 0 UI, 4
// /admin-verify              | admin (2nd factor, UI only)     | 0 UI, 1*
// --- bottom navigation shell (all signed-in roles) ---
// /tasks                     | all roles (my tasks)            | 0 UI, 2
// /approvals                 | all roles (steps waiting on me) | 0 UI, 3
// /dashboard                 | all roles (role-specific cards) | 0 UI, 6
// /notifications             | all roles                       | 0 UI, 4
// /more                      | all roles                       | 0
// /team-tasks                | manager, admin                  | 0 UI, 2
// /reports                   | manager, admin                  | 0 UI, 6
// /admin/departments         | admin                           | 0 UI, 1
// /admin/users               | admin                           | 0 UI, 1
// /admin/users/:id           | admin                           | 0 UI, 1
// /admin/reporting-tree      | admin                           | 0 UI, 1
// /admin/templates           | admin                           | 0 UI, 3
// /admin/templates/:id       | admin                           | 0 UI, 3
// /admin/settings            | admin                           | 0 UI, 1
// /admin/audit               | admin                           | 0 UI, 2
// --- full screen (above the shell) ---
// /tasks/new                 | all roles (staff: for self)     | 0 UI, 2
// /tasks/:id                 | viewers of the task (rules)     | 0 UI, 2/3/5
// /tasks/:id/edit            | creator / manager (rules)       | 0 UI, 2
// /workflows/start           | all roles if template allows    | 0 UI, 3
// ---------------------------------------------------------------------------
// * Admin MFA mechanism is an open decision; only the screen exists.
// Guard rules: lib/core/routing/route_guard.dart. The guard only hides
// screens; Security Rules and Cloud Functions enforce access (spec 6).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audit/presentation/audit_screen.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/admin_verify_screen.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/code_entry_screen.dart';
import '../../features/auth/presentation/email_sign_in_screen.dart';
import '../../features/auth/presentation/loading_screen.dart';
import '../../features/auth/presentation/not_invited_screen.dart';
import '../../features/auth/presentation/onboarding/onboarding_consent_screen.dart';
import '../../features/auth/presentation/onboarding/onboarding_language_screen.dart';
import '../../features/auth/presentation/onboarding/onboarding_notifications_screen.dart';
import '../../features/auth/presentation/phone_sign_in_screen.dart';
import '../../features/auth/presentation/setup_missing_screen.dart';
import '../../features/dashboards/presentation/dashboard_screen.dart';
import '../../features/departments/presentation/departments_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/organisation/presentation/org_settings_screen.dart';
import '../../features/organisation/presentation/reporting_tree_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../../features/tasks/presentation/task_form_screen.dart';
import '../../features/tasks/presentation/task_list_screen.dart';
import '../../features/users/presentation/admin_user_detail_screen.dart';
import '../../features/users/presentation/admin_users_screen.dart';
import '../../features/users/presentation/more_screen.dart';
import '../../features/workflows/presentation/approvals_screen.dart';
import '../../features/workflows/presentation/start_workflow_screen.dart';
import '../../features/workflows/presentation/template_detail_screen.dart';
import '../../features/workflows/presentation/template_list_screen.dart';
import 'not_found_screen.dart';
import 'route_guard.dart';
import 'route_names.dart';
import 'scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Builds pages with Flutter's own `MaterialPage`. go_router 18 detects
/// `MaterialApp` from the separate `material_ui` package, so without this it
/// would fall back to pages without transitions.
Page<void> _page(GoRouterState state, Widget child) =>
    MaterialPage<void>(key: state.pageKey, name: state.name, child: child);

GoRoute _route(
  String path,
  String name,
  Widget Function(GoRouterState state) build, {
  List<RouteBase> routes = const [],
  GlobalKey<NavigatorState>? parentNavigatorKey,
}) => GoRoute(
  path: path,
  name: name,
  parentNavigatorKey: parentNavigatorKey,
  pageBuilder: (context, state) => _page(state, build(state)),
  routes: routes,
);

String _param(GoRouterState state, String key) => state.pathParameters[key]!;

/// Creates the app router. [readAuth] returns the current auth state and
/// [refresh] notifies when it changes.
GoRouter createRouter({
  required AuthState Function() readAuth,
  required Listenable refresh,
  String initialLocation = RoutePaths.tasks,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) => guardRedirect(readAuth(), state.uri),
    errorPageBuilder: (context, state) => _page(state, const NotFoundScreen()),
    routes: [
      _route(
        RoutePaths.loading,
        RouteNames.loading,
        (_) => const LoadingScreen(),
      ),
      _route(
        RoutePaths.setupMissing,
        RouteNames.setupMissing,
        (_) => const SetupMissingScreen(),
      ),
      _route(
        RoutePaths.signInPhone,
        RouteNames.signInPhone,
        (_) => const PhoneSignInScreen(),
      ),
      _route(
        RoutePaths.signInCode,
        RouteNames.signInCode,
        (_) => const CodeEntryScreen(),
      ),
      _route(
        RoutePaths.signInEmail,
        RouteNames.signInEmail,
        (_) => const EmailSignInScreen(),
      ),
      _route(
        RoutePaths.notInvited,
        RouteNames.notInvited,
        (_) => const NotInvitedScreen(),
      ),
      _route(
        RoutePaths.onboardingLanguage,
        RouteNames.onboardingLanguage,
        (_) => const OnboardingLanguageScreen(),
      ),
      _route(
        RoutePaths.onboardingConsent,
        RouteNames.onboardingConsent,
        (_) => const OnboardingConsentScreen(),
      ),
      _route(
        RoutePaths.onboardingNotifications,
        RouteNames.onboardingNotifications,
        (_) => const OnboardingNotificationsScreen(),
      ),
      _route(
        RoutePaths.adminVerify,
        RouteNames.adminVerify,
        (_) => const AdminVerifyScreen(),
      ),
      _route(
        RoutePaths.workflowStart,
        RouteNames.workflowStart,
        (_) => const StartWorkflowScreen(),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) =>
            _page(state, ScaffoldWithNavBar(navigationShell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [
              _route(
                RoutePaths.tasks,
                RouteNames.tasks,
                (_) => const TaskListScreen(),
                routes: [
                  _route(
                    'new',
                    RouteNames.taskNew,
                    (_) => const TaskFormScreen(),
                    parentNavigatorKey: _rootNavigatorKey,
                  ),
                  _route(
                    ':id',
                    RouteNames.taskDetail,
                    (s) => TaskDetailScreen(taskId: _param(s, 'id')),
                    parentNavigatorKey: _rootNavigatorKey,
                    routes: [
                      _route(
                        'edit',
                        RouteNames.taskEdit,
                        (s) => TaskFormScreen(taskId: _param(s, 'id')),
                        parentNavigatorKey: _rootNavigatorKey,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _route(
                RoutePaths.approvals,
                RouteNames.approvals,
                (_) => const ApprovalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _route(
                RoutePaths.dashboard,
                RouteNames.dashboard,
                (_) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _route(
                RoutePaths.notifications,
                RouteNames.notifications,
                (_) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              _route(
                RoutePaths.more,
                RouteNames.more,
                (_) => const MoreScreen(),
              ),
              _route(
                RoutePaths.teamTasks,
                RouteNames.teamTasks,
                (_) => const TaskListScreen(team: true),
              ),
              _route(
                RoutePaths.reports,
                RouteNames.reports,
                (_) => const ReportsScreen(),
              ),
              _route(
                RoutePaths.adminDepartments,
                RouteNames.adminDepartments,
                (_) => const DepartmentsScreen(),
              ),
              _route(
                RoutePaths.adminUsers,
                RouteNames.adminUsers,
                (_) => const AdminUsersScreen(),
                routes: [
                  _route(
                    ':id',
                    RouteNames.adminUserDetail,
                    (s) => AdminUserDetailScreen(userId: _param(s, 'id')),
                  ),
                ],
              ),
              _route(
                RoutePaths.adminReportingTree,
                RouteNames.adminReportingTree,
                (_) => const ReportingTreeScreen(),
              ),
              _route(
                RoutePaths.adminTemplates,
                RouteNames.adminTemplates,
                (_) => const TemplateListScreen(),
                routes: [
                  _route(
                    ':id',
                    RouteNames.adminTemplateDetail,
                    (s) => TemplateDetailScreen(templateId: _param(s, 'id')),
                  ),
                ],
              ),
              _route(
                RoutePaths.adminSettings,
                RouteNames.adminSettings,
                (_) => const OrgSettingsScreen(),
              ),
              _route(
                RoutePaths.adminAudit,
                RouteNames.adminAudit,
                (_) => const AuditScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bridges the Riverpod auth state to go_router's `refreshListenable`.
class _AuthRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// The app's router, rebuilt never: auth changes trigger a redirect check.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.listen<AuthState>(authControllerProvider, (_, _) => refresh.notify());
  final router = createRouter(
    readAuth: () => ref.read(authControllerProvider),
    refresh: refresh,
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
