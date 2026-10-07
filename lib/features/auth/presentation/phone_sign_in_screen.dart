import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../domain/auth_repository.dart';
import '../domain/phone_number.dart';
import 'auth_providers.dart';
import 'widgets/developer_preview_panel.dart';

/// Phone entry (spec 4.1 step 3).
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
      final result = await ref
          .read(authRepositoryProvider)
          .startPhoneVerification(phone);
      if (!mounted) return;
      switch (result) {
        case PhoneVerificationCodeSent(
          :final verificationId,
          :final resendToken,
        ):
          ref
              .read(pendingPhoneVerificationProvider.notifier)
              .set(
                PendingPhoneVerification(
                  phoneNumber: phone,
                  verificationId: verificationId,
                  resendToken: resendToken,
                ),
              );
          context.go(RoutePaths.signInCode);
        case PhoneAutoVerified():
          ref.read(authControllerProvider.notifier).onFirebaseSignedIn();
      }
    } catch (error, stackTrace) {
      if (mounted) showFailureSnackBar(context, mapError(error, stackTrace));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
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
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
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
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(RoutePaths.signInEmail),
                child: Text(l10n.useEmailInstead),
              ),
              const SizedBox(height: 24),
              const DeveloperPreviewPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
