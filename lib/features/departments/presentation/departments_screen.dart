import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_list_screen.dart';
import '../../../shared/widgets/failure_snackbar.dart';

/// Admin: departments list (spec 4.2).
///
/// NOT IMPLEMENTED (Sprint 1): departments query and editor.
class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyListScreen(
      title: l10n.adminDepartmentsTitle,
      icon: Icons.apartment_outlined,
      emptyTitle: l10n.departmentsEmptyTitle,
      emptyMessage: l10n.departmentsEmptyMessage,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'departmentsFab',
        // NOT IMPLEMENTED (Sprint 1): department editor.
        onPressed: () =>
            showMessageSnackBar(context, l10n.featureNotAvailableYet),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionAddDepartment),
      ),
    );
  }
}
