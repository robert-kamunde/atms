import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../domain/auth_state.dart';
import '../domain/phone_number.dart';
import 'auth_providers.dart';
import 'widgets/sign_out_reason_banner.dart';

/// Phone entry (spec 4.1 step 3). Sign-in needs a connection; offline the
/// user sees "needs an internet connection".
class PhoneSignInScreen extends ConsumerStatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  ConsumerState<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends ConsumerState<PhoneSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = normaliseTanzanianPhone(_phoneController.text);
    if (phone == null) return;
    setState(() => _sending = true);
    try {
      final needsCode = await ref
          .read(phoneSignInControllerProvider.notifier)
          .sendCode(phone);
      if (mounted && needsCode) context.go(RoutePaths.signInCode);
    } on AppFailure catch (failure) {
      // Refusals move to the "ask your administrator" screen by themselves.
      if (mounted && !isSignInRefusal(failure)) {
        showFailureSnackBar(context, failure);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (auth case AuthSignedOut(:final reason?)) ...[
                SignOutReasonBanner(reason: reason),
                const SizedBox(height: 16),
              ],
              Text(
                l10n.phoneSignInHeading,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(l10n.phoneSignInHelp, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('phoneField'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.phoneNumberLabel,
                  hintText: l10n.phoneNumberHint,
                  prefixText: '${AppConstants.defaultDialCode} ', // l10n-ignore: country code
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.validationPhoneRequired;
                  }
                  if (normaliseTanzanianPhone(value) == null) {
                    return l10n.errorInvalidPhone;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('sendCodeButton'),
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.actionSendCode),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.signInNeedsConnection,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(RoutePaths.signInEmail),
                child: Text(l10n.useEmailInstead),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
