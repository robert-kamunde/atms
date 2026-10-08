import 'package:flutter/foundation.dart';

import 'firestore_converters.dart';
import 'user_role.dart';

/// A member of an organisation: `orgs/{orgId}/users/{id}` (spec 5).
///
/// Phone and email are not here: they live in `users/{id}/private/contact`
/// (A-12, see [UserContact]) so colleagues can read names but not numbers.
/// User documents are written only by Cloud Functions (`adminUpsertUser`);
/// the person may change only `language`, `consentVersion`,
/// `consentAcceptedAt` and `muteComments` (firestore.rules).
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.orgId,
    required this.name,
    required this.role,
    required this.deptId,
    this.supervisorId,
    this.managerChain = const [],
    this.confidentialDepts = const [],
    this.jobRole,
    this.language = 'en',
    this.active = true,
    this.consentVersion,
  });

  factory AppUser.fromMap(
    String id,
    Map<String, Object?> map, {
    required String orgId,
  }) => AppUser(
    id: id,
    orgId: orgId,
    name: FirestoreConverters.string(map['name'], field: 'name'),
    role: UserRole.fromFirestore(map['role']),
    deptId: FirestoreConverters.string(map['deptId'], field: 'deptId'),
    supervisorId: FirestoreConverters.stringOrNull(map['supervisorId']),
    managerChain: FirestoreConverters.stringList(map['managerChain']),
    confidentialDepts: FirestoreConverters.stringList(map['confidentialDepts']),
    jobRole: FirestoreConverters.stringOrNull(map['jobRole']),
    language: FirestoreConverters.stringOrNull(map['language']) ?? 'en',
    active: FirestoreConverters.boolOr(map['active'], true),
    consentVersion: FirestoreConverters.stringOrNull(map['consentVersion']),
  );

  final String id;
  final String orgId;
  final String name;
  final UserRole role;
  final String deptId;

  /// Null only for the top person in the organisation (spec 4.2).
  final String? supervisorId;

  /// Everyone above this user, nearest first. Written by the server.
  final List<String> managerChain;

  /// Department ids whose confidential tasks this user may see.
  final List<String> confidentialDepts;

  /// Job title used by role-owned workflow steps (D-05), e.g.
  /// "Finance Officer". Not the admin/manager/staff role.
  final String? jobRole;

  /// `en` or `sw`.
  final String language;
  final bool active;

  /// Version of the privacy notice the person accepted, or null before
  /// their first sign-in (`AppConstants.consentVersion`).
  final String? consentVersion;

  bool hasConfidentialAccessTo(String deptId) =>
      confidentialDepts.contains(deptId);

  /// Full document map (tests and fakes only: the app never writes it).
  Map<String, Object?> toMap() => {
    'name': name,
    'role': role.firestoreValue,
    'deptId': deptId,
    'supervisorId': supervisorId,
    'managerChain': managerChain,
    'confidentialDepts': confidentialDepts,
    'jobRole': jobRole,
    'language': language,
    'active': active,
    'consentVersion': consentVersion,
  };

  /// The language update a person may send for their own document.
  Map<String, Object?> toSelfUpdateMap() => {'language': language};

  AppUser copyWith({String? language}) => AppUser(
    id: id,
    orgId: orgId,
    name: name,
    role: role,
    deptId: deptId,
    supervisorId: supervisorId,
    managerChain: managerChain,
    confidentialDepts: confidentialDepts,
    jobRole: jobRole,
    language: language ?? this.language,
    active: active,
    consentVersion: consentVersion,
  );

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.orgId == orgId &&
      other.name == name &&
      other.role == role &&
      other.deptId == deptId &&
      other.supervisorId == supervisorId &&
      listEqualsOrdered(other.managerChain, managerChain) &&
      listEqualsOrdered(other.confidentialDepts, confidentialDepts) &&
      other.jobRole == jobRole &&
      other.language == language &&
      other.active == active &&
      other.consentVersion == consentVersion;

  @override
  int get hashCode => Object.hash(
    id,
    orgId,
    name,
    role,
    deptId,
    supervisorId,
    Object.hashAll(managerChain),
    Object.hashAll(confidentialDepts),
    jobRole,
    language,
    active,
    consentVersion,
  );

  /// Never includes the name (logs must not contain personal data).
  @override
  String toString() => 'AppUser(id: $id, role: ${role.name})';
}

/// `orgs/{orgId}/users/{id}/private/contact` (A-12): readable only by the
/// person and verified admins; written only by Cloud Functions.
@immutable
class UserContact {
  const UserContact({this.phone, this.email});

  factory UserContact.fromMap(Map<String, Object?> map) => UserContact(
    phone: FirestoreConverters.stringOrNull(map['phone']),
    email: FirestoreConverters.stringOrNull(map['email']),
  );

  /// E.164, e.g. `+255712345678`.
  final String? phone;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is UserContact && other.phone == phone && other.email == email;

  @override
  int get hashCode => Object.hash(phone, email);

  /// Never includes the values (personal data).
  @override
  String toString() =>
      'UserContact(hasPhone: ${phone != null}, hasEmail: ${email != null})';
}
