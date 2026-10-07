import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_status_source.dart';

/// Source of the offline/sync state.
///
/// MOCK/TEMPORARY: defaults to [UnknownSyncStatusSource] (banner hidden)
/// until `FirestoreSyncStatusSource` is implemented in Sprint 2.
final syncStatusSourceProvider = Provider<SyncStatusSource>(
  (ref) => const UnknownSyncStatusSource(),
);

/// Current sync state for the banner.
final syncStateProvider = StreamProvider<SyncState>(
  (ref) => ref.watch(syncStatusSourceProvider).watch(),
);
