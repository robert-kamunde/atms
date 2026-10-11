import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/offline_write.dart';
import '../../core/utils/logger.dart';

/// What the offline/sync banner shows (spec 4.9 step 2).
enum SyncState {
  /// Not known yet (start-up, signed out, or no Firebase). Banner hidden.
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

/// Source used while nobody is signed in (or Firebase is not set up):
/// always [SyncState.unknown], so the banner stays hidden instead of
/// claiming that changes are saved.
class UnknownSyncStatusSource implements SyncStatusSource {
  const UnknownSyncStatusSource();

  @override
  Stream<SyncState> watch() => Stream<SyncState>.value(SyncState.unknown);
}

/// The two signals Firestore gives about syncing.
abstract interface class SyncSignals {
  /// True when a watched document's latest snapshot came from the server,
  /// false when it came only from the phone's cache (no connection).
  Stream<bool> serverReachable();

  /// Completes when every write made so far has reached the server. Never
  /// completes while offline.
  Future<void> waitForPendingWrites();

  /// Fires whenever the app makes a write (so pending writes are checked
  /// again).
  Stream<void> localWrites();
}

/// [SyncSignals] from Firestore: snapshot metadata of the signed-in
/// person's own user document (`isFromCache`), `waitForPendingWrites()`
/// and the app's own writes ([localWriteEvents]).
///
/// Firestore has no direct "online" signal; a listener's snapshots switch
/// to `isFromCache: true` when the connection to the backend is lost and
/// back when it returns. That is enough here, so no connectivity package
/// is added.
class FirestoreSyncSignals implements SyncSignals {
  FirestoreSyncSignals(this._db, {required this.orgId, required this.uid});

  final FirebaseFirestore _db;
  final String orgId;
  final String uid;

  @override
  Stream<bool> serverReachable() => _db
      .collection('orgs')
      .doc(orgId)
      .collection('users')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map((snap) => !snap.metadata.isFromCache);

  @override
  Future<void> waitForPendingWrites() => _db.waitForPendingWrites();

  @override
  Stream<void> localWrites() => localWriteEvents;
}

/// Turns [SyncSignals] into the banner state (spec 4.9 step 2):
///
/// * no connection (after [offlineGrace], so a cached first snapshot at
///   start-up does not flash "Offline") -> [SyncState.offline];
/// * connected with writes not yet confirmed -> [SyncState.syncing];
/// * connected and every write confirmed -> [SyncState.synced].
///
/// Until the first signal arrives the state is [SyncState.unknown].
class FirestoreSyncStatusSource implements SyncStatusSource {
  FirestoreSyncStatusSource(
    this._signals, {
    this.offlineGrace = const Duration(seconds: 3),
  });

  final SyncSignals _signals;

  /// How long the server must be unreachable before "Offline" shows.
  final Duration offlineGrace;

  @override
  Stream<SyncState> watch() {
    late final StreamController<SyncState> controller;
    StreamSubscription<bool>? reachableSub;
    StreamSubscription<void>? writesSub;
    Timer? offlineTimer;
    bool? reachable;
    var offline = false;
    var pending = true;
    var failed = false;
    var generation = 0;
    SyncState? last;

    void emit() {
      final SyncState next;
      if (failed) {
        next = SyncState.unknown;
      } else if (offline) {
        next = SyncState.offline;
      } else if (reachable != true) {
        next = SyncState.unknown;
      } else {
        next = pending ? SyncState.syncing : SyncState.synced;
      }
      if (next != last && !controller.isClosed) {
        last = next;
        controller.add(next);
      }
    }

    void checkPendingWrites() {
      final mine = ++generation;
      pending = true;
      emit();
      Future<void>.sync(_signals.waitForPendingWrites).then(
        (_) {
          if (mine != generation) return;
          pending = false;
          emit();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (mine != generation) return;
          // The banner cannot tell the state: hide it rather than guess.
          AppLogger.warning(
            'waitForPendingWrites failed',
            error: error,
            stackTrace: stackTrace,
          );
          failed = true;
          emit();
        },
      );
    }

    void onReachable(bool value) {
      reachable = value;
      if (value) {
        offlineTimer?.cancel();
        offlineTimer = null;
        offline = false;
        emit();
      } else {
        offlineTimer ??= Timer(offlineGrace, () {
          offlineTimer = null;
          if (reachable == false) {
            offline = true;
            emit();
          }
        });
      }
    }

    controller = StreamController<SyncState>(
      onListen: () {
        controller.add(SyncState.unknown);
        last = SyncState.unknown;
        reachableSub = _signals.serverReachable().listen(
          onReachable,
          onError: (Object error, StackTrace stackTrace) {
            AppLogger.warning(
              'Sync status listener failed',
              error: error,
              stackTrace: stackTrace,
            );
            failed = true;
            emit();
          },
        );
        writesSub = _signals.localWrites().listen((_) {
          failed = false;
          checkPendingWrites();
        });
        checkPendingWrites();
      },
      onCancel: () async {
        offlineTimer?.cancel();
        generation++;
        await reachableSub?.cancel();
        await writesSub?.cancel();
      },
    );
    return controller.stream;
  }
}
