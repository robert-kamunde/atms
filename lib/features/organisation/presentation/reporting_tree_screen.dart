import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_list_screen.dart';

/// Admin: reporting tree view (spec 4.2).
///
/// NOT IMPLEMENTED (Sprint 1): built from users' supervisorId; loops are
/// rejected server-side.
class ReportingTreeScreen extends StatelessWidget {
  const ReportingTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyListScreen(
      title: l10n.adminReportingTreeTitle,
      icon: Icons.account_tree_outlined,
      emptyTitle: l10n.reportingTreeEmptyTitle,
      emptyMessage: l10n.reportingTreeEmptyMessage,
    );
  }
}
