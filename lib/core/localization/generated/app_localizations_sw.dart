// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get accountInactiveHelp =>
      'Ikiwa unadhani hili ni kosa, wasiliana na msimamizi wako.';

  @override
  String get accountInactiveTitle => 'Akaunti haitumiki';

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
  String get actionCancel => 'Ghairi';

  @override
  String get actionCancelTask => 'Sitisha kazi';

  @override
  String get actionClear => 'Ondoa';

  @override
  String get actionClose => 'Funga';

  @override
  String get actionConfirmDone => 'Thibitisha imekamilika';

  @override
  String get actionContinue => 'Endelea';

  @override
  String get actionContinueAnyway => 'Ndiyo, endelea';

  @override
  String get actionDeactivate => 'Simamisha';

  @override
  String get actionDeactivateUser => 'Simamisha mtu';

  @override
  String get actionDelete => 'Futa';

  @override
  String get actionEdit => 'Hariri';

  @override
  String get actionEditAndResend => 'Hariri na utume tena';

  @override
  String get actionForgotPassword => 'Umesahau nenosiri?';

  @override
  String get actionGoToTasks => 'Nenda kwenye kazi zangu';

  @override
  String get actionHidePassword => 'Ficha nenosiri';

  @override
  String get actionHideReports => 'Ficha walio chini yake';

  @override
  String get actionLoadMore => 'Pakia zaidi';

  @override
  String get actionMarkBlocked => 'Weka imekwama';

  @override
  String get actionMarkDone => 'Weka imekamilika';

  @override
  String get actionMoreOptions => 'Chaguo zaidi';

  @override
  String get actionMyPartDone => 'Nimemaliza';

  @override
  String get actionNewTask => 'Kazi mpya';

  @override
  String get actionNewTemplate => 'Kiolezo kipya';

  @override
  String get actionNotNow => 'Si sasa';

  @override
  String get actionReassign => 'Mpangie mwingine';

  @override
  String get actionRemove => 'Ondoa';

  @override
  String get actionResendCode => 'Tuma msimbo tena';

  @override
  String get actionResumeTask => 'Endelea';

  @override
  String get actionRetry => 'Jaribu tena';

  @override
  String get actionReturnWork => 'Rudisha kwa marekebisho';

  @override
  String get actionSave => 'Hifadhi';

  @override
  String get actionSendAdminCode => 'Nitumie msimbo kwa barua pepe';

  @override
  String get actionSendCode => 'Tuma msimbo';

  @override
  String get actionSendForCheck => 'Tuma ikaguliwe';

  @override
  String get actionSendResetLink => 'Tuma kiungo';

  @override
  String get actionShowPassword => 'Onyesha nenosiri';

  @override
  String get actionShowReports => 'Onyesha walio chini yake';

  @override
  String get actionSignIn => 'Ingia';

  @override
  String get actionSignOut => 'Ondoka';

  @override
  String get actionStartTask => 'Anza';

  @override
  String get actionUseAnotherNumber => 'Tumia namba nyingine';

  @override
  String get actionVerify => 'Thibitisha';

  @override
  String get activityAssigned => 'Kazi ilipangiwa watu';

  @override
  String activityCancelled(String actor, String reason) {
    return '$actor alisitisha kazi: $reason';
  }

  @override
  String activityCancelledNoReason(String actor) {
    return '$actor alisitisha kazi';
  }

  @override
  String activityCompletedBy(String actor) {
    return '$actor alimaliza sehemu yake';
  }

  @override
  String activityCreated(String actor) {
    return '$actor aliunda kazi';
  }

  @override
  String activityDeadlineChanged(String actor, String from, String to) {
    return '$actor alibadilisha tarehe ya mwisho kutoka $from hadi $to';
  }

  @override
  String activityDeadlineSet(String actor) {
    return '$actor alibadilisha tarehe ya mwisho';
  }

  @override
  String activityDeleted(String actor) {
    return '$actor alifuta kazi';
  }

  @override
  String activityEdited(String actor, String fields) {
    return '$actor alibadilisha: $fields';
  }

  @override
  String get activityEmpty => 'Bado hakuna shughuli';

  @override
  String activityGeneric(String actor) {
    return '$actor alifanya mabadiliko';
  }

  @override
  String get activityMadeOffline => 'Ilifanywa bila intaneti';

  @override
  String activityPriorityValue(String priority) {
    return 'Kipaumbele ($priority)';
  }

  @override
  String activityReassigned(String actor, String names) {
    return '$actor aliipangia kazi $names';
  }

  @override
  String activityReassignedNoNames(String actor) {
    return '$actor aliipangia kazi watu wengine';
  }

  @override
  String activityRejected(String reason) {
    return 'Kazi haikuweza kupangiwa: $reason';
  }

  @override
  String activityReturned(String actor, String reason) {
    return '$actor alirudisha kazi kwa marekebisho: $reason';
  }

  @override
  String activityReturnedNoReason(String actor) {
    return '$actor alirudisha kazi kwa marekebisho';
  }

  @override
  String activityStatusChanged(String actor, String from, String to) {
    return '$actor alibadilisha hali kutoka $from hadi $to';
  }

  @override
  String activityStatusSet(String actor, String to) {
    return '$actor alibadilisha hali kuwa $to';
  }

  @override
  String get activitySystemActor => 'ATMS';

  @override
  String get activityTitle => 'Shughuli';

  @override
  String activityUserAdded(String actor) {
    return '$actor aliongeza mtu';
  }

  @override
  String activityUserDeactivated(String actor) {
    return '$actor alimzima mtu';
  }

  @override
  String activityUserUpdated(String actor) {
    return '$actor alibadilisha taarifa za mtu';
  }

  @override
  String get adminAuditTitle => 'Kumbukumbu za ukaguzi';

  @override
  String adminCodeSentTo(String email, String time) {
    return 'Tumetuma msimbo wa tarakimu 6 kwa $email. Unatumika hadi saa $time.';
  }

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
  String adminVerifiedUntil(String time) {
    return 'Umethibitishwa hadi saa $time.';
  }

  @override
  String get adminVerifyHelp =>
      'Kwa usalama zaidi, wasimamizi wa mfumo lazima pia waweke msimbo wa tarakimu 6 uliotumwa kwenye barua pepe yao.';

  @override
  String get adminVerifySuccess => 'Uthibitisho wa msimamizi umekamilika.';

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
  String get assignedSectionTitle => 'Nilizopangiwa';

  @override
  String assigneeMe(String name) {
    return '$name (mimi)';
  }

  @override
  String assigneePickerDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chagua watu $count',
      one: 'Chagua mtu 1',
      zero: 'Chagua watu',
    );
    return '$_temp0';
  }

  @override
  String get assigneePickerEmpty => 'Bado hakuna watu wa kuchagua';

  @override
  String get assigneesChangeWithReassign =>
      'Ili kubadilisha anayefanya kazi, tumia \'Mpangie mwingine\' kwenye kazi.';

  @override
  String get assignmentPendingLabel => 'Inasubiri kupangiwa';

  @override
  String get assignmentPendingMessage =>
      'Ni wewe tu unayeona kazi hii hadi ipangiwe. Itapangiwa simu hii ikiwa mtandaoni.';

  @override
  String get assignmentRejectedGeneric =>
      'Watu uliowachagua hawakuweza kupangiwa.';

  @override
  String get assignmentRejectedLabel => 'Haijapangiwa';

  @override
  String assignmentRejectedMessage(String reason) {
    return 'Kazi hii haikupangiwa: $reason Ihariri uitume tena, au uifute.';
  }

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
  String get awaitingCheckAssigneeMessage =>
      'Imekamilika. Inasubiri aliyeunda akague kazi.';

  @override
  String get awaitingCheckCreatorMessage =>
      'Kazi imekamilika. Ikague, kisha uthibitishe au uirudishe kwa marekebisho.';

  @override
  String get blockTaskTitle => 'Kwa nini kazi hii imekwama?';

  @override
  String get blockedReasonLabel => 'Imekwama kwa sababu';

  @override
  String get boardColumnEmpty => 'Hakuna kazi';

  @override
  String boardColumnTitle(String status, int count) {
    return '$status ($count)';
  }

  @override
  String get cancelReasonLabel => 'Imesitishwa kwa sababu';

  @override
  String get cancelTaskTitle => 'Kwa nini kazi hii inasitishwa?';

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
  String get codeResent => 'Tumetuma msimbo mpya.';

  @override
  String get commentInputHint => 'Andika maoni';

  @override
  String get commentsEmpty => 'Bado hakuna maoni';

  @override
  String get commentsTitle => 'Maoni';

  @override
  String get completionModeAll => 'Imekamilika wote wakimaliza';

  @override
  String get completionModeAny => 'Imekamilika mtu yeyote mmoja akimaliza';

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
  String get dayFri => 'Ijm';

  @override
  String get dayMon => 'Jtatu';

  @override
  String get daySat => 'Jmos';

  @override
  String get daySun => 'Jpili';

  @override
  String get dayThu => 'Alh';

  @override
  String get dayTue => 'Jnne';

  @override
  String get dayWed => 'Jtano';

  @override
  String deactivateDepartmentMessage(String name) {
    return '$name haitaonyeshwa tena wakati wa kuongeza watu. Kazi zilizopo zitabaki na idara hii.';
  }

  @override
  String get deactivateDepartmentTitle => 'Simamisha idara?';

  @override
  String deactivateUserMessage(String name) {
    return '$name atatolewa kwenye akaunti ndani ya saa moja na hataweza kuingia tena. Kazi zake zilizo wazi zitawekewa alama ili zipangiwe mtu mwingine.';
  }

  @override
  String get deactivateUserTitle => 'Simamisha mtu huyu?';

  @override
  String get deleteTaskMessage =>
      'Kazi itaondolewa kwenye orodha za kila mtu. Kumbukumbu za ukaguzi zitabaki.';

  @override
  String get deleteTaskTitle => 'Ufute kazi hii?';

  @override
  String get departmentCreateTitle => 'Idara mpya';

  @override
  String get departmentEditTitle => 'Hariri idara';

  @override
  String get departmentFieldHead => 'Mkuu wa idara';

  @override
  String get departmentFieldName => 'Jina la idara';

  @override
  String departmentHead(String name) {
    return 'Mkuu: $name';
  }

  @override
  String get departmentNoHead => 'Hakuna mkuu aliyetajwa';

  @override
  String get departmentsEmptyMessage =>
      'Ongeza idara kama Fedha, Rasilimali Watu au TEHAMA, na umtaje mkuu wa kila moja.';

  @override
  String get departmentsEmptyTitle => 'Bado hakuna idara';

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
  String get errorAccountDeactivated =>
      'Akaunti yako haitumiki kwa sasa. Muulize msimamizi wako.';

  @override
  String get errorAdminCodeExpired =>
      'Msimbo huo umeisha muda wake. Omba msimbo mpya.';

  @override
  String get errorAdminCodeTooManyAttempts =>
      'Umekosea msimbo mara nyingi mno. Omba msimbo mpya.';

  @override
  String get errorAdminCodeWrong =>
      'Msimbo huo si sahihi. Angalia barua pepe yako na ujaribu tena.';

  @override
  String errorAdminCodeWrongAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Msimbo huo si sahihi. Zimebaki nafasi $count.',
      one: 'Msimbo huo si sahihi. Imebaki nafasi 1.',
      zero: 'Msimbo huo si sahihi. Omba msimbo mpya.',
    );
    return '$_temp0';
  }

  @override
  String get errorAdminEmailMissing =>
      'Akaunti yako haina barua pepe ya kupokea msimbo wa msimamizi. Muombe msimamizi mwingine aiongeze.';

  @override
  String get errorAdminVerificationRequired =>
      'Tafadhali thibitisha tena msimbo wako wa msimamizi.';

  @override
  String get errorAssigneeInactive =>
      'Mmoja wa watu uliowachagua hatumiki tena. Chagua mtu mwingine.';

  @override
  String get errorAssigneeNotAllowed =>
      'Huwezi kumpangia kazi mmoja wa watu uliowachagua. Chagua watu wa timu yako.';

  @override
  String get errorConflict =>
      'Mtu mwingine amebadilisha hiki kwanza. Tafadhali angalia toleo la sasa.';

  @override
  String errorConflictAlreadyApproved(String name, String time) {
    return 'Hatua hii tayari imeidhinishwa na $name saa $time.';
  }

  @override
  String get errorConnectionRequired =>
      'Hii inahitaji intaneti. Unganisha kisha ujaribu tena.';

  @override
  String get errorDepartmentInvalid =>
      'Idara uliyochagua haipo au haitumiki. Chagua idara nyingine.';

  @override
  String get errorEmailCannotBeRemoved =>
      'Barua pepe haiwezi kuondolewa ikishawekwa. Weka barua pepe mpya badala yake.';

  @override
  String get errorEmailInUse =>
      'Barua pepe hii tayari inatumiwa na mtu mwingine.';

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
  String get errorLastAdmin =>
      'Huyu ndiye msimamizi wa mwisho anayefanya kazi. Ongeza msimamizi mwingine kwanza.';

  @override
  String get errorNetwork =>
      'Hakuna mtandao. Mabadiliko yako yamehifadhiwa kwenye simu hii; jaribu tena ukiwa mtandaoni.';

  @override
  String get errorNotFound => 'Kipengele hiki hakijapatikana.';

  @override
  String get errorNotInvited => 'Mwombe msimamizi wa mfumo akuongeze.';

  @override
  String get errorPermissionDenied => 'Huna ruhusa ya kufanya hili.';

  @override
  String get errorPhoneInUse =>
      'Namba hii ya simu tayari inatumiwa na mtu mwingine.';

  @override
  String get errorProviderUnavailable =>
      'Huduma ya ujumbe haipatikani kwa sasa. Tafadhali jaribu tena baadaye.';

  @override
  String get errorRateLimited =>
      'Umeomba misimbo mingi mno. Tafadhali subiri kisha ujaribu tena baadaye.';

  @override
  String get errorReportingLoop =>
      'Msimamizi huyu angesababisha mzunguko katika mfumo wa uwajibikaji. Chagua mtu mwingine.';

  @override
  String get errorSelfDeactivation =>
      'Huwezi kusimamisha akaunti yako mwenyewe.';

  @override
  String get errorSelfDemotion =>
      'Huwezi kuondoa jukumu lako mwenyewe la msimamizi.';

  @override
  String get errorSessionExpired => 'Kwa usalama wako, tafadhali ingia tena.';

  @override
  String get errorSmsCapReached => 'Kikomo cha SMS cha mwezi kimefikiwa.';

  @override
  String get errorSupervisorInvalid =>
      'Msimamizi uliyemchagua si mtu anayetumika katika taasisi hii. Chagua mtu mwingine.';

  @override
  String get errorTaskClosed => 'Kazi hii tayari imekamilika au imesitishwa.';

  @override
  String get errorTooManyAttempts =>
      'Umejaribu mara nyingi mno. Tafadhali subiri dakika chache kisha ujaribu tena.';

  @override
  String get errorTopPersonRequiresSupervisor =>
      'Badiliko hili haliwezekani kwa mtu wa juu kabisa wa taasisi. Angalia mfumo wa uwajibikaji kisha ujaribu tena.';

  @override
  String get errorTreeBusy =>
      'Mfumo wa uwajibikaji unasasishwa. Tafadhali jaribu tena baada ya muda mfupi.';

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
  String get filterLoadedOnlyNote =>
      'Baadhi ya vichujio vinaangalia kazi zilizopakiwa tu. Pakia zaidi kuona zaidi.';

  @override
  String get filterNoOptionsYet => 'Bado hakuna machaguo';

  @override
  String get filterPriority => 'Kipaumbele';

  @override
  String get filterStatus => 'Hali';

  @override
  String get forgotPasswordHelp =>
      'Weka barua pepe yako. Ikiwa ni ya akaunti ya ATMS, tutatuma kiungo cha kuweka nenosiri jipya. Akaunti mpya hutumia njia hii kuweka nenosiri la kwanza.';

  @override
  String get forgotPasswordTitle => 'Weka nenosiri jipya';

  @override
  String get labelInactive => 'Haitumiki';

  @override
  String get labelNo => 'Hapana';

  @override
  String get labelSupervisorInactive => 'Msimamizi hatumiki';

  @override
  String get labelYes => 'Ndiyo';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSection => 'Lugha';

  @override
  String get languageSwahili => 'Kiswahili';

  @override
  String get loadingMessage => 'Tunaandaa akaunti yako...';

  @override
  String get loadingWaitingForConnection =>
      'Inasubiri intaneti ili kupakia akaunti yako...';

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
  String get needsConnectionNote => 'Hii inahitaji intaneti.';

  @override
  String get noChangesMessage => 'Hakuna mabadiliko ya kuhifadhi';

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
  String offlineChangeRefused(String reason) {
    return 'Badiliko lililohifadhiwa bila intaneti halikukubaliwa: $reason';
  }

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
  String get passwordResetSent =>
      'Ikiwa barua pepe hii ina akaunti, kiungo cha kuweka nenosiri jipya kimetumwa. Angalia sanduku lako la barua.';

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
  String get progressFinished => 'Amemaliza';

  @override
  String get progressNotFinished => 'Bado hajamaliza';

  @override
  String get reasonFieldLabel => 'Sababu';

  @override
  String get reassignTitle => 'Mpangie';

  @override
  String get reassignedMessage => 'Kazi imepangiwa watu wengine';

  @override
  String get reassignmentNeededLabel => 'Inahitaji mtu mwingine';

  @override
  String get reassignmentNeededMessage =>
      'Mtu mmoja kwenye kazi hii amezimwa. Mpangie mtu mwingine.';

  @override
  String get reassignmentReasonLabel => 'Sababu ya kupangiwa upya';

  @override
  String get reportingTreeEmptyMessage =>
      'Weka msimamizi wa kila mtu ili kujenga mfumo wa uwajibikaji unaotumika kupandisha kazi.';

  @override
  String get reportingTreeEmptyTitle => 'Bado hakuna mfumo wa uwajibikaji';

  @override
  String get reportingTreeHelp =>
      'Gusa mtu ili kuona wanaoripoti kwake. Bonyeza na ushikilie ili kufungua taarifa zake.';

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
  String resendCodeIn(int seconds) {
    return 'Tuma msimbo tena baada ya sekunde $seconds';
  }

  @override
  String get returnReasonLabel => 'Imerudishwa kwa marekebisho kwa sababu';

  @override
  String get returnWorkTitle => 'Nini kinahitaji kubadilishwa?';

  @override
  String get roleAdmin => 'Msimamizi wa mfumo';

  @override
  String get roleManager => 'Meneja';

  @override
  String get roleStaff => 'Mtumishi';

  @override
  String get savedMessage => 'Imehifadhiwa';

  @override
  String get savedOnPhoneMessage =>
      'Imehifadhiwa kwenye simu hii. Itatumwa utakapopata intaneti tena.';

  @override
  String get searchByName => 'Tafuta kwa jina';

  @override
  String get searchLoadedOnlyNote =>
      'Utafutaji unahusu watu waliopakiwa hadi sasa. Pakia zaidi ili kutafuta zaidi.';

  @override
  String sessionExpiredMessage(int staffDays, int adminDays) {
    return 'Kwa usalama wako umetolewa kwenye akaunti. Muda wa kuingia ni siku $staffDays (siku $adminDays kwa wasimamizi). Tafadhali ingia tena.';
  }

  @override
  String get settingEscalationDelay => 'Muda kabla ya kupandisha kazi';

  @override
  String get settingEscalationDelayHelp =>
      'Saa baada ya muda wa mwisho kabla msimamizi hajajulishwa';

  @override
  String get settingEscalationLevels => 'Ngazi za upandishaji';

  @override
  String get settingEscalationLevelsHelp =>
      'Kazi iliyochelewa hupanda ngazi ngapi katika mfumo wa uwajibikaji';

  @override
  String get settingReminderHoursHelp =>
      'Saa kabla ya muda wa mwisho, zikitenganishwa kwa koma, mfano 24, 1';

  @override
  String get settingReminderTimes => 'Nyakati za vikumbusho';

  @override
  String get settingRemindersSection => 'Vikumbusho na upandishaji';

  @override
  String get settingSmsCap => 'Kikomo cha SMS kwa mwezi';

  @override
  String get settingSmsCapHelp =>
      'Kiwango cha juu cha matumizi ya SMS kwa mwezi, kwa shilingi za Tanzania (TZS).';

  @override
  String get settingSmsEnabled => 'Tuma SMS';

  @override
  String get settingSmsEnabledHelp =>
      'Taarifa kwa SMS, mfano arifa ya simu isipofunguliwa.';

  @override
  String get settingSmsSection => 'SMS';

  @override
  String get settingTimeZone => 'Saa za eneo';

  @override
  String get settingWorkEnd => 'Kazi inaisha';

  @override
  String get settingWorkStart => 'Kazi inaanza';

  @override
  String get settingWorkingDays => 'Siku za kazi';

  @override
  String get settingWorkingHours => 'Saa za kazi';

  @override
  String get settingWorkingHoursEnabled => 'Hesabu saa za kazi tu';

  @override
  String get settingWorkingHoursEnabledHelp =>
      'Ikiwashwa, muda wa mwisho na upandishaji huhesabu saa za kazi katika siku za kazi tu.';

  @override
  String get setupMissingMessage =>
      'Nakala hii ya programu imetengenezwa bila mipangilio ya seva, kwa hiyo haiwezi kuunganishwa. Tafadhali sakinisha toleo lililotolewa na taasisi yako.';

  @override
  String get setupMissingTitle => 'Programu haijasanidiwa';

  @override
  String get showAsBoard => 'Onyesha kama ubao';

  @override
  String get showAsList => 'Onyesha kama orodha';

  @override
  String get signInNeedsConnection => 'Kuingia kunahitaji intaneti.';

  @override
  String get signInTitle => 'Ingia';

  @override
  String get startWorkflowEmptyMessage =>
      'Msimamizi wa mfumo bado hajachapisha violezo vya mtiririko wa kazi.';

  @override
  String get startWorkflowTitle => 'Anzisha mtiririko wa kazi';

  @override
  String get statusAwaitingCheck => 'Inasubiri ukaguzi';

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
  String get taskActionsTitle => 'Hatua inayofuata';

  @override
  String get taskCannotEditMessage => 'Kazi hii haiwezi kuhaririwa sasa.';

  @override
  String get taskCreateTitle => 'Kazi mpya';

  @override
  String get taskDetailTitle => 'Kazi';

  @override
  String taskDueAt(String date) {
    return 'Mwisho $date';
  }

  @override
  String get taskEditTitle => 'Hariri kazi';

  @override
  String get taskFieldAssignee => 'Amepewa';

  @override
  String get taskFieldAssigneeHint => 'Chagua watu';

  @override
  String get taskFieldCompletionMode => 'Kwa watu kadhaa';

  @override
  String get taskFieldCreator => 'Imeundwa na';

  @override
  String get taskFieldDeadline => 'Tarehe ya mwisho';

  @override
  String get taskFieldDeadlineHint => 'Chagua tarehe na saa';

  @override
  String get taskFieldDepartment => 'Idara';

  @override
  String get taskFieldDescription => 'Maelezo';

  @override
  String get taskFieldNeedsCheck => 'Kagua kazi kabla haijakamilika';

  @override
  String get taskFieldNeedsCheckHelp =>
      'Kazi ikikamilika, utaithibitisha au kuirudisha kwa marekebisho.';

  @override
  String get taskFieldPriority => 'Kipaumbele';

  @override
  String get taskFieldTitle => 'Kichwa';

  @override
  String taskProgress(int done, int total) {
    return '$done kati ya $total wamemaliza';
  }

  @override
  String get taskResubmitTitle => 'Rekebisha na utume tena';

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
  String timeZoneEastAfrica(String zone) {
    return 'Saa za Afrika Mashariki ($zone)';
  }

  @override
  String topPersonWarningMessage(String name) {
    return 'Mtu asiye na msimamizi anakuwa wa juu kabisa wa taasisi. Mtu wa juu wa sasa ataripoti kwa $name. Uendelee?';
  }

  @override
  String get topPersonWarningTitle =>
      'Mfanye mtu huyu kuwa wa juu kabisa wa taasisi?';

  @override
  String get unassignedSectionTitle => 'Nilizounda, bado hazijapangiwa';

  @override
  String get unknownDepartment => 'Idara';

  @override
  String get unknownPerson => 'Mtu fulani';

  @override
  String get useEmailInstead => 'Hupati SMS? Ingia kwa barua pepe';

  @override
  String get userAccessSection => 'Jukumu na uwajibikaji';

  @override
  String get userAddedMessage => 'Mtu ameongezwa.';

  @override
  String get userConfidentialHelp =>
      'Anaweza kuona kazi za siri za idara hizi.';

  @override
  String get userContactHelp =>
      'Namba ya simu au barua pepe inahitajika ili kuingia.';

  @override
  String get userCreateTitle => 'Ongeza mtu';

  @override
  String userDeactivatedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Mtu amesimamishwa. Kazi $count zilizo wazi zimewekewa alama zipangiwe watu wengine.',
      one: 'Mtu amesimamishwa. Kazi 1 iliyo wazi imewekewa alama ipangiwe mtu mwingine.',
      zero: 'Mtu amesimamishwa. Hakuwa na kazi zilizo wazi.',
    );
    return '$_temp0';
  }

  @override
  String get userDetailsSection => 'Taarifa';

  @override
  String get userFieldConfidentialAccess => 'Ruhusa ya kazi za siri';

  @override
  String get userFieldDepartment => 'Idara';

  @override
  String get userFieldJobRole => 'Cheo cha kazi';

  @override
  String get userFieldName => 'Jina';

  @override
  String get userFieldRole => 'Cheo';

  @override
  String get userFieldSupervisor => 'Msimamizi';

  @override
  String get userInviteNote =>
      'Kuhifadhi kunahitaji intaneti. Watu wenye namba ya simu hupata mwaliko kwa SMS.';

  @override
  String get userJobRoleHelp =>
      'Hutumika na hatua za mtiririko zilizopangiwa cheo, mfano Afisa Fedha.';

  @override
  String get userLanguageLabel => 'Lugha ya SMS na programu';

  @override
  String get userNoSupervisor => 'Hakuna (juu kabisa ya taasisi)';

  @override
  String get userTopOfOrganisation => 'Juu kabisa ya taasisi';

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
  String get validationDepartmentRequired => 'Chagua idara';

  @override
  String get validationEmailRequired => 'Weka barua pepe yako';

  @override
  String get validationNameRequired => 'Weka jina';

  @override
  String get validationPasswordRequired => 'Weka nenosiri lako';

  @override
  String get validationPhoneOrEmail => 'Weka namba ya simu au barua pepe';

  @override
  String get validationPhoneRequired => 'Weka namba yako ya simu';

  @override
  String get validationPriorityRequired => 'Chagua kipaumbele';

  @override
  String get validationReasonRequired => 'Andika sababu';

  @override
  String validationReminderHours(int max) {
    return 'Weka idadi kamili ya saa kuanzia 1 hadi $max, zikitenganishwa kwa koma';
  }

  @override
  String get validationTitleRequired => 'Weka kichwa cha kazi';

  @override
  String validationWholeNumberRange(int min, int max) {
    return 'Weka namba kamili kuanzia $min hadi $max';
  }

  @override
  String get validationWorkingDaysRequired =>
      'Chagua angalau siku moja ya kazi';

  @override
  String get valueNotChosen => 'Haijachaguliwa';

  @override
  String get valueNotLoaded => 'Bado haijapakiwa';

  @override
  String get waitingToSyncLabel => 'Inasubiri kusawazishwa';

  @override
  String get waitingToSyncMessage =>
      'Mabadiliko ya kazi hii yamehifadhiwa kwenye simu hii na yatatumwa ukipata intaneti tena.';
}
