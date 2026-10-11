import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/enum_labels.dart';
import '../../../shared/widgets/status_chip.dart';
import 'org_providers.dart';

/// Admin: reporting tree view (spec 4.2), built from each person's
/// `supervisorId`. Starts at the top of the organisation; tapping a person
/// shows their direct reports (20 at a time). People whose supervisor is
/// deactivated are flagged. Loops are rejected by the server when saving.
class ReportingTreeScreen extends ConsumerWidget {
  const ReportingTreeScreen({super.key});

  static const double _indent = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(reportingTreeProvider);
    final controller = ref.read(reportingTreeProvider.notifier);
    final root = state.branches[reportingTreeRootKey];
    final rows = flattenReportingTree(state);
    final Widget body;
    if (root != null &&
        root.loadedOnce &&
        root.items.isEmpty &&
        root.failure == null) {
      body = EmptyState(
        icon: Icons.account_tree_outlined,
        title: l10n.reportingTreeEmptyTitle,
        message: l10n.reportingTreeEmptyMessage,
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          final indent = EdgeInsetsDirectional.only(
            start: 8 + row.depth * _indent,
            end: 8,
          );
          switch (row) {
            case TreePersonRow(:final user, :final expanded):
              return Padding(
                padding: indent,
                child: ListTile(
                  key: ValueKey('tree-${user.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: IconButton(
                    tooltip: expanded
                        ? l10n.actionHideReports
                        : l10n.actionShowReports,
                    icon: Icon(
                      expanded ? Icons.expand_more : Icons.chevron_right,
                    ),
                    onPressed: () => controller.toggle(user.id),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.role.label(l10n)),
                  trailing: !user.active
                      ? StatusChip(label: l10n.labelInactive)
                      : row.supervisorInactive
                      ? StatusChip(
                          label: l10n.labelSupervisorInactive,
                          warning: true,
                        )
                      : null,
                  onTap: () => controller.toggle(user.id),
                  onLongPress: () =>
                      context.go(RoutePaths.adminUserDetailFor(user.id)),
                ),
              );
            case TreeStatusRow(:final parentKey, :final branch):
              final Widget child;
              if (branch.loading) {
                child = const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (branch.failure != null) {
                child = ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: Text(failureMessage(branch.failure!, l10n)),
                  trailing: TextButton(
                    onPressed: () => controller.loadMore(parentKey),
                    child: Text(l10n.actionRetry),
                  ),
                );
              } else {
                child = Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    key: ValueKey('treeMore-$parentKey'),
                    onPressed: () => controller.loadMore(parentKey),
                    child: Text(l10n.actionLoadMore),
                  ),
                );
              }
              return Padding(padding: indent, child: child);
          }
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminReportingTreeTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.reportingTreeHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
