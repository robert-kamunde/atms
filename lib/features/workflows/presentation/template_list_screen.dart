import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_list_screen.dart';
import '../../../shared/widgets/failure_snackbar.dart';

/// Admin: workflow templates (spec 4.4).
///
/// NOT IMPLEMENTED (Sprint 3): templates query and template builder.
class TemplateListScreen extends StatelessWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyListScreen(
      title: l10n.adminTemplatesTitle,
      icon: Icons.account_tree_outlined,
      emptyTitle: l10n.templatesEmptyTitle,
      emptyMessage: l10n.templatesEmptyMessage,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'templatesFab',
        // NOT IMPLEMENTED (Sprint 3): template builder.
        onPressed: () =>
            showMessageSnackBar(context, l10n.featureNotAvailableYet),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionNewTemplate),
      ),
    );
  }
}
