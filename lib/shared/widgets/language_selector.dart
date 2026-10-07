import 'package:flutter/material.dart';

import '../../core/localization/l10n.dart';
import '../../core/localization/locale_provider.dart';

/// Radio list to choose Kiswahili or English. Each language name is shown
/// in its own language so anyone can find theirs.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Locale selected;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RadioGroup<String>(
      groupValue: selected.languageCode,
      onChanged: (code) => onChanged(AppLocales.fromCode(code)),
      child: Column(
        children: [
          RadioListTile<String>(
            value: AppLocales.swahili.languageCode,
            title: Text(l10n.languageSwahili),
          ),
          RadioListTile<String>(
            value: AppLocales.english.languageCode,
            title: Text(l10n.languageEnglish),
          ),
        ],
      ),
    );
  }
}
