import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/section_card.dart';

/// Admin: user editor (spec 4.2): name, phone, department, role,
/// supervisor, confidential access, active.
///
/// NOT IMPLEMENTED (Sprint 1): load user [userId]; save via admin-only
/// writes; deactivation hands open tasks to the supervisor (server).
class AdminUserDetailScreen extends StatelessWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fields = [
      (Icons.badge_outlined, l10n.userFieldName),
      (Icons.phone_outlined, l10n.phoneNumberLabel),
      (Icons.apartment_outlined, l10n.userFieldDepartment),
      (Icons.shield_outlined, l10n.userFieldRole),
      (Icons.supervisor_account_outlined, l10n.userFieldSupervisor),
      (Icons.lock_outline, l10n.userFieldConfidentialAccess),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminUserDetailTitle)),
      body: ListView(
        children: [
          SectionCard(
            title: l10n.userDetailsSection,
            icon: Icons.person_outline,
            child: Column(
              children: [
                for (final (icon, label) in fields)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon),
                    title: Text(label),
                    subtitle: Text(l10n.valueNotLoaded),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
