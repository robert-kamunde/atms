import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failure_mapper.dart';
import '../../core/utils/logger.dart';

/// Opaque position in a paginated list. Screens pass it back unchanged to
/// load the next page; they never look inside.
@immutable
class PageCursor {
  const PageCursor._(this._snapshot);

  final DocumentSnapshot<Map<String, dynamic>> _snapshot;
}

/// One page of results.
@immutable
class PageResult<T> {
  const PageResult({required this.items, this.next});

  final List<T> items;

  /// Cursor for the next page, or null when this is the last page.
  final PageCursor? next;

  bool get hasMore => next != null;
}

/// The only way repositories expose lists (spec 8: "paginate lists, 20 at a
/// time"). Unlimited list reads are not allowed anywhere in the app.
abstract interface class PaginatedSource<T> {
  /// Page size used by this source; never more than [AppConstants.pageSize].
  int get pageSize;

  /// Loads the page after [after] (or the first page when null).
  ///
  /// Throws an `AppFailure` (never a raw Firebase error).
  Future<PageResult<T>> fetchPage({PageCursor? after});
}

/// Converts a Firestore document to a model.
typedef DocumentDecoder<T> = T Function(String id, Map<String, Object?> data);

/// [PaginatedSource] over a Firestore [Query].
///
/// The query must already contain its `where` and `orderBy` clauses (for
/// tasks: `viewerIds array-contains me`, ordered by `deadline`; spec 5).
/// This class adds `limit` and `startAfterDocument`.
class FirestorePaginatedQuery<T> implements PaginatedSource<T> {
  FirestorePaginatedQuery({
    required this.query,
    required this.decode,
    this.pageSize = AppConstants.pageSize,
    this.debugLabel = 'query',
  }) : assert(
         pageSize > 0 && pageSize <= AppConstants.pageSize,
         'pageSize must be between 1 and ${AppConstants.pageSize}',
       );

  /// Base query with its `where` and `orderBy` clauses.
  final Query<Map<String, dynamic>> query;

  /// Converts each document to a model.
  final DocumentDecoder<T> decode;

  @override
  final int pageSize;

  /// Name used in logs (e.g. `myTasks`). Never put content here.
  final String debugLabel;

  @override
  Future<PageResult<T>> fetchPage({PageCursor? after}) async {
    // Cursor first, then limit (order matters for some fakes; Firestore
    // itself accepts either). One extra document tells us whether another
    // page exists without a second round trip.
    var pageQuery = query;
    if (after != null) {
      pageQuery = pageQuery.startAfterDocument(after._snapshot);
    }
    pageQuery = pageQuery.limit(pageSize + 1);
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await pageQuery.get();
    } on FirebaseException catch (error, stackTrace) {
      final failure = mapFirebaseException(error);
      AppLogger.warning(
        'Paginated query failed',
        context: {'query': debugLabel, 'code': error.code},
        error: failure,
        stackTrace: stackTrace,
      );
      throw failure;
    }
    final docs = snapshot.docs;
    final hasMore = docs.length > pageSize;
    final pageDocs = hasMore ? docs.sublist(0, pageSize) : docs;
    final items = <T>[];
    for (final doc in pageDocs) {
      try {
        items.add(decode(doc.id, doc.data()));
      } on FormatException catch (error, stackTrace) {
        // A malformed document must not break the whole list. It is
        // skipped and logged (by id only) so it can be fixed.
        AppLogger.error(
          'Skipping malformed document',
          context: {'query': debugLabel, 'docId': doc.id},
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return PageResult<T>(
      items: List.unmodifiable(items),
      next: hasMore ? PageCursor._(pageDocs.last) : null,
    );
  }
}
