import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/localization/l10n.dart';
import '../../../shared/models/department.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/sync_banner.dart';
import '../../users/presentation/user_providers.dart';
import 'department_editor_dialog.dart';
import 'department_providers.dart';

/// Admin: departments list (spec 4.2) with create, edit and deactivate.
/// Writes go straight to Firestore (rules: verified admins) and work
/// offline; the sync banner shows when changes are waiting.
class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    Department? department,
  ]) async {
    final result = await showDialog<DepartmentEditorResult>(
      context: context,
      builder: (_) => DepartmentEditorDialog(department: department),
    );
    if (result == null || !context.mounted) return;
    try {
      final outcome = await ref
          .read(departmentEditorProvider.notifier)
          .save(
            id: department?.id,
            name: result.name,
            headUserId: result.headUserId,
          );
      if (!context.mounted) return;
      showWriteOutcomeSnackBar(context, outcome);
      await ref.read(departmentListProvider.notifier).refresh();
    } catch (error, stackTrace) {
      if (context.mounted) {
        showFailureSnackBar(context, mapError(error, stackTrace));
      }
    }
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    Department department,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deactivateDepartmentTitle),
        content: Text(l10n.deactivateDepartmentMessage(department.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('confirmDeactivateButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDeactivate),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final outcome = await ref
          .read(departmentEditorProvider.notifier)
          .deactivate(department.id);
      if (!context.mounted) return;
      showWriteOutcomeSnackBar(context, outcome);
      await ref.read(departmentListProvider.notifier).refresh();
    } catch (error, stackTrace) {
      if (context.mounted) {
        showFailureSnackBar(context, mapError(error, stackTrace));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(departmentListProvider);
    final people = ref.watch(userLookupProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDepartmentsTitle)),
      body: Column(
        children: [
          const SyncBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(departmentListProvider.notifier).refresh(),
              child: PagedListView<Department>(
                state: state,
                onLoadMore: () =>
                    ref.read(departmentListProvider.notifier).loadMore(),
                empty: EmptyState(
                  icon: Icons.apartment_outlined,
                  title: l10n.departmentsEmptyTitle,
                  message: l10n.departmentsEmptyMessage,
                ),
                itemBuilder: (context, dept) {
                  final head = dept.headUserId == null
                      ? null
                      : people[dept.headUserId];
                  return ListTile(
                    key: ValueKey('dept-${dept.id}'),
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(dept.name),
                    subtitle: Text(
                      dept.headUserId == null
                          ? l10n.departmentNoHead
                          : l10n.departmentHead(
                              head?.name ?? l10n.valueNotLoaded,
                            ),
                    ),
                    onTap: () => _edit(context, ref, dept),
                    trailing: dept.active
                        ? PopupMenuButton<String>(
                            key: ValueKey('deptMenu-${dept.id}'),
                            tooltip: l10n.actionMoreOptions,
                            onSelected: (value) => value == 'edit'
                                ? _edit(context, ref, dept)
                                : _deactivate(context, ref, dept),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit', // l10n-ignore: menu value id
                                child: Text(l10n.actionEdit),
                              ),
                              PopupMenuItem(
                                value:
                                    'deactivate', // l10n-ignore: menu value id
                                child: Text(l10n.actionDeactivate),
                              ),
                            ],
                          )
                        : StatusChip(label: l10n.labelInactive),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addDepartmentButton'),
        heroTag: 'departmentsFab',
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAddDepartment),
      ),
    );
  }
}
