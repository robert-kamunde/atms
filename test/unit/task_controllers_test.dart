import 'package:atms/core/config/firebase_providers.dart';
import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/core/services/offline_write.dart';
import 'package:atms/features/audit/presentation/audit_providers.dart';
import 'package:atms/features/auth/presentation/auth_providers.dart';
import 'package:atms/features/tasks/domain/task_filter.dart';
import 'package:atms/features/tasks/domain/task_repository.dart';
import 'package:atms/features/tasks/presentation/task_providers.dart';
import 'package:atms/shared/models/models.dart';
import 'package:atms/shared/providers/paged_list_controller.dart';
import 'package:atms/shared/providers/sync_providers.dart';
import 'package:atms/shared/services/sync_status_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';
import '../helpers/task_fixtures.dart';

AppUser _person(
  String id,
  String name, {
  UserRole role = UserRole.staff,
  List<String> chain = const [],
}) => AppUser(
  id: id,
  orgId: testOrg,
  name: name,
  role: role,
  deptId: 'finance',
  managerChain: chain,
  supervisorId: chain.isEmpty ? null : chain.first,
);

void main() {
  late FakeFirebaseFirestore db;
  late MockCallableClient callables;

  setUp(() async {
    db = FakeFirebaseFirestore();
    callables = MockCallableClient();
    for (final p in [
      _person('grace', 'Grace', role: UserRole.manager, chain: ['neema']),
      _person('asha', 'Asha', chain: ['grace', 'neema']),
      _person('baraka', 'Baraka', chain: ['grace', 'neema']),
      _person('juma', 'Juma', chain: ['neema']),
      _person('neema', 'Neema', role: UserRole.admin),
    ]) {
      await db
          .collection('orgs')
          .doc(testOrg)
          .collection('users')
          .doc(p.id)
          .set(p.toMap());
    }
  });

  ProviderContainer containerFor(AppUser user, {bool verified = false}) {
    final container = ProviderContainer(
      overrides: [
        signedInSession(
          user,
          adminVerifiedUntil: verified ? DateTime.utc(2100) : null,
        ),
        firestoreProvider.overrideWithValue(db),
        callableClientProvider.overrideWithValue(callables),
        clockProvider.overrideWithValue(() => testNow),
        syncStatusSourceProvider.overrideWithValue(
          const UnknownSyncStatusSource(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<PagedListState<T>> loaded<T>(
    ProviderContainer c,
    ProviderListenable<PagedListState<T>> provider,
  ) async {
    final sub = c.listen(provider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 20 && !c.read(provider).loadedOnce; i++) {
      await settle();
    }
    return c.read(provider);
  }

  final asha = _person('asha', 'Asha', chain: ['grace', 'neema']);
  final grace = _person(
    'grace',
    'Grace',
    role: UserRole.manager,
    chain: ['neema'],
  );
  final neema = _person('neema', 'Neema', role: UserRole.admin);

  group('taskActorProvider', () {
    test('admin powers only with a current second factor', () {
      expect(
        containerFor(neema).read(taskActorProvider)!.isVerifiedAdmin,
        isFalse,
      );
      expect(
        containerFor(
          neema,
          verified: true,
        ).read(taskActorProvider)!.isVerifiedAdmin,
        isTrue,
      );
    });
  });

  group('lists', () {
    test('My Tasks and the not-yet-assigned section', () async {
      await seedTask(db, taskFixture(id: 'a'));
      await seedTask(
        db,
        taskFixture(
          id: 'r',
          creatorId: 'asha',
          assigneeIds: ['juma'],
          viewerIds: ['asha'],
          assignmentState: AssignmentState.rejected,
          assignmentError: 'assignee-not-allowed',
        ),
      );
      final c = containerFor(asha);
      expect((await loaded(c, myTasksProvider)).items.map((t) => t.id), ['a']);
      expect(
        (await loaded(c, myUnassignedTasksProvider)).items.map((t) => t.id),
        ['r'],
      );
    });

    DocumentReference<Map<String, dynamic>> taskDoc(String id) =>
        db.collection('orgs').doc(testOrg).collection('tasks').doc(id);

    Future<void> settleFor(int rounds) async {
      for (var i = 0; i < rounds; i++) {
        await settle();
      }
    }

    test('My Tasks is live: a status change and a new assignment show '
        'without a refresh (AC-4.3-2)', () async {
      await seedTask(db, taskFixture(id: 'a'));
      final c = containerFor(asha);
      final first = await loaded(c, myTasksProvider);
      expect(first.items.single.status, TaskStatus.todo);

      await taskDoc('a').update({'status': 'in_progress'});
      await settleFor(3);
      expect(
        c.read(myTasksProvider).items.single.status,
        TaskStatus.inProgress,
      );

      await seedTask(
        db,
        taskFixture(id: 'b', deadline: testNow.add(const Duration(hours: 1))),
      );
      await settleFor(3);
      expect(c.read(myTasksProvider).items.map((t) => t.id), ['b', 'a']);

      // Done tasks leave My Tasks by themselves.
      await taskDoc('a').update({'status': 'done'});
      await settleFor(3);
      expect(c.read(myTasksProvider).items.map((t) => t.id), ['b']);
    });

    test(
      "the creator's waiting section is live: refused shows, assigned leaves",
      () async {
        await seedTask(
          db,
          taskFixture(
            id: 'p',
            creatorId: 'asha',
            assigneeIds: ['juma'],
            viewerIds: ['asha'],
            assignmentState: AssignmentState.pending,
          ),
        );
        final c = containerFor(asha);
        expect(
          (await loaded(
            c,
            myUnassignedTasksProvider,
          )).items.single.assignmentState,
          AssignmentState.pending,
        );
        await taskDoc('p').update({
          'assignmentState': 'rejected',
          'assignmentError': 'assignee-not-allowed',
        });
        await settleFor(3);
        expect(
          c.read(myUnassignedTasksProvider).items.single.assignmentState,
          AssignmentState.rejected,
        );
        await taskDoc('p').update({'assignmentState': 'assigned'});
        await settleFor(3);
        expect(c.read(myUnassignedTasksProvider).items, isEmpty);
      },
    );

    test('Team Tasks: Load more shows 20 more tasks, still live', () async {
      for (var i = 0; i < 45; i++) {
        await seedTask(
          db,
          taskFixture(
            id: 'task$i',
            viewerIds: ['grace'],
            deadline: testNow.add(Duration(hours: i + 1)),
          ),
        );
      }
      final c = containerFor(grace);
      final first = await loaded(c, teamTasksProvider);
      expect(first.items, hasLength(20));
      expect(first.hasMore, isTrue);
      final controller = c.read(teamTasksProvider.notifier);

      await controller.loadMore();
      await settle();
      expect(controller.loadedPages, 2);
      expect(c.read(teamTasksProvider).items, hasLength(40));
      expect(c.read(teamTasksProvider).hasMore, isTrue);

      await taskDoc('task35').update({'status': 'blocked'});
      await settleFor(3);
      expect(
        c
            .read(teamTasksProvider)
            .items
            .firstWhere((t) => t.id == 'task35')
            .status,
        TaskStatus.blocked,
      );

      await controller.loadMore();
      await settle();
      expect(controller.loadedPages, 3);
      expect(c.read(teamTasksProvider).items, hasLength(45));
      expect(c.read(teamTasksProvider).hasMore, isFalse);

      // Pull to refresh goes back to one page.
      await controller.refresh();
      expect(controller.loadedPages, 1);
      expect(c.read(teamTasksProvider).items, hasLength(20));
    });

    test(
      'Team Tasks: managers by viewerIds; filters reload the query',
      () async {
        await seedTask(db, taskFixture(id: 'a', viewerIds: ['grace']));
        await seedTask(
          db,
          taskFixture(
            id: 'b',
            viewerIds: ['grace'],
            status: TaskStatus.blocked,
          ),
        );
        await seedTask(db, taskFixture(id: 'other', viewerIds: ['x']));
        final c = containerFor(grace);
        expect(
          (await loaded(c, teamTasksProvider)).items.map((t) => t.id).toSet(),
          {'a', 'b'},
        );
        c
            .read(teamTaskFilterProvider.notifier)
            .set(const TaskFilter(status: TaskStatus.blocked));
        await settle();
        expect((await loaded(c, teamTasksProvider)).items.map((t) => t.id), [
          'b',
        ]);
      },
    );

    test(
      'Team Tasks: verified admins see every non-confidential task',
      () async {
        await seedTask(db, taskFixture(id: 'a', viewerIds: ['x']));
        await seedTask(
          db,
          taskFixture(id: 'secret', viewerIds: ['x'], confidential: true),
        );
        final c = containerFor(neema, verified: true);
        expect((await loaded(c, teamTasksProvider)).items.map((t) => t.id), [
          'a',
        ]);
      },
    );

    test('activity log of a task', () async {
      await seedAudit(db, 'e1', {
        'taskId': 't1',
        'actorId': 'grace',
        'action': 'task_created',
        'at': Timestamp.fromDate(testNow),
        'viewerIds': ['asha'],
        'confidential': false,
      });
      final c = containerFor(asha);
      final state = await loaded(c, taskActivityProvider('t1'));
      expect(state.items.single.action, AuditAction.taskCreated);
    });
  });

  group('assignable people (spec 2 matrix)', () {
    Future<List<String>> people(ProviderContainer c) async => (await loaded(
      c,
      assignablePeopleProvider,
    )).items.map((u) => u.id).toList();

    test('staff: only themselves', () async {
      expect(await people(containerFor(asha)), ['asha']);
    });

    test('managers: their reporting tree', () async {
      expect(await people(containerFor(grace)), ['asha', 'baraka']);
    });

    test(
      'verified admins: everyone; without the second factor: self',
      () async {
        expect(await people(containerFor(neema, verified: true)), hasLength(5));
        expect(await people(containerFor(neema)), ['neema']);
      },
    );
  });

  group('TaskActions', () {
    TaskActions actions(ProviderContainer c) =>
        c.read(taskActionsProvider.notifier);

    test('create writes a pending task and shows it as not assigned', () async {
      final c = containerFor(asha);
      await loaded(c, myUnassignedTasksProvider);
      final created = await actions(c).create(
        TaskDraft(
          title: 'Count the stock',
          deadline: testNow.add(const Duration(days: 1)),
          priority: TaskPriority.medium,
          assigneeIds: const ['asha'],
          deptId: 'finance',
        ),
      );
      expect(created.outcome, WriteOutcome.saved);
      final data = await readTask(db, created.taskId);
      expect(data['assignmentState'], 'pending');
      final unassigned = await loaded(c, myUnassignedTasksProvider);
      expect(unassigned.items.map((t) => t.id), [created.taskId]);
    });

    test('done becomes waiting for check when the creator asked', () async {
      await seedTask(db, taskFixture(needsCheck: true));
      final c = containerFor(asha);
      await actions(c).markDone(taskFixture(needsCheck: true));
      expect((await readTask(db, 't1'))['status'], 'awaiting_check');
    });

    test('block, resume, return and confirm write their statuses', () async {
      await seedTask(db, taskFixture(status: TaskStatus.inProgress));
      final c = containerFor(asha);
      final t = taskFixture();
      await actions(c).block(t, 'No paper');
      expect((await readTask(db, 't1'))['blockedReason'], 'No paper');
      await actions(c).resume(t);
      expect((await readTask(db, 't1'))['status'], 'in_progress');
      await actions(c).returnWork(t, 'Add totals');
      expect((await readTask(db, 't1'))['returnReason'], 'Add totals');
      await actions(c).confirmCheck(t);
      expect((await readTask(db, 't1'))['status'], 'done');
    });

    test('an edit with no changes writes nothing', () async {
      final t = taskFixture(creatorId: 'asha');
      final c = containerFor(asha);
      final outcome = await actions(c).edit(
        t,
        TaskDraft(
          title: t.title,
          description: t.description,
          deadline: t.deadline,
          priority: t.priority,
          assigneeIds: t.assigneeIds,
          deptId: t.deptId,
        ),
      );
      expect(outcome, WriteOutcome.saved);
      expect(
        (await db.collection('orgs').doc(testOrg).collection('tasks').get())
            .docs,
        isEmpty,
      );
    });

    test('reassign offline says it needs a connection', () async {
      when(() => callables.call('reassignTask', any()))
          .thenThrow(const ConnectionRequiredFailure());
      final c = containerFor(grace);
      expect(
        actions(c).reassign(taskFixture(), ['baraka']),
        throwsA(isA<ConnectionRequiredFailure>()),
      );
    });

    test('signed out: actions fail with UnauthenticatedFailure', () {
      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(null),
          clockProvider.overrideWithValue(() => testNow),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(taskActionsProvider.notifier).start(taskFixture()),
        throwsA(isA<UnauthenticatedFailure>()),
      );
    });
  });
}
