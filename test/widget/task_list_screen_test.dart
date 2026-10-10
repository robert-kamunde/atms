import 'package:atms/core/errors/failure_messages.dart';
import 'package:atms/features/tasks/presentation/task_list_screen.dart';
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
final _grace = personFixture('grace', 'Grace', role: UserRole.manager);

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await seedPeople(db, [_asha, _baraka, _grace]);
    await db.doc('orgs/$testOrg/departments/finance').set({
      'name': 'Finance',
      'active': true,
    });
  });

  for (final locale in testLocales) {
    group('TaskListScreen [$locale]', () {
      final l10n = l10nFor(locale);

      Future<void> pump(
        WidgetTester tester, {
        bool team = false,
        AppUser? user,
      }) => pumpLocalizedRouter(
        tester,
        TaskListScreen(team: team),
        locale: locale,
        initialPath: '/tasks',
        otherPaths: ['/tasks/:id', '/tasks/new'],
        overrides: taskScreenOverrides(user ?? _asha, db),
      );

      testWidgets('empty: message, filter chips and New task', (tester) async {
        await pump(tester);
        expect(find.text(l10n.myTasksTitle), findsOneWidget);
        expect(find.byKey(const Key('taskListEmpty')), findsOneWidget);
        expect(find.text(l10n.tasksEmptyTitle), findsOneWidget);
        for (final label in [
          l10n.filterStatus,
          l10n.filterPriority,
          l10n.filterDueDate,
        ]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
        // Assignee and department filters are for Team Tasks.
        expect(find.text(l10n.filterAssignee), findsNothing);
        expect(find.text(l10n.actionNewTask), findsOneWidget);
      });

      testWidgets('my tasks by deadline with status, priority and overdue', (
        tester,
      ) async {
        await seedTask(
          db,
          taskFixture(
            id: 'late',
            title: 'Pay the supplier',
            deadline: testNow.subtract(const Duration(hours: 3)),
            status: TaskStatus.inProgress,
          ),
        );
        await seedTask(db, taskFixture(id: 'next', title: 'Count the stock'));
        await pump(tester);
        final late = tester.getTopLeft(find.text('Pay the supplier'));
        final next = tester.getTopLeft(find.text('Count the stock'));
        expect(late.dy, lessThan(next.dy));
        expect(find.text(TaskStatus.inProgress.label(l10n)), findsWidgets);
        expect(find.text(l10n.dueOverdue), findsOneWidget);
        expect(find.text(TaskPriority.high.label(l10n)), findsNWidgets(2));
      });

      testWidgets('list and board update live, without a refresh', (
        tester,
      ) async {
        await seedTask(db, taskFixture(id: 'a', title: 'Alpha'));
        await pump(tester);
        expect(find.text(TaskStatus.inProgress.label(l10n)), findsNothing);

        final tasks = db.collection('orgs').doc(testOrg).collection('tasks');
        await tester.runAsync(
          () => tasks.doc('a').update({'status': 'in_progress'}),
        );
        await tester.pumpAndSettle();
        expect(find.text(TaskStatus.inProgress.label(l10n)), findsWidgets);

        await tester.runAsync(
          () => seedTask(db, taskFixture(id: 'b', title: 'Bravo')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Bravo'), findsOneWidget);

        await tester.tap(find.byKey(const Key('toggleBoardButton')));
        await tester.pumpAndSettle();
        final todo = TaskStatus.todo.label(l10n);
        expect(find.text(l10n.boardColumnTitle(todo, 1)), findsOneWidget);
        await tester.runAsync(
          () => tasks.doc('b').update({'status': 'in_progress'}),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.boardColumnTitle(todo, 0)), findsOneWidget);
        expect(
          find.text(
            l10n.boardColumnTitle(TaskStatus.inProgress.label(l10n), 2),
          ),
          findsOneWidget,
        );
      });

      testWidgets('refused and pending creations show with the reason', (
        tester,
      ) async {
        await seedTask(
          db,
          taskFixture(
            id: 'r',
            title: 'Audit the cash box',
            creatorId: 'asha',
            assigneeIds: ['baraka'],
            viewerIds: ['asha'],
            assignmentState: AssignmentState.rejected,
            assignmentError: 'assignee-not-allowed',
          ),
        );
        await seedTask(
          db,
          taskFixture(
            id: 'p',
            title: 'Order paper',
            creatorId: 'asha',
            assigneeIds: ['asha'],
            viewerIds: ['asha'],
            assignmentState: AssignmentState.pending,
          ),
        );
        await pump(tester);
        expect(find.byKey(const Key('unassignedSection')), findsOneWidget);
        expect(find.text(l10n.unassignedSectionTitle), findsOneWidget);
        expect(find.text(l10n.errorAssigneeNotAllowed), findsOneWidget);
        expect(find.byKey(const Key('labelRejected')), findsOneWidget);
        expect(find.byKey(const Key('labelPending')), findsOneWidget);
      });

      testWidgets('a status filter applies to the loaded tasks', (
        tester,
      ) async {
        await seedTask(db, taskFixture(id: 'a', title: 'Alpha'));
        await seedTask(
          db,
          taskFixture(id: 'b', title: 'Bravo', status: TaskStatus.blocked),
        );
        await pump(tester);
        await tester.tap(find.byKey(const Key('filterStatus')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(TaskStatus.blocked.label(l10n)).last);
        await tester.pumpAndSettle();
        expect(find.text('Bravo'), findsOneWidget);
        expect(find.text('Alpha'), findsNothing);
      });

      testWidgets('board shows a column per open status', (tester) async {
        await seedTask(db, taskFixture(id: 'a', title: 'Alpha'));
        await pump(tester);
        await tester.tap(find.byKey(const Key('toggleBoardButton')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('taskBoard')), findsOneWidget);
        expect(
          find.text(l10n.boardColumnTitle(TaskStatus.todo.label(l10n), 1)),
          findsOneWidget,
        );
        expect(find.byKey(const Key('boardColumn-todo')), findsOneWidget);
        expect(find.text('Alpha'), findsOneWidget);
      });

      testWidgets('tapping a task opens its detail', (tester) async {
        await seedTask(db, taskFixture(id: 'a', title: 'Alpha'));
        await pump(tester);
        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        expect(find.text(stubPage('/tasks/:id')), findsOneWidget);
      });

      testWidgets('team: names, people filters from the loaded tasks', (
        tester,
      ) async {
        await seedTask(
          db,
          taskFixture(id: 'a', title: 'Alpha', viewerIds: ['grace', 'asha']),
        );
        await seedTask(
          db,
          taskFixture(
            id: 'b',
            title: 'Bravo',
            assigneeIds: ['baraka'],
            viewerIds: ['grace', 'baraka'],
          ),
        );
        await pump(tester, team: true, user: _grace);
        expect(find.text(l10n.teamTasksTitle), findsOneWidget);
        expect(find.text('Asha'), findsOneWidget);
        expect(find.text('Baraka'), findsOneWidget);
        await tester.ensureVisible(find.byKey(const Key('filterAssignee')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('filterAssignee')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Baraka').last);
        await tester.pumpAndSettle();
        expect(find.text('Bravo'), findsOneWidget);
        expect(find.text('Alpha'), findsNothing);
      });

      testWidgets('team: empty state', (tester) async {
        await pump(tester, team: true, user: _grace);
        expect(find.text(l10n.teamTasksEmptyTitle), findsOneWidget);
      });
    });
  }

  test('rejection reasons have their own message', () {
    final en = l10nFor(testLocales.first);
    expect(
      assignmentErrorMessage('assignee-inactive', en),
      en.errorAssigneeInactive,
    );
    expect(
      assignmentErrorMessage('something-new', en),
      en.assignmentRejectedGeneric,
    );
  });
}
