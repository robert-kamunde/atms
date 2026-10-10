import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/firebase_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/services/offline_write.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/task_status.dart';
import '../../../shared/providers/live_paged_list_controller.dart';
import '../../../shared/providers/paged_list_controller.dart';
import '../../../shared/services/paginated_query.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../departments/presentation/department_providers.dart';
import '../../users/presentation/user_providers.dart';
import '../data/firestore_task_repository.dart';
import '../domain/task_filter.dart';
import '../domain/task_policy.dart';
import '../domain/task_repository.dart';

/// The signed-in person as a task actor; null when not signed in.
final taskActorProvider = Provider<TaskActor?>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthSignedIn) return null;
  final uid = auth.session?.uid;
  if (uid == null) return null;
  return TaskActor(
    uid: uid,
    role: auth.role,
    isVerifiedAdmin: auth.isAdminVerifiedAt(ref.watch(clockProvider)()),
  );
});

/// Tasks of the signed-in person's organisation; null when signed out.
final taskRepositoryProvider = Provider<TaskRepository?>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return null;
  return FirestoreTaskRepository(
    ref.watch(firestoreProvider),
    () => ref.read(callableClientProvider),
    orgId: session.orgId,
    uid: session.uid,
    clock: ref.watch(clockProvider),
  );
});

/// Looks up the names of the people and departments on loaded tasks.
void _lookupNames(Ref ref, List<Task> items) {
  ref
      .read(userLookupProvider.notifier)
      .ensure(items.expand((t) => [t.creatorId, ...t.assigneeIds]));
  ref
      .read(departmentLookupProvider.notifier)
      .ensure(items.map((t) => t.deptId));
}

/// My Tasks: open tasks assigned to me, by deadline, 20 at a time, live
/// (status changes and new assignments show without a refresh).
class MyTasksController extends LivePagedListController<Task> {
  @override
  LivePaginatedSource<Task> createSource() =>
      requireRepository(ref.read(taskRepositoryProvider)).myTasks();

  @override
  void onItemsLoaded(List<Task> items) => _lookupNames(ref, items);
}

final myTasksProvider =
    NotifierProvider.autoDispose<MyTasksController, PagedListState<Task>>(
      MyTasksController.new,
    );

/// Tasks I created that are waiting to be assigned or were refused (A-01),
/// live.
class MyUnassignedTasksController extends LivePagedListController<Task> {
  @override
  LivePaginatedSource<Task> createSource() =>
      requireRepository(ref.read(taskRepositoryProvider)).myUnassignedTasks();

  @override
  void onItemsLoaded(List<Task> items) => _lookupNames(ref, items);
}

final myUnassignedTasksProvider =
    NotifierProvider.autoDispose<
      MyUnassignedTasksController,
      PagedListState<Task>
    >(MyUnassignedTasksController.new);

/// The filters chosen on Team Tasks.
class TeamTaskFilterController extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => const TaskFilter();

  void set(TaskFilter filter) => state = filter;
}

final teamTaskFilterProvider =
    NotifierProvider<TeamTaskFilterController, TaskFilter>(
      TeamTaskFilterController.new,
    );

/// Team Tasks (managers, admins): by deadline, 20 at a time, live.
/// Listens again from the first page when a filter that is part of the
/// query changes.
class TeamTasksController extends LivePagedListController<Task> {
  @override
  PagedListState<Task> build() {
    ref.watch(teamTaskFilterProvider.select((f) => f.queryPart));
    ref.watch(taskActorProvider.select((a) => a?.isVerifiedAdmin));
    return super.build();
  }

  @override
  LivePaginatedSource<Task> createSource() {
    final repo = requireRepository(ref.read(taskRepositoryProvider));
    final filter = ref.read(teamTaskFilterProvider).queryPart;
    final now = ref.read(clockProvider)();
    final actor = ref.read(taskActorProvider);
    return (actor?.isVerifiedAdmin ?? false)
        ? repo.orgTasks(filter, now: now)
        : repo.teamTasks(filter, now: now);
  }

  @override
  void onItemsLoaded(List<Task> items) => _lookupNames(ref, items);
}

final teamTasksProvider =
    NotifierProvider.autoDispose<TeamTasksController, PagedListState<Task>>(
      TeamTasksController.new,
    );

/// One task, live (detail screen). Null when it does not exist.
final taskDetailProvider = StreamProvider.autoDispose.family<Task?, String>((
  ref,
  taskId,
) {
  final repo = ref.watch(taskRepositoryProvider);
  if (repo == null) return Stream.error(const UnauthenticatedFailure());
  return repo.watchTask(taskId);
}, retry: (_, _) => null);

/// A one-page source with fixed items (the "only me" assignee list).
class FixedPageSource<T> implements PaginatedSource<T> {
  const FixedPageSource(this.items);

  final List<T> items;

  @override
  int get pageSize => items.length;

  @override
  Future<PageResult<T>> fetchPage({PageCursor? after}) async =>
      PageResult<T>(items: after == null ? items : const []);
}

/// People the signed-in person may assign (spec 2 matrix), 20 at a time:
/// staff only themselves, managers their reporting tree, verified admins
/// anyone. The server checks again when the task syncs (A-01).
class AssignablePeopleController extends PagedListController<AppUser> {
  @override
  PagedListState<AppUser> build() {
    ref.watch(taskActorProvider);
    return super.build();
  }

  @override
  PaginatedSource<AppUser> createSource() {
    final actor = ref.read(taskActorProvider);
    final me = ref.read(currentSessionProvider)?.user;
    if (actor == null || me == null) throw const UnauthenticatedFailure();
    final users = requireRepository(ref.read(userDirectoryRepositoryProvider));
    return switch (assigneeScopeFor(actor)) {
      AssigneeScope.selfOnly => FixedPageSource([me]),
      AssigneeScope.team => users.teamMembers(actor.uid),
      AssigneeScope.anyone => users.allUsers(),
    };
  }

  @override
  void onPageLoaded(List<AppUser> items) {
    final lookup = ref.read(userLookupProvider.notifier);
    for (final user in items) {
      lookup.put(user);
    }
  }
}

final assignablePeopleProvider =
    NotifierProvider.autoDispose<
      AssignablePeopleController,
      PagedListState<AppUser>
    >(AssignablePeopleController.new);

/// Result of creating a task.
@immutable
class CreatedTask {
  const CreatedTask(this.taskId, this.outcome);

  final String taskId;
  final WriteOutcome outcome;
}

/// Every task change. Firestore writes work offline: the result says
/// whether the server confirmed or the change is kept on the phone
/// (A-25). Reassign is a callable and needs a connection. Methods throw
/// `AppFailure` only.
class TaskActions extends Notifier<void> {
  @override
  void build() {}

  TaskRepository get _repo =>
      requireRepository(ref.read(taskRepositoryProvider));

  Future<WriteOutcome> _run(String name, Future<void> Function() write) async {
    final Future<void> future;
    try {
      future = write();
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
    // The task lists are live, so they show the change by themselves.
    return awaitOfflineCapableWrite(future, writeName: name);
  }

  Future<CreatedTask> create(TaskDraft draft) async {
    final repo = _repo;
    final id = repo.newTaskId();
    final outcome = await _run('createTask', () => repo.create(id, draft));
    return CreatedTask(id, outcome);
  }

  /// Sends only the fields that changed; nothing when nothing changed.
  Future<WriteOutcome> edit(Task before, TaskDraft after) {
    final edit = TaskEdit.between(before, after);
    if (edit.isEmpty) return Future.value(WriteOutcome.saved);
    return _run('editTask', () => _repo.updateDetails(before.id, edit));
  }

  Future<WriteOutcome> start(Task task) => _run(
    'startTask',
    () => _repo.changeStatus(task.id, TaskStatus.inProgress),
  );

  Future<WriteOutcome> block(Task task, String reason) => _run(
    'blockTask',
    () => _repo.changeStatus(task.id, TaskStatus.blocked, reason: reason),
  );

  Future<WriteOutcome> resume(Task task) => _run(
    'resumeTask',
    () => _repo.changeStatus(task.id, TaskStatus.inProgress),
  );

  /// Done, or Waiting for check when the creator asked to check (D-06).
  Future<WriteOutcome> markDone(Task task) => _run(
    'markTaskDone',
    () => _repo.changeStatus(task.id, TaskPolicy.doneTarget(task)),
  );

  Future<WriteOutcome> markMyPartDone(Task task) =>
      _run('markMyPartDone', () => _repo.markMyPartDone(task.id));

  Future<WriteOutcome> confirmCheck(Task task) =>
      _run('confirmCheck', () => _repo.confirmCheck(task.id));

  Future<WriteOutcome> returnWork(Task task, String reason) =>
      _run('returnWork', () => _repo.returnWork(task.id, reason));

  Future<WriteOutcome> cancel(Task task, String reason) =>
      _run('cancelTask', () => _repo.cancel(task.id, reason));

  Future<WriteOutcome> delete(Task task) =>
      _run('deleteTask', () => _repo.softDelete(task.id));

  Future<WriteOutcome> resubmit(Task task, TaskDraft draft) =>
      _run('resubmitTask', () => _repo.resubmit(task.id, draft));

  Future<WriteOutcome> discard(Task task) =>
      _run('discardTask', () => _repo.discard(task.id));

  /// Online only (`reassignTask`); offline it throws
  /// `ConnectionRequiredFailure` ("needs connection").
  Future<void> reassign(Task task, List<String> assigneeIds) async {
    try {
      await _repo.reassign(task.id, assigneeIds);
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }
}

final taskActionsProvider = NotifierProvider<TaskActions, void>(
  TaskActions.new,
);
