// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountInactiveHelp =>
      'If you think this is a mistake, contact your administrator.';

  @override
  String get accountInactiveTitle => 'Account not active';

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
  String get actionCancel => 'Cancel';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionClose => 'Close';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionContinueAnyway => 'Yes, continue';

  @override
  String get actionDeactivate => 'Deactivate';

  @override
  String get actionDeactivateUser => 'Deactivate person';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionForgotPassword => 'Forgot password?';

  @override
  String get actionGoToTasks => 'Go to my tasks';

  @override
  String get actionHidePassword => 'Hide password';

  @override
  String get actionHideReports => 'Hide direct reports';

  @override
  String get actionLoadMore => 'Load more';

  @override
  String get actionMoreOptions => 'More options';

  @override
  String get actionNewTask => 'New task';

  @override
  String get actionNewTemplate => 'New template';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionResendCode => 'Send the code again';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSendAdminCode => 'Email me a code';

  @override
  String get actionSendCode => 'Send code';

  @override
  String get actionSendResetLink => 'Send link';

  @override
  String get actionShowPassword => 'Show password';

  @override
  String get actionShowReports => 'Show direct reports';

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
  String adminCodeSentTo(String email, String time) {
    return 'We sent a 6-digit code to $email. It works until $time.';
  }

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
  String adminVerifiedUntil(String time) {
    return 'You are verified until $time.';
  }

  @override
  String get adminVerifyHelp =>
      'For extra security, administrators must also enter the 6-digit code sent to their email.';

  @override
  String get adminVerifySuccess => 'Administrator check complete.';

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
  String get codeResent => 'We sent a new code.';

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
  String get dayFri => 'Fri';

  @override
  String get dayMon => 'Mon';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String deactivateDepartmentMessage(String name) {
    return '$name will no longer be offered when adding people. Existing tasks keep this department.';
  }

  @override
  String get deactivateDepartmentTitle => 'Deactivate department?';

  @override
  String deactivateUserMessage(String name) {
    return '$name will be signed out within an hour and can no longer sign in. Their open tasks will be flagged for reassignment.';
  }

  @override
  String get deactivateUserTitle => 'Deactivate this person?';

  @override
  String get departmentCreateTitle => 'New department';

  @override
  String get departmentEditTitle => 'Edit department';

  @override
  String get departmentFieldHead => 'Head of department';

  @override
  String get departmentFieldName => 'Department name';

  @override
  String departmentHead(String name) {
    return 'Head: $name';
  }

  @override
  String get departmentNoHead => 'No head named';

  @override
  String get departmentsEmptyMessage =>
      'Add departments such as Finance, HR or ICT, and name a head for each.';

  @override
  String get departmentsEmptyTitle => 'No departments yet';

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
  String get errorAccountDeactivated =>
      'Your account is not active. Ask your administrator.';

  @override
  String get errorAdminCodeExpired =>
      'That code has expired. Ask for a new code.';

  @override
  String get errorAdminCodeTooManyAttempts =>
      'Too many wrong codes. Ask for a new code.';

  @override
  String get errorAdminCodeWrong =>
      'That code is not correct. Check your email and try again.';

  @override
  String errorAdminCodeWrongAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'That code is not correct. $count attempts left.',
      one: 'That code is not correct. 1 attempt left.',
      zero: 'That code is not correct. Ask for a new code.',
    );
    return '$_temp0';
  }

  @override
  String get errorAdminEmailMissing =>
      'Your account has no email for the administrator code. Ask another administrator to add one.';

  @override
  String get errorAdminVerificationRequired =>
      'Please confirm your administrator code again.';

  @override
  String get errorConflict =>
      'Someone else changed this first. Please check the latest version.';

  @override
  String errorConflictAlreadyApproved(String name, String time) {
    return 'This step was already approved by $name at $time.';
  }

  @override
  String get errorConnectionRequired =>
      'This needs an internet connection. Connect and try again.';

  @override
  String get errorDepartmentInvalid =>
      'The chosen department does not exist or is not active. Choose another department.';

  @override
  String get errorEmailCannotBeRemoved =>
      'An email cannot be removed once it is set. Enter a new email instead.';

  @override
  String get errorEmailInUse => 'This email is already used by another person.';

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
  String get errorLastAdmin =>
      'This is the last active administrator. Add another administrator first.';

  @override
  String get errorNetwork =>
      'No internet connection. Your changes are kept on this phone; try again when you are online.';

  @override
  String get errorNotFound => 'This item was not found.';

  @override
  String get errorNotInvited => 'Ask your administrator to add you.';

  @override
  String get errorPermissionDenied => 'You do not have permission to do this.';

  @override
  String get errorPhoneInUse =>
      'This phone number is already used by another person.';

  @override
  String get errorProviderUnavailable =>
      'The message service is not available right now. Please try again later.';

  @override
  String get errorRateLimited =>
      'Too many codes requested. Please wait and try again later.';

  @override
  String get errorReportingLoop =>
      'This supervisor would create a loop in the reporting lines. Choose someone else.';

  @override
  String get errorSelfDeactivation => 'You cannot deactivate your own account.';

  @override
  String get errorSelfDemotion =>
      'You cannot remove your own administrator role.';

  @override
  String get errorSessionExpired => 'For your security, please sign in again.';

  @override
  String get errorSmsCapReached => 'The monthly SMS limit has been reached.';

  @override
  String get errorSupervisorInvalid =>
      'The chosen supervisor is not an active person in this organisation. Choose someone else.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get errorTopPersonRequiresSupervisor =>
      'This change is not possible for the top person of the organisation. Check the reporting lines and try again.';

  @override
  String get errorTreeBusy =>
      'The reporting lines are being updated. Please try again in a moment.';

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
  String get forgotPasswordHelp =>
      'Enter your email. If it belongs to an ATMS account, we will send a link to set a new password. New accounts use this to set their first password.';

  @override
  String get forgotPasswordTitle => 'Set a new password';

  @override
  String get labelInactive => 'Inactive';

  @override
  String get labelSupervisorInactive => 'Supervisor inactive';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSection => 'Language';

  @override
  String get languageSwahili => 'Kiswahili';

  @override
  String get loadingMessage => 'Getting your account ready...';

  @override
  String get loadingWaitingForConnection =>
      'Waiting for an internet connection to load your account...';

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
  String get needsConnectionNote => 'This needs an internet connection.';

  @override
  String get noChangesMessage => 'No changes to save';

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
  String offlineChangeRefused(String reason) {
    return 'A change saved offline was not accepted: $reason';
  }

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
  String get passwordResetSent =>
      'If this email has an account, a link to set a new password has been sent. Check your inbox.';

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
  String get reportingTreeHelp =>
      'Tap a person to show who reports to them. Press and hold to open their details.';

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
  String resendCodeIn(int seconds) {
    return 'Send the code again in $seconds s';
  }

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleStaff => 'Staff';

  @override
  String get savedMessage => 'Saved';

  @override
  String get savedOnPhoneMessage =>
      'Saved on this phone. It will be sent when you are back online.';

  @override
  String get searchByName => 'Search by name';

  @override
  String get searchLoadedOnlyNote =>
      'Search covers the people loaded so far. Load more to search further.';

  @override
  String sessionExpiredMessage(int staffDays, int adminDays) {
    return 'For your security you were signed out. Sessions last $staffDays days ($adminDays days for administrators). Please sign in again.';
  }

  @override
  String get settingEscalationDelay => 'Escalation delay';

  @override
  String get settingEscalationDelayHelp =>
      'Hours after the deadline before the supervisor is alerted';

  @override
  String get settingEscalationLevels => 'Escalation levels';

  @override
  String get settingEscalationLevelsHelp =>
      'How many levels up the reporting line an overdue task climbs';

  @override
  String get settingReminderHoursHelp =>
      'Hours before the deadline, separated by commas, e.g. 24, 1';

  @override
  String get settingReminderTimes => 'Reminder times';

  @override
  String get settingRemindersSection => 'Reminders and escalation';

  @override
  String get settingSmsCap => 'Monthly SMS limit';

  @override
  String get settingSmsCapHelp =>
      'Maximum SMS spending per month, in Tanzanian shillings (TZS).';

  @override
  String get settingSmsEnabled => 'Send SMS';

  @override
  String get settingSmsEnabledHelp =>
      'SMS alerts, for example when a push notification is not opened.';

  @override
  String get settingSmsSection => 'SMS';

  @override
  String get settingTimeZone => 'Time zone';

  @override
  String get settingWorkEnd => 'Work ends';

  @override
  String get settingWorkStart => 'Work starts';

  @override
  String get settingWorkingDays => 'Working days';

  @override
  String get settingWorkingHours => 'Working hours';

  @override
  String get settingWorkingHoursEnabled => 'Count working hours only';

  @override
  String get settingWorkingHoursEnabledHelp =>
      'When on, deadlines and escalation count only working hours on working days.';

  @override
  String get setupMissingMessage =>
      'This copy of the app was built without its server settings, so it cannot connect. Please install the version provided by your organisation.';

  @override
  String get setupMissingTitle => 'App not configured';

  @override
  String get signInNeedsConnection =>
      'Signing in needs an internet connection.';

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
  String timeZoneEastAfrica(String zone) {
    return 'East Africa Time ($zone)';
  }

  @override
  String topPersonWarningMessage(String name) {
    return 'A person without a supervisor becomes the top of the organisation. The current top person will then report to $name. Continue?';
  }

  @override
  String get topPersonWarningTitle =>
      'Make this person the top of the organisation?';

  @override
  String get useEmailInstead => 'No SMS? Sign in with email';

  @override
  String get userAccessSection => 'Role and reporting';

  @override
  String get userAddedMessage => 'Person added.';

  @override
  String get userConfidentialHelp =>
      'Can see confidential tasks of these departments.';

  @override
  String get userContactHelp =>
      'A phone number or an email is needed to sign in.';

  @override
  String get userCreateTitle => 'Add person';

  @override
  String userDeactivatedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Person deactivated. $count open tasks were flagged for reassignment.',
      one: 'Person deactivated. 1 open task was flagged for reassignment.',
      zero: 'Person deactivated. They had no open tasks.',
    );
    return '$_temp0';
  }

  @override
  String get userDetailsSection => 'Details';

  @override
  String get userFieldConfidentialAccess => 'Confidential access';

  @override
  String get userFieldDepartment => 'Department';

  @override
  String get userFieldJobRole => 'Job title';

  @override
  String get userFieldName => 'Name';

  @override
  String get userFieldRole => 'Role';

  @override
  String get userFieldSupervisor => 'Supervisor';

  @override
  String get userInviteNote =>
      'Saving needs an internet connection. People with a phone number get an SMS invitation.';

  @override
  String get userJobRoleHelp =>
      'Used by workflow steps assigned to a job title, e.g. Finance Officer.';

  @override
  String get userLanguageLabel => 'Language for SMS and the app';

  @override
  String get userNoSupervisor => 'None (top of organisation)';

  @override
  String get userTopOfOrganisation => 'Top of organisation';

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
  String get validationDepartmentRequired => 'Choose a department';

  @override
  String get validationEmailRequired => 'Enter your email';

  @override
  String get validationNameRequired => 'Enter a name';

  @override
  String get validationPasswordRequired => 'Enter your password';

  @override
  String get validationPhoneOrEmail => 'Enter a phone number or an email';

  @override
  String get validationPhoneRequired => 'Enter your phone number';

  @override
  String get validationPriorityRequired => 'Choose a priority';

  @override
  String validationReminderHours(int max) {
    return 'Enter whole numbers of hours from 1 to $max, separated by commas';
  }

  @override
  String get validationTitleRequired => 'Enter a title';

  @override
  String validationWholeNumberRange(int min, int max) {
    return 'Enter a whole number from $min to $max';
  }

  @override
  String get validationWorkingDaysRequired => 'Choose at least one working day';

  @override
  String get valueNotChosen => 'Not chosen';

  @override
  String get valueNotLoaded => 'Not loaded yet';
}
