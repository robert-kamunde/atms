import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fails when a .dart file under lib/ puts a string literal straight into a
/// user-facing widget property. All UI text must come from the ARB files.
///
/// A line can opt out with a trailing `// l10n-ignore: <reason>` comment
/// (for text that is never shown to users).
void main() {
  test('no hardcoded user-facing strings in lib/', () {
    final patterns = <RegExp>[
      RegExp(r'''\bText\(\s*['"]'''),
      RegExp(r'''\bText\.rich\(\s*TextSpan\(\s*text:\s*['"]'''),
      RegExp(
        r'''\b(title|label|labelText|hintText|helperText|errorText|tooltip|semanticsLabel|message|content|subtitle|prefixText|suffixText|counterText|restorationId)\s*:\s*['"][^'"]''',
      ),
      RegExp(r'''\bSnackBar\(\s*content:\s*Text\(\s*['"]'''),
    ];
    // Lines that legitimately match (not shown to users).
    final allowList = <RegExp>[
      RegExp(r'//\s*l10n-ignore'),
      RegExp(r'''debugLabel:'''),
      RegExp(r'''AppLogger\.\w+\('''),
    ];

    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) =>
              !f.path.replaceAll(r'\', '/').contains('localization/generated/'),
        );

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        if (allowList.any((a) => a.hasMatch(line))) continue;
        if (patterns.any((p) => p.hasMatch(line))) {
          offenders.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the scanner catches a hardcoded Text', () {
    final pattern = RegExp(r'''\bText\(\s*['"]''');
    expect(pattern.hasMatch("child: Text('Save')"), isTrue);
    expect(pattern.hasMatch('child: Text(l10n.actionSave)'), isFalse);
  });
}
