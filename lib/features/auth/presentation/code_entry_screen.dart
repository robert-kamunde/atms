import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/firebase_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import 'auth_providers.dart';
import 'widgets/resend_countdown.dart';

/// Code entry (spec 4.1 step 3): the 6-digit SMS code, with a resend
/// button that unlocks after [AppConstants.resendCodeDelay]. On Android the
/// code may be read automatically; the user is then signed in and the
/// router leaves this screen by itself.
class CodeEntryScreen extends ConsumerStatefulWidget {
  const CodeEntryScreen({super.key});

  @override
  ConsumerState<CodeEntryScreen> createState() => _CodeEntryScreenState();
}

class _CodeEntryScreenState extends ConsumerState<CodeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on AppFailure catch (failure) {
      if (mounted && !isSignInRefusal(failure)) {
        showFailureSnackBar(context, failure);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _run(
      () => ref
          .read(phoneSignInControllerProvider.notifier)
          .confirmCode(_codeController.text.trim()),
    );
  }

  Future<void> _resend() async {
    await _run(() async {
      await ref.read(phoneSignInControllerProvider.notifier).resendCode();
      if (mounted) showMessageSnackBar(context, context.l10n.codeResent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    ref.listen(
      phoneSignInControllerProvider.select((p) => p?.autoSignInFailure),
      (_, failure) {
        if (failure != null) showFailureSnackBar(context, failure);
      },
    );
    final pending = ref.watch(phoneSignInControllerProvider);
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
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('verifyCodeButton'),
                      onPressed: _busy ? null : _submit,
                      child: Text(l10n.actionVerify),
                    ),
                    const SizedBox(height: 8),
                    ResendCountdown(
                      key: ValueKey(pending.sentAt),
                      sentAt: pending.sentAt,
                      now: ref.read(clockProvider),
                      enabled: !_busy,
                      onResend: _resend,
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
