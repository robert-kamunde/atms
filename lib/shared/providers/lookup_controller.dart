import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure_mapper.dart';
import '../../core/utils/logger.dart';

/// Caches documents looked up by id (supervisor names, department names)
/// for the items on loaded pages. Only ids that are asked for are read,
/// so it never loads a whole collection.
abstract class LookupController<T> extends Notifier<Map<String, T>> {
  final Set<String> _requested = {};

  /// Reads the documents with [ids] (at most one page's worth).
  Future<List<T>> fetch(List<String> ids);

  String idOf(T item);

  @override
  Map<String, T> build() {
    _requested.clear();
    return const {};
  }

  /// Makes sure the items with [ids] are loaded. Errors are logged and the
  /// ids may be asked for again later; the screens show a placeholder.
  Future<void> ensure(Iterable<String?> ids) async {
    final missing = ids
        .whereType<String>()
        .where((id) => id.isNotEmpty && !_requested.contains(id))
        .toSet()
        .toList();
    if (missing.isEmpty) return;
    _requested.addAll(missing);
    try {
      final items = await fetch(missing);
      if (!ref.mounted) return;
      state = {...state, for (final item in items) idOf(item): item};
    } catch (error, stackTrace) {
      _requested.removeAll(missing);
      final failure = mapError(error, stackTrace);
      AppLogger.warning(
        'Lookup failed',
        context: {'lookup': runtimeType.toString(), 'errorCode': failure.code},
      );
    }
  }

  /// Puts a known item in the cache (e.g. after it was picked).
  void put(T item) {
    _requested.add(idOf(item));
    state = {...state, idOf(item): item};
  }
}
