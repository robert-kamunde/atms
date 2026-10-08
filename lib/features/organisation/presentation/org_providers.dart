import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/firebase_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/services/offline_write.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/providers/paged_list_controller.dart';
import '../../../shared/services/paginated_query.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../users/presentation/user_providers.dart';
import '../data/firestore_org_repository.dart';
import '../domain/org_repository.dart';
import '../domain/org_settings.dart';

/// The signed-in user's organisation document; null when signed out.
final orgRepositoryProvider = Provider<OrgRepository?>((ref) {
  final orgId = ref.watch(currentSessionProvider.select((s) => s?.orgId));
  if (orgId == null) return null;
  return FirestoreOrgRepository(ref.watch(firestoreProvider), orgId);
});

/// Organisation settings (from the offline cache first when available).
final orgSettingsProvider = StreamProvider.autoDispose<OrgSettings?>((ref) {
  final repo = ref.watch(orgRepositoryProvider);
  if (repo == null) return Stream.error(const UnauthenticatedFailure());
  return repo.watchSettings();
}, retry: (_, _) => null);

/// Saves organisation settings (verified admins; rules decide). Works
/// offline: the change is queued on the phone and synced later.
class OrgSettingsEditor extends Notifier<void> {
  @override
  void build() {}

  /// Writes the fields of [edited] that differ from [original]. Returns
  /// null when nothing changed.
  Future<WriteOutcome?> save(OrgSettings original, OrgSettings edited) async {
    final changes = original.changedFields(edited);
    if (changes.isEmpty) return null;
    final repo = requireRepository(ref.read(orgRepositoryProvider));
    return awaitOfflineCapableWrite(
      repo.updateSettings(changes),
      writeName: 'orgSettings',
    );
  }
}

final orgSettingsEditorProvider = NotifierProvider<OrgSettingsEditor, void>(
  OrgSettingsEditor.new,
);

/// Key of the top of the tree (people without a supervisor).
const String reportingTreeRootKey = '';

/// The direct reports of one person in the reporting tree.
@immutable
class TreeBranch {
  const TreeBranch({
    this.items = const [],
    this.next,
    this.loading = false,
    this.loadedOnce = false,
    this.failure,
  });

  final List<AppUser> items;
  final PageCursor? next;
  final bool loading;
  final bool loadedOnce;
  final AppFailure? failure;

  bool get hasMore => next != null;
}

@immutable
class ReportingTreeState {
  const ReportingTreeState({
    this.branches = const {},
    this.expanded = const {},
  });

  /// Loaded branches by supervisor id ([reportingTreeRootKey] = top).
  final Map<String, TreeBranch> branches;

  /// People whose direct reports are shown.
  final Set<String> expanded;

  ReportingTreeState copyWith({
    Map<String, TreeBranch>? branches,
    Set<String>? expanded,
  }) => ReportingTreeState(
    branches: branches ?? this.branches,
    expanded: expanded ?? this.expanded,
  );
}

/// One row of the indented tree.
sealed class TreeRow {
  const TreeRow(this.depth);

  final int depth;
}

final class TreePersonRow extends TreeRow {
  const TreePersonRow(
    super.depth, {
    required this.user,
    required this.expanded,
    required this.supervisorInactive,
  });

  final AppUser user;
  final bool expanded;

  /// The person's supervisor is deactivated: an admin must choose a new
  /// one (docs/SPRINT1_CONTRACT.md, `deactivateUser`).
  final bool supervisorInactive;
}

/// "Load more", loading or error row under [parentKey].
final class TreeStatusRow extends TreeRow {
  const TreeStatusRow(
    super.depth, {
    required this.parentKey,
    required this.branch,
  });

  final String parentKey;
  final TreeBranch branch;
}

/// Turns the loaded branches into indented rows (pure, for tests).
List<TreeRow> flattenReportingTree(ReportingTreeState state) {
  final rows = <TreeRow>[];
  void visit(String key, int depth, bool parentInactive, Set<String> path) {
    final branch = state.branches[key];
    if (branch == null) return;
    for (final user in branch.items) {
      // A loop in the data (the server rejects them) must not hang the app.
      if (path.contains(user.id)) continue;
      final expanded = state.expanded.contains(user.id);
      rows.add(
        TreePersonRow(
          depth,
          user: user,
          expanded: expanded,
          supervisorInactive: parentInactive,
        ),
      );
      if (expanded) {
        visit(user.id, depth + 1, !user.active, {...path, user.id});
      }
    }
    if (branch.loading || branch.failure != null || branch.hasMore) {
      rows.add(TreeStatusRow(depth, parentKey: key, branch: branch));
    }
  }

  visit(reportingTreeRootKey, 0, false, const {});
  return rows;
}

/// Reporting tree built from `supervisorId` (spec 4.2), loaded lazily:
/// the top first, then each person's direct reports when expanded, 20 at
/// a time.
class ReportingTreeController extends Notifier<ReportingTreeState> {
  final Map<String, PaginatedSource<AppUser>> _sources = {};
  final Set<String> _inFlight = {};

  @override
  ReportingTreeState build() {
    _sources.clear();
    _inFlight.clear();
    ref.watch(userDirectoryRepositoryProvider);
    Future.microtask(() {
      if (ref.mounted) unawaited(loadMore(reportingTreeRootKey));
    });
    return const ReportingTreeState(
      branches: {reportingTreeRootKey: TreeBranch(loading: true)},
    );
  }

  void _setBranch(String key, TreeBranch branch) {
    state = state.copyWith(branches: {...state.branches, key: branch});
  }

  Future<void> loadMore(String key) async {
    if (_inFlight.contains(key)) return;
    final current = state.branches[key] ?? const TreeBranch();
    if (current.loadedOnce && !current.hasMore) return;
    _inFlight.add(key);
    _setBranch(
      key,
      TreeBranch(
        items: current.items,
        next: current.next,
        loading: true,
        loadedOnce: current.loadedOnce,
      ),
    );
    try {
      final source = _sources[key] ??= requireRepository(
        ref.read(userDirectoryRepositoryProvider),
      ).directReports(key == reportingTreeRootKey ? null : key);
      final page = await source.fetchPage(after: current.next);
      if (!ref.mounted) return;
      final items = [...current.items, ...page.items]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _setBranch(
        key,
        TreeBranch(items: items, next: page.next, loadedOnce: true),
      );
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      _setBranch(
        key,
        TreeBranch(
          items: current.items,
          next: current.next,
          loadedOnce: current.loadedOnce,
          failure: mapError(error, stackTrace),
        ),
      );
    } finally {
      _inFlight.remove(key);
    }
  }

  /// Shows or hides [userId]'s direct reports, loading them the first time.
  Future<void> toggle(String userId) async {
    final expanded = {...state.expanded};
    if (!expanded.remove(userId)) expanded.add(userId);
    state = state.copyWith(expanded: expanded);
    if (expanded.contains(userId) && state.branches[userId] == null) {
      await loadMore(userId);
    }
  }
}

final reportingTreeProvider =
    NotifierProvider.autoDispose<ReportingTreeController, ReportingTreeState>(
      ReportingTreeController.new,
    );
