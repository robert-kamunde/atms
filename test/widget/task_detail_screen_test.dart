import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/features/tasks/presentation/task_detail_screen.dart';
import 'package:atms/features/tasks/presentation/task_providers.dart';
import 'package:atms/shared/models/models.dart';
import 'package:atms/shared/widgets/enum_labels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';
import '../helpers/task_fixtures.dart';

final _asha = personFixture('asha', 'Asha', chain: ['creator']);
final _baraka = personFixture('baraka', 'Baraka', chain: ['creator']);
final _creator = personFixture('creator', 'Grace', role: UserRole.manager);

void main() {
  late FakeFirebaseFirestore db;
  late MockCallableClient callables;

  setUp(() async {
    db = FakeFirebaseFirestore();
    callables = MockCallableClient();
    await seedPeople(db, [_asha, _baraka, _creator]);
    await db.doc('orgs/$testOrg/departments/finance').set({
      'name': 'Finance',
      'active': true,
    });
  });

  for (final locale in testLocales) {
    group('TaskDetailScreen [$locale]', () {
      final l10n = l10nFor(locale);

      Future<void> pump(
        WidgetTester tester,
        AppUser user, {
        String taskId = 't1',
        List<Object> extra = const [],
      }) => pumpLocalizedRouter(
        tester,
        TaskDetailScreen(taskId: taskId),
        locale: locale,
        initialPath: '/tasks/$taskId',
        otherPaths: ['/tasks/:id/edit', '/tasks'],
        overrides: [
          ...taskScreenOverrides(user, db, callables: callables),
          ...extra.cast(),
        ],
      );

      Future<void> scrollTo(WidgetTester tester, Finder finder) async {
        await tester.scrollUntilVisible(
          finder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }

      testWidgets('assignee: all fields and Start writes In progress', (
        tester,
      ) async {
        await seedTask(
          db,
          taskFixture(description: 'Use the new template', needsCheck: true),
        );
        await pump(tester, _asha);
        expect(find.text('Prepare the monthly report'), findsOneWidget);
        expect(find.text('Use the new template'), findsOneWidget);
        expect(find.text('Asha'), findsOneWidget);
        expect(find.text('Grace'), findsOneWidget);
        expect(find.text('Finance'), findsOneWidget);
        expect(find.byKey(const Key('editTaskButton')), findsNothing);
        expect(find.text(l10n.actionSendForCheck), findsOneWidget);
        expect(find.byKey(const Key('actionCancelTask')), findsNothing);
        await tester.tap(find.byKey(const Key('actionStart')));
        await tester.pumpAndSettle();
        expect((await readTask(db, 't1'))['status'], 'in_progress');
        expect(find.text(l10n.savedMessage), findsOneWidget);
        expect(find.text(TaskStatus.inProgress.label(l10n)), findsOneWidget);
      });

      testWidgets('blocked needs a reason', (tester) async {
        await seedTask(db, taskFixture(status: TaskStatus.inProgress));
        await pump(tester, _asha);
        await tester.tap(find.byKey(const Key('actionBlock')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('reasonConfirmButton')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.validationReasonRequired), findsOneWidget);
        await tester.enterText(find.byKey(const Key('reasonField')), 'No ink');
        await tester.tap(find.byKey(const Key('reasonConfirmButton')));
        await tester.pumpAndSettle();
        final data = await readTask(db, 't1');
        expect(data['status'], 'blocked');
        expect(data['blockedReason'], 'No ink');
      });

      testWidgets('creator checks the work: confirm or return (D-06)', (
        tester,
      ) async {
        await seedTask(
          db,
          taskFixture(status: TaskStatus.awaitingCheck, needsCheck: true),
        );
        await pump(tester, _creator);
        expect(find.text(l10n.awaitingCheckCreatorMessage), findsOneWidget);
        expect(find.byKey(const Key('actionConfirmCheck')), findsOneWidget);
        await tester.tap(find.byKey(const Key('actionReturn')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('reasonField')),
          'Add the totals',
        );
        await tester.tap(find.byKey(const Key('reasonConfirmButton')));
        await tester.pumpAndSettle();
        final data = await readTask(db, 't1');
        expect(data['status'], 'in_progress');
        expect(data['returnReason'], 'Add the totals');
      });

      testWidgets('several assignees: progress and "I\'m done"', (
        tester,
      ) async {
        await seedTask(
          db,
          taskFixture(
            assigneeIds: ['asha', 'baraka'],
            completedByIds: ['baraka'],
            status: TaskStatus.inProgress,
          ),
        );
        await pump(tester, _asha);
        expect(find.text(l10n.taskProgress(1, 2)), findsWidgets);
        expect(find.byKey(const Key('actionDone')), findsNothing);
        await tester.tap(find.byKey(const Key('actionMyPartDone')));
        await tester.pumpAndSettle();
        expect((await readTask(db, 't1'))['completedByIds'], [
          'baraka',
          'asha',
        ]);
      });

      testWidgets('refused task: reason, edit and send again, delete', (
        tester,
      ) async {
        await seedTask(
          db,
          taskFixture(
            creatorId: 'asha',
            assigneeIds: ['baraka'],
            viewerIds: ['asha'],
            assignmentState: AssignmentState.rejected,
            assignmentError: 'assignee-inactive',
          ),
        );
        await pump(tester, _asha);
        expect(find.byKey(const Key('rejectedNotice')), findsOneWidget);
        expect(
          find.text(l10n.assignmentRejectedMessage(l10n.errorAssigneeInactive)),
          findsOneWidget,
        );
        expect(find.byKey(const Key('actionStart')), findsNothing);
        expect(find.byKey(const Key('activitySection')), findsNothing);
        await tester.tap(find.byKey(const Key('actionResubmit')));
        await tester.pumpAndSettle();
        expect(find.text(stubPage('/tasks/:id/edit')), findsOneWidget);
      });

      testWidgets('refused task can be deleted after confirming', (
        tester,
      ) async {
        await seedTask(
          db,
          taskFixture(
            creatorId: 'asha',
            viewerIds: ['asha'],
            assignmentState: AssignmentState.rejected,
          ),
        );
        await pump(tester, _asha);
        await tester.tap(find.byKey(const Key('actionDiscard')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.deleteTaskTitle), findsOneWidget);
        await tester.tap(find.byKey(const Key('confirmDialogButton')));
        await tester.pumpAndSettle();
        expect((await readTask(db, 't1'))['deleted'], isTrue);
      });

      testWidgets('pending task explains it is assigned when online', (
        tester,
      ) async {
        await seedTask(
          db,
          taskFixture(
            creatorId: 'asha',
            viewerIds: ['asha'],
            assignmentState: AssignmentState.pending,
          ),
        );
        await pump(tester, _asha);
        expect(find.text(l10n.assignmentPendingMessage), findsOneWidget);
        expect(find.byKey(const Key('labelPending')), findsOneWidget);
      });

      testWidgets('waiting to sync while a change is on the phone only', (
        tester,
      ) async {
        await pump(
          tester,
          _asha,
          extra: [
            taskDetailProvider.overrideWith(
              (ref, id) => Stream.value(
                Task.fromMap(id, taskFixture().toMap(), hasPendingWrites: true),
              ),
            ),
          ],
        );
        expect(find.byKey(const Key('waitingToSyncNotice')), findsOneWidget);
        expect(find.text(l10n.waitingToSyncLabel), findsOneWidget);
      });

      testWidgets('missing task shows "not found"', (tester) async {
        await pump(tester, _asha, taskId: 'nope');
        expect(find.byKey(const Key('taskNotFound')), findsOneWidget);
        expect(find.text(l10n.errorNotFound), findsOneWidget);
      });

      testWidgets('a refused read shows the same "not found"', (tester) async {
        await pump(
          tester,
          _asha,
          extra: [
            taskDetailProvider.overrideWith(
              (ref, id) => Stream<Task?>.error(const PermissionDeniedFailure()),
            ),
          ],
        );
        expect(find.text(l10n.errorNotFound), findsOneWidget);
      });

      testWidgets('activity log in plain words, with "made offline"', (
        tester,
      ) async {
        await seedTask(db, taskFixture());
        await seedAudit(db, 'e1', {
          'taskId': 't1',
          'actorId': 'asha',
          'action': 'status_changed',
          'before': {'status': 'todo'},
          'after': {'status': 'in_progress'},
          'at': Timestamp.fromDate(testNow),
          'madeOffline': true,
          'viewerIds': ['asha'],
          'confidential': false,
        });
        await seedAudit(db, 'e0', {
          'taskId': 't1',
          'actorId': 'creator',
          'action': 'task_created',
          'at': Timestamp.fromDate(testNow.subtract(const Duration(hours: 1))),
          'madeOffline': false,
          'viewerIds': ['asha'],
          'confidential': false,
        });
        await pump(tester, _asha);
        await scrollTo(tester, find.byKey(const Key('activity-e0')));
        expect(
          find.text(
            l10n.activityStatusChanged(
              'Asha',
              TaskStatus.todo.label(l10n),
              TaskStatus.inProgress.label(l10n),
            ),
          ),
          findsOneWidget,
        );
        expect(find.text(l10n.activityCreated('Grace')), findsOneWidget);
        expect(find.byKey(const Key('madeOfflineMarker')), findsOneWidget);
      });

      testWidgets('reassign offline says it needs a connection', (
        tester,
      ) async {
        when(() => callables.call('reassignTask', any()))
            .thenThrow(const ConnectionRequiredFailure());
        await seedTask(db, taskFixture());
        await pump(tester, _creator);
        await tester.tap(find.byKey(const Key('actionReassign')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('assignee-baraka')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('assigneePickerDone')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.errorConnectionRequired), findsOneWidget);
      });

      testWidgets('manager creator: edit, cancel and delete before start', (
        tester,
      ) async {
        await seedTask(db, taskFixture());
        await pump(tester, _creator);
        expect(find.byKey(const Key('editTaskButton')), findsOneWidget);
        expect(find.byKey(const Key('actionCancelTask')), findsOneWidget);
        expect(find.byKey(const Key('actionDelete')), findsOneWidget);
        expect(find.byKey(const Key('actionStart')), findsNothing);
      });
    });
  }
}
