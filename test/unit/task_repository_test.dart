import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/features/audit/data/firestore_audit_repository.dart';
import 'package:atms/features/tasks/data/firestore_task_repository.dart';
import 'package:atms/features/tasks/data/task_write_maps.dart';
import 'package:atms/features/tasks/domain/task_filter.dart';
import 'package:atms/features/tasks/domain/task_repository.dart';
import 'package:atms/shared/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';
import '../helpers/task_fixtures.dart';

const _bookkeeping = {'updatedAt', 'updatedBy', 'clientUpdatedAt'};

final _draft = TaskDraft(
  title: '  Prepare the monthly report ',
  description: 'Use the new template',
  deadline: testNow.add(const Duration(days: 2)),
  priority: TaskPriority.urgent,
  assigneeIds: const ['asha', 'baraka'],
  deptId: 'finance',
  completionMode: CompletionMode.any,
  needsCheck: true,
);

void main() {
  // fake_cloud_firestore installs its FieldValue factory when the first
  // fake is created; FieldValues made before that cannot be written.
  setUpAll(FakeFirebaseFirestore.new);
  final maps = TaskWriteMaps(uid: 'me', clientNow: testNow);

  group('TaskWriteMaps: exact field sets (firestore.rules task section)', () {
    test('create: a pending task only the creator sees (A-01)', () {
      final map = maps.create(_draft);
      expect(map.keys.toSet(), {
        'title',
        'description',
        'priority',
        'deadline',
        'assigneeIds',
        'deptId',
        'confidential',
        'participantIds',
        'completionMode',
        'needsCheck',
        'creatorId',
        'status',
        'viewerIds',
        'assignmentState',
        'completedByIds',
        'deleted',
        'createdAt',
        ..._bookkeeping,
      });
      expect(map['title'], 'Prepare the monthly report');
      expect(map['status'], 'todo');
      expect(map['creatorId'], 'me');
      expect(map['updatedBy'], 'me');
      expect(map['viewerIds'], ['me']);
      expect(map['assignmentState'], 'pending');
      expect(map['completedByIds'], isEmpty);
      expect(map['confidential'], isFalse);
      expect(map['deleted'], isFalse);
      expect(map['needsCheck'], isTrue);
      expect(map['completionMode'], 'any');
      expect(map['createdAt'], isA<FieldValue>());
      expect(map['updatedAt'], isA<FieldValue>());
      expect(map['clientUpdatedAt'], Timestamp.fromDate(testNow));
      for (final field in Task.serverOnlyFields) {
        expect(map.containsKey(field), isFalse, reason: field);
      }
    });

    test('creator edit sends only the changed fields', () {
      final before = taskFixture(title: 'Old', priority: TaskPriority.low);
      final edit = TaskEdit.between(
        before,
        TaskDraft(
          title: 'Old',
          deadline: before.deadline,
          priority: TaskPriority.high,
          assigneeIds: before.assigneeIds,
          deptId: before.deptId,
        ),
      );
      expect(maps.edit(edit).keys.toSet(), {'priority', ..._bookkeeping});
      final all = maps.edit(
        TaskEdit(
          title: 't',
          description: 'd',
          priority: TaskPriority.low,
          deadline: testNow,
          needsCheck: true,
        ),
      );
      expect(all.keys.toSet(), {
        'title',
        'description',
        'priority',
        'deadline',
        'needsCheck',
        ..._bookkeeping,
      });
      expect(TaskEdit.between(before, _sameAs(before)).isEmpty, isTrue);
    });

    test('status changes: blocked carries a reason, others only status', () {
      expect(maps.status(TaskStatus.inProgress).keys.toSet(), {
        'status',
        ..._bookkeeping,
      });
      final blocked = maps.status(TaskStatus.blocked, reason: ' No paper ');
      expect(blocked.keys.toSet(), {
        'status',
        'blockedReason',
        ..._bookkeeping,
      });
      expect(blocked['blockedReason'], 'No paper');
      expect(maps.status(TaskStatus.awaitingCheck)['status'], 'awaiting_check');
    });

    test('several assignees: add only myself to completedByIds', () {
      final map = maps.completeMyPart();
      expect(map.keys.toSet(), {'completedByIds', ..._bookkeeping});
      expect(map['completedByIds'], isA<FieldValue>());
    });

    test('check: confirm and return (D-06)', () {
      expect(maps.confirmCheck(), containsPair('status', 'done'));
      expect(maps.confirmCheck().keys.toSet(), {'status', ..._bookkeeping});
      final back = maps.returnWork('Add the totals');
      expect(back.keys.toSet(), {'status', 'returnReason', ..._bookkeeping});
      expect(back['status'], 'in_progress');
    });

    test('cancel with a reason; soft delete', () {
      expect(maps.cancel('Not needed').keys.toSet(), {
        'status',
        'cancelReason',
        ..._bookkeeping,
      });
      final deleted = maps.softDelete();
      expect(deleted.keys.toSet(), {'deleted', 'deletedAt', ..._bookkeeping});
      expect(deleted['deleted'], isTrue);
    });

    test('resubmit: corrected fields, back to pending, error removed', () {
      final map = maps.resubmit(_draft);
      expect(map.keys.toSet(), {
        'title',
        'description',
        'priority',
        'deadline',
        'assigneeIds',
        'completionMode',
        'needsCheck',
        'assignmentState',
        'assignmentError',
        ..._bookkeeping,
      });
      expect(map['assignmentState'], 'pending');
      expect(map['assignmentError'], isA<FieldValue>());
    });
  });

  group('FirestoreTaskRepository', () {
    late FakeFirebaseFirestore db;
    late MockCallableClient callables;
    late FirestoreTaskRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      callables = MockCallableClient();
      repo = FirestoreTaskRepository(
        db,
        () => callables,
        orgId: testOrg,
        uid: 'asha',
        clock: () => testNow,
      );
    });

    test('create writes the pending task under the given id', () async {
      final id = repo.newTaskId();
      await repo.create(id, _draft);
      final data = await readTask(db, id);
      expect(data['assignmentState'], 'pending');
      expect(data['creatorId'], 'asha');
      expect(data['viewerIds'], ['asha']);
      expect(data['deleted'], isFalse);
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('updates change exactly the fields of each transition', () async {
      await seedTask(
        db,
        taskFixture(assigneeIds: ['asha', 'baraka'], completedByIds: []),
      );
      final before = await readTask(db, 't1');

      Future<Set<String>> changedBy(Future<void> Function() write) async {
        final old = await readTask(db, 't1');
        await write();
        final now = await readTask(db, 't1');
        return {
          for (final key in {...old.keys, ...now.keys})
            if ('${old[key]}' != '${now[key]}') key,
        };
      }

      expect(await changedBy(() => repo.markMyPartDone('t1')), {
        'completedByIds',
        'updatedAt',
        'updatedBy',
        'clientUpdatedAt',
      });
      expect((await readTask(db, 't1'))['completedByIds'], ['asha']);
      expect(
        await changedBy(
          () => repo.changeStatus('t1', TaskStatus.blocked, reason: 'Paper'),
        ),
        containsAll(['status', 'blockedReason']),
      );
      expect(
        (await changedBy(() => repo.cancel('t1', 'No longer needed'))),
        containsAll(['status', 'cancelReason']),
      );
      expect(before['deleted'], isFalse);
      await repo.softDelete('t1');
      final after = await readTask(db, 't1');
      expect(after['deleted'], isTrue);
      expect(after['deletedAt'], isA<Timestamp>());
    });

    test('resubmit removes the server error and returns to pending', () async {
      await seedTask(
        db,
        taskFixture(
          creatorId: 'asha',
          assignmentState: AssignmentState.rejected,
          assignmentError: 'assignee-not-allowed',
        ),
      );
      await repo.resubmit('t1', _draft);
      final data = await readTask(db, 't1');
      expect(data['assignmentState'], 'pending');
      expect(data.containsKey('assignmentError'), isFalse);
      expect(data['assigneeIds'], ['asha', 'baraka']);
    });

    test('watchTask: missing and deleted tasks are null', () async {
      await seedTask(db, taskFixture());
      await seedTask(db, taskFixture(id: 'gone', deleted: true));
      expect((await repo.watchTask('t1').first)?.id, 't1');
      expect(await repo.watchTask('gone').first, isNull);
      expect(await repo.watchTask('none').first, isNull);
    });

    test('My Tasks: my open assigned tasks by deadline, 20 per page', () async {
      for (var i = 0; i < 23; i++) {
        await seedTask(
          db,
          taskFixture(
            id: 'mine$i',
            deadline: testNow.add(Duration(hours: i + 1)),
          ),
        );
      }
      await seedTask(db, taskFixture(id: 'done', status: TaskStatus.done));
      await seedTask(db, taskFixture(id: 'other', assigneeIds: ['baraka']));
      await seedTask(db, taskFixture(id: 'deleted', deleted: true));
      await seedTask(
        db,
        taskFixture(id: 'pending', assignmentState: AssignmentState.pending),
      );
      await seedTask(
        db,
        taskFixture(id: 'waiting', status: TaskStatus.awaitingCheck),
      );
      final first = await repo.myTasks().watch(pages: 1).first;
      expect(first.items, hasLength(20));
      expect(first.items.first.id, 'mine0');
      expect(first.hasMore, isTrue);
      final second = await repo.myTasks().watch(pages: 2).first;
      expect(second.items, hasLength(24));
      expect(second.items.skip(20).map((t) => t.id), [
        'mine20',
        'mine21',
        'mine22',
        'waiting',
      ]);
      expect(second.hasMore, isFalse);
    });

    test('unassigned: my pending and refused creations', () async {
      await seedTask(
        db,
        taskFixture(
          id: 'p',
          creatorId: 'asha',
          assigneeIds: ['baraka'],
          viewerIds: ['asha'],
          assignmentState: AssignmentState.pending,
        ),
      );
      await seedTask(
        db,
        taskFixture(
          id: 'r',
          creatorId: 'asha',
          assigneeIds: ['baraka'],
          viewerIds: ['asha'],
          assignmentState: AssignmentState.rejected,
        ),
      );
      await seedTask(db, taskFixture(id: 'a', creatorId: 'asha'));
      final page = await repo.myUnassignedTasks().watch(pages: 1).first;
      expect(page.items.map((t) => t.id).toSet(), {'p', 'r'});
    });

    test('team and org tasks apply status, priority and due date', () async {
      await seedTask(db, taskFixture(id: 'a', viewerIds: ['asha']));
      await seedTask(
        db,
        taskFixture(
          id: 'b',
          viewerIds: ['asha'],
          status: TaskStatus.blocked,
          priority: TaskPriority.low,
        ),
      );
      await seedTask(
        db,
        taskFixture(
          id: 'late',
          viewerIds: ['asha'],
          deadline: testNow.subtract(const Duration(hours: 2)),
        ),
      );
      await seedTask(
        db,
        taskFixture(id: 'secret', viewerIds: ['x'], confidential: true),
      );
      await seedTask(db, taskFixture(id: 'hidden', viewerIds: ['x']));

      Future<Set<String>> team(TaskFilter f) async =>
          (await repo.teamTasks(f, now: testNow).watch(pages: 1).first).items
              .map((t) => t.id)
              .toSet();
      Future<Set<String>> org(TaskFilter f) async =>
          (await repo.orgTasks(f, now: testNow).watch(pages: 1).first).items
              .map((t) => t.id)
              .toSet();

      expect(await team(const TaskFilter()), {'a', 'b', 'late'});
      expect(await team(const TaskFilter(status: TaskStatus.blocked)), {'b'});
      expect(await team(const TaskFilter(priority: TaskPriority.low)), {'b'});
      expect(await team(const TaskFilter(due: DueFilter.overdue)), {'late'});
      expect(await org(const TaskFilter()), {'a', 'b', 'late', 'hidden'});
    });

    test('team and org tasks filter by department in the query', () async {
      await seedTask(db, taskFixture(id: 'fin', viewerIds: ['asha']));
      await seedTask(
        db,
        taskFixture(id: 'ops', viewerIds: ['asha'], deptId: 'ops'),
      );
      await seedTask(
        db,
        taskFixture(
          id: 'opsBlocked',
          viewerIds: ['asha'],
          deptId: 'ops',
          status: TaskStatus.blocked,
        ),
      );
      await seedTask(
        db,
        taskFixture(id: 'opsOther', viewerIds: ['x'], deptId: 'ops'),
      );
      await seedTask(
        db,
        taskFixture(
          id: 'opsSecret',
          viewerIds: ['x'],
          deptId: 'ops',
          confidential: true,
        ),
      );

      Future<Set<String>> team(TaskFilter f) async =>
          (await repo.teamTasks(f, now: testNow).watch(pages: 1).first).items
              .map((t) => t.id)
              .toSet();
      Future<Set<String>> org(TaskFilter f) async =>
          (await repo.orgTasks(f, now: testNow).watch(pages: 1).first).items
              .map((t) => t.id)
              .toSet();

      expect(await team(const TaskFilter(deptId: 'ops')), {
        'ops',
        'opsBlocked',
      });
      expect(
        await team(const TaskFilter(deptId: 'ops', status: TaskStatus.blocked)),
        {'opsBlocked'},
      );
      expect(await team(const TaskFilter(deptId: 'finance')), {'fin'});
      expect(await org(const TaskFilter(deptId: 'ops')), {
        'ops',
        'opsBlocked',
        'opsOther',
      });
    });

    test('reassign calls reassignTask with the exact input', () async {
      when(() => callables.call('reassignTask', any()))
          .thenAnswer((_) async => {'ok': true});
      await repo.reassign('t1', ['baraka']);
      verify(
        () => callables.call('reassignTask', {
          'taskId': 't1',
          'assigneeIds': ['baraka'],
        }),
      ).called(1);
    });

    test('reassign offline fails with "needs connection"', () {
      when(() => callables.call('reassignTask', any()))
          .thenThrow(const ConnectionRequiredFailure());
      expect(
        repo.reassign('t1', ['baraka']),
        throwsA(isA<ConnectionRequiredFailure>()),
      );
    });
  });

  group('FirestoreAuditRepository', () {
    late FakeFirebaseFirestore db;
    setUp(() async {
      db = FakeFirebaseFirestore();
      for (var i = 0; i < 3; i++) {
        await seedAudit(db, 'e$i', {
          'taskId': 't1',
          'actorId': 'asha',
          'action': 'status_changed',
          'before': {},
          'after': {},
          'at': Timestamp.fromDate(testNow.add(Duration(minutes: i))),
          'madeOffline': false,
          'viewerIds': ['asha'],
          'confidential': false,
        });
      }
      await seedAudit(db, 'other', {
        'taskId': 't1',
        'actorId': 'x',
        'action': 'task_created',
        'at': Timestamp.fromDate(testNow),
        'viewerIds': ['x'],
        'confidential': true,
      });
    });

    test('task activity: newest first, my entries only', () async {
      final repo = FirestoreAuditRepository(db, orgId: testOrg, uid: 'asha');
      final page = await repo.taskActivity('t1', asAdmin: false).fetchPage();
      expect(page.items.map((e) => e.id), ['e2', 'e1', 'e0']);
    });

    test('admins read the non-confidential entries', () async {
      final repo = FirestoreAuditRepository(db, orgId: testOrg, uid: 'admin');
      final task = await repo.taskActivity('t1', asAdmin: true).fetchPage();
      expect(task.items.map((e) => e.id), ['e2', 'e1', 'e0']);
      final org = await repo.orgActivity().fetchPage();
      expect(org.items, hasLength(3));
    });
  });
}

TaskDraft _sameAs(Task t) => TaskDraft(
  title: t.title,
  description: t.description,
  deadline: t.deadline,
  priority: t.priority,
  assigneeIds: t.assigneeIds,
  deptId: t.deptId,
  needsCheck: t.needsCheck,
);
