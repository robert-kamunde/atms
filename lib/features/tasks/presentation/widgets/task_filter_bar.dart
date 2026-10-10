import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../shared/models/task_priority.dart';
import '../../../../shared/models/task_status.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/enum_labels.dart';
import '../../domain/task_filter.dart';

/// Horizontal row of filter chips: status, priority, assignee, department,
/// due date (spec 4.3). Assignee and department are offered only when
/// [showPeopleFilters] is true (Team Tasks); their options are the people
/// on the loaded pages and the departments known so far.
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    this.showPeopleFilters = true,
    this.assigneeOptions = const {},
    this.departmentOptions = const {},
    this.statuses = TaskStatus.values,
  });

  final TaskFilter filter;
  final ValueChanged<TaskFilter> onChanged;
  final bool showPeopleFilters;

  /// Person id -> name.
  final Map<String, String> assigneeOptions;

  /// Department id -> name.
  final Map<String, String> departmentOptions;

  /// Statuses offered by the status filter.
  final List<TaskStatus> statuses;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _chip(
            context,
            key: const Key('filterStatus'),
            label: filter.status?.label(l10n) ?? l10n.filterStatus,
            selected: filter.status != null,
            onTap: () => _pick<TaskStatus>(
              context,
              title: l10n.filterStatus,
              options: {for (final s in statuses) s: s.label(l10n)},
              current: filter.status,
              onPicked: (v) => onChanged(filter.copyWith(status: () => v)),
            ),
          ),
          _chip(
            context,
            key: const Key('filterPriority'),
            label: filter.priority?.label(l10n) ?? l10n.filterPriority,
            selected: filter.priority != null,
            onTap: () => _pick<TaskPriority>(
              context,
              title: l10n.filterPriority,
              options: {for (final p in TaskPriority.values) p: p.label(l10n)},
              current: filter.priority,
              onPicked: (v) => onChanged(filter.copyWith(priority: () => v)),
            ),
          ),
          if (showPeopleFilters) ...[
            _chip(
              context,
              key: const Key('filterAssignee'),
              label: filter.assigneeId == null
                  ? l10n.filterAssignee
                  : assigneeOptions[filter.assigneeId] ?? l10n.unknownPerson,
              selected: filter.assigneeId != null,
              onTap: () => _pick<String>(
                context,
                title: l10n.filterAssignee,
                options: assigneeOptions,
                current: filter.assigneeId,
                onPicked: (v) =>
                    onChanged(filter.copyWith(assigneeId: () => v)),
              ),
            ),
            _chip(
              context,
              key: const Key('filterDepartment'),
              label: filter.deptId == null
                  ? l10n.filterDepartment
                  : departmentOptions[filter.deptId] ?? l10n.filterDepartment,
              selected: filter.deptId != null,
              onTap: () => _pick<String>(
                context,
                title: l10n.filterDepartment,
                options: departmentOptions,
                current: filter.deptId,
                onPicked: (v) => onChanged(filter.copyWith(deptId: () => v)),
              ),
            ),
          ],
          _chip(
            context,
            key: const Key('filterDue'),
            label: switch (filter.due) {
              null => l10n.filterDueDate,
              DueFilter.today => l10n.dueToday,
              DueFilter.thisWeek => l10n.dueThisWeek,
              DueFilter.overdue => l10n.dueOverdue,
            },
            selected: filter.due != null,
            onTap: () => _pick<DueFilter>(
              context,
              title: l10n.filterDueDate,
              options: {
                DueFilter.today: l10n.dueToday,
                DueFilter.thisWeek: l10n.dueThisWeek,
                DueFilter.overdue: l10n.dueOverdue,
              },
              current: filter.due,
              onPicked: (v) => onChanged(filter.copyWith(due: () => v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        key: key,
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    required Map<T, String> options,
    required T? current,
    required ValueChanged<T?> onPicked,
  }) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            if (options.isEmpty)
              EmptyState(
                compact: true,
                icon: Icons.inbox_outlined,
                title: l10n.filterNoOptionsYet,
              )
            else
              for (final entry in options.entries)
                ListTile(
                  title: Text(entry.value),
                  trailing: entry.key == current
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    onPicked(entry.key);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            if (current != null)
              ListTile(
                leading: const Icon(Icons.clear),
                title: Text(l10n.filterClear),
                onTap: () {
                  onPicked(null);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
