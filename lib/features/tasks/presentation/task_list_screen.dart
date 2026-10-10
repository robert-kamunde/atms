import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/firebase_providers.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/task_status.dart';
import '../../../shared/providers/paged_list_controller.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../../../shared/widgets/sync_banner.dart';
import '../../departments/presentation/department_providers.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/task_filter.dart';
import 'task_providers.dart';
import 'widgets/task_board.dart';
import 'widgets/task_filter_bar.dart';
import 'widgets/task_tile.dart';

/// My Tasks (spec 4.3), or Team Tasks for managers and admins when [team]
/// is true. Both load 20 tasks at a time sorted by deadline, as a list or
/// as a Kanban board built from the same pages.
///
/// My Tasks also shows the tasks I created that the server has not
/// assigned yet or refused (A-01), with the reason.
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key, this.team = false});

  final bool team;

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  bool _board = false;

  /// My Tasks filters (applied within loaded pages; Team Tasks keeps its
  /// filter in [teamTaskFilterProvider] because part of it is a query).
  TaskFilter _myFilter = const TaskFilter();

  bool get _team => widget.team;

  void _open(Task task) => context.push(RoutePaths.taskDetailFor(task.id));

  Future<void> _refresh() async {
    if (_team) {
      await ref.read(teamTasksProvider.notifier).refresh();
    } else {
      await Future.wait([
        ref.read(myTasksProvider.notifier).refresh(),
        ref.read(myUnassignedTasksProvider.notifier).refresh(),
      ]);
    }
  }

  void _loadMore() => _team
      ? ref.read(teamTasksProvider.notifier).loadMore()
      : ref.read(myTasksProvider.notifier).loadMore();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = ref.watch(clockProvider)();
    final state = ref.watch(_team ? teamTasksProvider : myTasksProvider);
    final filter = _team ? ref.watch(teamTaskFilterProvider) : _myFilter;
    final people = ref.watch(userLookupProvider);
    final departments = ref.watch(departmentLookupProvider);
    final visible = state.items.where((t) => filter.matches(t, now)).toList();

    void setFilter(TaskFilter next) {
      if (_team) {
        ref.read(teamTaskFilterProvider.notifier).set(next);
      } else {
        setState(() => _myFilter = next);
      }
    }

    final assigneeOptions = <String, String>{
      for (final id in state.items.expand((t) => t.assigneeIds))
        id: people[id]?.name ?? l10n.unknownPerson,
    };
    final departmentOptions = <String, String>{
      for (final id in state.items.map((t) => t.deptId))
        id: departments[id]?.name ?? l10n.unknownDepartment,
    };
    // Some filters only look at the tasks loaded so far: say so while more
    // pages exist.
    final pageFiltered = _team ? filter.hasPageFilters : !filter.isEmpty;
    final showPageNote = pageFiltered && state.hasMore;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskFilterBar(
          filter: filter,
          onChanged: setFilter,
          showPeopleFilters: _team,
          assigneeOptions: assigneeOptions,
          departmentOptions: departmentOptions,
          statuses: _team ? TaskStatus.values : TaskStatus.openStatuses,
        ),
        if (showPageNote)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.filterLoadedOnlyNote,
              key: const Key('filterLoadedOnlyNote'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const Divider(height: 1),
      ],
    );

    final Widget body;
    if (_board) {
      body = Column(
        children: [
          header,
          Expanded(
            child: TaskBoard(
              state: state,
              tasks: visible,
              statuses: _team ? TaskStatus.values : TaskStatus.openStatuses,
              now: now,
              onOpen: _open,
              onLoadMore: _loadMore,
            ),
          ),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: PagedListView<Task>(
          state: state,
          items: visible,
          onLoadMore: _loadMore,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              if (!_team) _UnassignedSection(now: now, onOpen: _open),
              if (state.loadedOnce && state.items.isNotEmpty && visible.isEmpty)
                EmptyState(
                  compact: true,
                  icon: Icons.filter_alt_off_outlined,
                  title: l10n.tasksEmptyFilteredTitle,
                ),
            ],
          ),
          empty: EmptyState(
            key: const Key('taskListEmpty'),
            icon: Icons.task_alt,
            title: !filter.queryPart.isEmpty && _team
                ? l10n.tasksEmptyFilteredTitle
                : _team
                ? l10n.teamTasksEmptyTitle
                : l10n.tasksEmptyTitle,
            message: _team ? null : l10n.tasksEmptyMessage,
          ),
          itemBuilder: (context, task) => TaskTile(
            task: task,
            now: now,
            onTap: () => _open(task),
            assigneeNames: _team
                ? peopleNames(task.assigneeIds, people, l10n)
                : null,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_team ? l10n.teamTasksTitle : l10n.myTasksTitle),
        actions: [
          IconButton(
            key: const Key('toggleBoardButton'),
            tooltip: _board ? l10n.showAsList : l10n.showAsBoard,
            icon: Icon(_board ? Icons.view_list : Icons.view_kanban_outlined),
            onPressed: () => setState(() => _board = !_board),
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncBanner(),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: _team ? 'teamTasksFab' : 'myTasksFab',
        onPressed: () => context.push(RoutePaths.taskNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionNewTask),
      ),
    );
  }
}

/// "Waiting to be assigned" on My Tasks: tasks I created that the server
/// has not assigned yet or refused, with their own paging.
class _UnassignedSection extends ConsumerWidget {
  const _UnassignedSection({required this.now, required this.onOpen});

  final DateTime now;
  final ValueChanged<Task> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final PagedListState<Task> state = ref.watch(myUnassignedTasksProvider);
    if (state.items.isEmpty && state.failure == null) {
      return const SizedBox.shrink();
    }
    return Column(
      key: const Key('unassignedSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Semantics(
            header: true,
            child: Text(
              l10n.unassignedSectionTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        for (final task in state.items)
          TaskTile(task: task, now: now, onTap: () => onOpen(task)),
        if (state.failure != null)
          ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(failureMessage(state.failure!, l10n)),
            trailing: TextButton(
              onPressed: () =>
                  ref.read(myUnassignedTasksProvider.notifier).loadMore(),
              child: Text(l10n.actionRetry),
            ),
          )
        else if (state.hasMore)
          Center(
            child: TextButton(
              key: const Key('unassignedLoadMore'),
              onPressed: () =>
                  ref.read(myUnassignedTasksProvider.notifier).loadMore(),
              child: Text(l10n.actionLoadMore),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Semantics(
            header: true,
            child: Text(
              l10n.assignedSectionTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
      ],
    );
  }
}
