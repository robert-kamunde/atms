import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_list_screen.dart';
import '../../../shared/widgets/failure_snackbar.dart';

/// Admin: user list (spec 4.2).
///
/// NOT IMPLEMENTED (Sprint 1): paginated users query and invite flow.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyListScreen(
      title: l10n.adminUsersTitle,
      icon: Icons.people_outline,
      emptyTitle: l10n.usersEmptyTitle,
      emptyMessage: l10n.usersEmptyMessage,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'usersFab',
        // NOT IMPLEMENTED (Sprint 1): user editor.
        onPressed: () =>
            showMessageSnackBar(context, l10n.featureNotAvailableYet),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.actionAddUser),
      ),
    );
  }
}
