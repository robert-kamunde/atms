import 'package:atms/features/auth/presentation/not_invited_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  for (final locale in testLocales) {
    testWidgets('NotInvitedScreen [$locale]', (tester) async {
      final l10n = l10nFor(locale);
      await pumpLocalized(tester, const NotInvitedScreen(), locale: locale);
      expect(find.text(l10n.notInvitedTitle), findsOneWidget);
      expect(find.text(l10n.notInvitedMessage), findsOneWidget);
      expect(find.text(l10n.notInvitedHelp), findsOneWidget);
      expect(find.text(l10n.actionUseAnotherNumber), findsOneWidget);
    });
  }

  test('English text matches the spec wording', () {
    expect(
      l10nFor(testLocales.first).notInvitedMessage,
      'Ask your administrator to add you.',
    );
  });
}
