import 'package:atms/features/auth/domain/session_policy.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final authTime = DateTime.utc(2026, 10, 1, 8);

  bool expired(UserRole role, Duration age) =>
      isSessionExpired(authTime: authTime, role: role, now: authTime.add(age));

  test('staff and managers stay signed in for 30 days', () {
    for (final role in [UserRole.staff, UserRole.manager]) {
      expect(expired(role, const Duration(days: 29, hours: 23)), isFalse);
      expect(expired(role, const Duration(days: 30)), isTrue);
      expect(expired(role, const Duration(days: 45)), isTrue);
    }
  });

  test('admins must sign in again after 7 days', () {
    expect(
      expired(UserRole.admin, const Duration(days: 6, hours: 23)),
      isFalse,
    );
    expect(expired(UserRole.admin, const Duration(days: 7)), isTrue);
    expect(expired(UserRole.admin, const Duration(days: 8)), isTrue);
  });

  test('a fresh session is never expired', () {
    for (final role in UserRole.values) {
      expect(expired(role, Duration.zero), isFalse);
    }
  });

  test('auth time in the future (wrong phone clock) is not expired', () {
    expect(expired(UserRole.admin, const Duration(days: -2)), isFalse);
  });

  test('policy durations', () {
    expect(SessionPolicy.maxAgeFor(UserRole.admin), const Duration(days: 7));
    expect(SessionPolicy.maxAgeFor(UserRole.staff), const Duration(days: 30));
  });
}
