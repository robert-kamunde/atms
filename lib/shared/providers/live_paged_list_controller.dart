import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure_mapper.dart';
import '../services/paginated_query.dart';
import 'paged_list_controller.dart';

/// Like [PagedListController], but the list stays up to date while it is
/// shown: one snapshot listener on the first `pages * 20` items. "Load
/// more" listens again with one more page (never an unlimited query);
/// pull to refresh and a change of query start again from one page.
///
/// The state is a [PagedListState], so the same list, board and
/// loading/error/empty widgets work for both kinds of list.
abstract class LivePagedListController<T> extends Notifier<PagedListState<T>> {
  LivePaginatedSource<T>? _source;
  StreamSubscription<LivePage<T>>? _subscription;
  Completer<void>? _firstResult;
  int _pages = 1;
  int _generation = 0;

  /// Creates the source. May throw an `AppFailure` (e.g. signed out).
  LivePaginatedSource<T> createSource();

  /// Called with all shown items each time they change (e.g. to look up
  /// names).
  void onItemsLoaded(List<T> items) {}

  /// Pages currently listened to (for tests and logs).
  int get loadedPages => _pages;

  @override
  PagedListState<T> build() {
    ref.onDispose(_cancel);
    _cancel();
    _source = null;
    _pages = 1;
    final generation = ++_generation;
    Future.microtask(() {
      if (ref.mounted && generation == _generation) unawaited(_listen());
    });
    return PagedListState<T>(loading: true);
  }

  void _cancel() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    // A refresh still waiting for its first result must not hang.
    final first = _firstResult;
    if (first != null && !first.isCompleted) first.complete();
    _firstResult = null;
  }

  /// (Re)starts the listener for [_pages] pages. Completes when the first
  /// result or error arrives.
  Future<void> _listen() {
    _cancel();
    final generation = ++_generation;
    final first = _firstResult = Completer<void>();
    void done() {
      if (!first.isCompleted) first.complete();
    }

    state = state.copyWith(loading: true, clearFailure: true);
    final LivePaginatedSource<T> source;
    try {
      source = _source ??= createSource();
    } catch (error, stackTrace) {
      state = state.copyWith(
        loading: false,
        failure: mapError(error, stackTrace),
      );
      done();
      return first.future;
    }
    _subscription = source
        .watch(pages: _pages)
        .listen(
          (page) {
            done();
            if (!ref.mounted || generation != _generation) return;
            state = PagedListState<T>(
              items: page.items,
              moreAvailable: page.hasMore,
              loadedOnce: true,
            );
            onItemsLoaded(page.items);
          },
          onError: (Object error, StackTrace stackTrace) {
            done();
            if (!ref.mounted || generation != _generation) return;
            state = state.copyWith(
              loading: false,
              failure: mapError(error, stackTrace),
            );
          },
          cancelOnError: true,
        );
    return first.future;
  }

  /// Shows one more page, or retries after an error.
  Future<void> loadMore() async {
    if (state.failure != null) return _listen();
    if (state.loading || !state.hasMore) return;
    _pages++;
    return _listen();
  }

  /// Starts again from the first page (pull to refresh).
  Future<void> refresh() {
    _source = null;
    _pages = 1;
    state = PagedListState<T>(loading: true);
    return _listen();
  }
}
