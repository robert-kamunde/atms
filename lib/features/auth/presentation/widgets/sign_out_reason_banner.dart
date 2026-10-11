import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../domain/auth_state.dart';
import '../../domain/session_policy.dart';

/// Explains why the app signed the user out (shown on the sign-in screens).
class SignOutReasonBanner extends StatelessWidget {
  const SignOutReasonBanner({super.key, required this.reason});

  final SignOutReason reason;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final text = switch (reason) {
      SignOutReason.sessionExpired => l10n.sessionExpiredMessage(
        SessionPolicy.standardMaxAge.inDays,
        SessionPolicy.adminMaxAge.inDays,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_clock_outlined,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
