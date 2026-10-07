import 'enum_parsing.dart';

/// The three base roles (spec section 2). Confidential access is a
/// permission (`AppUser.confidentialDepts`), not a role.
enum UserRole {
  admin('admin'),
  manager('manager'),
  staff('staff');

  const UserRole(this.firestoreValue);

  final String firestoreValue;

  static UserRole fromFirestore(Object? raw) =>
      parseEnum(values, raw, (v) => v.firestoreValue, field: 'role');

  bool get isAdmin => this == UserRole.admin;

  /// Managers and admins can see team tasks and reports.
  bool get canSeeTeam => this == UserRole.manager || this == UserRole.admin;
}
