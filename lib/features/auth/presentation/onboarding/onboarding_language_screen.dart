import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../shared/widgets/failure_snackbar.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../auth_providers.dart';

/// First sign-in: choose Kiswahili or English (spec 4.1 step 4). The choice
/// is stored as `language` on the person's user document (works offline).
class OnboardingLanguageScreen extends ConsumerStatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  ConsumerState<OnboardingLanguageScreen> createState() =>
      _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState
    extends ConsumerState<OnboardingLanguageScreen> {
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .completeLanguageStep(ref.read(localeProvider));
    } catch (error, stackTrace) {
      if (mounted) showFailureSnackBar(context, mapError(error, stackTrace));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingLanguageTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l10n.onboardingLanguageHelp, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            LanguageSelector(
              selected: locale,
              onChanged: (value) =>
                  ref.read(localeProvider.notifier).setLocale(value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('languageContinueButton'),
              onPressed: _busy ? null : _continue,
              child: Text(l10n.actionContinue),
            ),
          ],
        ),
      ),
    );
  }
}
