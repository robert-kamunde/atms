import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/audit_entry.dart';
import '../../../shared/services/paginated_query.dart';
import '../domain/audit_repository.dart';

/// [AuditRepository] over `orgs/{org}/audit`. The queries carry the
/// clauses the audit read rule needs (indexes in firestore.indexes.json).
class FirestoreAuditRepository implements AuditRepository {
  FirestoreAuditRepository(this._db, {required this.orgId, required this.uid});

  final FirebaseFirestore _db;
  final String orgId;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _audit =>
      _db.collection('orgs').doc(orgId).collection('audit');

  @override
  PaginatedSource<AuditEntry> taskActivity(
    String taskId, {
    required bool asAdmin,
  }) => FirestorePaginatedQuery<AuditEntry>(
    query:
        (asAdmin
                ? _audit
                      .where('taskId', isEqualTo: taskId)
                      .where('confidential', isEqualTo: false)
                : _audit
                      .where('taskId', isEqualTo: taskId)
                      .where('viewerIds', arrayContains: uid))
            .orderBy('at', descending: true),
    decode: AuditEntry.fromMap,
    debugLabel: 'taskActivity',
  );

  @override
  PaginatedSource<AuditEntry> orgActivity() =>
      FirestorePaginatedQuery<AuditEntry>(
        query: _audit
            .where('confidential', isEqualTo: false)
            .orderBy('at', descending: true),
        decode: AuditEntry.fromMap,
        debugLabel: 'orgActivity',
      );
}
