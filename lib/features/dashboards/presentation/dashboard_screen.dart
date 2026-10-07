import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/sync_banner.dart';
import '../../auth/presentation/auth_providers.dart';

/// One dashboard card definition.
typedef DashboardCardSpec = ({Key key, IconData icon, String title});

/// Role-specific dashboard (spec 4.10).
///
/// NOT IMPLEMENTED (Sprint 6): values are read from the server-maintained
/// counter documents `orgs/{org}/stats/{scope_day}`. Until then every card
/// shows "No data yet"; no numbers are invented.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static List<DashboardCardSpec> cardsFor(
    UserRole role,
    AppLocalizations l10n,
  ) => switch (role) {
    UserRole.staff => [
      (
        key: const Key('dashStaffDueToday'),
        icon: Icons.today,
        title: l10n.dashDueToday,
      ),
      (
        key: const Key('dashStaffDueWeek'),
        icon: Icons.date_range,
        title: l10n.dashDueThisWeek,
      ),
      (
        key: const Key('dashStaffOverdue'),
        icon: Icons.warning_amber,
        title: l10n.dashMyOverdue,
      ),
      (
        key: const Key('dashStaffCompletion'),
        icon: Icons.percent,
        title: l10n.dashCompletionRate,
      ),
    ],
    UserRole.manager => [
      (
        key: const Key('dashMgrTotals'),
        icon: Icons.stacked_bar_chart,
        title: l10n.dashTeamByStatus,
      ),
      (
        key: const Key('dashMgrOverdue'),
        icon: Icons.warning_amber,
        title: l10n.dashOverdueEscalated,
      ),
      (
        key: const Key('dashMgrApprovals'),
        icon: Icons.fact_check_outlined,
        title: l10n.dashApprovalsWaiting,
      ),
      (
        key: const Key('dashMgrWorkload'),
        icon: Icons.groups_outlined,
        title: l10n.dashWorkloadPerPerson,
      ),
      (
        key: const Key('dashMgrBottleneck'),
        icon: Icons.hourglass_bottom,
        title: l10n.dashAvgDaysPerStep,
      ),
    ],
    UserRole.admin => [
      (
        key: const Key('dashAdminDepts'),
        icon: Icons.apartment_outlined,
        title: l10n.dashOrgByDepartment,
      ),
      (
        key: const Key('dashAdminSms'),
        icon: Icons.sms_outlined,
        title: l10n.dashSmsSpend,
      ),
      (
        key: const Key('dashAdminUsers'),
        icon: Icons.people_outline,
        title: l10n.dashActiveUsers,
      ),
      (
        key: const Key('dashAdminTemplates'),
        icon: Icons.account_tree_outlined,
        title: l10n.dashTemplatesInUse,
      ),
    ],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final role = ref.watch(currentRoleProvider) ?? UserRole.staff;
    final cards = cardsFor(role, l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SyncBanner(),
          for (final card in cards)
            Card(
              key: card.key,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(card.icon, color: theme.colorScheme.primary),
                title: Text(card.title, style: theme.textTheme.titleMedium),
                subtitle: Text(l10n.dashNoDataYet),
              ),
            ),
        ],
      ),
    );
  }
}
