import 'dart:async';

import '../constants/app_constants.dart';
import '../errors/app_failure.dart';
import '../errors/failure_mapper.dart';
import '../utils/logger.dart';

/// What happened to a Firestore write the app made.
enum WriteOutcome {
  /// The server accepted it.
  saved,

  /// No answer from the server yet (usually offline). The write is kept in
  /// Firestore's offline queue on the phone and is sent when the connection
  /// returns (spec 4.9). If the server later refuses it, the change is
  /// rolled back on the phone and [lateWriteFailureHandler] is told.
  savedOnPhone,
}

/// Receives failures of writes that were reported as
/// [WriteOutcome.savedOnPhone] and refused later. Set by the app shell to
/// show a message; logged in every case.
void Function(AppFailure failure)? lateWriteFailureHandler;

final StreamController<void> _localWrites = StreamController<void>.broadcast();

/// Fires each time the app starts an offline-capable write, so the sync
/// banner checks for unconfirmed writes again (spec 4.9).
Stream<void> get localWriteEvents => _localWrites.stream;

/// Waits up to [wait] for [write] (a Firestore `set`/`update`) to be
/// acknowledged. Firestore applies the change to the local cache at once
/// but its future only completes when the server answers, which never
/// happens while offline, so screens must not await it forever.
///
/// Throws an [AppFailure] if the server refuses within [wait].
Future<WriteOutcome> awaitOfflineCapableWrite(
  Future<void> write, {
  required String writeName,
  Duration wait = AppConstants.offlineWriteWait,
}) async {
  _localWrites.add(null);
  try {
    await write.timeout(wait);
    return WriteOutcome.saved;
  } on TimeoutException {
    unawaited(
      write.then<void>(
        (_) => AppLogger.info(
          'Queued write synced',
          context: {'write': writeName},
        ),
        onError: (Object error, StackTrace stackTrace) {
          final failure = mapError(error, stackTrace);
          AppLogger.error(
            'Queued write refused after sync',
            context: {'write': writeName, 'errorCode': failure.code},
            error: failure,
            stackTrace: stackTrace,
          );
          lateWriteFailureHandler?.call(failure);
        },
      ),
    );
    return WriteOutcome.savedOnPhone;
  } catch (error, stackTrace) {
    final failure = mapError(error, stackTrace);
    AppLogger.warning(
      'Write refused',
      context: {'write': writeName, 'errorCode': failure.code},
    );
    throw failure;
  }
}
