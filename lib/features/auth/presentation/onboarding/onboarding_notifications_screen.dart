import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../auth_providers.dart';

/// Explains why notifications matter, then asks for permission
/// (spec 4.1 step 4).
class OnboardingNotificationsScreen extends ConsumerWidget {
  const OnboardingNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    void finish() =>
        ref.read(authControllerProvider.notifier).completeNotificationStep();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingNotificationsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboardingNotificationsHelp,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              // NOT IMPLEMENTED (Sprint 4): request permission with
              // firebase_messaging and register the FCM token.
              onPressed: finish,
              child: Text(l10n.actionAllowNotifications),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: finish, child: Text(l10n.actionNotNow)),
          ],
        ),
      ),
    );
  }
}
