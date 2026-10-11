import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../shared/models/department.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/paged_list_view.dart';
import '../department_providers.dart';

/// Lets an admin pick an active department, 20 at a time.
Future<Department?> showDepartmentPicker(
  BuildContext context, {
  required String title,
  Set<String> excludeIds = const {},
}) => showModalBottomSheet<Department>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _DepartmentPickerSheet(title: title, excludeIds: excludeIds),
);

class _DepartmentPickerSheet extends ConsumerWidget {
  const _DepartmentPickerSheet({required this.title, required this.excludeIds});

  final String title;
  final Set<String> excludeIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(departmentListProvider);
    final visible = state.items
        .where((d) => d.active && !excludeIds.contains(d.id))
        .toList();
    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: Theme.of(context).textTheme.titleLarge),
            trailing: IconButton(
              tooltip: l10n.actionClose,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: PagedListView<Department>(
              state: state,
              items: visible,
              onLoadMore: () =>
                  ref.read(departmentListProvider.notifier).loadMore(),
              empty: EmptyState(
                icon: Icons.apartment_outlined,
                title: l10n.departmentsEmptyTitle,
              ),
              itemBuilder: (context, dept) => ListTile(
                leading: const Icon(Icons.apartment_outlined),
                title: Text(dept.name),
                onTap: () => Navigator.of(context).pop(dept),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
