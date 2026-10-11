import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/enum_labels.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../departments/presentation/department_providers.dart';
import 'user_providers.dart';
import 'widgets/user_picker.dart';

/// Admin: people list (spec 4.2), 20 at a time, with a name search over
/// the loaded pages. Flags deactivated people and people whose supervisor
/// is deactivated (they need a new supervisor; docs/SPRINT1_CONTRACT.md).
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(userListProvider);
    final people = ref.watch(userLookupProvider);
    final departments = ref.watch(departmentLookupProvider);
    ref.listen(userListProvider, (_, next) {
      ref
          .read(departmentLookupProvider.notifier)
          .ensure(next.items.map((u) => u.deptId));
    });
    final visible = state.items
        .where((u) => nameMatches(u.name, _query))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminUsersTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(userListProvider.notifier).refresh(),
        child: PagedListView<AppUser>(
          state: state,
          items: visible,
          onLoadMore: () => ref.read(userListProvider.notifier).loadMore(),
          footerNote: _query.isEmpty ? null : l10n.searchLoadedOnlyNote,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const Key('userSearchField'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.searchByName,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          empty: EmptyState(
            icon: Icons.people_outline,
            title: l10n.usersEmptyTitle,
            message: l10n.usersEmptyMessage,
          ),
          itemBuilder: (context, user) {
            final supervisor = user.supervisorId == null
                ? null
                : people[user.supervisorId];
            final department = departments[user.deptId];
            final supervisorInactive = supervisor != null && !supervisor.active;
            return ListTile(
              key: ValueKey('user-${user.id}'),
              leading: CircleAvatar(
                child: Icon(user.active ? Icons.person : Icons.person_off),
              ),
              title: Text(user.name),
              subtitle: Text(
                [
                  user.role.label(l10n),
                  ?department?.name,
                  if (user.supervisorId == null) l10n.userTopOfOrganisation,
                ].join(' · '), // l10n-ignore: separator
              ),
              trailing: !user.active
                  ? StatusChip(label: l10n.labelInactive)
                  : supervisorInactive
                  ? StatusChip(
                      label: l10n.labelSupervisorInactive,
                      warning: true,
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () => context.go(RoutePaths.adminUserDetailFor(user.id)),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addUserButton'),
        heroTag: 'usersFab',
        onPressed: () => context.go(RoutePaths.adminUserNew),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.actionAddUser),
      ),
    );
  }
}
