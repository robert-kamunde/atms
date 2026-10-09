import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/firebase_providers.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_guard.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../domain/auth_state.dart';
import 'auth_providers.dart';
import 'widgets/resend_countdown.dart';

/// Admin second factor (spec 6, D-01): a 6-digit code sent to the admin's
/// email by the `sendAdminCode` callable and checked by `verifyAdminCode`.
/// Afterwards the ID token is refreshed and the admin continues to
/// [returnTo] (the admin screen they opened) or the More tab.
///
/// Needs a connection (callables are online-only).
class AdminVerifyScreen extends ConsumerStatefulWidget {
  const AdminVerifyScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<AdminVerifyScreen> createState() => _AdminVerifyScreenState();
}

class _AdminVerifyScreenState extends ConsumerState<AdminVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    try {
      await ref.read(adminVerifyControllerProvider.notifier).sendCode();
    } catch (error, stackTrace) {
      if (mounted) _showFailure(error, stackTrace);
    }
  }

  void _showFailure(Object error, StackTrace stackTrace) {
    showFailureSnackBar(context, mapError(error, stackTrace));
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await ref
          .read(adminVerifyControllerProvider.notifier)
          .verify(_codeController.text.trim());
      if (!mounted) return;
      final now = ref.read(clockProvider)();
      final auth = ref.read(authControllerProvider);
      if (auth is AuthSignedIn && auth.isAdminVerifiedAt(now)) {
        showMessageSnackBar(context, context.l10n.adminVerifySuccess);
        context.go(adminVerifyReturnPath(widget.returnTo));
      }
    } catch (error, stackTrace) {
      if (mounted) _showFailure(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(adminVerifyControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final now = ref.read(clockProvider)();
    final alreadyVerified = auth is AuthSignedIn && auth.isAdminVerifiedAt(now);
    final sent = state.sent;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminVerifyTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(l10n.adminVerifyHelp, style: theme.textTheme.bodyLarge),
              if (alreadyVerified) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.adminVerifiedUntil(
                    formatClockTime((auth).adminVerifiedUntil!),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              if (sent == null) ...[
                FilledButton.icon(
                  key: const Key('sendAdminCodeButton'),
                  onPressed: state.busy ? null : _sendCode,
                  icon: const Icon(Icons.mail_outline),
                  label: Text(l10n.actionSendAdminCode),
                ),
              ] else ...[
                Text(
                  l10n.adminCodeSentTo(
                    sent.maskedEmail,
                    formatClockTime(sent.expiresAt),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('adminCodeField'),
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: l10n.codeLabel),
                  validator: (value) =>
                      RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                      ? null
                      : l10n.validationCodeSixDigits,
                  onFieldSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('verifyAdminCodeButton'),
                  onPressed: state.busy ? null : _verify,
                  child: Text(l10n.actionVerify),
                ),
                const SizedBox(height: 8),
                ResendCountdown(
                  key: ValueKey(state.sentAt),
                  sentAt: state.sentAt!,
                  now: ref.read(clockProvider),
                  enabled: !state.busy,
                  onResend: _sendCode,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.needsConnectionNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              if (state.busy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
