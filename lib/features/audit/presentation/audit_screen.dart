import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/models/audit_entry.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../../users/presentation/user_providers.dart';
import 'audit_providers.dart';
import 'widgets/activity_tile.dart';

/// Admin: audit log (spec 4.11), newest first, 20 at a time. Read-only:
/// only server functions write it. Confidential entries are not shown to
/// admins (spec 2).
class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(orgActivityProvider);
    final people = ref.watch(userLookupProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminAuditTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(orgActivityProvider.notifier).refresh(),
        child: PagedListView<AuditEntry>(
          state: state,
          onLoadMore: () => ref.read(orgActivityProvider.notifier).loadMore(),
          empty: EmptyState(
            icon: Icons.history,
            title: l10n.auditEmptyTitle,
            message: l10n.auditEmptyMessage,
          ),
          itemBuilder: (context, entry) =>
              ActivityTile(entry: entry, people: people),
        ),
      ),
    );
  }
}
