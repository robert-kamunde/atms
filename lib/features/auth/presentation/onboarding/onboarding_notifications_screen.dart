import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../auth_providers.dart';

/// Explains why notifications matter, then asks the phone for permission
/// (spec 4.1 step 4). Shown only while the phone has never been asked.
///
/// NOT IMPLEMENTED (Sprint 4): registering the push token for this device.
class OnboardingNotificationsScreen extends ConsumerStatefulWidget {
  const OnboardingNotificationsScreen({super.key});

  @override
  ConsumerState<OnboardingNotificationsScreen> createState() =>
      _OnboardingNotificationsScreenState();
}

class _OnboardingNotificationsScreenState
    extends ConsumerState<OnboardingNotificationsScreen> {
  bool _busy = false;

  Future<void> _finish({required bool allow}) async {
    setState(() => _busy = true);
    try {
      // Never throws: a refused or failed permission request must not
      // keep the user out of the app.
      await ref
          .read(authControllerProvider.notifier)
          .completeNotificationStep(allow: allow);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
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
              key: const Key('allowNotificationsButton'),
              onPressed: _busy ? null : () => _finish(allow: true),
              child: Text(l10n.actionAllowNotifications),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('notNowButton'),
              onPressed: _busy ? null : () => _finish(allow: false),
              child: Text(l10n.actionNotNow),
            ),
          ],
        ),
      ),
    );
  }
}
