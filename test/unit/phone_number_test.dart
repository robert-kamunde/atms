import 'package:atms/features/auth/domain/phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts common Tanzanian formats', () {
    for (final input in [
      '0712345678',
      '0712 345 678',
      '712345678',
      '255712345678',
      '+255 712 345 678',
      '+255-654-321-000',
    ]) {
      expect(normaliseTanzanianPhone(input), startsWith('+255'), reason: input);
    }
    expect(normaliseTanzanianPhone('0712345678'), '+255712345678');
  });

  test('rejects invalid numbers', () {
    for (final input in [
      '',
      '123',
      '0812345678',
      '+254712345678',
      '07123456789',
      'abc',
    ]) {
      expect(normaliseTanzanianPhone(input), isNull, reason: input);
    }
  });

  test('normalises every accepted format to the same E.164 number', () {
    for (final input in [
      '0754 123 456',
      '754123456',
      '255754123456',
      '+255754123456',
      ' +255 (754) 123-456 ',
      '0754-123-456',
    ]) {
      expect(normaliseTanzanianPhone(input), '+255754123456', reason: input);
    }
  });

  test('accepts 06x and 07x mobile prefixes only', () {
    expect(normaliseTanzanianPhone('0612345678'), '+255612345678');
    expect(normaliseTanzanianPhone('0222123456'), isNull); // landline
    expect(normaliseTanzanianPhone('0512345678'), isNull);
  });

  test('rejects numbers with the wrong length or extra characters', () {
    for (final input in [
      '+2557123456789',
      '+25571234567',
      '00255712345678',
      '0712 345 67a',
      '+',
    ]) {
      expect(normaliseTanzanianPhone(input), isNull, reason: input);
    }
  });
}
