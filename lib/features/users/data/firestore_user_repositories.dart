import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/services/callable_client.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/services/paginated_query.dart';
import '../domain/user_repositories.dart';

CollectionReference<Map<String, dynamic>> _users(
  FirebaseFirestore db,
  String orgId,
) => db.collection('orgs').doc(orgId).collection('users');

/// [UserProfileRepository] over `orgs/{org}/users/{uid}`.
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<AppUser?> watchUser({required String orgId, required String uid}) {
    return _users(_db, orgId)
        .doc(uid)
        .snapshots(includeMetadataChanges: true)
        // A missing document read only from the offline cache says nothing
        // about the server: wait for the server's answer.
        .where((snap) => snap.exists || !snap.metadata.isFromCache)
        .map((snap) {
          final data = snap.data();
          if (data == null) return null;
          return AppUser.fromMap(snap.id, data, orgId: orgId);
        })
        .handleError((Object error, StackTrace stackTrace) {
          throw mapError(error, stackTrace);
        });
  }

  @override
  Future<void> updateLanguage({
    required String orgId,
    required String uid,
    required String language,
  }) => _users(_db, orgId).doc(uid).update({'language': language});

  @override
  Future<void> acceptConsent({
    required String orgId,
    required String uid,
    required String version,
  }) => _users(_db, orgId).doc(uid).update({
    'consentVersion': version,
    'consentAcceptedAt': FieldValue.serverTimestamp(),
  });
}

/// [UserDirectoryRepository] over `orgs/{org}/users`.
class FirestoreUserDirectoryRepository implements UserDirectoryRepository {
  FirestoreUserDirectoryRepository(this._db, this.orgId);

  final FirebaseFirestore _db;
  final String orgId;

  AppUser _decode(String id, Map<String, Object?> data) =>
      AppUser.fromMap(id, data, orgId: orgId);

  @override
  PaginatedSource<AppUser> allUsers() => FirestorePaginatedQuery<AppUser>(
    query: _users(_db, orgId).orderBy('name'),
    decode: _decode,
    debugLabel: 'allUsers',
  );

  @override
  PaginatedSource<AppUser> directReports(String? supervisorId) =>
      FirestorePaginatedQuery<AppUser>(
        // Equality plus document-id order needs no composite index.
        query:
            (supervisorId == null
                    ? _users(_db, orgId).where('supervisorId', isNull: true)
                    : _users(
                        _db,
                        orgId,
                      ).where('supervisorId', isEqualTo: supervisorId))
                .orderBy(FieldPath.documentId),
        decode: _decode,
        debugLabel: 'directReports',
      );

  @override
  Future<List<AppUser>> usersByIds(Iterable<String> ids) async {
    final unique = ids.toSet().toList();
    assert(
      unique.length <= AppConstants.pageSize * 2,
      'usersByIds is for the names on one loaded page only',
    );
    final result = <AppUser>[];
    // Firestore `whereIn` accepts at most 30 values; 10 keeps each read small.
    for (var i = 0; i < unique.length; i += 10) {
      final chunk = unique.sublist(i, (i + 10).clamp(0, unique.length));
      try {
        final snap = await _users(
          _db,
          orgId,
        ).where(FieldPath.documentId, whereIn: chunk).get();
        for (final doc in snap.docs) {
          try {
            result.add(_decode(doc.id, doc.data()));
          } on FormatException catch (error, stackTrace) {
            AppLogger.error(
              'Skipping malformed user',
              context: {'docId': doc.id},
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
      } catch (error, stackTrace) {
        throw mapError(error, stackTrace);
      }
    }
    return result;
  }

  @override
  Future<AppUser?> user(String id) async {
    try {
      final snap = await _users(_db, orgId).doc(id).get();
      final data = snap.data();
      return data == null ? null : _decode(snap.id, data);
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }

  @override
  Future<UserContact?> contact(String id) async {
    try {
      final snap = await _users(
        _db,
        orgId,
      ).doc(id).collection('private').doc('contact').get();
      final data = snap.data();
      return data == null ? null : UserContact.fromMap(data);
    } catch (error, stackTrace) {
      throw mapError(error, stackTrace);
    }
  }
}

/// [UserAdminRepository] over the `adminUpsertUser` and `deactivateUser`
/// callables (docs/SPRINT1_CONTRACT.md).
class FunctionsUserAdminRepository implements UserAdminRepository {
  FunctionsUserAdminRepository(this._client);

  final CallableClient _client;

  @override
  Future<UpsertUserResult> upsertUser(UserDraft draft) async {
    final data = await _client.call('adminUpsertUser', draft.toCallableData());
    return UpsertUserResult(
      uid: readString(data, 'uid'),
      created: data['created'] == true,
    );
  }

  @override
  Future<int> deactivateUser(String uid) async {
    final data = await _client.call('deactivateUser', {'uid': uid});
    return readNum(data, 'flaggedTaskCount').toInt();
  }
}
