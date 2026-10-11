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

/// The first `pages * pageSize` items of a live list.
@immutable
class LivePage<T> {
  const LivePage({required this.items, required this.hasMore});

  final List<T> items;

  /// True when at least one more item exists after [items].
  final bool hasMore;
}

/// A list that stays up to date while it is shown (e.g. task lists: a
/// status change must reach the creator within seconds, PDD AC-4.3-2).
///
/// It is still paged: [watch] listens to the first `pages * pageSize`
/// items only, and "Load more" listens again with one more page. Never
/// an unlimited query.
abstract interface class LivePaginatedSource<T> {
  /// Page size used by this source; never more than [AppConstants.pageSize].
  int get pageSize;

  /// The first [pages] pages, again every time they change (including
  /// "waiting to sync" changes). Errors are `AppFailure`s; the stream ends
  /// after an error.
  Stream<LivePage<T>> watch({required int pages});
}

/// Converts a Firestore document to a model.
typedef DocumentDecoder<T> = T Function(String id, Map<String, Object?> data);

/// Like [DocumentDecoder], also told whether the document has changes made
/// on this phone that have not reached the server ("waiting to sync").
typedef PendingAwareDecoder<T> = T Function(
  String id,
  Map<String, Object?> data,
  bool hasPendingWrites,
);

/// [PaginatedSource] and [LivePaginatedSource] over a Firestore [Query].
///
/// The query must already contain its `where` and `orderBy` clauses (for
/// tasks: `viewerIds array-contains me`, ordered by `deadline`; spec 5).
/// This class adds `limit` and `startAfterDocument` (one-shot pages) or
/// `limit` alone (live pages).
class FirestorePaginatedQuery<T>
    implements PaginatedSource<T>, LivePaginatedSource<T> {
  FirestorePaginatedQuery({
    required this.query,
    required this.decode,
    this.pendingAwareDecode,
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

  /// When set, used instead of [decode] with the document's
  /// `metadata.hasPendingWrites`.
  final PendingAwareDecoder<T>? pendingAwareDecode;

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
    return PageResult<T>(
      items: _decodeAll(pageDocs),
      next: hasMore ? PageCursor._(pageDocs.last) : null,
    );
  }

  @override
  Stream<LivePage<T>> watch({required int pages}) {
    assert(pages > 0, 'pages must be at least 1');
    final limit = pages * pageSize;
    // One extra document tells us whether more exist, as for fetchPage.
    // Metadata changes are included so "waiting to sync" stays right.
    return query
        .limit(limit + 1)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final docs = snapshot.docs;
          final hasMore = docs.length > limit;
          return LivePage<T>(
            items: _decodeAll(hasMore ? docs.sublist(0, limit) : docs),
            hasMore: hasMore,
          );
        })
        .handleError((Object error, StackTrace stackTrace) {
          final failure = mapError(error, stackTrace);
          AppLogger.warning(
            'Live paginated query failed',
            context: {'query': debugLabel, 'code': failure.code},
            error: failure,
            stackTrace: stackTrace,
          );
          throw failure;
        });
  }

  List<T> _decodeAll(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final items = <T>[];
    for (final doc in docs) {
      try {
        final pendingAware = pendingAwareDecode;
        items.add(
          pendingAware != null
              ? pendingAware(doc.id, doc.data(), doc.metadata.hasPendingWrites)
              : decode(doc.id, doc.data()),
        );
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
    return List.unmodifiable(items);
  }
}
