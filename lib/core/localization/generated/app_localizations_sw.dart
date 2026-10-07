// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get actionAddAttachment => 'Ambatisha faili';

  @override
  String get actionAddDepartment => 'Ongeza idara';

  @override
  String get actionAddUser => 'Ongeza mtu';

  @override
  String get actionAgreeAndContinue => 'Kubali na uendelee';

  @override
  String get actionAllowNotifications => 'Ruhusu arifa';

  @override
  String get actionBackToPhone => 'Weka namba ya simu tena';

  @override
  String get actionContinue => 'Endelea';

  @override
  String get actionEdit => 'Hariri';

  @override
  String get actionGoToTasks => 'Nenda kwenye kazi zangu';

  @override
  String get actionHidePassword => 'Ficha nenosiri';

  @override
  String get actionNewTask => 'Kazi mpya';

  @override
  String get actionNewTemplate => 'Kiolezo kipya';

  @override
  String get actionNotNow => 'Si sasa';

  @override
  String get actionResendCode => 'Tuma msimbo tena';

  @override
  String get actionSave => 'Hifadhi';

  @override
  String get actionSendCode => 'Tuma msimbo';

  @override
  String get actionShowPassword => 'Onyesha nenosiri';

  @override
  String get actionSignIn => 'Ingia';

  @override
  String get actionSignOut => 'Ondoka';

  @override
  String get actionUseAnotherNumber => 'Tumia namba nyingine';

  @override
  String get actionVerify => 'Thibitisha';

  @override
  String get adminAuditTitle => 'Kumbukumbu za ukaguzi';

  @override
  String get adminDepartmentsTitle => 'Idara';

  @override
  String get adminReportingTreeTitle => 'Mfumo wa uwajibikaji';

  @override
  String get adminSection => 'Utawala';

  @override
  String get adminSettingsTitle => 'Mipangilio ya taasisi';

  @override
  String get adminTemplatesTitle => 'Violezo vya mtiririko wa kazi';

  @override
  String get adminUserDetailTitle => 'Taarifa za mtu';

  @override
  String get adminUsersTitle => 'Watu';

  @override
  String get adminVerifyHelp =>
      'Kwa usalama zaidi, wasimamizi wa mfumo lazima pia waweke msimbo wa tarakimu 6 uliotumwa kwenye barua pepe yao.';

  @override
  String get adminVerifyTitle => 'Uthibitisho wa msimamizi';

  @override
  String get appTitle => 'ATMS';

  @override
  String get approvalsEmptyMessage =>
      'Hatua inayohitaji idhini yako itaonekana hapa.';

  @override
  String get approvalsEmptyTitle => 'Hakuna kinachosubiri idhini yako';

  @override
  String get approvalsTitle => 'Idhini zinazosubiri';

  @override
  String assigneeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Watu $count wamechaguliwa',
      one: 'Mtu 1 amechaguliwa',
    );
    return '$_temp0';
  }

  @override
  String get assigneePickerEmpty => 'Bado hakuna watu wa kuchagua';

  @override
  String get attachmentsEmpty => 'Bado hakuna viambatisho';

  @override
  String get attachmentsTitle => 'Viambatisho';

  @override
  String get auditEmptyMessage =>
      'Kila badiliko la kazi, watu na violezo litarekodiwa hapa.';

  @override
  String get auditEmptyTitle => 'Bado hakuna kumbukumbu za ukaguzi';

  @override
  String codeEntryHelp(String phone) {
    return 'Weka msimbo wa tarakimu 6 tuliokutumia kwa SMS kwenda $phone.';
  }

  @override
  String get codeEntryNoPending =>
      'Ombi lako la msimbo limeisha muda. Tafadhali weka namba yako ya simu tena.';

  @override
  String get codeEntryTitle => 'Weka msimbo';

  @override
  String get codeLabel => 'Msimbo wa tarakimu 6';

  @override
  String get commentInputHint => 'Andika maoni';

  @override
  String get commentsEmpty => 'Bado hakuna maoni';

  @override
  String get commentsTitle => 'Maoni';

  @override
  String get consentCheckbox =>
      'Nimesoma taarifa hii na ninakubali taarifa zangu zitumike kama ilivyoelezwa.';

  @override
  String get consentIntro =>
      'Kabla ya kuanza, tafadhali soma jinsi ATMS inavyotumia taarifa zako binafsi. Taarifa hii inazingatia Sheria ya Ulinzi wa Taarifa Binafsi ya Tanzania, 2022.';

  @override
  String get consentRetentionBody =>
      'Kumbukumbu za kazi na za ukaguzi zinahifadhiwa kwa angalau miaka 3, au kama taasisi yako itakavyoamua, kwa ajili ya uwajibikaji.';

  @override
  String get consentRetentionTitle => 'Tunazihifadhi kwa muda gani';

  @override
  String get consentRightsBody =>
      'Unaweza kumwomba msimamizi wa mfumo wa taasisi yako kuona au kusahihisha taarifa zako binafsi, au kuacha kuzitumia pale sheria inaporuhusu. Unaweza pia kuwasilisha malalamiko kwa Tume ya Ulinzi wa Taarifa Binafsi.';

  @override
  String get consentRightsTitle => 'Haki zako';

  @override
  String get consentSecurityBody =>
      'Taarifa zako zinasimbwa kwa njia fiche zinaposafiri kwenye intaneti na zinapohifadhiwa kwenye seva. Ruhusa inakaguliwa kwenye seva kwa kila ombi. Nakala pia inahifadhiwa kwenye simu yako ili uweze kufanya kazi bila intaneti.';

  @override
  String get consentSecurityTitle => 'Jinsi zinavyolindwa';

  @override
  String get consentTitle => 'Taarifa ya faragha';

  @override
  String get consentWhatWeCollectBody =>
      'Jina lako, namba ya simu, barua pepe (ikiwa imetolewa), idara, cheo na msimamizi wako, vilivyoongezwa na msimamizi wa mfumo wa taasisi yako; kazi, maoni na mafaili unayoweka; na taarifa za msingi za matumizi ya programu na hitilafu.';

  @override
  String get consentWhatWeCollectTitle => 'Tunachokusanya';

  @override
  String get consentWhoSeesBody =>
      'Watu katika taasisi yako wanaona kazi kulingana na cheo chao na mfumo wa uwajibikaji. Kazi za siri zinaonekana kwa washiriki wake tu. Watoa huduma wetu (Google Firebase kwa kuhifadhi, na mtoa huduma wa SMS kwa ujumbe mfupi) wanashughulikia taarifa kwa niaba yetu.';

  @override
  String get consentWhoSeesTitle => 'Nani anaweza kuziona';

  @override
  String get consentWhyBody =>
      'Kwa ajili ya kuendesha kazi za taasisi yako tu: kugawa kazi, kupitisha idhini, kutuma vikumbusho na kupandisha kazi zilizochelewa, na kutoa ripoti. Hatuuzi taarifa zako wala kuzitumia kwa matangazo.';

  @override
  String get consentWhyTitle => 'Kwa nini tunaitumia';

  @override
  String get dashActiveUsers => 'Watumiaji hai';

  @override
  String get dashApprovalsWaiting => 'Idhini zinazonisubiri';

  @override
  String get dashAvgDaysPerStep => 'Wastani wa siku kwa kila hatua';

  @override
  String get dashCompletionRate => 'Kiwango changu cha kukamilisha mwezi huu';

  @override
  String get dashDueThisWeek => 'Zinazotakiwa wiki hii';

  @override
  String get dashDueToday => 'Zinazotakiwa leo';

  @override
  String get dashMyOverdue => 'Kazi zangu zilizochelewa';

  @override
  String get dashNoDataYet => 'Bado hakuna takwimu';

  @override
  String get dashOrgByDepartment => 'Jumla ya taasisi kwa idara';

  @override
  String get dashOverdueEscalated => 'Kazi zilizochelewa na zilizopandishwa';

  @override
  String get dashSmsSpend => 'Gharama ya SMS mwezi huu';

  @override
  String get dashTeamByStatus => 'Kazi za timu kwa hali';

  @override
  String get dashTemplatesInUse => 'Violezo vinavyotumika';

  @override
  String get dashWorkloadPerPerson => 'Mzigo wa kazi kwa kila mtu';

  @override
  String get dashboardTitle => 'Dashibodi';

  @override
  String get departmentsEmptyMessage =>
      'Ongeza idara kama Fedha, Rasilimali Watu au TEHAMA, na umtaje mkuu wa kila moja.';

  @override
  String get departmentsEmptyTitle => 'Bado hakuna idara';

  @override
  String devPreviewAsRole(String role) {
    return 'Fungua kama $role';
  }

  @override
  String get devPreviewMessage =>
      'Kwa matoleo ya majaribio tu. Inafungua skrini bila takwimu na bila kuingia.';

  @override
  String get devPreviewTitle => 'Onyesho la msanidi';

  @override
  String get dueOverdue => 'Zimechelewa';

  @override
  String get dueThisWeek => 'Wiki hii';

  @override
  String get dueToday => 'Leo';

  @override
  String get emailLabel => 'Barua pepe';

  @override
  String get emailSignInHelp =>
      'Tumia njia hii kama huwezi kupokea SMS. Msimamizi wa mfumo atakupa barua pepe na nenosiri.';

  @override
  String get emailSignInTitle => 'Ingia kwa barua pepe';

  @override
  String get errorConflict =>
      'Mtu mwingine amebadilisha hiki kwanza. Tafadhali angalia toleo la sasa.';

  @override
  String errorConflictAlreadyApproved(String name, String time) {
    return 'Hatua hii tayari imeidhinishwa na $name saa $time.';
  }

  @override
  String get errorInvalidCode =>
      'Msimbo huo si sahihi. Angalia SMS na ujaribu tena.';

  @override
  String get errorInvalidEmail => 'Weka anwani sahihi ya barua pepe.';

  @override
  String get errorInvalidInput =>
      'Baadhi ya taarifa si sahihi. Tafadhali angalia na ujaribu tena.';

  @override
  String get errorInvalidPhone =>
      'Weka namba sahihi ya simu ya mkononi ya Tanzania, kwa mfano 0712 345 678.';

  @override
  String get errorNetwork =>
      'Hakuna mtandao. Mabadiliko yako yamehifadhiwa kwenye simu hii; jaribu tena ukiwa mtandaoni.';

  @override
  String get errorNotFound => 'Kipengele hiki hakijapatikana.';

  @override
  String get errorNotInvited => 'Mwombe msimamizi wa mfumo akuongeze.';

  @override
  String get errorSessionExpired => 'Kwa usalama wako, tafadhali ingia tena.';

  @override
  String get errorTooManyAttempts =>
      'Umejaribu mara nyingi mno. Tafadhali subiri dakika chache kisha ujaribu tena.';

  @override
  String get errorUnauthenticated => 'Tafadhali ingia ili uendelee.';

  @override
  String get errorUnknown => 'Hitilafu imetokea. Tafadhali jaribu tena.';

  @override
  String get errorWrongCredentials => 'Barua pepe au nenosiri si sahihi.';

  @override
  String get featureNotAvailableYet =>
      'Huduma hii bado haipatikani. Itakuja katika toleo lijalo.';

  @override
  String get filterAssignee => 'Mhusika';

  @override
  String get filterClear => 'Ondoa kichujio';

  @override
  String get filterDepartment => 'Idara';

  @override
  String get filterDueDate => 'Tarehe ya mwisho';

  @override
  String get filterNoOptionsYet => 'Bado hakuna machaguo';

  @override
  String get filterPriority => 'Kipaumbele';

  @override
  String get filterStatus => 'Hali';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSection => 'Lugha';

  @override
  String get languageSwahili => 'Kiswahili';

  @override
  String get loadingMessage => 'Tunaandaa akaunti yako...';

  @override
  String get managerSection => 'Timu';

  @override
  String get moreTitle => 'Zaidi';

  @override
  String get myTasksTitle => 'Kazi zangu';

  @override
  String get navApprovals => 'Idhini';

  @override
  String get navDashboard => 'Dashibodi';

  @override
  String get navMore => 'Zaidi';

  @override
  String get navNotifications => 'Arifa';

  @override
  String get navTasks => 'Kazi';

  @override
  String get notInvitedHelp =>
      'Ni namba za simu zilizoongezwa na taasisi yako pekee zinazoweza kutumia ATMS.';

  @override
  String get notInvitedMessage => 'Mwombe msimamizi wa mfumo akuongeze.';

  @override
  String get notInvitedTitle => 'Hujasajiliwa';

  @override
  String get notificationsEmptyMessage =>
      'Vikumbusho, idhini na kazi zilizopandishwa vitaonekana hapa.';

  @override
  String get notificationsEmptyTitle => 'Bado hakuna arifa';

  @override
  String get notificationsTitle => 'Arifa';

  @override
  String get onboardingLanguageHelp =>
      'Chagua lugha ya programu. Unaweza kuibadilisha baadaye kwenye Zaidi.';

  @override
  String get onboardingLanguageTitle => 'Chagua lugha';

  @override
  String get onboardingNotificationsHelp =>
      'ATMS inakujulisha unapopewa kazi, idhini inaposubiri na tarehe ya mwisho inapokaribia. Ruhusu arifa ili usizikose.';

  @override
  String get onboardingNotificationsTitle => 'Arifa';

  @override
  String get optionalFieldHint => 'Si lazima';

  @override
  String get passwordLabel => 'Nenosiri';

  @override
  String get phoneNumberHint => '0712 345 678';

  @override
  String get phoneNumberLabel => 'Namba ya simu';

  @override
  String get phoneSignInHeading => 'Karibu ATMS';

  @override
  String get phoneSignInHelp =>
      'Weka namba ya simu iliyosajiliwa na taasisi yako. Tutakutumia msimbo wa tarakimu 6 kwa SMS.';

  @override
  String get priorityHigh => 'Juu';

  @override
  String get priorityLow => 'Chini';

  @override
  String get priorityMedium => 'Wastani';

  @override
  String get priorityUrgent => 'Dharura';

  @override
  String get profileSection => 'Wasifu';

  @override
  String profileSignedInAs(String role) {
    return 'Umeingia kama $role';
  }

  @override
  String get reportingTreeEmptyMessage =>
      'Weka msimamizi wa kila mtu ili kujenga mfumo wa uwajibikaji unaotumika kupandisha kazi.';

  @override
  String get reportingTreeEmptyTitle => 'Bado hakuna mfumo wa uwajibikaji';

  @override
  String get reportsEmptyMessage =>
      'Muhtasari wa wiki hutolewa kila Jumatatu na wa mwezi tarehe 1.';

  @override
  String get reportsEmptyTitle => 'Bado hakuna ripoti';

  @override
  String get reportsTitle => 'Ripoti';

  @override
  String get requiredFieldHint => 'Lazima';

  @override
  String get roleAdmin => 'Msimamizi wa mfumo';

  @override
  String get roleManager => 'Meneja';

  @override
  String get roleStaff => 'Mtumishi';

  @override
  String get settingEscalationDelay => 'Muda kabla ya kupandisha kazi';

  @override
  String get settingReminderTimes => 'Nyakati za vikumbusho';

  @override
  String get settingSmsCap => 'Kikomo cha SMS kwa mwezi';

  @override
  String get settingTimeZone => 'Saa za eneo';

  @override
  String get settingWorkingDays => 'Siku za kazi';

  @override
  String get settingWorkingHours => 'Saa za kazi';

  @override
  String get setupMissingMessage =>
      'Nakala hii ya programu imetengenezwa bila mipangilio ya seva, kwa hiyo haiwezi kuunganishwa. Tafadhali sakinisha toleo lililotolewa na taasisi yako.';

  @override
  String get setupMissingTitle => 'Programu haijasanidiwa';

  @override
  String get signInTitle => 'Ingia';

  @override
  String get startWorkflowEmptyMessage =>
      'Msimamizi wa mfumo bado hajachapisha violezo vya mtiririko wa kazi.';

  @override
  String get startWorkflowTitle => 'Anzisha mtiririko wa kazi';

  @override
  String get statusBlocked => 'Imekwama';

  @override
  String get statusCancelled => 'Imesitishwa';

  @override
  String get statusDone => 'Imekamilika';

  @override
  String get statusInProgress => 'Inaendelea';

  @override
  String get statusTodo => 'Haijaanza';

  @override
  String get stepTrackerEmpty => 'Kazi hii haina hatua za mtiririko';

  @override
  String get stepTrackerTitle => 'Hatua';

  @override
  String get syncAllSaved => 'Mabadiliko yote yamehifadhiwa';

  @override
  String get syncOffline =>
      'Nje ya mtandao: mabadiliko yamehifadhiwa kwenye simu hii';

  @override
  String get syncSyncing => 'Inasawazisha...';

  @override
  String get taskCreateTitle => 'Kazi mpya';

  @override
  String get taskDetailTitle => 'Kazi';

  @override
  String get taskEditTitle => 'Hariri kazi';

  @override
  String get taskFieldAssignee => 'Amepewa';

  @override
  String get taskFieldAssigneeHint => 'Chagua watu';

  @override
  String get taskFieldDeadline => 'Tarehe ya mwisho';

  @override
  String get taskFieldDeadlineHint => 'Chagua tarehe na saa';

  @override
  String get taskFieldDescription => 'Maelezo';

  @override
  String get taskFieldPriority => 'Kipaumbele';

  @override
  String get taskFieldTitle => 'Kichwa';

  @override
  String get taskNotLoadedYet => 'Taarifa za kazi zitaonekana hapa.';

  @override
  String get taskSummaryTitle => 'Taarifa';

  @override
  String get tasksEmptyFilteredTitle =>
      'Hakuna kazi zinazolingana na vichujio hivi';

  @override
  String get tasksEmptyMessage =>
      'Kazi utakazopewa zitaonekana hapa, zikipangwa kwa tarehe ya mwisho.';

  @override
  String get tasksEmptyTitle => 'Huna kazi yoyote';

  @override
  String get teamTasksEmptyTitle => 'Timu yako haina kazi yoyote';

  @override
  String get teamTasksTitle => 'Kazi za timu';

  @override
  String get templateDetailTitle => 'Kiolezo cha mtiririko wa kazi';

  @override
  String get templateStepsEmpty => 'Bado hakuna hatua';

  @override
  String get templateStepsTitle => 'Hatua';

  @override
  String get templatesEmptyMessage =>
      'Tengeneza kiolezo, kama ombi la ununuzi, ili kazi zipite moja kwa moja kutoka kwa mtu mmoja hadi mwingine.';

  @override
  String get templatesEmptyTitle => 'Bado hakuna violezo vya mtiririko wa kazi';

  @override
  String get useEmailInstead => 'Hupati SMS? Ingia kwa barua pepe';

  @override
  String get userDetailsSection => 'Taarifa';

  @override
  String get userFieldConfidentialAccess => 'Ruhusa ya kazi za siri';

  @override
  String get userFieldDepartment => 'Idara';

  @override
  String get userFieldName => 'Jina';

  @override
  String get userFieldRole => 'Cheo';

  @override
  String get userFieldSupervisor => 'Msimamizi';

  @override
  String get usersEmptyMessage =>
      'Ongeza watu pamoja na namba zao za simu, idara, cheo na msimamizi.';

  @override
  String get usersEmptyTitle => 'Bado hakuna watu';

  @override
  String get validationAssigneeRequired => 'Chagua angalau mtu mmoja';

  @override
  String get validationCodeSixDigits => 'Weka msimbo wa tarakimu 6';

  @override
  String get validationDeadlineInPast =>
      'Tarehe ya mwisho lazima iwe ya baadaye';

  @override
  String get validationDeadlineRequired => 'Chagua tarehe ya mwisho';

  @override
  String get validationEmailRequired => 'Weka barua pepe yako';

  @override
  String get validationPasswordRequired => 'Weka nenosiri lako';

  @override
  String get validationPhoneRequired => 'Weka namba yako ya simu';

  @override
  String get validationPriorityRequired => 'Chagua kipaumbele';

  @override
  String get validationTitleRequired => 'Weka kichwa cha kazi';

  @override
  String get valueNotLoaded => 'Bado haijapakiwa';
}
