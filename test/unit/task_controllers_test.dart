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
