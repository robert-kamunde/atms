import 'package:atms/features/tasks/presentation/task_form_screen.dart';
import 'package:atms/shared/models/models.dart';
import 'package:atms/shared/widgets/enum_labels.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';
import '../helpers/task_fixtures.dart';

final _asha = personFixture('asha', 'Asha', chain: ['grace']);
final _baraka = personFixture('baraka', 'Baraka', chain: ['grace']);
final _juma = personFixture('juma', 'Juma');
final _grace = personFixture('grace', 'Grace', role: UserRole.manager);

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await seedPeople(db, [_asha, _baraka, _juma, _grace]);
  });

  Future<List<Map<String, dynamic>>> allTasks() async => [
    for (final d
        in (await db.collection('orgs').doc(testOrg).collection('tasks').get())
            .docs)
      d.data(),
  ];

  for (final locale in testLocales) {
    group('TaskFormScreen [$locale]', () {
      final l10n = l10nFor(locale);

      Future<void> pump(WidgetTester tester, AppUser user, {String? taskId}) =>
          pumpLocalizedRouter(
            tester,
            TaskFormScreen(taskId: taskId),
            locale: locale,
            initialPath: '/form',
            otherPaths: ['/tasks'],
            overrides: taskScreenOverrides(user, db),
          );

      Future<void> reveal(WidgetTester tester, Key key) async {
        // A focused field keeps itself on screen: let go of it first.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(key),
          200,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('taskFormList')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
      }

      Future<void> tapSave(WidgetTester tester) async {
        await reveal(tester, const Key('taskSaveButton'));
        await tester.tap(find.byKey(const Key('taskSaveButton')));
        await tester.pumpAndSettle();
      }

      Future<void> pickPriority(WidgetTester tester, TaskPriority p) async {
        await tester.tap(find.byKey(const Key('taskPriorityField')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(p.label(l10n)).last);
        await tester.pumpAndSettle();
      }

      Future<void> pickDeadline(WidgetTester tester) async {
        await tester.tap(find.byKey(const Key('taskDeadlineField')));
        await tester.pumpAndSettle();
        final material = MaterialLocalizations.of(
          tester.element(find.byType(DatePickerDialog)),
        );
        await tester.tap(find.text(material.okButtonLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text(material.okButtonLabel));
        await tester.pumpAndSettle();
      }

      testWidgets('shows required and optional fields', (tester) async {
        await pump(tester, _grace);
        expect(find.text(l10n.taskCreateTitle), findsOneWidget);
        expect(find.text(l10n.taskFieldTitle), findsOneWidget);
        expect(find.text(l10n.taskFieldDeadline), findsOneWidget);
        expect(find.text(l10n.taskFieldPriority), findsOneWidget);
        expect(find.text(l10n.taskFieldAssignee), findsOneWidget);
        expect(find.text(l10n.taskFieldNeedsCheck), findsOneWidget);
        expect(find.text(l10n.taskFieldDescription), findsOneWidget);
      });

      testWidgets('saving an empty form shows every required message', (
        tester,
      ) async {
        await pump(tester, _grace);
        await tapSave(tester);
        expect(find.text(l10n.validationTitleRequired), findsOneWidget);
        expect(find.text(l10n.validationDeadlineRequired), findsOneWidget);
        expect(find.text(l10n.validationPriorityRequired), findsOneWidget);
        expect(find.text(l10n.validationAssigneeRequired), findsOneWidget);
        expect(await allTasks(), isEmpty);
      });

      testWidgets('staff: assigned to themselves; saves a pending task', (
        tester,
      ) async {
        await pump(tester, _asha);
        expect(find.text('Asha'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('taskTitleField')),
          'Count the stock',
        );
        await pickPriority(tester, TaskPriority.high);
        await pickDeadline(tester);
        await tapSave(tester);
        final tasks = await allTasks();
        expect(tasks, hasLength(1));
        final task = tasks.single;
        expect(task['title'], 'Count the stock');
        expect(task['assigneeIds'], ['asha']);
        expect(task['creatorId'], 'asha');
        expect(task['assignmentState'], 'pending');
        expect(task['priority'], 'high');
        expect(task['confidential'], isFalse);
        expect(task['deptId'], 'finance');
        expect(find.text(stubPage('/tasks')), findsOneWidget);
      });

      testWidgets('manager: picks people from their team; several people '
          'offer "all" or "any one"', (tester) async {
        await pump(tester, _grace);
        await tester.tap(find.byKey(const Key('taskAssigneeField')));
        await tester.pumpAndSettle();
        // Only people below the manager, plus the manager.
        expect(find.byKey(const Key('assignee-juma')), findsNothing);
        await tester.tap(find.byKey(const Key('assignee-asha')));
        await tester.tap(find.byKey(const Key('assignee-baraka')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('assigneePickerDone')));
        await tester.pumpAndSettle();
        expect(find.text('Asha, Baraka'), findsOneWidget);
        expect(find.byKey(const Key('completionModeAny')), findsOneWidget);
        await tester.tap(find.byKey(const Key('completionModeAny')));
        await tester.enterText(
          find.byKey(const Key('taskTitleField')),
          'Visit the branch',
        );
        await pickPriority(tester, TaskPriority.low);
        await pickDeadline(tester);
        await reveal(tester, const Key('needsCheckSwitch'));
        await tester.tap(find.byKey(const Key('needsCheckSwitch')));
        await tapSave(tester);
        final task = (await allTasks()).single;
        expect(task['assigneeIds'], ['asha', 'baraka']);
        expect(task['completionMode'], 'any');
        expect(task['needsCheck'], isTrue);
      });

      testWidgets('edit: loads the task, people locked, sends changed fields', (
        tester,
      ) async {
        await seedTask(db, taskFixture(creatorId: 'grace', title: 'Old'));
        await pump(tester, _grace, taskId: 't1');
        expect(find.text(l10n.taskEditTitle), findsOneWidget);
        expect(find.text(l10n.assigneesChangeWithReassign), findsOneWidget);
        expect(find.text('Asha'), findsOneWidget);
        await tester.enterText(find.byKey(const Key('taskTitleField')), 'New');
        await tapSave(tester);
        final data = await readTask(db, 't1');
        expect(data['title'], 'New');
        expect(data['updatedBy'], 'grace');
        expect(data['priority'], 'high');
      });

      testWidgets('refused task: fix and send again', (tester) async {
        await seedTask(
          db,
          taskFixture(
            creatorId: 'asha',
            assigneeIds: ['asha'],
            viewerIds: ['asha'],
            assignmentState: AssignmentState.rejected,
            assignmentError: 'assignee-not-allowed',
          ),
        );
        await pump(tester, _asha, taskId: 't1');
        expect(find.text(l10n.taskResubmitTitle), findsOneWidget);
        await tapSave(tester);
        final data = await readTask(db, 't1');
        expect(data['assignmentState'], 'pending');
        expect(data.containsKey('assignmentError'), isFalse);
      });

      testWidgets('someone else\'s task cannot be edited', (tester) async {
        await seedTask(db, taskFixture(creatorId: 'grace'));
        await pump(tester, _asha, taskId: 't1');
        expect(find.byKey(const Key('taskCannotEdit')), findsOneWidget);
        expect(find.text(l10n.taskCannotEditMessage), findsOneWidget);
      });
    });
  }

  test('title limit follows the rules (KI-10)', () {
    expect(Task.maxTitleLength, 200);
  });
}
