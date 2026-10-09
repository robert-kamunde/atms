import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../domain/auth_state.dart';
import 'auth_providers.dart';

/// Shown while the auth state is being worked out (start-up, profile
/// loading, or waiting for a connection on a phone with nothing cached).
class LoadingScreen extends ConsumerWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final waiting = auth is AuthUnknown && auth.waitingForConnection;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (waiting)
                  const Icon(Icons.cloud_off, size: 48)
                else
                  const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  waiting
                      ? l10n.loadingWaitingForConnection
                      : l10n.loadingMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // A user must always be able to leave this screen.
                TextButton(
                  onPressed: () async {
                    try {
                      await ref.read(authControllerProvider.notifier).signOut();
                    } catch (error, stackTrace) {
                      if (context.mounted) {
                        showFailureSnackBar(
                          context,
                          mapError(error, stackTrace),
                        );
                      }
                    }
                  },
                  child: Text(l10n.actionSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
