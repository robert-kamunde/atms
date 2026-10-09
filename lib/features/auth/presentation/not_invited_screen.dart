import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../domain/auth_state.dart';
import 'auth_providers.dart';

/// Shown when the phone number or email was not added by an administrator
/// (spec 4.1: "Ask your administrator to add you."), or when the account
/// was deactivated.
class NotInvitedScreen extends ConsumerWidget {
  const NotInvitedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final deactivated =
        auth is AuthNotInvited && auth.reason == NotAllowedReason.deactivated;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          deactivated ? l10n.accountInactiveTitle : l10n.notInvitedTitle,
        ),
      ),
      body: SafeArea(
        child: EmptyState(
          icon: deactivated ? Icons.block_outlined : Icons.person_off_outlined,
          title: deactivated
              ? l10n.errorAccountDeactivated
              : l10n.notInvitedMessage,
          message: deactivated ? l10n.accountInactiveHelp : l10n.notInvitedHelp,
          action: OutlinedButton(
            onPressed: () async {
              try {
                await ref.read(authControllerProvider.notifier).signOut();
              } catch (error, stackTrace) {
                if (context.mounted) {
                  showFailureSnackBar(context, mapError(error, stackTrace));
                }
              }
            },
            child: Text(l10n.actionUseAnotherNumber),
          ),
        ),
      ),
    );
  }
}
