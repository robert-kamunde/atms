import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../auth_providers.dart';

/// Privacy notice and consent (Tanzania Personal Data Protection Act, 2022;
/// spec 6). Text lives in the ARB files and must be reviewed by the
/// client's legal/data-protection contact before the pilot.
class OnboardingConsentScreen extends ConsumerStatefulWidget {
  const OnboardingConsentScreen({super.key});

  @override
  ConsumerState<OnboardingConsentScreen> createState() =>
      _OnboardingConsentScreenState();
}

class _OnboardingConsentScreenState
    extends ConsumerState<OnboardingConsentScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sections = <(String, String)>[
      (l10n.consentWhatWeCollectTitle, l10n.consentWhatWeCollectBody),
      (l10n.consentWhyTitle, l10n.consentWhyBody),
      (l10n.consentWhoSeesTitle, l10n.consentWhoSeesBody),
      (l10n.consentSecurityTitle, l10n.consentSecurityBody),
      (l10n.consentRetentionTitle, l10n.consentRetentionBody),
      (l10n.consentRightsTitle, l10n.consentRightsBody),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consentTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(l10n.consentIntro, style: theme.textTheme.bodyLarge),
                  for (final (title, body) in sections) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                    const SizedBox(height: 4),
                    Text(body, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            CheckboxListTile(
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
              title: Text(l10n.consentCheckbox),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // NOT IMPLEMENTED (Sprint 1): store consent version and
                  // timestamp on the user document (server time).
                  onPressed: _agreed
                      ? () => ref
                            .read(authControllerProvider.notifier)
                            .completeConsentStep()
                      : null,
                  child: Text(l10n.actionAgreeAndContinue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
