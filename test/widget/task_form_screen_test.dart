import 'package:atms/features/tasks/presentation/task_form_screen.dart';
import 'package:atms/shared/models/task_priority.dart';
import 'package:atms/shared/widgets/enum_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  for (final locale in testLocales) {
    group('TaskFormScreen [$locale]', () {
      final l10n = l10nFor(locale);

      Future<void> tapSave(WidgetTester tester) async {
        await tester.ensureVisible(find.byKey(const Key('taskSaveButton')));
        await tester.tap(find.byKey(const Key('taskSaveButton')));
        await tester.pumpAndSettle();
      }

      testWidgets('shows required and optional fields', (tester) async {
        await pumpLocalized(tester, const TaskFormScreen(), locale: locale);
        expect(find.text(l10n.taskCreateTitle), findsOneWidget);
        expect(find.text(l10n.taskFieldTitle), findsOneWidget);
        expect(find.text(l10n.taskFieldDeadline), findsOneWidget);
        expect(find.text(l10n.taskFieldPriority), findsOneWidget);
        expect(find.text(l10n.taskFieldAssignee), findsOneWidget);
        expect(find.text(l10n.taskFieldDescription), findsOneWidget);
        expect(find.text(l10n.optionalFieldHint), findsOneWidget);
      });

      testWidgets('saving empty form shows every required message', (
        tester,
      ) async {
        await pumpLocalized(tester, const TaskFormScreen(), locale: locale);
        await tapSave(tester);
        expect(find.text(l10n.validationTitleRequired), findsOneWidget);
        expect(find.text(l10n.validationDeadlineRequired), findsOneWidget);
        expect(find.text(l10n.validationPriorityRequired), findsOneWidget);
        expect(find.text(l10n.validationAssigneeRequired), findsOneWidget);
      });

      testWidgets('filled fields clear their messages; description optional', (
        tester,
      ) async {
        await pumpLocalized(tester, const TaskFormScreen(), locale: locale);
        await tester.enterText(
          find.byKey(const Key('taskTitleField')),
          'Monthly report',
        );
        await tester.tap(find.byKey(const Key('taskPriorityField')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(TaskPriority.high.label(l10n)).last);
        await tester.pumpAndSettle();
        await tapSave(tester);
        expect(find.text(l10n.validationTitleRequired), findsNothing);
        expect(find.text(l10n.validationPriorityRequired), findsNothing);
        expect(find.text(l10n.validationDeadlineRequired), findsOneWidget);
        expect(find.text(l10n.validationAssigneeRequired), findsOneWidget);
      });

      testWidgets('edit mode uses the edit title', (tester) async {
        await pumpLocalized(
          tester,
          const TaskFormScreen(taskId: 't1'),
          locale: locale,
        );
        expect(find.text(l10n.taskEditTitle), findsOneWidget);
      });
    });
  }
}
