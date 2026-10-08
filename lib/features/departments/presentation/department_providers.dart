import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/firebase_providers.dart';
import '../../../core/services/offline_write.dart';
import '../../../shared/models/department.dart';
import '../../../shared/providers/lookup_controller.dart';
import '../../../shared/providers/paged_list_controller.dart';
import '../../../shared/services/paginated_query.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../users/presentation/user_providers.dart';
import '../data/firestore_department_repository.dart';
import '../domain/department_repository.dart';

/// Departments of the signed-in user's organisation; null when signed out.
final departmentRepositoryProvider = Provider<DepartmentRepository?>((ref) {
  final orgId = ref.watch(currentSessionProvider.select((s) => s?.orgId));
  if (orgId == null) return null;
  return FirestoreDepartmentRepository(ref.watch(firestoreProvider), orgId);
});

/// All departments, a page at a time (admin list and pickers).
class DepartmentListController extends PagedListController<Department> {
  @override
  PaginatedSource<Department> createSource() =>
      requireRepository(ref.read(departmentRepositoryProvider)).departments();

  @override
  void onPageLoaded(List<Department> items) {
    // Names of the heads shown in the list.
    ref
        .read(userLookupProvider.notifier)
        .ensure(items.map((d) => d.headUserId));
  }
}

final departmentListProvider =
    NotifierProvider.autoDispose<
      DepartmentListController,
      PagedListState<Department>
    >(DepartmentListController.new);

/// Department names by id, for the items on loaded pages.
class DepartmentLookup extends LookupController<Department> {
  @override
  Map<String, Department> build() {
    ref.watch(departmentRepositoryProvider);
    return super.build();
  }

  @override
  Future<List<Department>> fetch(List<String> ids) =>
      requireRepository(ref.read(departmentRepositoryProvider))
          .departmentsByIds(ids);

  @override
  String idOf(Department item) => item.id;
}

final departmentLookupProvider =
    NotifierProvider<DepartmentLookup, Map<String, Department>>(
      DepartmentLookup.new,
    );

/// Department writes (verified admins; rules decide). They work offline:
/// the result says whether the server confirmed or the change is queued.
class DepartmentEditor extends Notifier<void> {
  @override
  void build() {}

  DepartmentRepository get _repo =>
      requireRepository(ref.read(departmentRepositoryProvider));

  Future<WriteOutcome> save({
    String? id,
    required String name,
    String? headUserId,
  }) async {
    final repo = _repo;
    final write = id == null
        ? repo.create(name: name, headUserId: headUserId)
        : repo.update(id: id, name: name, headUserId: headUserId);
    return awaitOfflineCapableWrite(
      write,
      writeName: id == null ? 'createDepartment' : 'updateDepartment',
    );
  }

  Future<WriteOutcome> deactivate(String id) => awaitOfflineCapableWrite(
    _repo.deactivate(id),
    writeName: 'deactivateDepartment',
  );
}

final departmentEditorProvider = NotifierProvider<DepartmentEditor, void>(
  DepartmentEditor.new,
);
