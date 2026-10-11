import 'package:flutter/foundation.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/services/paginated_query.dart';

/// The signed-in person's own user document. Implementations throw
/// `AppFailure` only.
abstract interface class UserProfileRepository {
  /// The person's document. Emits null when it does not exist on the
  /// server (not invited). A missing document seen only in the offline
  /// cache is not reported as null, so a phone that has never synced does
  /// not show "not invited" by mistake.
  Stream<AppUser?> watchUser({required String orgId, required String uid});

  /// Writes `language` (`en` or `sw`), allowed by the rules for the owner.
  /// The returned future completes when the server confirms; while offline
  /// the change is already applied on the phone (see `offline_write.dart`).
  Future<void> updateLanguage({
    required String orgId,
    required String uid,
    required String language,
  });

  /// Writes `consentVersion` and `consentAcceptedAt` (server time), exactly
  /// the consent fields the rules allow the owner to change.
  Future<void> acceptConsent({
    required String orgId,
    required String uid,
    required String version,
  });
}

/// Reading other members of the organisation (lists are always paged).
abstract interface class UserDirectoryRepository {
  /// All people, by name, [PaginatedSource.pageSize] at a time.
  PaginatedSource<AppUser> allUsers();

  /// Everyone below [managerId] in the reporting tree (people with the
  /// manager in their `managerChain`), by name: who a manager may assign.
  PaginatedSource<AppUser> teamMembers(String managerId);

  /// The people whose supervisor is [supervisorId]; with null, the top of
  /// the organisation (people without a supervisor).
  PaginatedSource<AppUser> directReports(String? supervisorId);

  /// The people with these ids (at most one page worth; used to show the
  /// names of supervisors and department heads of a loaded page).
  Future<List<AppUser>> usersByIds(Iterable<String> ids);

  Future<AppUser?> user(String id);

  /// Phone and email (verified admins and the person only).
  Future<UserContact?> contact(String id);
}

/// What an admin enters in the user editor (`adminUpsertUser` input).
@immutable
class UserDraft {
  const UserDraft({
    this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.deptId,
    required this.supervisorId,
    required this.jobRole,
    required this.language,
    required this.confidentialDepts,
  });

  /// Null when adding a new person.
  final String? uid;
  final String name;

  /// E.164 (+255...), or null.
  final String? phone;
  final String? email;
  final UserRole role;
  final String deptId;
  final String? supervisorId;
  final String? jobRole;
  final String language;
  final List<String> confidentialDepts;

  /// Exactly the callable's input (docs/SPRINT1_CONTRACT.md).
  Map<String, Object?> toCallableData() => {
    'uid': ?uid,
    'name': name,
    'phone': phone,
    'email': email,
    'role': role.firestoreValue,
    'deptId': deptId,
    'supervisorId': supervisorId,
    'jobRole': jobRole,
    'language': language,
    'confidentialDepts': confidentialDepts,
  };
}

/// Result of `adminUpsertUser`.
@immutable
class UpsertUserResult {
  const UpsertUserResult({required this.uid, required this.created});

  final String uid;
  final bool created;
}

/// User management through Cloud Functions (online only).
abstract interface class UserAdminRepository {
  Future<UpsertUserResult> upsertUser(UserDraft draft);

  /// Returns how many open tasks were flagged for reassignment.
  Future<int> deactivateUser(String uid);
}
