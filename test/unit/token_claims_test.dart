import 'package:atms/features/auth/domain/token_claims.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses orgId, auth_time and adminVerifiedUntil (seconds)', () {
    final claims = TokenClaims.fromClaims({
      'orgId': 'org1',
      'auth_time': 1791460800, // 2026-10-08T12:00:00Z
      'adminVerifiedUntil': 1791504000,
    });
    expect(claims.orgId, 'org1');
    expect(claims.authTime, DateTime.utc(2026, 10, 8, 12));
    expect(claims.adminVerifiedUntil, DateTime.utc(2026, 10, 9));
    expect(claims.isAdminVerifiedAt(DateTime.utc(2026, 10, 8, 23)), isTrue);
    expect(claims.isAdminVerifiedAt(DateTime.utc(2026, 10, 9)), isFalse);
  });

  test('missing or wrongly typed claims are treated as absent', () {
    final claims = TokenClaims.fromClaims({
      'orgId': 42,
      'adminVerifiedUntil': 'tomorrow',
    });
    expect(claims.orgId, isNull);
    expect(claims.adminVerifiedUntil, isNull);
    expect(claims.authTime, isNull);
    expect(claims.isAdminVerifiedAt(DateTime.utc(2000)), isFalse);
    expect(TokenClaims.fromClaims(null).orgId, isNull);
    expect(TokenClaims.fromClaims({'orgId': ''}).orgId, isNull);
  });

  test('auth time falls back to IdTokenResult.authTime', () {
    final fallback = DateTime.utc(2026, 10, 1);
    expect(
      TokenClaims.fromClaims({}, authTimeFallback: fallback).authTime,
      fallback,
    );
    expect(
      TokenClaims.fromClaims({
        'auth_time': 1791460800,
      }, authTimeFallback: fallback).authTime,
      DateTime.utc(2026, 10, 8, 12),
    );
  });

  test('withoutAdminVerification keeps the rest', () {
    final claims = TokenClaims(
      orgId: 'org1',
      authTime: DateTime.utc(2026),
      adminVerifiedUntil: DateTime.utc(2027),
    );
    final dropped = claims.withoutAdminVerification();
    expect(dropped.adminVerifiedUntil, isNull);
    expect(dropped.orgId, 'org1');
    expect(dropped.authTime, DateTime.utc(2026));
  });
}
