import 'package:atms/core/errors/app_failure.dart';
import 'package:atms/core/services/callable_client.dart';
import 'package:atms/features/auth/data/functions_admin_verification_repository.dart';
import 'package:atms/features/departments/data/firestore_department_repository.dart';
import 'package:atms/features/organisation/data/firestore_org_repository.dart';
import 'package:atms/features/organisation/domain/org_settings.dart';
import 'package:atms/features/users/data/firestore_user_repositories.dart';
import 'package:atms/features/users/domain/user_repositories.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock implements HttpsCallableResult<Object?> {}

class _FunctionsException extends FirebaseFunctionsException {
  _FunctionsException(String code, {super.details})
    : super(code: code, message: 'raw');
}

void main() {
  late FakeFirebaseFirestore db;
  setUp(() => db = FakeFirebaseFirestore());

  CollectionReference<Map<String, dynamic>> col(String name) =>
      db.collection('orgs').doc(testOrg).collection(name);

  group('FirestoreDepartmentRepository', () {
    late FirestoreDepartmentRepository repo;
    setUp(() => repo = FirestoreDepartmentRepository(db, testOrg));

    test('create writes exactly the fields the rules allow', () async {
      await repo.create(name: 'Finance', headUserId: 'u9');
      final docs = (await col('departments').get()).docs;
      expect(docs, hasLength(1));
      final data = docs.single.data();
      expect(data.keys.toSet(), {
        'name',
        'headUserId',
        'active',
        'createdAt',
        'updatedAt',
      });
      expect(data['active'], isTrue);
      expect(data['createdAt'], isA<Timestamp>());
    });

    test('update and deactivate change only allowed fields', () async {
      await col('departments')
          .doc('d1')
          .set({'name': 'HR', 'headUserId': null, 'active': true});
      await repo.update(id: 'd1', name: 'Human Resources', headUserId: 'u3');
      await repo.deactivate('d1');
      final data = (await col('departments').doc('d1').get()).data()!;
      expect(data['name'], 'Human Resources');
      expect(data['headUserId'], 'u3');
      expect(data['active'], isFalse);
      expect(data['updatedAt'], isA<Timestamp>());
      expect(data.containsKey('createdAt'), isFalse);
    });

    test('pages by name and looks up by id', () async {
      for (var i = 0; i < 25; i++) {
        await col('departments').doc('d$i').set({
          'name': 'Dept ${i.toString().padLeft(2, '0')}',
          'active': i.isEven,
        });
      }
      final first = await repo.departments().fetchPage();
      expect(first.items, hasLength(20));
      expect(first.items.first.name, 'Dept 00');
      final second = await repo.departments().fetchPage(after: first.next);
      expect(second.items, hasLength(5));
      final byId = await repo.departmentsByIds(['d1', 'd2', 'd1']);
      expect(byId.map((d) => d.id).toSet(), {'d1', 'd2'});
      expect(byId.firstWhere((d) => d.id == 'd1').active, isFalse);
    });
  });

  group('FirestoreUserDirectoryRepository', () {
    late FirestoreUserDirectoryRepository repo;
    setUp(() async {
      repo = FirestoreUserDirectoryRepository(db, testOrg);
      await seedUser(
        db,
        userFixture(id: 'top', name: 'Neema', supervisorId: null),
      );
      await seedUser(
        db,
        userFixture(id: 'a', name: 'Asha', supervisorId: 'top'),
      );
      await seedUser(
        db,
        userFixture(id: 'b', name: 'Baraka', supervisorId: 'top'),
      );
      await seedUser(
        db,
        userFixture(id: 'c', name: 'Chausiku', supervisorId: 'a'),
      );
    });

    test('all users by name', () async {
      final page = await repo.allUsers().fetchPage();
      expect(page.items.map((u) => u.name), [
        'Asha',
        'Baraka',
        'Chausiku',
        'Neema',
      ]);
    });

    test('direct reports, and the top of the tree', () async {
      final top = await repo.directReports(null).fetchPage();
      expect(top.items.map((u) => u.id), ['top']);
      final underTop = await repo.directReports('top').fetchPage();
      expect(underTop.items.map((u) => u.id).toSet(), {'a', 'b'});
    });

    test('users by id and contact details', () async {
      final users = await repo.usersByIds(['a', 'c']);
      expect(users.map((u) => u.id).toSet(), {'a', 'c'});
      await col('users')
          .doc('a')
          .collection('private')
          .doc('contact')
          .set({'phone': '+255712345678', 'email': null});
      final contact = await repo.contact('a');
      expect(contact?.phone, '+255712345678');
      expect(await repo.contact('b'), isNull);
      expect((await repo.user('a'))?.name, 'Asha');
      expect(await repo.user('nobody'), isNull);
    });
  });

  group('FirestoreUserProfileRepository', () {
    test('consent writes only consentVersion and consentAcceptedAt', () async {
      await seedUser(db, userFixture());
      final before = (await col('users').doc('u1').get()).data()!;
      final repo = FirestoreUserProfileRepository(db);
      await repo.acceptConsent(orgId: testOrg, uid: 'u1', version: 'v1');
      final after = (await col('users').doc('u1').get()).data()!;
      final changed = after.keys
          .where((k) => '${before[k]}' != '${after[k]}')
          .toSet();
      expect(changed, {'consentVersion', 'consentAcceptedAt'});
      expect(after['consentAcceptedAt'], isA<Timestamp>());
    });

    test('watchUser emits the user, then null when it is missing', () async {
      await seedUser(db, userFixture());
      final repo = FirestoreUserProfileRepository(db);
      final user = await repo.watchUser(orgId: testOrg, uid: 'u1').first;
      expect(user?.name, 'Asha');
      expect(await repo.watchUser(orgId: testOrg, uid: 'nobody').first, isNull);
    });
  });

  group('FirestoreOrgRepository', () {
    test('writes only the changed fields plus updatedAt', () async {
      await db.collection('orgs').doc(testOrg).set({
        'name': 'Wizara',
        'timezone': 'Africa/Dar_es_Salaam',
        'escalationHours': 24,
        'smsMonthlyCap': 10000,
      });
      final repo = FirestoreOrgRepository(db, testOrg);
      final original = (await repo.watchSettings().first)!;
      final changes = original.changedFields(
        original.copyWith(escalationHours: 12),
      );
      expect(changes, {'escalationHours': 12});
      await repo.updateSettings(changes);
      final data = (await db.collection('orgs').doc(testOrg).get()).data()!;
      expect(data['escalationHours'], 12);
      expect(data['smsMonthlyCap'], 10000);
      expect(data['updatedAt'], isA<Timestamp>());
    });

    test('refuses fields the rules do not allow', () {
      final repo = FirestoreOrgRepository(db, testOrg);
      expect(() => repo.updateSettings({'createdAt': 1}), throwsArgumentError);
    });
  });

  group('callables', () {
    late MockCallableClient client;
    setUp(() => client = MockCallableClient());

    test('adminUpsertUser sends exactly the contract fields', () async {
      when(() => client.call(any(), any()))
          .thenAnswer((_) async => {'uid': 'new1', 'created': true});
      final repo = FunctionsUserAdminRepository(client);
      const draft = UserDraft(
        name: 'Asha',
        phone: '+255712345678',
        email: null,
        role: UserRole.staff,
        deptId: 'finance',
        supervisorId: 'u2',
        jobRole: null,
        language: 'sw',
        confidentialDepts: [],
      );
      final result = await repo.upsertUser(draft);
      expect(result.uid, 'new1');
      expect(result.created, isTrue);
      final sent =
          verify(() => client.call('adminUpsertUser', captureAny()))
                  .captured
                  .single
              as Map<String, Object?>;
      expect(sent.keys.toSet(), {
        'name',
        'phone',
        'email',
        'role',
        'deptId',
        'supervisorId',
        'jobRole',
        'language',
        'confidentialDepts',
      });
      expect(sent['role'], 'staff');
      expect(
        const UserDraft(
          uid: 'u1',
          name: 'A',
          phone: null,
          email: 'a@b.tz',
          role: UserRole.admin,
          deptId: 'd',
          supervisorId: null,
          jobRole: null,
          language: 'en',
          confidentialDepts: ['hr'],
        ).toCallableData()['uid'],
        'u1',
      );
    });

    test('deactivateUser returns the flagged task count', () async {
      when(() => client.call('deactivateUser', {'uid': 'u1'}))
          .thenAnswer((_) async => {'flaggedTaskCount': 4});
      expect(
        await FunctionsUserAdminRepository(client).deactivateUser('u1'),
        4,
      );
    });

    test('admin code send and verify', () async {
      when(() => client.call('sendAdminCode')).thenAnswer(
        (_) async => {'maskedEmail': 'i***@org.tz', 'expiresAt': 1791461400000},
      );
      when(() => client.call('verifyAdminCode', {'code': '123456'}))
          .thenAnswer((_) async => {'verifiedUntil': 1791504000000});
      final repo = FunctionsAdminVerificationRepository(client);
      final sent = await repo.sendAdminCode();
      expect(sent.maskedEmail, 'i***@org.tz');
      expect(sent.expiresAt, DateTime.utc(2026, 10, 8, 12, 10));
      expect(await repo.verifyAdminCode('123456'), DateTime.utc(2026, 10, 9));
    });

    test('a malformed answer is an UnknownFailure', () async {
      when(() => client.call('sendAdminCode')).thenAnswer((_) async => {});
      expect(
        FunctionsAdminVerificationRepository(client).sendAdminCode(),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  group('CallableClient', () {
    late _MockFunctions functions;
    late _MockCallable callable;
    setUpAll(() => registerFallbackValue(HttpsCallableOptions()));
    setUp(() {
      functions = _MockFunctions();
      callable = _MockCallable();
      when(() => functions.httpsCallable(any(), options: any(named: 'options')))
          .thenReturn(callable);
    });

    test('returns the data map', () async {
      final result = _MockResult();
      when(() => result.data).thenReturn({'uid': 'x'});
      when(() => callable.call<Object?>(any<Object?>()))
          .thenAnswer((_) async => result);
      expect(await CallableClient(functions).call('f'), {'uid': 'x'});
      final options =
          verify(
                () => functions.httpsCallable(
                  'f',
                  options: captureAny(named: 'options'),
                ),
              ).captured.single
              as HttpsCallableOptions;
      expect(options.timeout, const Duration(seconds: 20));
    });

    test('server error codes become friendly failures', () async {
      when(() => callable.call<Object?>(any<Object?>())).thenThrow(
        _FunctionsException(
          'failed-precondition',
          details: {'code': 'reporting-loop'},
        ),
      );
      expect(
        CallableClient(functions).call('adminUpsertUser'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('offline means "needs a connection"', () async {
      when(() => callable.call<Object?>(any<Object?>()))
          .thenThrow(_FunctionsException('unavailable'));
      expect(
        CallableClient(functions).call('sendAdminCode'),
        throwsA(isA<ConnectionRequiredFailure>()),
      );
    });
  });

  test('parseReminderHours and clocks', () {
    expect(parseReminderHours('24, 1'), [24, 1]);
    expect(parseReminderHours('1 48 24 24'), [48, 24, 1]);
    expect(parseReminderHours(''), isNull);
    expect(parseReminderHours('0'), isNull);
    expect(parseReminderHours('abc'), isNull);
    expect(parseReminderHours('721'), isNull);
    expect(parseClock('08:30'), (hour: 8, minute: 30));
    expect(parseClock('24:00'), isNull);
    expect(formatClock(7, 5), '07:05');
  });

  test('OrgSettings.changedFields only lists allowed, changed keys', () {
    final original = OrgSettings.fromMap({});
    final edited = original.copyWith(
      workingHours: const WorkingHours(
        start: '07:30',
        end: '16:00',
        days: [5, 1],
      ),
      smsEnabled: true,
      reminderHours: [48, 2],
    );
    final changes = original.changedFields(edited);
    expect(changes.keys.toSet(), {
      'workingHours',
      'smsEnabled',
      'reminderHours',
    });
    expect(changes['workingHours'], {
      'start': '07:30',
      'end': '16:00',
      'days': [1, 5],
    });
    expect(orgEditableFields.containsAll(changes.keys), isTrue);
    expect(original.changedFields(original), isEmpty);
  });
}
