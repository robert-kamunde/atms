import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  /// Help text on the screen for deactivated users.
  ///
  /// In en, this message translates to:
  /// **'If you think this is a mistake, contact your administrator.'**
  String get accountInactiveHelp;

  /// Title of the screen for deactivated users.
  ///
  /// In en, this message translates to:
  /// **'Account not active'**
  String get accountInactiveTitle;

  /// Button: add a file to a task.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get actionAddAttachment;

  /// Button: create a department.
  ///
  /// In en, this message translates to:
  /// **'Add department'**
  String get actionAddDepartment;

  /// Button: add a user.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get actionAddUser;

  /// Consent screen button.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get actionAgreeAndContinue;

  /// Onboarding button.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get actionAllowNotifications;

  /// Button back to the phone entry screen.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number again'**
  String get actionBackToPhone;

  /// Cancel button in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Tooltip: clear the chosen value.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// Close button / tooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Generic continue button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Confirm button.
  ///
  /// In en, this message translates to:
  /// **'Yes, continue'**
  String get actionContinueAnyway;

  /// Button: deactivate. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get actionDeactivate;

  /// Button in the user editor. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Deactivate person'**
  String get actionDeactivateUser;

  /// Edit button / tooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Button on the email sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get actionForgotPassword;

  /// Button on not-found screen.
  ///
  /// In en, this message translates to:
  /// **'Go to my tasks'**
  String get actionGoToTasks;

  /// Tooltip on password field.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get actionHidePassword;

  /// Tooltip in the reporting tree. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Hide direct reports'**
  String get actionHideReports;

  /// Button: load the next page of a list.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get actionLoadMore;

  /// Tooltip of a menu button.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get actionMoreOptions;

  /// Button to create a task.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get actionNewTask;

  /// Button to create a workflow template. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get actionNewTemplate;

  /// Skip button.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get actionNotNow;

  /// Tooltip: remove an item from a list.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// Resend SMS/email code.
  ///
  /// In en, this message translates to:
  /// **'Send the code again'**
  String get actionResendCode;

  /// Retry button after a load error.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// Save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Button: send the admin second-factor code by email.
  ///
  /// In en, this message translates to:
  /// **'Email me a code'**
  String get actionSendAdminCode;

  /// Phone sign-in: send SMS code.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get actionSendCode;

  /// Button: send password reset email.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get actionSendResetLink;

  /// Tooltip on password field.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get actionShowPassword;

  /// Tooltip in the reporting tree. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Show direct reports'**
  String get actionShowReports;

  /// Sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get actionSignIn;

  /// Sign-out button.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// Not-invited screen: go back to sign-in.
  ///
  /// In en, this message translates to:
  /// **'Use another number'**
  String get actionUseAnotherNumber;

  /// Verify code button.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get actionVerify;

  /// Admin: audit log screen title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get adminAuditTitle;

  /// After sending the admin code. email is masked, e.g. i***@org.tz.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}. It works until {time}.'**
  String adminCodeSentTo(String email, String time);

  /// Admin: departments screen title.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get adminDepartmentsTitle;

  /// Admin: reporting tree (who reports to whom). SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Reporting lines'**
  String get adminReportingTreeTitle;

  /// More screen: admin section header.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get adminSection;

  /// Admin: settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Organisation settings'**
  String get adminSettingsTitle;

  /// Admin: workflow templates title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Workflow templates'**
  String get adminTemplatesTitle;

  /// Admin: user editor title.
  ///
  /// In en, this message translates to:
  /// **'Person details'**
  String get adminUserDetailTitle;

  /// Admin: users list title.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get adminUsersTitle;

  /// Shown when the admin second factor is already valid.
  ///
  /// In en, this message translates to:
  /// **'You are verified until {time}.'**
  String adminVerifiedUntil(String time);

  /// Admin second factor explanation.
  ///
  /// In en, this message translates to:
  /// **'For extra security, administrators must also enter the 6-digit code sent to their email.'**
  String get adminVerifyHelp;

  /// Snackbar after the admin second factor succeeds. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Administrator check complete.'**
  String get adminVerifySuccess;

  /// Admin second-factor screen title.
  ///
  /// In en, this message translates to:
  /// **'Administrator check'**
  String get adminVerifyTitle;

  /// App name shown in the task switcher.
  ///
  /// In en, this message translates to:
  /// **'ATMS'**
  String get appTitle;

  /// Approvals empty state message.
  ///
  /// In en, this message translates to:
  /// **'When a step needs your approval, it will appear here.'**
  String get approvalsEmptyMessage;

  /// Approvals empty state title.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting for your approval'**
  String get approvalsEmptyTitle;

  /// Approvals screen title.
  ///
  /// In en, this message translates to:
  /// **'Approvals waiting'**
  String get approvalsTitle;

  /// Number of assignees picked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person chosen} other{{count} people chosen}}'**
  String assigneeCount(int count);

  /// Assignee picker empty state.
  ///
  /// In en, this message translates to:
  /// **'No people to choose from yet'**
  String get assigneePickerEmpty;

  /// Attachments empty state.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet'**
  String get attachmentsEmpty;

  /// Task detail: attachments section.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsTitle;

  /// Audit empty message. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Every change to tasks, people and templates will be recorded here.'**
  String get auditEmptyMessage;

  /// Audit empty title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'No audit entries yet'**
  String get auditEmptyTitle;

  /// Code entry instructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent by SMS to {phone}.'**
  String codeEntryHelp(String phone);

  /// Shown when there is no pending SMS verification.
  ///
  /// In en, this message translates to:
  /// **'Your code request has expired. Please enter your phone number again.'**
  String get codeEntryNoPending;

  /// Code entry screen title.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get codeEntryTitle;

  /// Code field label.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get codeLabel;

  /// Snackbar after resending the SMS code.
  ///
  /// In en, this message translates to:
  /// **'We sent a new code.'**
  String get codeResent;

  /// Comment field hint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get commentInputHint;

  /// Comments empty state.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get commentsEmpty;

  /// Task detail: comments section.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// Consent checkbox label.
  ///
  /// In en, this message translates to:
  /// **'I have read this notice and agree to my data being used as described.'**
  String get consentCheckbox;

  /// Consent intro. Legal text: client must review. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Before you start, please read how ATMS uses your personal data. This notice follows the Tanzania Personal Data Protection Act, 2022.'**
  String get consentIntro;

  /// Consent: retention. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Task records and the audit log are kept for at least 3 years, or as your organisation decides, for accountability.'**
  String get consentRetentionBody;

  /// Consent section title.
  ///
  /// In en, this message translates to:
  /// **'How long we keep it'**
  String get consentRetentionTitle;

  /// Consent: data subject rights. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'You can ask your organisation\'s administrator to see or correct your personal data, or to stop using it where the law allows. You can also complain to the Personal Data Protection Commission.'**
  String get consentRightsBody;

  /// Consent section title.
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get consentRightsTitle;

  /// Consent: security. Must NOT claim end-to-end encryption. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted while it travels over the internet and while it is stored on the servers. Access is checked on the server for every request. A copy is also kept on your phone so you can work offline.'**
  String get consentSecurityBody;

  /// Consent section title.
  ///
  /// In en, this message translates to:
  /// **'How it is protected'**
  String get consentSecurityTitle;

  /// Consent screen title.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get consentTitle;

  /// Consent: data collected. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Your name, phone number, email (if given), department, role and supervisor, added by your organisation\'s administrator; the tasks, comments and files you create; and basic app usage and crash information.'**
  String get consentWhatWeCollectBody;

  /// Consent section title.
  ///
  /// In en, this message translates to:
  /// **'What we collect'**
  String get consentWhatWeCollectTitle;

  /// Consent: who sees data. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'People in your organisation see tasks according to their role and reporting line. Confidential tasks are visible only to their participants. Our service providers (Google Firebase for storage, and an SMS provider for text messages) process data on our behalf.'**
  String get consentWhoSeesBody;

  /// Consent section title.
  ///
  /// In en, this message translates to:
  /// **'Who can see it'**
  String get consentWhoSeesTitle;

  /// Consent: purpose. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Only to run your organisation\'s tasks: to assign work, route approvals, send reminders and escalations, and produce reports. We do not sell your data or use it for advertising.'**
  String get consentWhyBody;

  /// Consent section title.
  ///
  /// In en, this message translates to:
  /// **'Why we use it'**
  String get consentWhyTitle;

  /// Admin dashboard card. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Active users'**
  String get dashActiveUsers;

  /// Manager dashboard card.
  ///
  /// In en, this message translates to:
  /// **'Approvals waiting for me'**
  String get dashApprovalsWaiting;

  /// Manager dashboard card (bottleneck step).
  ///
  /// In en, this message translates to:
  /// **'Average days per workflow step'**
  String get dashAvgDaysPerStep;

  /// Staff dashboard card.
  ///
  /// In en, this message translates to:
  /// **'My completion rate this month'**
  String get dashCompletionRate;

  /// Staff dashboard card.
  ///
  /// In en, this message translates to:
  /// **'Due this week'**
  String get dashDueThisWeek;

  /// Staff dashboard card.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dashDueToday;

  /// Staff dashboard card.
  ///
  /// In en, this message translates to:
  /// **'My overdue tasks'**
  String get dashMyOverdue;

  /// Dashboard card with no data.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get dashNoDataYet;

  /// Admin dashboard card.
  ///
  /// In en, this message translates to:
  /// **'Organisation totals by department'**
  String get dashOrgByDepartment;

  /// Manager dashboard card. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Overdue and escalated tasks'**
  String get dashOverdueEscalated;

  /// Admin dashboard card.
  ///
  /// In en, this message translates to:
  /// **'SMS spend this month'**
  String get dashSmsSpend;

  /// Manager dashboard card.
  ///
  /// In en, this message translates to:
  /// **'Team tasks by status'**
  String get dashTeamByStatus;

  /// Admin dashboard card. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Templates in use'**
  String get dashTemplatesInUse;

  /// Manager dashboard card.
  ///
  /// In en, this message translates to:
  /// **'Workload per person'**
  String get dashWorkloadPerPerson;

  /// Dashboard screen title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// Short weekday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// Short weekday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// Short weekday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// Short weekday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// Short weekday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// Short weekday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// Short weekday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// Confirmation dialog text. Departments are never deleted. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer be offered when adding people. Existing tasks keep this department.'**
  String deactivateDepartmentMessage(String name);

  /// Confirmation dialog title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Deactivate department?'**
  String get deactivateDepartmentTitle;

  /// Confirmation dialog text (spec 4.1). SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'{name} will be signed out within an hour and can no longer sign in. Their open tasks will be flagged for reassignment.'**
  String deactivateUserMessage(String name);

  /// Confirmation dialog title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Deactivate this person?'**
  String get deactivateUserTitle;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'New department'**
  String get departmentCreateTitle;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Edit department'**
  String get departmentEditTitle;

  /// Department field.
  ///
  /// In en, this message translates to:
  /// **'Head of department'**
  String get departmentFieldHead;

  /// Department field.
  ///
  /// In en, this message translates to:
  /// **'Department name'**
  String get departmentFieldName;

  /// Department list subtitle.
  ///
  /// In en, this message translates to:
  /// **'Head: {name}'**
  String departmentHead(String name);

  /// Department without a head.
  ///
  /// In en, this message translates to:
  /// **'No head named'**
  String get departmentNoHead;

  /// Departments empty message.
  ///
  /// In en, this message translates to:
  /// **'Add departments such as Finance, HR or ICT, and name a head for each.'**
  String get departmentsEmptyMessage;

  /// Departments empty title.
  ///
  /// In en, this message translates to:
  /// **'No departments yet'**
  String get departmentsEmptyTitle;

  /// Due-date filter option.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dueOverdue;

  /// Due-date filter option.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dueThisWeek;

  /// Due-date filter option.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dueToday;

  /// Email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Email sign-in explanation.
  ///
  /// In en, this message translates to:
  /// **'Use this if you cannot receive SMS. Your administrator gives you the email and password.'**
  String get emailSignInHelp;

  /// Email sign-in title.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get emailSignInTitle;

  /// Error account-deactivated: the account was deactivated by an administrator.
  ///
  /// In en, this message translates to:
  /// **'Your account is not active. Ask your administrator.'**
  String get errorAccountDeactivated;

  /// Error code-expired (10 minutes).
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Ask for a new code.'**
  String get errorAdminCodeExpired;

  /// Error code-attempts-exceeded.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong codes. Ask for a new code.'**
  String get errorAdminCodeTooManyAttempts;

  /// Error code-invalid without attempts count.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct. Check your email and try again.'**
  String get errorAdminCodeWrong;

  /// Error code-invalid with details.attemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{That code is not correct. Ask for a new code.} =1{That code is not correct. 1 attempt left.} other{That code is not correct. {count} attempts left.}}'**
  String errorAdminCodeWrongAttempts(int count);

  /// Error admin-email-missing. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Your account has no email for the administrator code. Ask another administrator to add one.'**
  String get errorAdminEmailMissing;

  /// Error: the admin second factor has expired. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your administrator code again.'**
  String get errorAdminVerificationRequired;

  /// Generic conflict error.
  ///
  /// In en, this message translates to:
  /// **'Someone else changed this first. Please check the latest version.'**
  String get errorConflict;

  /// Late workflow approval rejected by the server (spec 4.9).
  ///
  /// In en, this message translates to:
  /// **'This step was already approved by {name} at {time}.'**
  String errorConflictAlreadyApproved(String name, String time);

  /// Error: an online-only action (sign-in, saving a person, admin code) could not reach the server.
  ///
  /// In en, this message translates to:
  /// **'This needs an internet connection. Connect and try again.'**
  String get errorConnectionRequired;

  /// Error department-invalid.
  ///
  /// In en, this message translates to:
  /// **'The chosen department does not exist or is not active. Choose another department.'**
  String get errorDepartmentInvalid;

  /// Error email-cannot-be-removed (also client-side validation). SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'An email cannot be removed once it is set. Enter a new email instead.'**
  String get errorEmailCannotBeRemoved;

  /// Error email-in-use.
  ///
  /// In en, this message translates to:
  /// **'This email is already used by another person.'**
  String get errorEmailInUse;

  /// Wrong verification code.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct. Check the SMS and try again.'**
  String get errorInvalidCode;

  /// Invalid email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errorInvalidEmail;

  /// Generic validation error.
  ///
  /// In en, this message translates to:
  /// **'Some information is not valid. Please check and try again.'**
  String get errorInvalidInput;

  /// Invalid phone number.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Tanzanian mobile number, for example 0712 345 678.'**
  String get errorInvalidPhone;

  /// Error last-admin.
  ///
  /// In en, this message translates to:
  /// **'This is the last active administrator. Add another administrator first.'**
  String get errorLastAdmin;

  /// Network error.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Your changes are kept on this phone; try again when you are online.'**
  String get errorNetwork;

  /// Shown for BOTH not-found and permission-denied so confidential items look missing.
  ///
  /// In en, this message translates to:
  /// **'This item was not found.'**
  String get errorNotFound;

  /// User not invited.
  ///
  /// In en, this message translates to:
  /// **'Ask your administrator to add you.'**
  String get errorNotInvited;

  /// Error permission-denied from a server function.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to do this.'**
  String get errorPermissionDenied;

  /// Error phone-in-use.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already used by another person.'**
  String get errorPhoneInUse;

  /// Error provider-unavailable (SMS/email provider down).
  ///
  /// In en, this message translates to:
  /// **'The message service is not available right now. Please try again later.'**
  String get errorProviderUnavailable;

  /// Error code-rate-limited (5 codes per hour).
  ///
  /// In en, this message translates to:
  /// **'Too many codes requested. Please wait and try again later.'**
  String get errorRateLimited;

  /// Error reporting-loop: the chosen supervisor reports (directly or indirectly) to this person. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'This supervisor would create a loop in the reporting lines. Choose someone else.'**
  String get errorReportingLoop;

  /// Error self-deactivation.
  ///
  /// In en, this message translates to:
  /// **'You cannot deactivate your own account.'**
  String get errorSelfDeactivation;

  /// Error self-demotion.
  ///
  /// In en, this message translates to:
  /// **'You cannot remove your own administrator role.'**
  String get errorSelfDemotion;

  /// Session expired.
  ///
  /// In en, this message translates to:
  /// **'For your security, please sign in again.'**
  String get errorSessionExpired;

  /// Error sms-cap-reached.
  ///
  /// In en, this message translates to:
  /// **'The monthly SMS limit has been reached.'**
  String get errorSmsCapReached;

  /// Error supervisor-invalid. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'The chosen supervisor is not an active person in this organisation. Choose someone else.'**
  String get errorSupervisorInvalid;

  /// Rate limited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes and try again.'**
  String get errorTooManyAttempts;

  /// Error top-person-requires-supervisor. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'This change is not possible for the top person of the organisation. Check the reporting lines and try again.'**
  String get errorTopPersonRequiresSupervisor;

  /// Error tree-busy (retryable). SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'The reporting lines are being updated. Please try again in a moment.'**
  String get errorTreeBusy;

  /// Not signed in.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get errorUnauthenticated;

  /// Unknown error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// Wrong email/password.
  ///
  /// In en, this message translates to:
  /// **'The email or password is not correct.'**
  String get errorWrongCredentials;

  /// Honest message for buttons whose feature is not built yet.
  ///
  /// In en, this message translates to:
  /// **'This is not available yet. It is coming in a later version.'**
  String get featureNotAvailableYet;

  /// Task filter chip: person assigned. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get filterAssignee;

  /// Clear a filter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get filterClear;

  /// Task filter chip.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get filterDepartment;

  /// Task filter chip.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get filterDueDate;

  /// Empty filter options.
  ///
  /// In en, this message translates to:
  /// **'No options available yet'**
  String get filterNoOptionsYet;

  /// Task filter chip.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get filterPriority;

  /// Task filter chip.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// Forgot password dialog text. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Enter your email. If it belongs to an ATMS account, we will send a link to set a new password. New accounts use this to set their first password.'**
  String get forgotPasswordHelp;

  /// Title of the forgot password dialog.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get forgotPasswordTitle;

  /// Label on a deactivated person or department.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get labelInactive;

  /// Warning label: this person's supervisor was deactivated and must be changed. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Supervisor inactive'**
  String get labelSupervisorInactive;

  /// Language option; always shown in English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// More screen: language section.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// Language option; always shown in Kiswahili.
  ///
  /// In en, this message translates to:
  /// **'Kiswahili'**
  String get languageSwahili;

  /// Loading screen text.
  ///
  /// In en, this message translates to:
  /// **'Getting your account ready...'**
  String get loadingMessage;

  /// Loading screen when offline and nothing is cached yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an internet connection to load your account...'**
  String get loadingWaitingForConnection;

  /// More screen: manager section.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get managerSection;

  /// More screen title.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// Task list title.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get myTasksTitle;

  /// Bottom navigation: approvals waiting tab.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get navApprovals;

  /// Bottom navigation: dashboard tab. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Bottom navigation: more/menu tab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// Bottom navigation: notifications tab (short label).
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navNotifications;

  /// Bottom navigation: task list tab.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// Note under buttons that call the server (online only).
  ///
  /// In en, this message translates to:
  /// **'This needs an internet connection.'**
  String get needsConnectionNote;

  /// Snackbar when saving without changes.
  ///
  /// In en, this message translates to:
  /// **'No changes to save'**
  String get noChangesMessage;

  /// Not-invited explanation.
  ///
  /// In en, this message translates to:
  /// **'Only phone numbers added by your organisation can use ATMS.'**
  String get notInvitedHelp;

  /// Not-invited main message (spec 4.1).
  ///
  /// In en, this message translates to:
  /// **'Ask your administrator to add you.'**
  String get notInvitedMessage;

  /// Not-invited screen title.
  ///
  /// In en, this message translates to:
  /// **'Not registered'**
  String get notInvitedTitle;

  /// Notifications empty message. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Reminders, approvals and escalations will appear here.'**
  String get notificationsEmptyMessage;

  /// Notifications empty title.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// Notifications screen title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Snackbar when a change queued offline is refused after syncing. reason is another friendly error message. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'A change saved offline was not accepted: {reason}'**
  String offlineChangeRefused(String reason);

  /// Language step help.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for the app. You can change it later under More.'**
  String get onboardingLanguageHelp;

  /// Language step title.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get onboardingLanguageTitle;

  /// Notification permission explanation.
  ///
  /// In en, this message translates to:
  /// **'ATMS tells you when a task is assigned to you, when an approval is waiting and when a deadline is near. Allow notifications so you do not miss them.'**
  String get onboardingNotificationsHelp;

  /// Notification step title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get onboardingNotificationsTitle;

  /// Helper text for optional fields.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalFieldHint;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Snackbar after requesting a password reset (does not reveal whether the account exists). SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'If this email has an account, a link to set a new password has been sent. Check your inbox.'**
  String get passwordResetSent;

  /// Phone number example.
  ///
  /// In en, this message translates to:
  /// **'0712 345 678'**
  String get phoneNumberHint;

  /// Phone field label.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// Phone sign-in heading.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ATMS'**
  String get phoneSignInHeading;

  /// Phone sign-in explanation.
  ///
  /// In en, this message translates to:
  /// **'Enter the phone number your organisation registered. We will send you a 6-digit code by SMS.'**
  String get phoneSignInHelp;

  /// Priority value.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// Priority value.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// Priority value.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// Priority value.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// More screen: profile section.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSection;

  /// Profile line with the user role.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {role}'**
  String profileSignedInAs(String role);

  /// Reporting tree empty message. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Set each person\'s supervisor to build the reporting lines used for escalation.'**
  String get reportingTreeEmptyMessage;

  /// Reporting tree empty title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'No reporting lines yet'**
  String get reportingTreeEmptyTitle;

  /// Help text above the reporting tree. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Tap a person to show who reports to them. Press and hold to open their details.'**
  String get reportingTreeHelp;

  /// Reports empty message.
  ///
  /// In en, this message translates to:
  /// **'Weekly summaries are made every Monday and monthly summaries on the 1st.'**
  String get reportsEmptyMessage;

  /// Reports empty title.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get reportsEmptyTitle;

  /// Reports title.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// Helper text for required fields.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredFieldHint;

  /// Disabled resend button with countdown.
  ///
  /// In en, this message translates to:
  /// **'Send the code again in {seconds} s'**
  String resendCodeIn(int seconds);

  /// Role name.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// Role name.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// Role name. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// Snackbar after a save reached the server.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedMessage;

  /// Snackbar after an offline save (queued).
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. It will be sent when you are back online.'**
  String get savedOnPhoneMessage;

  /// Search field label.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchByName;

  /// Note shown while searching within loaded pages only. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Search covers the people loaded so far. Load more to search further.'**
  String get searchLoadedOnlyNote;

  /// Banner on the sign-in screen after the app signed the user out because the session was too old. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'For your security you were signed out. Sessions last {staffDays} days ({adminDays} days for administrators). Please sign in again.'**
  String sessionExpiredMessage(int staffDays, int adminDays);

  /// Org setting. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Escalation delay'**
  String get settingEscalationDelay;

  /// Helper for escalation delay. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Hours after the deadline before the supervisor is alerted'**
  String get settingEscalationDelayHelp;

  /// How many levels up an overdue task climbs. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Escalation levels'**
  String get settingEscalationLevels;

  /// Helper for escalation levels. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'How many levels up the reporting line an overdue task climbs'**
  String get settingEscalationLevelsHelp;

  /// Helper for the reminder hours field.
  ///
  /// In en, this message translates to:
  /// **'Hours before the deadline, separated by commas, e.g. 24, 1'**
  String get settingReminderHoursHelp;

  /// Org setting.
  ///
  /// In en, this message translates to:
  /// **'Reminder times'**
  String get settingReminderTimes;

  /// Settings section title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Reminders and escalation'**
  String get settingRemindersSection;

  /// Org setting.
  ///
  /// In en, this message translates to:
  /// **'Monthly SMS limit'**
  String get settingSmsCap;

  /// Helper for the SMS cap.
  ///
  /// In en, this message translates to:
  /// **'Maximum SMS spending per month, in Tanzanian shillings (TZS).'**
  String get settingSmsCapHelp;

  /// Switch: SMS on/off.
  ///
  /// In en, this message translates to:
  /// **'Send SMS'**
  String get settingSmsEnabled;

  /// Help for the SMS switch. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'SMS alerts, for example when a push notification is not opened.'**
  String get settingSmsEnabledHelp;

  /// Settings section title.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get settingSmsSection;

  /// Org setting. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get settingTimeZone;

  /// Working hours end.
  ///
  /// In en, this message translates to:
  /// **'Work ends'**
  String get settingWorkEnd;

  /// Working hours start.
  ///
  /// In en, this message translates to:
  /// **'Work starts'**
  String get settingWorkStart;

  /// Org setting.
  ///
  /// In en, this message translates to:
  /// **'Working days'**
  String get settingWorkingDays;

  /// Org setting.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get settingWorkingHours;

  /// Organisation setting switch.
  ///
  /// In en, this message translates to:
  /// **'Count working hours only'**
  String get settingWorkingHoursEnabled;

  /// Help for the working-hours switch (spec 4.2). SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'When on, deadlines and escalation count only working hours on working days.'**
  String get settingWorkingHoursEnabledHelp;

  /// App not configured explanation.
  ///
  /// In en, this message translates to:
  /// **'This copy of the app was built without its server settings, so it cannot connect. Please install the version provided by your organisation.'**
  String get setupMissingMessage;

  /// App not configured title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'App not configured'**
  String get setupMissingTitle;

  /// Note under the sign-in buttons.
  ///
  /// In en, this message translates to:
  /// **'Signing in needs an internet connection.'**
  String get signInNeedsConnection;

  /// Sign-in screen title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Start workflow empty message. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Your administrator has not published any workflow templates yet.'**
  String get startWorkflowEmptyMessage;

  /// Start workflow title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Start a workflow'**
  String get startWorkflowTitle;

  /// Task status.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// Task status.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Task status.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// Task status.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// Task status.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get statusTodo;

  /// Step tracker empty state. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'This task has no workflow steps'**
  String get stepTrackerEmpty;

  /// Task detail: step tracker section.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepTrackerTitle;

  /// Sync banner: synced.
  ///
  /// In en, this message translates to:
  /// **'All changes saved'**
  String get syncAllSaved;

  /// Sync banner: offline.
  ///
  /// In en, this message translates to:
  /// **'Offline: changes saved on this phone'**
  String get syncOffline;

  /// Sync banner: syncing. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncSyncing;

  /// Create task title.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskCreateTitle;

  /// Task detail title.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskDetailTitle;

  /// Edit task title.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskEditTitle;

  /// Assignee field label.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get taskFieldAssignee;

  /// Assignee field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Choose people'**
  String get taskFieldAssigneeHint;

  /// Deadline field label.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get taskFieldDeadline;

  /// Deadline placeholder.
  ///
  /// In en, this message translates to:
  /// **'Choose date and time'**
  String get taskFieldDeadlineHint;

  /// Description field label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskFieldDescription;

  /// Priority field label.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskFieldPriority;

  /// Title field label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskFieldTitle;

  /// Task summary placeholder while loading is not built.
  ///
  /// In en, this message translates to:
  /// **'Task details will appear here.'**
  String get taskNotLoadedYet;

  /// Task detail summary section.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get taskSummaryTitle;

  /// Empty list with filters.
  ///
  /// In en, this message translates to:
  /// **'No tasks match these filters'**
  String get tasksEmptyFilteredTitle;

  /// My tasks empty message.
  ///
  /// In en, this message translates to:
  /// **'Tasks assigned to you will appear here, sorted by deadline.'**
  String get tasksEmptyMessage;

  /// My tasks empty title.
  ///
  /// In en, this message translates to:
  /// **'You have no tasks'**
  String get tasksEmptyTitle;

  /// Team tasks empty title.
  ///
  /// In en, this message translates to:
  /// **'Your team has no tasks'**
  String get teamTasksEmptyTitle;

  /// Team tasks title.
  ///
  /// In en, this message translates to:
  /// **'Team tasks'**
  String get teamTasksTitle;

  /// Template detail title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Workflow template'**
  String get templateDetailTitle;

  /// Template steps empty.
  ///
  /// In en, this message translates to:
  /// **'No steps yet'**
  String get templateStepsEmpty;

  /// Template steps section.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get templateStepsTitle;

  /// Templates empty message. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Create a template, such as a purchase request, to route tasks automatically from one person to the next.'**
  String get templatesEmptyMessage;

  /// Templates empty title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'No workflow templates yet'**
  String get templatesEmptyTitle;

  /// Time zone display (not editable).
  ///
  /// In en, this message translates to:
  /// **'East Africa Time ({zone})'**
  String timeZoneEastAfrica(String zone);

  /// Confirmation text (adminUpsertUser moves the previous top under the new one). SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'A person without a supervisor becomes the top of the organisation. The current top person will then report to {name}. Continue?'**
  String topPersonWarningMessage(String name);

  /// Confirmation when saving a person without a supervisor. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Make this person the top of the organisation?'**
  String get topPersonWarningTitle;

  /// Link to email fallback.
  ///
  /// In en, this message translates to:
  /// **'No SMS? Sign in with email'**
  String get useEmailInstead;

  /// Section title in the user editor. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Role and reporting'**
  String get userAccessSection;

  /// Snackbar after adding a person.
  ///
  /// In en, this message translates to:
  /// **'Person added.'**
  String get userAddedMessage;

  /// Confidential access help.
  ///
  /// In en, this message translates to:
  /// **'Can see confidential tasks of these departments.'**
  String get userConfidentialHelp;

  /// Helper under the phone field.
  ///
  /// In en, this message translates to:
  /// **'A phone number or an email is needed to sign in.'**
  String get userContactHelp;

  /// Title of the user editor when adding.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get userCreateTitle;

  /// Snackbar after deactivating a person. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Person deactivated. They had no open tasks.} =1{Person deactivated. 1 open task was flagged for reassignment.} other{Person deactivated. {count} open tasks were flagged for reassignment.}}'**
  String userDeactivatedMessage(int count);

  /// User editor section.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get userDetailsSection;

  /// User field.
  ///
  /// In en, this message translates to:
  /// **'Confidential access'**
  String get userFieldConfidentialAccess;

  /// User field.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get userFieldDepartment;

  /// User field (D-05), e.g. Finance Officer.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get userFieldJobRole;

  /// User field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get userFieldName;

  /// User field. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get userFieldRole;

  /// User field.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get userFieldSupervisor;

  /// Note under Save when adding a person.
  ///
  /// In en, this message translates to:
  /// **'Saving needs an internet connection. People with a phone number get an SMS invitation.'**
  String get userInviteNote;

  /// Helper for job title. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Used by workflow steps assigned to a job title, e.g. Finance Officer.'**
  String get userJobRoleHelp;

  /// User editor language label.
  ///
  /// In en, this message translates to:
  /// **'Language for SMS and the app'**
  String get userLanguageLabel;

  /// Supervisor picker when empty. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'None (top of organisation)'**
  String get userNoSupervisor;

  /// Person without a supervisor. SW_REVIEW: Kiswahili needs native-speaker check.
  ///
  /// In en, this message translates to:
  /// **'Top of organisation'**
  String get userTopOfOrganisation;

  /// Users empty message.
  ///
  /// In en, this message translates to:
  /// **'Add people with their phone number, department, role and supervisor.'**
  String get usersEmptyMessage;

  /// Users empty title.
  ///
  /// In en, this message translates to:
  /// **'No people yet'**
  String get usersEmptyTitle;

  /// Required assignee.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one person'**
  String get validationAssigneeRequired;

  /// Code validation.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get validationCodeSixDigits;

  /// Deadline validation.
  ///
  /// In en, this message translates to:
  /// **'The deadline must be in the future'**
  String get validationDeadlineInPast;

  /// Required deadline.
  ///
  /// In en, this message translates to:
  /// **'Choose a deadline'**
  String get validationDeadlineRequired;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Choose a department'**
  String get validationDepartmentRequired;

  /// Required email.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get validationEmailRequired;

  /// Validation: name required.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get validationNameRequired;

  /// Required password.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get validationPasswordRequired;

  /// Validation: at least one contact.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number or an email'**
  String get validationPhoneOrEmail;

  /// Required phone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get validationPhoneRequired;

  /// Required priority.
  ///
  /// In en, this message translates to:
  /// **'Choose a priority'**
  String get validationPriorityRequired;

  /// Validation for reminder hours.
  ///
  /// In en, this message translates to:
  /// **'Enter whole numbers of hours from 1 to {max}, separated by commas'**
  String validationReminderHours(int max);

  /// Required title.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get validationTitleRequired;

  /// Validation for number fields.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from {min} to {max}'**
  String validationWholeNumberRange(int min, int max);

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one working day'**
  String get validationWorkingDaysRequired;

  /// Placeholder for an empty picker.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get valueNotChosen;

  /// Value placeholder while data source is not built.
  ///
  /// In en, this message translates to:
  /// **'Not loaded yet'**
  String get valueNotLoaded;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
