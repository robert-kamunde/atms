import 'package:atms/features/dashboards/presentation/dashboard_screen.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  const expectedKeys = {
    UserRole.staff: [
      'dashStaffDueToday',
      'dashStaffDueWeek',
      'dashStaffOverdue',
      'dashStaffCompletion',
    ],
    UserRole.manager: [
      'dashMgrTotals',
      'dashMgrOverdue',
      'dashMgrApprovals',
      'dashMgrWorkload',
      'dashMgrBottleneck',
    ],
    UserRole.admin: [
      'dashAdminDepts',
      'dashAdminSms',
      'dashAdminUsers',
      'dashAdminTemplates',
    ],
  };

  for (final locale in testLocales) {
    final l10n = l10nFor(locale);
    for (final role in UserRole.values) {
      testWidgets('Dashboard for ${role.name} [$locale]', (tester) async {
        await pumpLocalized(
          tester,
          const DashboardScreen(),
          locale: locale,
          overrides: [signedInAs(role)],
        );
        expect(find.text(l10n.dashboardTitle), findsOneWidget);
        final cards = DashboardScreen.cardsFor(role, l10n);
        expect(
          cards.map((c) => (c.key as ValueKey<String>).value),
          expectedKeys[role],
        );
        for (final card in cards) {
          await tester.scrollUntilVisible(find.byKey(card.key), 100);
          expect(find.text(card.title), findsOneWidget);
        }
        // Cards of other roles are not shown.
        for (final other in UserRole.values.where((r) => r != role)) {
          for (final key in expectedKeys[other]!) {
            expect(find.byKey(Key(key)), findsNothing);
          }
        }
        // No numbers are invented.
        expect(find.text(l10n.dashNoDataYet), findsWidgets);
      });
    }
  }
}
