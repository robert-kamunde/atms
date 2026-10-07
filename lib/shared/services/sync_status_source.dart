import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// What the offline/sync banner shows (spec 4.9 step 2).
enum SyncState {
  /// Not known yet (start-up, or no Firebase). The banner is hidden.
  unknown,

  /// "Offline: changes saved on this phone"
  offline,

  /// "Syncing..."
  syncing,

  /// "All changes saved"
  synced,
}

/// Something that reports the sync state of local data.
abstract interface class SyncStatusSource {
  Stream<SyncState> watch();
}

/// Default source until the Firestore-backed one is built: always
/// [SyncState.unknown], so the banner stays hidden instead of claiming that
/// changes are saved.
///
/// MOCK/TEMPORARY: replaced by [FirestoreSyncStatusSource] in Sprint 2
/// (spec 4.9). Showing "All changes saved" without checking would be a lie.
class UnknownSyncStatusSource implements SyncStatusSource {
  const UnknownSyncStatusSource();

  @override
  Stream<SyncState> watch() => Stream<SyncState>.value(SyncState.unknown);
}

/// Firestore-backed sync state.
///
/// NOT IMPLEMENTED (Sprint 2): planned design —
/// * `FirebaseFirestore.snapshotsInSync()` fires when all listeners are in
///   sync with the server: candidate for [SyncState.synced];
/// * a listener on the user's task query with
///   `includeMetadataChanges: true`: `metadata.hasPendingWrites` → syncing,
///   `metadata.isFromCache` with pending writes and no connectivity →
///   offline.
/// Firestore has no direct "online" signal, so the offline state needs a
/// connectivity signal too (decide in Sprint 2 whether to add
/// `connectivity_plus`).
class FirestoreSyncStatusSource implements SyncStatusSource {
  FirestoreSyncStatusSource(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Stream<SyncState> watch() {
    // NOT IMPLEMENTED (Sprint 2): see class documentation.
    throw UnimplementedError('FirestoreSyncStatusSource is built in Sprint 2');
  }
}
