import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_list_screen.dart';

/// In-app notification list (spec 4.6, the bell).
///
/// NOT IMPLEMENTED (Sprint 4): paginated `notifications where userId == me`.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyListScreen(
      title: l10n.notificationsTitle,
      icon: Icons.notifications_none,
      emptyTitle: l10n.notificationsEmptyTitle,
      emptyMessage: l10n.notificationsEmptyMessage,
    );
  }
}
