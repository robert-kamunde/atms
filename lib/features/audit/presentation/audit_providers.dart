import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/firebase_providers.dart';
import '../../../shared/models/audit_entry.dart';
import '../../../shared/providers/paged_list_controller.dart';
import '../../../shared/services/paginated_query.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../tasks/presentation/task_providers.dart';
import '../../users/presentation/user_providers.dart';
import '../data/firestore_audit_repository.dart';
import '../domain/audit_repository.dart';

/// The audit log; null when signed out.
final auditRepositoryProvider = Provider<AuditRepository?>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return null;
  return FirestoreAuditRepository(
    ref.watch(firestoreProvider),
    orgId: session.orgId,
    uid: session.uid,
  );
});

/// The activity log of one task, newest first, 20 at a time.
class TaskActivityController extends PagedListController<AuditEntry> {
  TaskActivityController(this.taskId);

  final String taskId;

  @override
  PaginatedSource<AuditEntry> createSource() =>
      requireRepository(ref.read(auditRepositoryProvider)).taskActivity(
        taskId,
        asAdmin: ref.read(taskActorProvider)?.isVerifiedAdmin ?? false,
      );

  @override
  void onPageLoaded(List<AuditEntry> items) => ref
      .read(userLookupProvider.notifier)
      .ensure(items.expand(auditPeopleIds));
}

/// Everyone named by [entry]: the actor and any assignees it lists.
Iterable<String> auditPeopleIds(AuditEntry entry) sync* {
  yield entry.actorId;
  for (final side in [entry.before, entry.after]) {
    final ids = side['assigneeIds'];
    if (ids is List) yield* ids.whereType<String>();
  }
}

final taskActivityProvider = NotifierProvider.autoDispose
    .family<TaskActivityController, PagedListState<AuditEntry>, String>(
      TaskActivityController.new,
    );

/// The organisation's audit log for verified admins, newest first.
class OrgActivityController extends PagedListController<AuditEntry> {
  @override
  PaginatedSource<AuditEntry> createSource() =>
      requireRepository(ref.read(auditRepositoryProvider)).orgActivity();

  @override
  void onPageLoaded(List<AuditEntry> items) => ref
      .read(userLookupProvider.notifier)
      .ensure(items.expand(auditPeopleIds));
}

final orgActivityProvider =
    NotifierProvider.autoDispose<
      OrgActivityController,
      PagedListState<AuditEntry>
    >(OrgActivityController.new);
