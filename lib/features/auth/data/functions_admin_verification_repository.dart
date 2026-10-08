import '../../../core/services/callable_client.dart';
import '../domain/admin_verification_repository.dart';

/// [AdminVerificationRepository] over the `sendAdminCode` and
/// `verifyAdminCode` callables (docs/SPRINT1_CONTRACT.md).
class FunctionsAdminVerificationRepository
    implements AdminVerificationRepository {
  FunctionsAdminVerificationRepository(this._client);

  final CallableClient _client;

  @override
  Future<AdminCodeSent> sendAdminCode() async {
    final data = await _client.call('sendAdminCode');
    return AdminCodeSent(
      maskedEmail: readString(data, 'maskedEmail'),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        readNum(data, 'expiresAt').toInt(),
        isUtc: true,
      ),
    );
  }

  @override
  Future<DateTime> verifyAdminCode(String code) async {
    final data = await _client.call('verifyAdminCode', {'code': code});
    return DateTime.fromMillisecondsSinceEpoch(
      readNum(data, 'verifiedUntil').toInt(),
      isUtc: true,
    );
  }
}
