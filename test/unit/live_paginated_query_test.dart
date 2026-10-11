import 'dart:async';

import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/shared/providers/live_paged_list_controller.dart';
import 'package:atms/shared/providers/paged_list_controller.dart';
import 'package:atms/shared/services/paginated_query.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

/// Records each `watch` and lets the test push results into it.
class _RecordingSource implements LivePaginatedSource<int> {
  final List<int> watchedPages = [];
  final List<StreamController<LivePage<int>>> streams = [];

  @override
  int get pageSize => 20;

  @override
  Stream<LivePage<int>> watch({required int pages}) {
    watchedPages.add(pages);
    final controller = StreamController<LivePage<int>>();
    streams.add(controller);
    return controller.stream;
  }

  /// Sends the first `pages * 20` of [total] numbers to the newest watch.
  void emit(int total) {
    final limit = watchedPages.last * pageSize;
    streams.last.add(
      LivePage(
        items: List.generate(total < limit ? total : limit, (i) => i),
        hasMore: total > limit,
      ),
    );
  }
}

late _RecordingSource _source;

class _Controller extends LivePagedListController<int> {
  @override
  LivePaginatedSource<int> createSource() => _source;
}

final _provider =
    NotifierProvider.autoDispose<_Controller, PagedListState<int>>(
      _Controller.new,
    );

void main() {
  group('FirestorePaginatedQuery.watch', () {
    test('listens to pages * 20 items, with one extra for hasMore', () async {
      final db = FakeFirebaseFirestore();
      for (var i = 0; i < 45; i++) {
        await db.collection('items').doc('d$i').set({'n': i});
      }
      final source = FirestorePaginatedQuery<int>(
        query: db.collection('items').orderBy('n'),
        decode: (id, data) => data['n']! as int,
      );
      final one = await source.watch(pages: 1).first;
      expect(one.items, List.generate(20, (i) => i));
      expect(one.hasMore, isTrue);
      final two = await source.watch(pages: 2).first;
      expect(two.items, List.generate(40, (i) => i));
      expect(two.hasMore, isTrue);
      final three = await source.watch(pages: 3).first;
      expect(three.items, List.generate(45, (i) => i));
      expect(three.hasMore, isFalse);
    });

    test('emits again when a shown or new document changes', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('items').doc('a').set({'n': 1});
      final source = FirestorePaginatedQuery<int>(
        query: db.collection('items').orderBy('n'),
        decode: (id, data) => data['n']! as int,
      );
      final seen = <List<int>>[];
      final sub = source.watch(pages: 1).listen((p) => seen.add(p.items));
      addTearDown(sub.cancel);
      await settle();
      await db.collection('items').doc('a').update({'n': 5});
      await settle();
      await db.collection('items').doc('b').set({'n': 2});
      await settle();
      expect(seen, [
        [1],
        [5],
        [2, 5],
      ]);
    });

    test('skips malformed documents', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('items').doc('good').set({'n': 1});
      await db.collection('items').doc('bad').set({'n': 2, 'bad': true});
      final page = await FirestorePaginatedQuery<int>(
        query: db.collection('items').orderBy('n'),
        decode: (id, data) {
          if (data['bad'] == true) throw const FormatException('bad');
          return data['n']! as int;
        },
      ).watch(pages: 1).first;
      expect(page.items, [1]);
    });
  });

  group('LivePagedListController', () {
    late ProviderContainer container;

    setUp(() {
      _source = _RecordingSource();
      container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(_provider, (_, _) {});
      addTearDown(sub.close);
    });

    PagedListState<int> state() => container.read(_provider);
    _Controller controller() => container.read(_provider.notifier);

    test('Load more raises the listened limit by one page (20)', () async {
      await settle();
      expect(_source.watchedPages, [1]);
      expect(state().loading, isTrue);
      _source.emit(45);
      await settle();
      expect(state().items, hasLength(20));
      expect(state().hasMore, isTrue);
      expect(state().loading, isFalse);

      unawaited(controller().loadMore());
      expect(_source.watchedPages, [1, 2]);
      expect(controller().loadedPages, 2);
      // The old listener is cancelled; its results are ignored.
      expect(_source.streams.first.hasListener, isFalse);
      expect(state().loading, isTrue);
      expect(state().items, hasLength(20), reason: 'keeps what is shown');
      _source.emit(45);
      await settle();
      expect(state().items, hasLength(40));

      unawaited(controller().loadMore());
      _source.emit(45);
      await settle();
      expect(_source.watchedPages, [1, 2, 3]);
      expect(state().items, hasLength(45));
      expect(state().hasMore, isFalse);

      // Nothing more to load: no new listener.
      await controller().loadMore();
      expect(_source.watchedPages, [1, 2, 3]);
    });

    test('later results replace the list (live updates)', () async {
      await settle();
      _source.emit(3);
      await settle();
      expect(state().items, [0, 1, 2]);
      _source.emit(4);
      await settle();
      expect(state().items, [0, 1, 2, 3]);
    });

    test(
      'an error is shown; retry listens again with the same limit',
      () async {
        await settle();
        _source.emit(30);
        await settle();
        unawaited(controller().loadMore());
        _source.streams.last.addError(const NetworkFailure());
        await settle();
        expect(state().failure, isA<NetworkFailure>());
        expect(state().items, hasLength(20));
        expect(state().loading, isFalse);
        unawaited(controller().loadMore());
        expect(_source.watchedPages, [1, 2, 2]);
        expect(state().failure, isNull);
      },
    );

    test('refresh starts again from one page', () async {
      await settle();
      _source.emit(45);
      await settle();
      unawaited(controller().loadMore());
      _source.emit(45);
      await settle();
      final refreshed = controller().refresh();
      expect(_source.watchedPages, [1, 2, 1]);
      expect(_source.streams[1].hasListener, isFalse);
      _source.emit(45);
      await refreshed;
      expect(state().items, hasLength(20));
    });

    test('dispose cancels the listener', () async {
      await settle();
      expect(_source.streams.single.hasListener, isTrue);
      container.dispose();
      await settle();
      expect(_source.streams.single.hasListener, isFalse);
    });
  });
}
