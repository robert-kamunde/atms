import 'dart:async';

import 'package:atms/core/services/offline_write.dart';
import 'package:atms/shared/services/sync_status_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Signals the test controls: server reachability, pending writes and the
/// app's own writes.
class FakeSyncSignals implements SyncSignals {
  final reachable = StreamController<bool>.broadcast();
  final writes = StreamController<void>.broadcast();
  final List<Completer<void>> waits = [];
  Object? waitError;

  @override
  Stream<bool> serverReachable() => reachable.stream;

  @override
  Stream<void> localWrites() => writes.stream;

  @override
  Future<void> waitForPendingWrites() {
    if (waitError case final error?) throw error;
    final completer = Completer<void>();
    waits.add(completer);
    return completer.future;
  }

  void dispose() {
    reachable.close();
    writes.close();
  }
}

Future<void> _tick([Duration d = Duration.zero]) => Future<void>.delayed(d);

void main() {
  late FakeSyncSignals signals;
  late List<SyncState> states;
  late StreamSubscription<SyncState> sub;

  Future<void> start({
    Duration grace = const Duration(milliseconds: 30),
  }) async {
    states = [];
    sub = FirestoreSyncStatusSource(
      signals,
      offlineGrace: grace,
    ).watch().listen(states.add);
    await _tick();
  }

  setUp(() => signals = FakeSyncSignals());
  tearDown(() async {
    await sub.cancel();
    signals.dispose();
  });

  test('unknown until the server answers, then syncing, then saved', () async {
    await start();
    expect(states, [SyncState.unknown]);
    signals.reachable.add(true);
    await _tick();
    expect(states.last, SyncState.syncing);
    signals.waits.single.complete();
    await _tick();
    expect(states.last, SyncState.synced);
  });

  test('offline only after the grace period; reconnecting syncs', () async {
    await start();
    signals.waits.single.complete();
    signals.reachable.add(false);
    await _tick();
    expect(states.last, SyncState.unknown);
    await _tick(const Duration(milliseconds: 60));
    expect(states.last, SyncState.offline);

    // A write while offline: still offline (saved on this phone).
    signals.writes.add(null);
    await _tick();
    expect(states.last, SyncState.offline);

    signals.reachable.add(true);
    await _tick();
    expect(states.last, SyncState.syncing);
    signals.waits.last.complete();
    await _tick();
    expect(states.last, SyncState.synced);
  });

  test('a brief cached snapshot does not flash "Offline"', () async {
    await start();
    signals.reachable.add(false);
    await _tick();
    signals.reachable.add(true);
    await _tick(const Duration(milliseconds: 60));
    expect(states, isNot(contains(SyncState.offline)));
  });

  test('a new write while saved shows syncing again', () async {
    await start();
    signals.reachable.add(true);
    signals.waits.single.complete();
    await _tick();
    expect(states.last, SyncState.synced);
    signals.writes.add(null);
    await _tick();
    expect(states.last, SyncState.syncing);
    signals.waits.last.complete();
    await _tick();
    expect(states.last, SyncState.synced);
  });

  test('a failing check hides the banner instead of guessing', () async {
    signals.waitError = StateError('terminated');
    await start();
    signals.reachable.add(true);
    await _tick();
    expect(states.last, SyncState.unknown);
  });

  test('UnknownSyncStatusSource always says unknown', () async {
    sub = const UnknownSyncStatusSource().watch().listen((_) {});
    expect(
      await const UnknownSyncStatusSource().watch().first,
      SyncState.unknown,
    );
  });

  test('offline-capable writes announce themselves', () async {
    var count = 0;
    sub = const UnknownSyncStatusSource().watch().listen((_) {});
    final events = localWriteEvents.listen((_) => count++);
    addTearDown(events.cancel);
    await awaitOfflineCapableWrite(Future.value(), writeName: 't');
    await _tick();
    expect(count, 1);
  });
}
