import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import 'auth_providers.dart';

/// Code entry (spec 4.1 step 3): the 6-digit SMS code.
class CodeEntryScreen extends ConsumerStatefulWidget {
  const CodeEntryScreen({super.key});

  @override
  ConsumerState<CodeEntryScreen> createState() => _CodeEntryScreenState();
}

class _CodeEntryScreenState extends ConsumerState<CodeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit(PendingPhoneVerification pending) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _verifying = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmSmsCode(
            verificationId: pending.verificationId,
            smsCode: _codeController.text.trim(),
          );
      ref.read(pendingPhoneVerificationProvider.notifier).set(null);
      ref.read(authControllerProvider.notifier).onFirebaseSignedIn();
    } catch (error, stackTrace) {
      if (mounted) showFailureSnackBar(context, mapError(error, stackTrace));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pending = ref.watch(pendingPhoneVerificationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.codeEntryTitle),
        leading: BackButton(
          onPressed: () => context.go(RoutePaths.signInPhone),
        ),
      ),
      body: SafeArea(
        child: pending == null
            ? _NoPendingVerification(l10n: l10n)
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      l10n.codeEntryHelp(pending.phoneNumber),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('codeField'),
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(labelText: l10n.codeLabel),
                      validator: (value) =>
                          RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                          ? null
                          : l10n.validationCodeSixDigits,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _verifying ? null : () => _submit(pending),
                      child: Text(l10n.actionVerify),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      // NOT IMPLEMENTED (Sprint 1): resend with
                      // pending.resendToken and a countdown timer.
                      onPressed: null,
                      child: Text(l10n.actionResendCode),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _NoPendingVerification extends StatelessWidget {
  const _NoPendingVerification({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.codeEntryNoPending),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(RoutePaths.signInPhone),
            child: Text(l10n.actionBackToPhone),
          ),
        ],
      ),
    );
  }
}
