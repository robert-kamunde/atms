import 'package:flutter/foundation.dart';

import 'firestore_converters.dart';

/// `orgs/{orgId}/departments/{id}` (spec 5). Departments are deactivated,
/// never deleted, so old tasks keep their department (A-13).
@immutable
class Department {
  const Department({
    required this.id,
    required this.name,
    this.headUserId,
    this.active = true,
  });

  factory Department.fromMap(String id, Map<String, Object?> map) => Department(
    id: id,
    name: FirestoreConverters.string(map['name'], field: 'name'),
    headUserId: FirestoreConverters.stringOrNull(map['headUserId']),
    active: FirestoreConverters.boolOr(map['active'], true),
  );

  /// Longest name the Security Rules accept.
  static const int maxNameLength = 100;

  final String id;
  final String name;
  final String? headUserId;
  final bool active;

  Map<String, Object?> toMap() => {
    'name': name,
    'headUserId': headUserId,
    'active': active,
  };

  @override
  bool operator ==(Object other) =>
      other is Department &&
      other.id == id &&
      other.name == name &&
      other.headUserId == headUserId &&
      other.active == active;

  @override
  int get hashCode => Object.hash(id, name, headUserId, active);

  @override
  String toString() => 'Department(id: $id, active: $active)';
}
