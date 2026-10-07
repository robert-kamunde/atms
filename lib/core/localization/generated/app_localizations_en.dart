// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get actionAddAttachment => 'Add attachment';

  @override
  String get actionAddDepartment => 'Add department';

  @override
  String get actionAddUser => 'Add person';

  @override
  String get actionAgreeAndContinue => 'Agree and continue';

  @override
  String get actionAllowNotifications => 'Allow notifications';

  @override
  String get actionBackToPhone => 'Enter phone number again';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionGoToTasks => 'Go to my tasks';

  @override
  String get actionHidePassword => 'Hide password';

  @override
  String get actionNewTask => 'New task';

  @override
  String get actionNewTemplate => 'New template';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get actionResendCode => 'Send the code again';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSendCode => 'Send code';

  @override
  String get actionShowPassword => 'Show password';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionUseAnotherNumber => 'Use another number';

  @override
  String get actionVerify => 'Verify';

  @override
  String get adminAuditTitle => 'Audit log';

  @override
  String get adminDepartmentsTitle => 'Departments';

  @override
  String get adminReportingTreeTitle => 'Reporting lines';

  @override
  String get adminSection => 'Administration';

  @override
  String get adminSettingsTitle => 'Organisation settings';

  @override
  String get adminTemplatesTitle => 'Workflow templates';

  @override
  String get adminUserDetailTitle => 'Person details';

  @override
  String get adminUsersTitle => 'People';

  @override
  String get adminVerifyHelp =>
      'For extra security, administrators must also enter the 6-digit code sent to their email.';

  @override
  String get adminVerifyTitle => 'Administrator check';

  @override
  String get appTitle => 'ATMS';

  @override
  String get approvalsEmptyMessage =>
      'When a step needs your approval, it will appear here.';

  @override
  String get approvalsEmptyTitle => 'Nothing is waiting for your approval';

  @override
  String get approvalsTitle => 'Approvals waiting';

  @override
  String assigneeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people chosen',
      one: '1 person chosen',
    );
    return '$_temp0';
  }

  @override
  String get assigneePickerEmpty => 'No people to choose from yet';

  @override
  String get attachmentsEmpty => 'No attachments yet';

  @override
  String get attachmentsTitle => 'Attachments';

  @override
  String get auditEmptyMessage =>
      'Every change to tasks, people and templates will be recorded here.';

  @override
  String get auditEmptyTitle => 'No audit entries yet';

  @override
  String codeEntryHelp(String phone) {
    return 'Enter the 6-digit code we sent by SMS to $phone.';
  }

  @override
  String get codeEntryNoPending =>
      'Your code request has expired. Please enter your phone number again.';

  @override
  String get codeEntryTitle => 'Enter code';

  @override
  String get codeLabel => '6-digit code';

  @override
  String get commentInputHint => 'Write a comment';

  @override
  String get commentsEmpty => 'No comments yet';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get consentCheckbox =>
      'I have read this notice and agree to my data being used as described.';

  @override
  String get consentIntro =>
      'Before you start, please read how ATMS uses your personal data. This notice follows the Tanzania Personal Data Protection Act, 2022.';

  @override
  String get consentRetentionBody =>
      'Task records and the audit log are kept for at least 3 years, or as your organisation decides, for accountability.';

  @override
  String get consentRetentionTitle => 'How long we keep it';

  @override
  String get consentRightsBody =>
      'You can ask your organisation\'s administrator to see or correct your personal data, or to stop using it where the law allows. You can also complain to the Personal Data Protection Commission.';

  @override
  String get consentRightsTitle => 'Your rights';

  @override
  String get consentSecurityBody =>
      'Your data is encrypted while it travels over the internet and while it is stored on the servers. Access is checked on the server for every request. A copy is also kept on your phone so you can work offline.';

  @override
  String get consentSecurityTitle => 'How it is protected';

  @override
  String get consentTitle => 'Privacy notice';

  @override
  String get consentWhatWeCollectBody =>
      'Your name, phone number, email (if given), department, role and supervisor, added by your organisation\'s administrator; the tasks, comments and files you create; and basic app usage and crash information.';

  @override
  String get consentWhatWeCollectTitle => 'What we collect';

  @override
  String get consentWhoSeesBody =>
      'People in your organisation see tasks according to their role and reporting line. Confidential tasks are visible only to their participants. Our service providers (Google Firebase for storage, and an SMS provider for text messages) process data on our behalf.';

  @override
  String get consentWhoSeesTitle => 'Who can see it';

  @override
  String get consentWhyBody =>
      'Only to run your organisation\'s tasks: to assign work, route approvals, send reminders and escalations, and produce reports. We do not sell your data or use it for advertising.';

  @override
  String get consentWhyTitle => 'Why we use it';

  @override
  String get dashActiveUsers => 'Active users';

  @override
  String get dashApprovalsWaiting => 'Approvals waiting for me';

  @override
  String get dashAvgDaysPerStep => 'Average days per workflow step';

  @override
  String get dashCompletionRate => 'My completion rate this month';

  @override
  String get dashDueThisWeek => 'Due this week';

  @override
  String get dashDueToday => 'Due today';

  @override
  String get dashMyOverdue => 'My overdue tasks';

  @override
  String get dashNoDataYet => 'No data yet';

  @override
  String get dashOrgByDepartment => 'Organisation totals by department';

  @override
  String get dashOverdueEscalated => 'Overdue and escalated tasks';

  @override
  String get dashSmsSpend => 'SMS spend this month';

  @override
  String get dashTeamByStatus => 'Team tasks by status';

  @override
  String get dashTemplatesInUse => 'Templates in use';

  @override
  String get dashWorkloadPerPerson => 'Workload per person';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get departmentsEmptyMessage =>
      'Add departments such as Finance, HR or ICT, and name a head for each.';

  @override
  String get departmentsEmptyTitle => 'No departments yet';

  @override
  String devPreviewAsRole(String role) {
    return 'Open as $role';
  }

  @override
  String get devPreviewMessage =>
      'Development builds only. Opens the screens with no data and no sign-in.';

  @override
  String get devPreviewTitle => 'Developer preview';

  @override
  String get dueOverdue => 'Overdue';

  @override
  String get dueThisWeek => 'This week';

  @override
  String get dueToday => 'Today';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailSignInHelp =>
      'Use this if you cannot receive SMS. Your administrator gives you the email and password.';

  @override
  String get emailSignInTitle => 'Sign in with email';

  @override
  String get errorConflict =>
      'Someone else changed this first. Please check the latest version.';

  @override
  String errorConflictAlreadyApproved(String name, String time) {
    return 'This step was already approved by $name at $time.';
  }

  @override
  String get errorInvalidCode =>
      'That code is not correct. Check the SMS and try again.';

  @override
  String get errorInvalidEmail => 'Enter a valid email address.';

  @override
  String get errorInvalidInput =>
      'Some information is not valid. Please check and try again.';

  @override
  String get errorInvalidPhone =>
      'Enter a valid Tanzanian mobile number, for example 0712 345 678.';

  @override
  String get errorNetwork =>
      'No internet connection. Your changes are kept on this phone; try again when you are online.';

  @override
  String get errorNotFound => 'This item was not found.';

  @override
  String get errorNotInvited => 'Ask your administrator to add you.';

  @override
  String get errorSessionExpired => 'For your security, please sign in again.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get errorUnauthenticated => 'Please sign in to continue.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorWrongCredentials => 'The email or password is not correct.';

  @override
  String get featureNotAvailableYet =>
      'This is not available yet. It is coming in a later version.';

  @override
  String get filterAssignee => 'Assignee';

  @override
  String get filterClear => 'Clear filter';

  @override
  String get filterDepartment => 'Department';

  @override
  String get filterDueDate => 'Due date';

  @override
  String get filterNoOptionsYet => 'No options available yet';

  @override
  String get filterPriority => 'Priority';

  @override
  String get filterStatus => 'Status';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSection => 'Language';

  @override
  String get languageSwahili => 'Kiswahili';

  @override
  String get loadingMessage => 'Getting your account ready...';

  @override
  String get managerSection => 'Team';

  @override
  String get moreTitle => 'More';

  @override
  String get myTasksTitle => 'My tasks';

  @override
  String get navApprovals => 'Approvals';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navMore => 'More';

  @override
  String get navNotifications => 'Alerts';

  @override
  String get navTasks => 'Tasks';

  @override
  String get notInvitedHelp =>
      'Only phone numbers added by your organisation can use ATMS.';

  @override
  String get notInvitedMessage => 'Ask your administrator to add you.';

  @override
  String get notInvitedTitle => 'Not registered';

  @override
  String get notificationsEmptyMessage =>
      'Reminders, approvals and escalations will appear here.';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get onboardingLanguageHelp =>
      'Choose the language for the app. You can change it later under More.';

  @override
  String get onboardingLanguageTitle => 'Choose language';

  @override
  String get onboardingNotificationsHelp =>
      'ATMS tells you when a task is assigned to you, when an approval is waiting and when a deadline is near. Allow notifications so you do not miss them.';

  @override
  String get onboardingNotificationsTitle => 'Notifications';

  @override
  String get optionalFieldHint => 'Optional';

  @override
  String get passwordLabel => 'Password';

  @override
  String get phoneNumberHint => '0712 345 678';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneSignInHeading => 'Welcome to ATMS';

  @override
  String get phoneSignInHelp =>
      'Enter the phone number your organisation registered. We will send you a 6-digit code by SMS.';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get profileSection => 'Profile';

  @override
  String profileSignedInAs(String role) {
    return 'Signed in as $role';
  }

  @override
  String get reportingTreeEmptyMessage =>
      'Set each person\'s supervisor to build the reporting lines used for escalation.';

  @override
  String get reportingTreeEmptyTitle => 'No reporting lines yet';

  @override
  String get reportsEmptyMessage =>
      'Weekly summaries are made every Monday and monthly summaries on the 1st.';

  @override
  String get reportsEmptyTitle => 'No reports yet';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get requiredFieldHint => 'Required';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleStaff => 'Staff';

  @override
  String get settingEscalationDelay => 'Escalation delay';

  @override
  String get settingReminderTimes => 'Reminder times';

  @override
  String get settingSmsCap => 'Monthly SMS limit';

  @override
  String get settingTimeZone => 'Time zone';

  @override
  String get settingWorkingDays => 'Working days';

  @override
  String get settingWorkingHours => 'Working hours';

  @override
  String get setupMissingMessage =>
      'This copy of the app was built without its server settings, so it cannot connect. Please install the version provided by your organisation.';

  @override
  String get setupMissingTitle => 'App not configured';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get startWorkflowEmptyMessage =>
      'Your administrator has not published any workflow templates yet.';

  @override
  String get startWorkflowTitle => 'Start a workflow';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusDone => 'Done';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusTodo => 'To do';

  @override
  String get stepTrackerEmpty => 'This task has no workflow steps';

  @override
  String get stepTrackerTitle => 'Steps';

  @override
  String get syncAllSaved => 'All changes saved';

  @override
  String get syncOffline => 'Offline: changes saved on this phone';

  @override
  String get syncSyncing => 'Syncing...';

  @override
  String get taskCreateTitle => 'New task';

  @override
  String get taskDetailTitle => 'Task';

  @override
  String get taskEditTitle => 'Edit task';

  @override
  String get taskFieldAssignee => 'Assigned to';

  @override
  String get taskFieldAssigneeHint => 'Choose people';

  @override
  String get taskFieldDeadline => 'Deadline';

  @override
  String get taskFieldDeadlineHint => 'Choose date and time';

  @override
  String get taskFieldDescription => 'Description';

  @override
  String get taskFieldPriority => 'Priority';

  @override
  String get taskFieldTitle => 'Title';

  @override
  String get taskNotLoadedYet => 'Task details will appear here.';

  @override
  String get taskSummaryTitle => 'Details';

  @override
  String get tasksEmptyFilteredTitle => 'No tasks match these filters';

  @override
  String get tasksEmptyMessage =>
      'Tasks assigned to you will appear here, sorted by deadline.';

  @override
  String get tasksEmptyTitle => 'You have no tasks';

  @override
  String get teamTasksEmptyTitle => 'Your team has no tasks';

  @override
  String get teamTasksTitle => 'Team tasks';

  @override
  String get templateDetailTitle => 'Workflow template';

  @override
  String get templateStepsEmpty => 'No steps yet';

  @override
  String get templateStepsTitle => 'Steps';

  @override
  String get templatesEmptyMessage =>
      'Create a template, such as a purchase request, to route tasks automatically from one person to the next.';

  @override
  String get templatesEmptyTitle => 'No workflow templates yet';

  @override
  String get useEmailInstead => 'No SMS? Sign in with email';

  @override
  String get userDetailsSection => 'Details';

  @override
  String get userFieldConfidentialAccess => 'Confidential access';

  @override
  String get userFieldDepartment => 'Department';

  @override
  String get userFieldName => 'Name';

  @override
  String get userFieldRole => 'Role';

  @override
  String get userFieldSupervisor => 'Supervisor';

  @override
  String get usersEmptyMessage =>
      'Add people with their phone number, department, role and supervisor.';

  @override
  String get usersEmptyTitle => 'No people yet';

  @override
  String get validationAssigneeRequired => 'Choose at least one person';

  @override
  String get validationCodeSixDigits => 'Enter the 6-digit code';

  @override
  String get validationDeadlineInPast => 'The deadline must be in the future';

  @override
  String get validationDeadlineRequired => 'Choose a deadline';

  @override
  String get validationEmailRequired => 'Enter your email';

  @override
  String get validationPasswordRequired => 'Enter your password';

  @override
  String get validationPhoneRequired => 'Enter your phone number';

  @override
  String get validationPriorityRequired => 'Choose a priority';

  @override
  String get validationTitleRequired => 'Enter a title';

  @override
  String get valueNotLoaded => 'Not loaded yet';
}
