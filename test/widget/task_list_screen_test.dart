import 'package:atms/features/tasks/presentation/task_list_screen.dart';
import 'package:atms/shared/models/task_status.dart';
import 'package:atms/shared/widgets/enum_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  for (final locale in testLocales) {
    group('TaskListScreen [$locale]', () {
      final l10n = l10nFor(locale);

      testWidgets('shows empty state, filter chips and New task', (
        tester,
      ) async {
        await pumpLocalized(tester, const TaskListScreen(), locale: locale);
        expect(find.text(l10n.myTasksTitle), findsOneWidget);
        expect(find.byKey(const Key('taskListEmpty')), findsOneWidget);
        expect(find.text(l10n.tasksEmptyTitle), findsOneWidget);
        for (final label in [
          l10n.filterStatus,
          l10n.filterPriority,
          l10n.filterAssignee,
          l10n.filterDepartment,
          l10n.filterDueDate,
        ]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
        expect(find.text(l10n.actionNewTask), findsOneWidget);
      });

      testWidgets('choosing a status filter shows the filtered empty state', (
        tester,
      ) async {
        await pumpLocalized(tester, const TaskListScreen(), locale: locale);
        await tester.tap(find.byKey(const Key('filterStatus')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(TaskStatus.blocked.label(l10n)));
        await tester.pumpAndSettle();
        expect(find.text(l10n.tasksEmptyFilteredTitle), findsOneWidget);
        expect(find.text(TaskStatus.blocked.label(l10n)), findsOneWidget);
      });

      testWidgets('team variant uses the team title', (tester) async {
        await pumpLocalized(
          tester,
          const TaskListScreen(team: true),
          locale: locale,
        );
        expect(find.text(l10n.teamTasksTitle), findsOneWidget);
        expect(find.text(l10n.teamTasksEmptyTitle), findsOneWidget);
      });
    });
  }
}
