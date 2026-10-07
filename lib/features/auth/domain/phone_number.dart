/// Normalises a Tanzanian mobile number typed by the user to E.164
/// (`+255` followed by 9 digits starting with 6 or 7).
///
/// Accepts `0712 345 678`, `712345678`, `255712345678`, `+255 712 345 678`.
/// Returns null when the number is not a valid Tanzanian mobile number.
String? normaliseTanzanianPhone(String input) {
  final digits = input.replaceAll(RegExp(r'[\s\-().]'), '');
  final String local;
  if (RegExp(r'^\+255\d{9}$').hasMatch(digits)) {
    local = digits.substring(4);
  } else if (RegExp(r'^255\d{9}$').hasMatch(digits)) {
    local = digits.substring(3);
  } else if (RegExp(r'^0\d{9}$').hasMatch(digits)) {
    local = digits.substring(1);
  } else if (RegExp(r'^\d{9}$').hasMatch(digits)) {
    local = digits;
  } else {
    return null;
  }
  if (!RegExp(r'^[67]\d{8}$').hasMatch(local)) return null;
  return '+255$local';
}
