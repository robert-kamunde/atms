import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/assignment_state.dart';
import '../../../../shared/models/task.dart';
import '../../../../shared/models/task_priority.dart';
import '../../../../shared/widgets/enum_labels.dart';

/// Date and time of a deadline in the phone's time zone.
String formatDeadline(DateTime deadline, AppLocalizations l10n) =>
    DateFormat.yMMMEd(l10n.localeName).add_Hm().format(deadline.toLocal());

/// Names of [ids] from [people]; people not loaded yet show as "Someone".
String peopleNames(
  Iterable<String> ids,
  Map<String, AppUser> people,
  AppLocalizations l10n,
) => ids
    .map((id) => people[id]?.name ?? l10n.unknownPerson)
    .join(', '); // l10n-ignore: list separator

/// A small coloured label (status, priority, warnings). Colour is never
/// the only signal: the text says the same.
class TaskLabel extends StatelessWidget {
  const TaskLabel({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// The labels shown for a task in lists, the board and the detail screen:
/// status, priority, overdue, assignment, sync and reassignment state, and
/// progress for tasks every assignee must finish.
List<Widget> taskLabels(
  BuildContext context,
  Task task, {
  required DateTime now,
}) {
  final l10n = context.l10n;
  final colors = context.atmsColors;
  final scheme = Theme.of(context).colorScheme;
  return [
    if (task.assignmentState == AssignmentState.pending)
      TaskLabel(
        key: const Key('labelPending'),
        text: l10n.assignmentPendingLabel,
        color: colors.syncing,
        icon: Icons.hourglass_empty,
      )
    else if (task.assignmentState == AssignmentState.rejected)
      TaskLabel(
        key: const Key('labelRejected'),
        text: l10n.assignmentRejectedLabel,
        color: scheme.error,
        icon: Icons.error_outline,
      )
    else
      TaskLabel(
        text: task.status.label(l10n),
        color: colors.forStatus(task.status),
      ),
    TaskLabel(
      text: task.priority.label(l10n),
      color: colors.forPriority(task.priority),
      icon: task.priority == TaskPriority.urgent ? Icons.priority_high : null,
    ),
    if (task.isOverdueAt(now))
      TaskLabel(
        text: l10n.dueOverdue,
        color: colors.overdue,
        icon: Icons.schedule,
      ),
    if (task.needsEveryAssignee && task.status.isOpen)
      TaskLabel(
        text: l10n.taskProgress(
          task.completedByIds.length,
          task.assigneeIds.length,
        ),
        color: colors.inProgress,
        icon: Icons.groups_outlined,
      ),
    if (task.reassignmentNeeded)
      TaskLabel(
        text: l10n.reassignmentNeededLabel,
        color: colors.overdue,
        icon: Icons.person_off_outlined,
      ),
    if (task.hasPendingWrites)
      TaskLabel(
        key: const Key('labelWaitingToSync'),
        text: l10n.waitingToSyncLabel,
        color: colors.offline,
        icon: Icons.cloud_upload_outlined,
      ),
  ];
}

/// One task in a list (My Tasks, Team Tasks).
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.now,
    required this.onTap,
    this.assigneeNames,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onTap;

  /// Shown on Team Tasks.
  final String? assigneeNames;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rejected = task.assignmentState == AssignmentState.rejected;
    return Card(
      key: ValueKey('task-${task.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.taskDueAt(formatDeadline(task.deadline, l10n)),
                style: theme.textTheme.bodySmall,
              ),
              if (assigneeNames != null && assigneeNames!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  assigneeNames!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (rejected) ...[
                const SizedBox(height: 4),
                Text(
                  assignmentErrorMessage(task.assignmentError, l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: taskLabels(context, task, now: now),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
