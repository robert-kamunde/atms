import '../../../shared/models/department.dart';
import '../../../shared/services/paginated_query.dart';

/// Departments of the organisation. Writes go straight to Firestore with
/// exactly the fields `firestore.rules` allows a verified admin, so they
/// work offline (queued on the phone). Implementations throw `AppFailure`.
///
/// The write methods return the Firestore write future, which completes
/// only when the server confirms; callers use `awaitOfflineCapableWrite`.
abstract interface class DepartmentRepository {
  /// All departments (active and inactive), by name, one page at a time.
  PaginatedSource<Department> departments();

  /// The departments with these ids (names for one loaded page).
  Future<List<Department>> departmentsByIds(Iterable<String> ids);

  /// Creates an active department: `name`, `headUserId`, `active: true`,
  /// `createdAt` and `updatedAt` (server time).
  Future<void> create({required String name, String? headUserId});

  /// Changes `name` and `headUserId`, with `updatedAt` (server time).
  Future<void> update({
    required String id,
    required String name,
    String? headUserId,
  });

  /// Sets `active: false` (departments are never deleted, A-13).
  Future<void> deactivate(String id);
}
