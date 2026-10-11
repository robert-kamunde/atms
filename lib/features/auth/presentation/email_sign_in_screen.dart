import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../domain/auth_state.dart';
import 'auth_providers.dart';
import 'widgets/sign_out_reason_banner.dart';

/// A simple email check for forms (the server and Firebase Auth do the
/// real validation).
bool looksLikeEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

/// Email and password fallback for staff without a reliable SIM (spec 4.1),
/// with "forgot password" (people added with an email start with a random
/// password and set their own through the reset email).
class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  ConsumerState<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(emailSignInControllerProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on AppFailure catch (failure) {
      if (mounted && !isSignInRefusal(failure)) {
        showFailureSnackBar(context, failure);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) =>
          _ForgotPasswordDialog(initialEmail: _emailController.text.trim()),
    );
    if (email == null || !mounted) return;
    try {
      await ref
          .read(emailSignInControllerProvider.notifier)
          .sendPasswordReset(email);
      if (mounted) {
        showMessageSnackBar(context, context.l10n.passwordResetSent);
      }
    } catch (error, stackTrace) {
      if (mounted) showFailureSnackBar(context, mapError(error, stackTrace));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emailSignInTitle),
        leading: BackButton(
          onPressed: () => context.go(RoutePaths.signInPhone),
        ),
      ),
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
              Text(l10n.emailSignInHelp),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('emailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l10n.emailLabel),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return l10n.validationEmailRequired;
                  if (!looksLikeEmail(v)) return l10n.errorInvalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('passwordField'),
                controller: _passwordController,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: l10n.passwordLabel,
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? l10n.actionShowPassword
                        : l10n.actionHidePassword,
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.validationPasswordRequired
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: const Key('forgotPasswordButton'),
                  onPressed: _busy ? null : _forgotPassword,
                  child: Text(l10n.actionForgotPassword),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('emailSignInButton'),
                onPressed: _busy ? null : _submit,
                child: Text(l10n.actionSignIn),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.signInNeedsConnection,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for the email to send the password reset to.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialEmail,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.forgotPasswordTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.forgotPasswordHelp),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('resetEmailField'),
              controller: _controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailLabel),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return l10n.validationEmailRequired;
                if (!looksLikeEmail(v)) return l10n.errorInvalidEmail;
                return null;
              },
              onFieldSubmitted: (_) => _send(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('sendResetButton'),
          onPressed: _send,
          child: Text(l10n.actionSendResetLink),
        ),
      ],
    );
  }
}
