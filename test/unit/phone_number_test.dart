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
}
