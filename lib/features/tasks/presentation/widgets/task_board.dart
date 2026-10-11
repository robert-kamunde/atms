import 'package:flutter/material.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../shared/models/task.dart';
import '../../../../shared/models/task_status.dart';
import '../../../../shared/providers/paged_list_controller.dart';
import '../../../../shared/widgets/enum_labels.dart';
import 'task_tile.dart';

/// Kanban board (spec 4.3): one column per status, built from the same
/// loaded pages as the list (20 tasks at a time, "Load more" below). It
/// never loads more than the list does.
class TaskBoard extends StatelessWidget {
  const TaskBoard({
    super.key,
    required this.state,
    required this.tasks,
    required this.statuses,
    required this.now,
    required this.onOpen,
    required this.onLoadMore,
  });

  final PagedListState<Task> state;

  /// The loaded tasks after filters.
  final List<Task> tasks;

  /// Columns, in order.
  final List<TaskStatus> statuses;
  final DateTime now;
  final ValueChanged<Task> onOpen;
  final VoidCallback onLoadMore;

  static const double columnWidth = 280;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.atmsColors;
    final footer = state.loading
        ? const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          )
        : state.failure != null
        ? ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(failureMessage(state.failure!, l10n)),
            trailing: TextButton(
              key: const Key('retryButton'),
              onPressed: onLoadMore,
              child: Text(l10n.actionRetry),
            ),
          )
        : state.hasMore
        ? Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: OutlinedButton(
                key: const Key('loadMoreButton'),
                onPressed: onLoadMore,
                child: Text(l10n.actionLoadMore),
              ),
            ),
          )
        : const SizedBox.shrink();
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const Key('taskBoard'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            children: [
              for (final status in statuses)
                SizedBox(
                  width: columnWidth,
                  child: _BoardColumn(
                    key: ValueKey('boardColumn-${status.firestoreValue}'),
                    title: status.label(l10n),
                    color: colors.forStatus(status),
                    tasks: tasks.where((t) => t.status == status).toList(),
                    now: now,
                    onOpen: onOpen,
                  ),
                ),
            ],
          ),
        ),
        footer,
      ],
    );
  }
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    super.key,
    required this.title,
    required this.color,
    required this.tasks,
    required this.now,
    required this.onOpen,
  });

  final String title;
  final Color color;
  final List<Task> tasks;
  final DateTime now;
  final ValueChanged<Task> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: color, width: 4)),
            ),
            padding: const EdgeInsets.all(12),
            child: Semantics(
              header: true,
              child: Text(
                l10n.boardColumnTitle(title, tasks.length),
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      l10n.boardColumnEmpty,
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      for (final task in tasks)
                        TaskTile(
                          task: task,
                          now: now,
                          onTap: () => onOpen(task),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
