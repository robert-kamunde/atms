import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_list_screen.dart';

/// Start a workflow: pick a template, then fill in the request (spec 4.4).
///
/// NOT IMPLEMENTED (Sprint 3): list active templates the user may start;
/// starting is a server request, never a direct task write.
class StartWorkflowScreen extends StatelessWidget {
  const StartWorkflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyListScreen(
      title: l10n.startWorkflowTitle,
      icon: Icons.account_tree_outlined,
      emptyTitle: l10n.templatesEmptyTitle,
      emptyMessage: l10n.startWorkflowEmptyMessage,
    );
  }
}
