import 'package:flutter/material.dart';

/// Small coloured label such as "Inactive" or "Supervisor inactive".
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.warning = false});

  final String label;

  /// Uses the error colours for something the admin should fix.
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = warning
        ? scheme.errorContainer
        : scheme.surfaceContainerHighest;
    final foreground = warning
        ? scheme.onErrorContainer
        : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}
