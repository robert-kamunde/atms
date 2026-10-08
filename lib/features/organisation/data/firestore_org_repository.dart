import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failure_mapper.dart';
import '../domain/org_repository.dart';
import '../domain/org_settings.dart';

/// Keys a verified admin may change in `orgs/{org}` (firestore.rules,
/// "organisation"). Anything else is refused by the rules, so the app
/// never sends it.
const Set<String> orgEditableFields = {
  'name',
  'timezone',
  'workingHoursEnabled',
  'workingHours',
  'reminderHours',
  'escalationHours',
  'escalationMaxLevel',
  'smsEnabled',
  'smsMonthlyCap',
  'auditRetentionYears',
};

/// [OrgRepository] over `orgs/{org}`.
class FirestoreOrgRepository implements OrgRepository {
  FirestoreOrgRepository(this._db, this.orgId);

  final FirebaseFirestore _db;
  final String orgId;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('orgs').doc(orgId);

  @override
  Stream<OrgSettings?> watchSettings() => _doc
      .snapshots()
      .map((snap) {
        final data = snap.data();
        return data == null ? null : OrgSettings.fromMap(data);
      })
      .handleError((Object error, StackTrace stackTrace) {
        throw mapError(error, stackTrace);
      });

  @override
  Future<void> updateSettings(Map<String, Object?> changes) {
    final unexpected = changes.keys.toSet().difference(orgEditableFields);
    if (unexpected.isNotEmpty) {
      throw ArgumentError.value(
        unexpected.join(','),
        'changes',
        'not editable',
      );
    }
    return _doc.update({...changes, 'updatedAt': FieldValue.serverTimestamp()});
  }
}
