import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../auth_providers.dart';

/// First sign-in: choose Kiswahili or English (spec 4.1 step 4).
class OnboardingLanguageScreen extends ConsumerWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onPressed: () => ref
                  .read(authControllerProvider.notifier)
                  .completeLanguageStep(),
              child: Text(l10n.actionContinue),
            ),
          ],
        ),
      ),
    );
  }
}
