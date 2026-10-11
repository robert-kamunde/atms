import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/firebase_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/server_error_code.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/providers/lookup_controller.dart';
import '../../../shared/providers/paged_list_controller.dart';
import '../../../shared/services/paginated_query.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/firestore_user_repositories.dart';
import '../domain/user_repositories.dart';

/// Members of the signed-in user's organisation; null when signed out.
final userDirectoryRepositoryProvider = Provider<UserDirectoryRepository?>((
  ref,
) {
  final orgId = ref.watch(currentSessionProvider.select((s) => s?.orgId));
  if (orgId == null) return null;
  return FirestoreUserDirectoryRepository(ref.watch(firestoreProvider), orgId);
});

/// User management callables (online only).
final userAdminRepositoryProvider = Provider<UserAdminRepository>(
  (ref) => FunctionsUserAdminRepository(ref.watch(callableClientProvider)),
);

/// All people by name, a page at a time (admin list and pickers).
class UserListController extends PagedListController<AppUser> {
  @override
  PaginatedSource<AppUser> createSource() =>
      requireRepository(ref.read(userDirectoryRepositoryProvider)).allUsers();

  @override
  void onPageLoaded(List<AppUser> items) {
    // Supervisors (to flag inactive ones) and department names.
    final lookup = ref.read(userLookupProvider.notifier);
    for (final user in items) {
      lookup.put(user);
    }
    lookup.ensure(items.map((u) => u.supervisorId));
  }
}

final userListProvider =
    NotifierProvider.autoDispose<UserListController, PagedListState<AppUser>>(
      UserListController.new,
    );

/// People by id, for names shown next to loaded items.
class UserLookup extends LookupController<AppUser> {
  @override
  Map<String, AppUser> build() {
    ref.watch(userDirectoryRepositoryProvider);
    return super.build();
  }

  @override
  Future<List<AppUser>> fetch(List<String> ids) =>
      requireRepository(ref.read(userDirectoryRepositoryProvider))
          .usersByIds(ids);

  @override
  String idOf(AppUser item) => item.id;
}

final userLookupProvider = NotifierProvider<UserLookup, Map<String, AppUser>>(
  UserLookup.new,
);

/// What the user editor loads for an existing person.
@immutable
class UserEditorData {
  const UserEditorData({required this.user, required this.contact});

  final AppUser user;
  final UserContact? contact;
}

/// Loads a person and their contact details (verified admins only).
final userEditorDataProvider = FutureProvider.autoDispose
    .family<UserEditorData, String>((ref, uid) async {
      try {
        final repo = requireRepository(
          ref.watch(userDirectoryRepositoryProvider),
        );
        final user = await repo.user(uid);
        if (user == null) throw const NotFoundFailure();
        final contact = await repo.contact(uid);
        return UserEditorData(user: user, contact: contact);
      } catch (error, stackTrace) {
        throw mapError(error, stackTrace);
      }
    }, retry: (_, _) => null);

/// Saves and deactivates people through the callables. Methods throw
/// `AppFailure`; an expired session signs the admin out and an expired
/// admin second factor sends them back to the verification screen.
class UserEditor extends Notifier<void> {
  @override
  void build() {}

  Future<T> _call<T>(
    Future<T> Function(UserAdminRepository repo) action,
  ) async {
    try {
      return await action(ref.read(userAdminRepositoryProvider));
    } catch (error, stackTrace) {
      final failure = mapError(error, stackTrace);
      if (ref.mounted) {
        final auth = ref.read(authControllerProvider.notifier);
        if (failure is SessionExpiredFailure) {
          await auth.expireSession();
        } else if (failure is ServerFailure &&
            failure.serverCode == ServerErrorCode.adminVerificationRequired) {
          auth.markAdminVerificationExpired();
        }
      }
      throw failure;
    }
  }

  Future<UpsertUserResult> save(UserDraft draft) async {
    final result = await _call((repo) => repo.upsertUser(draft));
    if (ref.mounted) {
      ref.invalidate(userListProvider);
      ref.invalidate(userLookupProvider);
      ref.invalidate(userEditorDataProvider(result.uid));
    }
    return result;
  }

  Future<int> deactivate(String uid) async {
    final count = await _call((repo) => repo.deactivateUser(uid));
    if (ref.mounted) {
      ref.invalidate(userListProvider);
      ref.invalidate(userLookupProvider);
      ref.invalidate(userEditorDataProvider(uid));
    }
    return count;
  }
}

final userEditorProvider = NotifierProvider<UserEditor, void>(UserEditor.new);
