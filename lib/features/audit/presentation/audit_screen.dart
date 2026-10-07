import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_list_screen.dart';

/// Admin: audit log (spec 4.11). Read-only: only server functions write it.
///
/// NOT IMPLEMENTED (Sprint 2): paginated audit query.
class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyListScreen(
      title: l10n.adminAuditTitle,
      icon: Icons.history,
      emptyTitle: l10n.auditEmptyTitle,
      emptyMessage: l10n.auditEmptyMessage,
    );
  }
}
