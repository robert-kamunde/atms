import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/enum_labels.dart';
import '../../../../shared/widgets/paged_list_view.dart';
import '../user_providers.dart';

/// True when [name] contains [query], ignoring case and extra spaces.
bool nameMatches(String name, String query) {
  final q = query.trim().toLowerCase();
  return q.isEmpty || name.toLowerCase().contains(q);
}

/// Lets an admin pick an active person (supervisor, department head).
/// Loads 20 people at a time; the search box filters the loaded pages only.
Future<AppUser?> showUserPicker(
  BuildContext context, {
  required String title,
  Set<String> excludeIds = const {},
}) => showModalBottomSheet<AppUser>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _UserPickerSheet(title: title, excludeIds: excludeIds),
);

class _UserPickerSheet extends ConsumerStatefulWidget {
  const _UserPickerSheet({required this.title, required this.excludeIds});

  final String title;
  final Set<String> excludeIds;

  @override
  ConsumerState<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends ConsumerState<_UserPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(userListProvider);
    final visible = state.items
        .where((u) => u.active && !widget.excludeIds.contains(u.id))
        .where((u) => nameMatches(u.name, _query))
        .toList();
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            trailing: IconButton(
              tooltip: l10n.actionClose,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('userPickerSearch'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.searchByName,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: PagedListView<AppUser>(
              state: state,
              items: visible,
              onLoadMore: () => ref.read(userListProvider.notifier).loadMore(),
              footerNote: _query.isEmpty ? null : l10n.searchLoadedOnlyNote,
              empty: EmptyState(
                icon: Icons.people_outline,
                title: l10n.usersEmptyTitle,
              ),
              itemBuilder: (context, user) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(user.name),
                subtitle: Text(user.role.label(l10n)),
                onTap: () => Navigator.of(context).pop(user),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
