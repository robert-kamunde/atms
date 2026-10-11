import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/department.dart';
import '../../../shared/services/paginated_query.dart';
import '../domain/department_repository.dart';

/// [DepartmentRepository] over `orgs/{org}/departments`.
class FirestoreDepartmentRepository implements DepartmentRepository {
  FirestoreDepartmentRepository(this._db, this.orgId);

  final FirebaseFirestore _db;
  final String orgId;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('orgs').doc(orgId).collection('departments');

  @override
  PaginatedSource<Department> departments() =>
      FirestorePaginatedQuery<Department>(
        query: _col.orderBy('name'),
        decode: Department.fromMap,
        debugLabel: 'departments',
      );

  @override
  Future<List<Department>> departmentsByIds(Iterable<String> ids) async {
    final unique = ids.toSet().toList();
    final result = <Department>[];
    for (var i = 0; i < unique.length; i += 10) {
      final chunk = unique.sublist(i, (i + 10).clamp(0, unique.length));
      try {
        final snap = await _col
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          try {
            result.add(Department.fromMap(doc.id, doc.data()));
          } on FormatException catch (error, stackTrace) {
            AppLogger.error(
              'Skipping malformed department',
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
  Future<void> create({required String name, String? headUserId}) =>
      _col.doc().set({
        'name': name,
        'headUserId': headUserId,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> update({
    required String id,
    required String name,
    String? headUserId,
  }) => _col.doc(id).update({
    'name': name,
    'headUserId': headUserId,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> deactivate(String id) => _col.doc(id).update({
    'active': false,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
