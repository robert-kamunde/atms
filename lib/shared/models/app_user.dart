import 'package:flutter/foundation.dart';

import 'firestore_converters.dart';
import 'user_role.dart';

/// A member of an organisation: `orgs/{orgId}/users/{id}` (spec 5).
///
/// Phone, email and FCM tokens are intentionally not part of this client
/// model in Sprint 0; they are added in Sprint 1 / 4 when a screen needs them.
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
    this.language = 'en',
    this.active = true,
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
    language: FirestoreConverters.stringOrNull(map['language']) ?? 'en',
    active: FirestoreConverters.boolOr(map['active'], true),
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

  /// `en` or `sw`.
  final String language;
  final bool active;

  bool hasConfidentialAccessTo(String deptId) =>
      confidentialDepts.contains(deptId);

  /// Full document map. Users may only write their own `language`
  /// (spec 5); everything else is written by an admin.
  Map<String, Object?> toMap() => {
    'name': name,
    'role': role.firestoreValue,
    'deptId': deptId,
    'supervisorId': supervisorId,
    'managerChain': managerChain,
    'confidentialDepts': confidentialDepts,
    'language': language,
    'active': active,
  };

  /// The only update a non-admin user may send for their own document.
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
    language: language ?? this.language,
    active: active,
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
      other.language == language &&
      other.active == active;

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
    language,
    active,
  );

  /// Never includes the name (logs must not contain personal data).
  @override
  String toString() => 'AppUser(id: $id, role: ${role.name})';
}
