import 'org_settings.dart';

/// The organisation document `orgs/{org}`. Implementations throw
/// `AppFailure` only.
abstract interface class OrgRepository {
  /// Emits the settings, from the offline cache first when available.
  /// Emits null when the organisation document does not exist.
  Stream<OrgSettings?> watchSettings();

  /// Writes [changes] (keys from `OrgSettings.changedFields`) plus
  /// `updatedAt` (server time). The future completes when the server
  /// confirms; callers use `awaitOfflineCapableWrite`.
  Future<void> updateSettings(Map<String, Object?> changes);
}
