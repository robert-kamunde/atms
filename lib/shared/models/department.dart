import 'package:flutter/foundation.dart';

import 'firestore_converters.dart';

/// `orgs/{orgId}/departments/{id}` (spec 5).
@immutable
class Department {
  const Department({required this.id, required this.name, this.headUserId});

  factory Department.fromMap(String id, Map<String, Object?> map) => Department(
    id: id,
    name: FirestoreConverters.string(map['name'], field: 'name'),
    headUserId: FirestoreConverters.stringOrNull(map['headUserId']),
  );

  final String id;
  final String name;
  final String? headUserId;

  Map<String, Object?> toMap() => {'name': name, 'headUserId': headUserId};

  @override
  bool operator ==(Object other) =>
      other is Department &&
      other.id == id &&
      other.name == name &&
      other.headUserId == headUserId;

  @override
  int get hashCode => Object.hash(id, name, headUserId);

  @override
  String toString() => 'Department(id: $id)';
}
