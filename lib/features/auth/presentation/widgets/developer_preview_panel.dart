import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/config_providers.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../shared/models/user_role.dart';
import '../../../../shared/widgets/enum_labels.dart';
import '../auth_providers.dart';

/// MOCK/TEMPORARY: development-only buttons to open the signed-in screens
/// for a role, with no data, so the Sprint 0 skeleton can be clicked
/// through. Rendered only in debug builds with `ATMS_ENV=dev`
/// (see `isDeveloperPreviewAllowed`). Remove after Sprint 1.
class DeveloperPreviewPanel extends ConsumerWidget {
  const DeveloperPreviewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDeveloperPreviewAllowed(ref.watch(appConfigProvider))) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.devPreviewTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.devPreviewMessage),
            const SizedBox(height: 12),
            for (final role in UserRole.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(authControllerProvider.notifier)
                      .startDeveloperPreview(role),
                  child: Text(l10n.devPreviewAsRole(role.label(l10n))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
