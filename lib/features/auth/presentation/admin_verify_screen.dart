import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/failure_snackbar.dart';

/// Admin second factor: email code entry (spec 6).
///
/// UI ONLY. NOT IMPLEMENTED (Sprint 1, pending decision): how the email code
/// is sent and verified (custom Cloud Function vs Firebase MFA) has not been
/// decided, so this screen validates the format and does nothing else.
class AdminVerifyScreen extends StatefulWidget {
  const AdminVerifyScreen({super.key});

  @override
  State<AdminVerifyScreen> createState() => _AdminVerifyScreenState();
}

class _AdminVerifyScreenState extends State<AdminVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // NOT IMPLEMENTED (Sprint 1): verify the code on the server.
    showMessageSnackBar(context, context.l10n.featureNotAvailableYet);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
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
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l10n.codeLabel),
                validator: (value) =>
                    RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : l10n.validationCodeSixDigits,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _submit, child: Text(l10n.actionVerify)),
              const SizedBox(height: 8),
              TextButton(
                // NOT IMPLEMENTED (Sprint 1): resend email code.
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
