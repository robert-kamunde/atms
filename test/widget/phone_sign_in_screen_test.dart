import 'dart:async';

import 'package:atms/features/auth/domain/auth_repository.dart';
import 'package:atms/features/auth/presentation/auth_providers.dart';
import 'package:atms/features/auth/presentation/phone_sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  for (final locale in testLocales) {
    group('PhoneSignInScreen [$locale]', () {
      final l10n = l10nFor(locale);
      late MockAuthRepository repo;

      setUp(() => repo = MockAuthRepository());

      Future<void> pump(WidgetTester tester) => pumpLocalized(
        tester,
        const PhoneSignInScreen(),
        locale: locale,
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );

      testWidgets('shows localized heading, field and button', (tester) async {
        await pump(tester);
        expect(find.text(l10n.signInTitle), findsOneWidget);
        expect(find.text(l10n.phoneSignInHeading), findsOneWidget);
        expect(find.text(l10n.phoneNumberLabel), findsOneWidget);
        expect(find.text(l10n.actionSendCode), findsOneWidget);
        expect(find.text(l10n.useEmailInstead), findsOneWidget);
      });

      testWidgets('empty number shows the required message', (tester) async {
        await pump(tester);
        await tester.tap(find.byKey(const Key('sendCodeButton')));
        await tester.pump();
        expect(find.text(l10n.validationPhoneRequired), findsOneWidget);
        verifyNever(() => repo.startPhoneVerification(any()));
      });

      testWidgets('invalid number shows a friendly message', (tester) async {
        await pump(tester);
        await tester.enterText(find.byKey(const Key('phoneField')), '12345');
        await tester.tap(find.byKey(const Key('sendCodeButton')));
        await tester.pump();
        expect(find.text(l10n.errorInvalidPhone), findsOneWidget);
        verifyNever(() => repo.startPhoneVerification(any()));
      });

      testWidgets('valid number is sent in E.164 format', (tester) async {
        when(() => repo.startPhoneVerification(any()))
            .thenAnswer((_) => Completer<PhoneVerificationResult>().future);
        await pump(tester);
        await tester.enterText(
          find.byKey(const Key('phoneField')),
          '0712 345 678',
        );
        await tester.tap(find.byKey(const Key('sendCodeButton')));
        await tester.pump();
        verify(() => repo.startPhoneVerification('+255712345678')).called(1);
      });
    });
  }
}
