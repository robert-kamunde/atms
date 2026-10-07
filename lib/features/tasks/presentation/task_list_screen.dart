import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/sync_banner.dart';
import '../domain/task_filter.dart';
import 'widgets/task_filter_bar.dart';

/// My Tasks (spec 4.3), or Team Tasks for managers when [team] is true.
///
/// NOT IMPLEMENTED (Sprint 2): tasks come from a TaskRepository that uses
/// `FirestorePaginatedQuery` (`viewerIds array-contains me`, ordered by
/// deadline, 20 per page). Until then the list is always empty; no sample
/// data is shown.
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, this.team = false});

  final bool team;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskFilter _filter = const TaskFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team ? l10n.teamTasksTitle : l10n.myTasksTitle),
      ),
      body: Column(
        children: [
          const SyncBanner(),
          TaskFilterBar(
            filter: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const Divider(height: 1),
          Expanded(
            child: EmptyState(
              key: const Key('taskListEmpty'),
              icon: Icons.task_alt,
              title: _filter.isEmpty
                  ? (widget.team
                        ? l10n.teamTasksEmptyTitle
                        : l10n.tasksEmptyTitle)
                  : l10n.tasksEmptyFilteredTitle,
              message: _filter.isEmpty ? l10n.tasksEmptyMessage : null,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: widget.team ? 'teamTasksFab' : 'myTasksFab',
        onPressed: () => context.push(RoutePaths.taskNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionNewTask),
      ),
    );
  }
}
