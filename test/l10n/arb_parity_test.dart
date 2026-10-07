import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _load(String name) =>
    jsonDecode(File('lib/core/localization/arb/$name').readAsStringSync())
        as Map<String, Object?>;

Set<String> _messageKeys(Map<String, Object?> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  final en = _load('app_en.arb');
  final sw = _load('app_sw.arb');

  test('English and Kiswahili have exactly the same keys', () {
    final enKeys = _messageKeys(en);
    final swKeys = _messageKeys(sw);
    expect(enKeys.difference(swKeys), isEmpty, reason: 'missing in sw');
    expect(swKeys.difference(enKeys), isEmpty, reason: 'missing in en');
  });

  test('no empty values', () {
    for (final arb in [en, sw]) {
      for (final key in _messageKeys(arb)) {
        final value = arb[key];
        expect(value, isA<String>(), reason: key);
        expect((value! as String).trim(), isNotEmpty, reason: key);
      }
    }
  });

  test('placeholders match between languages', () {
    final placeholder = RegExp(r'\{(\w+)[,}]');
    for (final key in _messageKeys(en)) {
      Set<String> names(Map<String, Object?> arb) =>
          placeholder.allMatches(arb[key]! as String).map((m) => m[1]!).toSet();
      expect(names(sw), names(en), reason: key);
    }
  });

  test('locales are declared', () {
    expect(en['@@locale'], 'en');
    expect(sw['@@locale'], 'sw');
  });

  test('privacy text never claims end-to-end encryption', () {
    for (final arb in [en, sw]) {
      for (final key in _messageKeys(arb)) {
        final value = (arb[key]! as String).toLowerCase();
        expect(value, isNot(contains('end-to-end')), reason: key);
        expect(value, isNot(contains('mwisho hadi mwisho')), reason: key);
      }
    }
  });
}
