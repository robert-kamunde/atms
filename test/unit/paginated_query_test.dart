import 'package:atms/core/constants/app_constants.dart';
import 'package:atms/shared/services/paginated_query.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pages through 45 documents as 20 + 20 + 5', () async {
    final db = FakeFirebaseFirestore();
    for (var i = 0; i < 45; i++) {
      await db.collection('items').doc('d$i').set({'n': i});
    }
    final source = FirestorePaginatedQuery<int>(
      query: db.collection('items').orderBy('n'),
      decode: (id, data) => data['n']! as int,
    );
    expect(source.pageSize, AppConstants.pageSize);

    final p1 = await source.fetchPage();
    expect(p1.items, List.generate(20, (i) => i));
    expect(p1.hasMore, isTrue);

    final p2 = await source.fetchPage(after: p1.next);
    expect(p2.items, List.generate(20, (i) => i + 20));
    expect(p2.hasMore, isTrue);

    final p3 = await source.fetchPage(after: p2.next);
    expect(p3.items, List.generate(5, (i) => i + 40));
    expect(p3.hasMore, isFalse);
  });

  test('exactly one page has no next cursor', () async {
    final db = FakeFirebaseFirestore();
    for (var i = 0; i < 20; i++) {
      await db.collection('items').add({'n': i});
    }
    final page = await FirestorePaginatedQuery<int>(
      query: db.collection('items').orderBy('n'),
      decode: (id, data) => data['n']! as int,
    ).fetchPage();
    expect(page.items, hasLength(20));
    expect(page.hasMore, isFalse);
  });

  test('malformed documents are skipped, not fatal', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('items').doc('a').set({'n': 1});
    await db.collection('items').doc('b').set({'n': 2, 'bad': true});
    final page = await FirestorePaginatedQuery<int>(
      query: db.collection('items').orderBy('n'),
      decode: (id, data) {
        if (data['bad'] == true) throw const FormatException('bad');
        return data['n']! as int;
      },
    ).fetchPage();
    expect(page.items, [1]);
  });

  test('page size above 20 is not allowed', () {
    final db = FakeFirebaseFirestore();
    expect(
      () => FirestorePaginatedQuery<int>(
        query: db.collection('items'),
        decode: (id, data) => 0,
        pageSize: 50,
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
