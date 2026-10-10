import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/failure_mapper.dart';
import '../services/paginated_query.dart';

/// State of a list loaded one page (20 items) at a time.
@immutable
class PagedListState<T> {
  const PagedListState({
    this.items = const [],
    this.next,
    this.loading = false,
    this.loadedOnce = false,
    this.failure,
    this.moreAvailable,
  });

  final List<T> items;
  final PageCursor? next;
  final bool loading;

  /// True after the first page arrived (so an empty list means "none").
  final bool loadedOnce;

  /// The last load error, shown with a retry button.
  final AppFailure? failure;

  /// Set by live lists, which have no cursor; null means "use [next]".
  final bool? moreAvailable;

  bool get hasMore => moreAvailable ?? next != null;

  PagedListState<T> copyWith({
    List<T>? items,
    PageCursor? next,
    bool clearNext = false,
    bool? loading,
    bool? loadedOnce,
    AppFailure? failure,
    bool clearFailure = false,
  }) => PagedListState<T>(
    items: items ?? this.items,
    next: clearNext ? null : (next ?? this.next),
    loading: loading ?? this.loading,
    loadedOnce: loadedOnce ?? this.loadedOnce,
    failure: clearFailure ? null : (failure ?? this.failure),
    moreAvailable: moreAvailable,
  );
}

/// Loads a [PaginatedSource] page by page ("Load more"), never more than
/// one page per request (spec 8: no unlimited lists). The first page loads
/// when the provider is first read.
abstract class PagedListController<T> extends Notifier<PagedListState<T>> {
  PaginatedSource<T>? _source;
  int _generation = 0;
  bool _inFlight = false;

  /// Creates the source. May throw an `AppFailure` (e.g. signed out).
  PaginatedSource<T> createSource();

  /// Called after each page with its items (e.g. to look up names).
  void onPageLoaded(List<T> items) {}

  @override
  PagedListState<T> build() {
    _source = null;
    _inFlight = false;
    final generation = ++_generation;
    Future.microtask(() {
      if (ref.mounted && generation == _generation) unawaited(loadMore());
    });
    return PagedListState<T>(loading: true);
  }

  /// Loads the next page (or the first one).
  Future<void> loadMore() async {
    if (_inFlight) return;
    if (state.loadedOnce && !state.hasMore) return;
    _inFlight = true;
    final generation = _generation;
    state = state.copyWith(loading: true, clearFailure: true);
    try {
      final source = _source ??= createSource();
      final page = await source.fetchPage(after: state.next);
      if (!ref.mounted || generation != _generation) return;
      state = PagedListState<T>(
        items: List.unmodifiable([...state.items, ...page.items]),
        next: page.next,
        loadedOnce: true,
      );
      onPageLoaded(page.items);
    } catch (error, stackTrace) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        loading: false,
        failure: mapError(error, stackTrace),
      );
    } finally {
      if (generation == _generation) _inFlight = false;
    }
  }

  /// Starts again from the first page (after an edit, or pull to refresh).
  Future<void> refresh() async {
    _generation++;
    _source = null;
    _inFlight = false;
    state = PagedListState<T>(loading: true);
    await loadMore();
  }
}

/// Throws [UnauthenticatedFailure] when [repository] is null (no session),
/// so no query runs while signed out.
T requireRepository<T extends Object>(T? repository) =>
    repository ?? (throw const UnauthenticatedFailure());
