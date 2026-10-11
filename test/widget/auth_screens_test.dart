import 'package:atms/core/config/firebase_providers.dart';
import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/core/errors/failure_messages.dart';
import 'package:atms/core/errors/server_error_code.dart';
import 'package:atms/core/localization/locale_provider.dart';
import 'package:atms/features/auth/domain/admin_verification_repository.dart';
import 'package:atms/features/auth/domain/auth_state.dart';
import 'package:atms/features/auth/domain/session_policy.dart';
import 'package:atms/features/auth/presentation/admin_verify_screen.dart';
import 'package:atms/features/auth/presentation/auth_providers.dart';
import 'package:atms/features/auth/presentation/code_entry_screen.dart';
import 'package:atms/features/auth/presentation/email_sign_in_screen.dart';
import 'package:atms/features/auth/presentation/loading_screen.dart';
import 'package:atms/features/auth/presentation/not_invited_screen.dart';
import 'package:atms/features/auth/presentation/onboarding/onboarding_consent_screen.dart';
import 'package:atms/features/auth/presentation/onboarding/onboarding_language_screen.dart';
import 'package:atms/features/auth/presentation/onboarding/onboarding_notifications_screen.dart';
import 'package:atms/features/auth/presentation/setup_missing_screen.dart';
import 'package:atms/features/users/presentation/more_screen.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

class _MockAdminVerification extends Mock
    implements AdminVerificationRepository {}

void main() {
  for (final locale in testLocales) {
    final l10n = l10nFor(locale);

    group('CodeEntryScreen [$locale]', () {
      late MockAuthRepository repo;

      setUp(() => repo = MockAuthRepository());

      Future<void> pump(WidgetTester tester) => pumpLocalized(
        tester,
        const CodeEntryScreen(),
        locale: locale,
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(() => testNow),
          phoneSignInControllerProvider.overrideWithBuild(
            (ref, notifier) => PendingPhoneVerification(
              phoneNumber: '+255712345678',
              verificationId: 'v1',
              sentAt: testNow,
            ),
          ),
        ],
      );

      testWidgets('resend unlocks after the countdown', (tester) async {
        await pump(tester);
        expect(find.text(l10n.codeEntryHelp('+255712345678')), findsOneWidget);
        expect(find.text(l10n.resendCodeIn(60)), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(find.byKey(const Key('resendCodeButton')))
              .onPressed,
          isNull,
        );
        await tester.pump(const Duration(seconds: 60));
        expect(find.text(l10n.actionResendCode), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(find.byKey(const Key('resendCodeButton')))
              .onPressed,
          isNotNull,
        );
      });

      testWidgets('a short code is refused before calling Firebase', (
        tester,
      ) async {
        await pump(tester);
        await tester.enterText(find.byKey(const Key('codeField')), '123');
        await tester.tap(find.byKey(const Key('verifyCodeButton')));
        await tester.pump();
        expect(find.text(l10n.validationCodeSixDigits), findsOneWidget);
        verifyNever(
          () => repo.confirmSmsCode(
            verificationId: any(named: 'verificationId'),
            smsCode: any(named: 'smsCode'),
          ),
        );
      });

      testWidgets('a wrong code shows a friendly message', (tester) async {
        when(() => repo.confirmSmsCode(verificationId: 'v1', smsCode: '123456'))
            .thenThrow(const ValidationFailure(ValidationReason.invalidCode));
        await pump(tester);
        await tester.enterText(find.byKey(const Key('codeField')), '123456');
        await tester.tap(find.byKey(const Key('verifyCodeButton')));
        await tester.pump();
        expect(
          find.text(
            failureMessage(
              const ValidationFailure(ValidationReason.invalidCode),
              l10n,
            ),
          ),
          findsOneWidget,
        );
      });
    });

    group('EmailSignInScreen [$locale]', () {
      late FakeAuthRepository repo;

      setUp(() => repo = FakeAuthRepository());

      Future<void> pump(WidgetTester tester, {AuthState? state}) =>
          pumpLocalized(
            tester,
            const EmailSignInScreen(),
            locale: locale,
            overrides: [
              authRepositoryProvider.overrideWithValue(repo),
              authControllerProvider.overrideWith(
                () => RecordingAuthController(state ?? const AuthSignedOut()),
              ),
            ],
          );

      testWidgets('validates the email and password', (tester) async {
        await pump(tester);
        expect(find.text(l10n.emailSignInTitle), findsOneWidget);
        await tester.tap(find.byKey(const Key('emailSignInButton')));
        await tester.pump();
        expect(find.text(l10n.validationEmailRequired), findsOneWidget);
        expect(find.text(l10n.validationPasswordRequired), findsOneWidget);
        await tester.enterText(find.byKey(const Key('emailField')), 'asha@');
        await tester.tap(find.byKey(const Key('emailSignInButton')));
        await tester.pump();
        expect(find.text(l10n.errorInvalidEmail), findsOneWidget);
      });

      testWidgets('forgot password sends the reset email', (tester) async {
        await pump(tester);
        await tester.enterText(
          find.byKey(const Key('emailField')),
          'asha@wizara.go.tz',
        );
        await tester.tap(find.byKey(const Key('forgotPasswordButton')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.forgotPasswordTitle), findsOneWidget);
        await tester.tap(find.byKey(const Key('sendResetButton')));
        await tester.pumpAndSettle();
        expect(repo.resetEmail, 'asha@wizara.go.tz');
        expect(find.text(l10n.passwordResetSent), findsOneWidget);
      });

      testWidgets('explains a session expiry', (tester) async {
        await pump(
          tester,
          state: const AuthSignedOut(reason: SignOutReason.sessionExpired),
        );
        expect(
          find.text(
            l10n.sessionExpiredMessage(
              SessionPolicy.standardMaxAge.inDays,
              SessionPolicy.adminMaxAge.inDays,
            ),
          ),
          findsOneWidget,
        );
      });
    });

    group('NotInvitedScreen and LoadingScreen [$locale]', () {
      testWidgets('deactivated variant', (tester) async {
        final controller = RecordingAuthController(
          const AuthNotInvited(reason: NotAllowedReason.deactivated),
        );
        await pumpLocalized(
          tester,
          const NotInvitedScreen(),
          locale: locale,
          overrides: [authControllerProvider.overrideWith(() => controller)],
        );
        expect(find.text(l10n.accountInactiveTitle), findsOneWidget);
        expect(find.text(l10n.errorAccountDeactivated), findsOneWidget);
        expect(find.text(l10n.accountInactiveHelp), findsOneWidget);
        await tester.tap(find.text(l10n.actionUseAnotherNumber));
        await tester.pump();
        expect(controller.calls, ['signOut']);
      });

      testWidgets('waiting for a connection', (tester) async {
        await pumpLocalized(
          tester,
          const LoadingScreen(),
          locale: locale,
          overrides: [
            authControllerProvider.overrideWith(
              () => RecordingAuthController(
                const AuthUnknown(waitingForConnection: true),
              ),
            ),
          ],
        );
        expect(find.text(l10n.loadingWaitingForConnection), findsOneWidget);
        expect(find.text(l10n.actionSignOut), findsOneWidget);
      });
    });

    group('Onboarding [$locale]', () {
      const needs = AuthNeedsLanguage(UserRole.staff);

      testWidgets('language: the chosen language is saved', (tester) async {
        final controller = RecordingAuthController(needs);
        await pumpLocalized(
          tester,
          const OnboardingLanguageScreen(),
          locale: locale,
          overrides: [authControllerProvider.overrideWith(() => controller)],
        );
        expect(find.text(l10n.onboardingLanguageTitle), findsOneWidget);
        await tester.tap(find.text(l10n.languageSwahili));
        await tester.pump();
        await tester.tap(find.byKey(const Key('languageContinueButton')));
        await tester.pump();
        expect(controller.calls, [
          'language:${AppLocales.swahili.languageCode}',
        ]);
      });

      testWidgets('language: a refused write is shown', (tester) async {
        final controller = RecordingAuthController(
          needs,
          failure: const PermissionDeniedFailure(),
        );
        await pumpLocalized(
          tester,
          const OnboardingLanguageScreen(),
          locale: locale,
          overrides: [authControllerProvider.overrideWith(() => controller)],
        );
        await tester.tap(find.byKey(const Key('languageContinueButton')));
        await tester.pump();
        expect(
          find.text(failureMessage(const PermissionDeniedFailure(), l10n)),
          findsOneWidget,
        );
      });

      testWidgets('consent: accept needs the checkbox', (tester) async {
        final controller = RecordingAuthController(
          const AuthNeedsConsent(UserRole.staff),
        );
        await pumpLocalized(
          tester,
          const OnboardingConsentScreen(),
          locale: locale,
          overrides: [authControllerProvider.overrideWith(() => controller)],
        );
        expect(find.text(l10n.consentTitle), findsOneWidget);
        final accept = find.byKey(const Key('consentAcceptButton'));
        expect(tester.widget<FilledButton>(accept).onPressed, isNull);
        await tester.tap(find.byKey(const Key('consentCheckbox')));
        await tester.pump();
        await tester.tap(accept);
        await tester.pump();
        expect(controller.calls, ['consent']);
      });

      testWidgets('notifications: allow or not now', (tester) async {
        final controller = RecordingAuthController(
          const AuthNeedsNotificationPermission(UserRole.staff),
        );
        await pumpLocalized(
          tester,
          const OnboardingNotificationsScreen(),
          locale: locale,
          overrides: [authControllerProvider.overrideWith(() => controller)],
        );
        expect(find.text(l10n.onboardingNotificationsHelp), findsOneWidget);
        await tester.tap(find.byKey(const Key('notNowButton')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('allowNotificationsButton')));
        await tester.pump();
        expect(controller.calls, ['notifications:false', 'notifications:true']);
      });
    });

    group('AdminVerifyScreen [$locale]', () {
      late _MockAdminVerification repo;
      late RecordingAuthController controller;
      final expiresAt = testNow.add(const Duration(minutes: 10));

      setUp(() {
        repo = _MockAdminVerification();
        controller = RecordingAuthController(
          const AuthSignedIn(UserRole.admin),
          afterAdminVerify: AuthSignedIn(
            UserRole.admin,
            adminVerifiedUntil: testNow.add(const Duration(hours: 12)),
          ),
        );
        when(repo.sendAdminCode).thenAnswer(
          (_) async =>
              AdminCodeSent(maskedEmail: 'i***@org.tz', expiresAt: expiresAt),
        );
      });

      Future<void> pump(WidgetTester tester) => pumpLocalizedRouter(
        tester,
        const AdminVerifyScreen(returnTo: '/admin/users'),
        locale: locale,
        otherPaths: ['/admin/users', '/more'],
        overrides: [
          adminVerificationRepositoryProvider.overrideWithValue(repo),
          authControllerProvider.overrideWith(() => controller),
          clockProvider.overrideWithValue(() => testNow),
        ],
      );

      testWidgets('send, verify, then back to the admin screen', (
        tester,
      ) async {
        when(() => repo.verifyAdminCode('123456'))
            .thenAnswer((_) async => testNow.add(const Duration(hours: 12)));
        await pump(tester);
        expect(find.text(l10n.adminVerifyHelp), findsOneWidget);
        await tester.tap(find.byKey(const Key('sendAdminCodeButton')));
        await tester.pump();
        expect(
          find.text(
            l10n.adminCodeSentTo('i***@org.tz', formatClockTime(expiresAt)),
          ),
          findsOneWidget,
        );
        expect(find.text(l10n.resendCodeIn(60)), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('adminCodeField')),
          '123456',
        );
        await tester.tap(find.byKey(const Key('verifyAdminCodeButton')));
        await tester.pumpAndSettle();
        expect(controller.calls, ['adminVerified']);
        expect(find.text(stubPage('/admin/users')), findsOneWidget);
      });

      testWidgets('a wrong code shows the attempts left', (tester) async {
        final failure = ServerFailure(
          ServerErrorCode.codeInvalid,
          attemptsLeft: 2,
        );
        when(() => repo.verifyAdminCode('000000')).thenThrow(failure);
        await pump(tester);
        await tester.tap(find.byKey(const Key('sendAdminCodeButton')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('adminCodeField')),
          '000000',
        );
        await tester.tap(find.byKey(const Key('verifyAdminCodeButton')));
        await tester.pump();
        expect(find.text(l10n.errorAdminCodeWrongAttempts(2)), findsOneWidget);
        expect(controller.calls, isEmpty);
        // The countdown timer must not outlive the test.
        await tester.pump(const Duration(seconds: 60));
      });
    });

    testWidgets('SetupMissingScreen [$locale] has no developer preview', (
      tester,
    ) async {
      await pumpLocalized(tester, const SetupMissingScreen(), locale: locale);
      expect(find.text(l10n.setupMissingTitle), findsOneWidget);
      expect(find.text(l10n.setupMissingMessage), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    group('MoreScreen [$locale]', () {
      final admin = userFixture(
        id: 'admin',
        name: 'Imani',
        role: UserRole.admin,
      );

      testWidgets('profile, admin links and language change', (tester) async {
        final controller = RecordingAuthController(
          AuthSignedIn(
            UserRole.admin,
            adminVerifiedUntil: farFuture,
            session: UserSession(
              uid: admin.id,
              orgId: testOrg,
              claims: claimsFor(),
              user: admin,
            ),
          ),
        );
        await pumpLocalized(
          tester,
          const MoreScreen(),
          locale: locale,
          overrides: [authControllerProvider.overrideWith(() => controller)],
        );
        expect(find.text('Imani'), findsOneWidget);
        expect(find.text(l10n.adminSection), findsOneWidget);
        expect(find.text(l10n.adminDepartmentsTitle), findsOneWidget);
        await tester.tap(find.text(l10n.languageSwahili));
        await tester.pump();
        expect(controller.calls, ['changeLanguage:sw']);
      });

      testWidgets('staff see no admin area', (tester) async {
        await pumpLocalized(
          tester,
          const MoreScreen(),
          locale: locale,
          overrides: [
            authControllerProvider.overrideWith(
              () => RecordingAuthController(const AuthSignedIn(UserRole.staff)),
            ),
          ],
        );
        expect(find.text(l10n.adminSection), findsNothing);
        expect(find.text(l10n.actionSignOut), findsOneWidget);
      });
    });
  }
}
