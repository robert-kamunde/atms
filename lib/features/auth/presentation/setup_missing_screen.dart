import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import 'widgets/developer_preview_panel.dart';

/// Shown when the app was built without Firebase options (or Firebase failed
/// to start). Lets CI builds and widget tests run without real keys.
class SetupMissingScreen extends StatelessWidget {
  const SetupMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Icon(
              Icons.settings_suggest_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.setupMissingTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.setupMissingMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            const DeveloperPreviewPanel(),
          ],
        ),
      ),
    );
  }
}
