/// Every route path in ATMS. Screens navigate with these constants or the
/// helper functions below, never with string literals.
abstract final class RoutePaths {
  // Start-up and sign-in
  static const String loading = '/loading';
  static const String setupMissing = '/setup-missing';
  static const String signInPhone = '/sign-in/phone';
  static const String signInCode = '/sign-in/code';
  static const String signInEmail = '/sign-in/email';
  static const String notInvited = '/not-invited';
  static const String onboardingLanguage = '/onboarding/language';
  static const String onboardingConsent = '/onboarding/consent';
  static const String onboardingNotifications = '/onboarding/notifications';
  static const String adminVerify = '/admin-verify';

  // Bottom navigation tabs
  static const String tasks = '/tasks';
  static const String approvals = '/approvals';
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';
  static const String more = '/more';

  // Tasks and workflows
  static const String taskNew = '/tasks/new';
  static const String taskDetail = '/tasks/:id';
  static const String taskEdit = '/tasks/:id/edit';
  static const String workflowStart = '/workflows/start';

  // Managers and admins
  static const String teamTasks = '/team-tasks';
  static const String reports = '/reports';

  // Admin only
  static const String adminPrefix = '/admin';
  static const String adminDepartments = '/admin/departments';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/users/:id';
  static const String adminReportingTree = '/admin/reporting-tree';
  static const String adminTemplates = '/admin/templates';
  static const String adminTemplateDetail = '/admin/templates/:id';
  static const String adminSettings = '/admin/settings';
  static const String adminAudit = '/admin/audit';

  static String taskDetailFor(String id) => '/tasks/${Uri.encodeComponent(id)}';
  static String taskEditFor(String id) =>
      '/tasks/${Uri.encodeComponent(id)}/edit';
  static String adminUserDetailFor(String id) =>
      '/admin/users/${Uri.encodeComponent(id)}';
  static String adminTemplateDetailFor(String id) =>
      '/admin/templates/${Uri.encodeComponent(id)}';
}

/// Route names (for `context.goNamed`) — kept equal to a readable id.
abstract final class RouteNames {
  static const String loading = 'loading';
  static const String setupMissing = 'setupMissing';
  static const String signInPhone = 'signInPhone';
  static const String signInCode = 'signInCode';
  static const String signInEmail = 'signInEmail';
  static const String notInvited = 'notInvited';
  static const String onboardingLanguage = 'onboardingLanguage';
  static const String onboardingConsent = 'onboardingConsent';
  static const String onboardingNotifications = 'onboardingNotifications';
  static const String adminVerify = 'adminVerify';
  static const String tasks = 'tasks';
  static const String approvals = 'approvals';
  static const String dashboard = 'dashboard';
  static const String notifications = 'notifications';
  static const String more = 'more';
  static const String taskNew = 'taskNew';
  static const String taskDetail = 'taskDetail';
  static const String taskEdit = 'taskEdit';
  static const String workflowStart = 'workflowStart';
  static const String teamTasks = 'teamTasks';
  static const String reports = 'reports';
  static const String adminDepartments = 'adminDepartments';
  static const String adminUsers = 'adminUsers';
  static const String adminUserDetail = 'adminUserDetail';
  static const String adminReportingTree = 'adminReportingTree';
  static const String adminTemplates = 'adminTemplates';
  static const String adminTemplateDetail = 'adminTemplateDetail';
  static const String adminSettings = 'adminSettings';
  static const String adminAudit = 'adminAudit';
}
