import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/section_card.dart';

/// Admin: organisation settings (spec 4.2, 4.5, 4.6): working days and
/// hours, reminder times, escalation delay, time zone, SMS monthly cap.
///
/// NOT IMPLEMENTED (Sprint 1): read and write `orgs/{org}`.
class OrgSettingsScreen extends StatelessWidget {
  const OrgSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = [
      (Icons.calendar_month_outlined, l10n.settingWorkingDays),
      (Icons.schedule, l10n.settingWorkingHours),
      (Icons.alarm, l10n.settingReminderTimes),
      (Icons.trending_up, l10n.settingEscalationDelay),
      (Icons.public, l10n.settingTimeZone),
      (Icons.sms_outlined, l10n.settingSmsCap),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminSettingsTitle)),
      body: ListView(
        children: [
          SectionCard(
            title: l10n.adminSettingsTitle,
            icon: Icons.tune,
            child: Column(
              children: [
                for (final (icon, label) in rows)
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
