import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_list_screen.dart';

/// Approvals waiting for me (spec 4.4): workflow steps whose owner is the
/// current user.
///
/// NOT IMPLEMENTED (Sprint 3): paginated query of tasks whose current step
/// is owned by me.
class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyListScreen(
      title: l10n.approvalsTitle,
      icon: Icons.fact_check_outlined,
      emptyTitle: l10n.approvalsEmptyTitle,
      emptyMessage: l10n.approvalsEmptyMessage,
    );
  }
}
