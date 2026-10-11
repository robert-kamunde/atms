import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/firebase_providers.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../services/sync_status_source.dart';

/// Source of the offline/sync state (spec 4.9, KI-9): Firestore snapshot
/// metadata and pending writes while someone is signed in, otherwise
/// [UnknownSyncStatusSource] (banner hidden).
final syncStatusSourceProvider = Provider<SyncStatusSource>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return const UnknownSyncStatusSource();
  return FirestoreSyncStatusSource(
    FirestoreSyncSignals(
      ref.watch(firestoreProvider),
      orgId: session.orgId,
      uid: session.uid,
    ),
  );
});

/// Current sync state for the banner.
final syncStateProvider = StreamProvider<SyncState>(
  (ref) => ref.watch(syncStatusSourceProvider).watch(),
);
