import 'package:cloud_functions/cloud_functions.dart';

import '../constants/app_constants.dart';
import '../errors/app_failure.dart';
import '../errors/failure_mapper.dart';
import '../utils/logger.dart';

/// Calls an online-only callable Cloud Function and returns its data as a
/// map. Every error becomes an `AppFailure`: a timeout or no connection is a
/// [ConnectionRequiredFailure] (shown as "needs an internet connection"),
/// so the app never hangs while offline (ARCHITECTURE section 1).
class CallableClient {
  CallableClient(
    this._functions, {
    this.timeout = AppConstants.callableTimeout,
  });

  final FirebaseFunctions _functions;
  final Duration timeout;

  Future<Map<String, Object?>> call(
    String name, [
    Map<String, Object?> data = const {},
  ]) async {
    try {
      final result = await _functions
          .httpsCallable(name, options: HttpsCallableOptions(timeout: timeout))
          .call<Object?>(data);
      final value = result.data;
      if (value is Map) return value.cast<String, Object?>();
      if (value == null) return const {};
      throw const FormatException('Callable returned an unexpected shape');
    } on AppFailure {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      AppLogger.error(
        'Callable returned malformed data',
        context: {'callable': name},
        error: error,
        stackTrace: stackTrace,
      );
      throw UnknownFailure(code: 'malformed-response', cause: error);
    } catch (error, stackTrace) {
      final failure = mapError(error, stackTrace);
      AppLogger.warning(
        'Callable failed',
        context: {'callable': name, 'errorCode': failure.code},
      );
      throw failure;
    }
  }
}

/// Reads a required number field from a callable result.
num readNum(Map<String, Object?> data, String field) {
  final value = data[field];
  if (value is num) return value;
  throw UnknownFailure(code: 'malformed-response', cause: field);
}

/// Reads a required string field from a callable result.
String readString(Map<String, Object?> data, String field) {
  final value = data[field];
  if (value is String) return value;
  throw UnknownFailure(code: 'malformed-response', cause: field);
}
