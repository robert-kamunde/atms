import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/firebase_providers.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/services/offline_write.dart';
import '../../../core/theme/status_colors.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/assignment_state.dart';
import '../../../shared/models/audit_entry.dart';
import '../../../shared/models/completion_mode.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/task_status.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/sync_banner.dart';
import '../../audit/presentation/audit_providers.dart';
import '../../audit/presentation/widgets/activity_tile.dart';
import '../../collaboration/presentation/attachments_section.dart';
import '../../collaboration/presentation/comments_section.dart';
import '../../departments/presentation/department_providers.dart';
import '../../users/presentation/user_providers.dart';
import '../../workflows/presentation/widgets/step_tracker.dart';
import '../domain/task_policy.dart';
import 'task_providers.dart';
import 'widgets/task_dialogs.dart';
import 'widgets/task_tile.dart';

/// Task detail (spec 4.3): every field, the status actions the viewer may
/// take, progress of several assignees, check confirm/return (D-06),
/// reassign, and the activity log (spec 4.11). Comments and attachments
/// arrive in Sprint 5, workflow steps in Sprint 3.
///
/// A missing task and a task the viewer may not read show the same "not
/// found" message (spec 4.8, A-17).
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(taskDetailProvider(taskId));
    final actor = ref.watch(taskActorProvider);
    final task = async.value;
    final canEdit =
        task != null &&
        actor != null &&
        TaskPolicy.can(TaskAction.edit, task, actor);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskDetailTitle),
        actions: [
          if (canEdit)
            IconButton(
              key: const Key('editTaskButton'),
              tooltip: l10n.actionEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(RoutePaths.taskEditFor(taskId)),
            ),
        ],
      ),
      body: Column(
        children: [
          const SyncBanner(),
          Expanded(
            child: switch (async) {
              AsyncValue(:final error?, :final stackTrace) => _NotFound(
                message: failureMessage(mapError(error, stackTrace), l10n),
              ),
              AsyncValue(hasValue: true, :final value) =>
                value == null || actor == null
                    ? _NotFound(message: l10n.errorNotFound)
                    : _TaskDetailBody(task: value, actor: actor),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      key: const Key('taskNotFound'),
      icon: Icons.search_off,
      title: message,
      action: FilledButton(
        onPressed: () => context.go(RoutePaths.tasks),
        child: Text(context.l10n.actionGoToTasks),
      ),
    );
  }
}

class _TaskDetailBody extends ConsumerWidget {
  const _TaskDetailBody({required this.task, required this.actor});

  final Task task;
  final TaskActor actor;

  TaskActions _actions(WidgetRef ref) => ref.read(taskActionsProvider.notifier);

  /// Runs an offline-capable change and says whether it reached the
  /// server or is kept on the phone (A-25).
  Future<void> _write(
    BuildContext context,
    Future<WriteOutcome> Function() write, {
    bool leaveAfter = false,
  }) async {
    try {
      final outcome = await write();
      if (!context.mounted) return;
      showWriteOutcomeSnackBar(context, outcome);
      if (leaveAfter) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.tasks);
        }
      }
    } catch (error, stackTrace) {
      if (context.mounted) {
        showFailureSnackBar(context, mapError(error, stackTrace));
      }
    }
  }

  Future<void> _withReason(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    required Future<WriteOutcome> Function(String reason) write,
  }) async {
    final reason = await showReasonDialog(
      context,
      title: title,
      confirmLabel: confirmLabel,
    );
    if (reason == null || !context.mounted) return;
    await _write(context, () => write(reason));
  }

  Future<void> _reassign(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ids = await showAssigneePicker(
      context,
      title: l10n.reassignTitle,
      initial: task.assigneeIds,
    );
    if (ids == null || !context.mounted) return;
    try {
      await _actions(ref).reassign(task, ids);
      if (context.mounted) showMessageSnackBar(context, l10n.reassignedMessage);
    } catch (error, stackTrace) {
      if (context.mounted) {
        showFailureSnackBar(context, mapError(error, stackTrace));
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref, {
    required bool discard,
  }) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteTaskTitle,
      message: l10n.deleteTaskMessage,
      confirmLabel: l10n.actionDelete,
    );
    if (!confirmed || !context.mounted) return;
    await _write(
      context,
      () => discard ? _actions(ref).discard(task) : _actions(ref).delete(task),
      leaveAfter: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.atmsColors;
    final now = ref.watch(clockProvider)();
    final people = ref.watch(userLookupProvider);
    final departments = ref.watch(departmentLookupProvider);
    final allowed = TaskPolicy.allowedActions(task, actor);
    final isCreator = task.creatorId == actor.uid;
    // Names of the people and the department on this task.
    Future.microtask(() {
      if (!context.mounted) return;
      ref.read(userLookupProvider.notifier).ensure([
        task.creatorId,
        ...task.assigneeIds,
      ]);
      ref.read(departmentLookupProvider.notifier).ensure([task.deptId]);
    });

    final actionButtons = <Widget>[
      if (allowed.contains(TaskAction.start))
        FilledButton.icon(
          key: const Key('actionStart'),
          onPressed: () => _write(context, () => _actions(ref).start(task)),
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.actionStartTask),
        ),
      if (allowed.contains(TaskAction.markDone))
        FilledButton.icon(
          key: const Key('actionDone'),
          onPressed: () => _write(context, () => _actions(ref).markDone(task)),
          icon: const Icon(Icons.check),
          label: Text(
            task.needsCheck ? l10n.actionSendForCheck : l10n.actionMarkDone,
          ),
        ),
      if (allowed.contains(TaskAction.markMyPartDone))
        FilledButton.icon(
          key: const Key('actionMyPartDone'),
          onPressed: () =>
              _write(context, () => _actions(ref).markMyPartDone(task)),
          icon: const Icon(Icons.check),
          label: Text(l10n.actionMyPartDone),
        ),
      if (allowed.contains(TaskAction.resume))
        FilledButton.icon(
          key: const Key('actionResume'),
          onPressed: () => _write(context, () => _actions(ref).resume(task)),
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.actionResumeTask),
        ),
      if (allowed.contains(TaskAction.confirmCheck))
        FilledButton.icon(
          key: const Key('actionConfirmCheck'),
          onPressed: () =>
              _write(context, () => _actions(ref).confirmCheck(task)),
          icon: const Icon(Icons.verified_outlined),
          label: Text(l10n.actionConfirmDone),
        ),
      if (allowed.contains(TaskAction.returnWork))
        OutlinedButton.icon(
          key: const Key('actionReturn'),
          onPressed: () => _withReason(
            context,
            title: l10n.returnWorkTitle,
            confirmLabel: l10n.actionReturnWork,
            write: (reason) => _actions(ref).returnWork(task, reason),
          ),
          icon: const Icon(Icons.undo),
          label: Text(l10n.actionReturnWork),
        ),
      if (allowed.contains(TaskAction.block))
        OutlinedButton.icon(
          key: const Key('actionBlock'),
          onPressed: () => _withReason(
            context,
            title: l10n.blockTaskTitle,
            confirmLabel: l10n.actionMarkBlocked,
            write: (reason) => _actions(ref).block(task, reason),
          ),
          icon: const Icon(Icons.block),
          label: Text(l10n.actionMarkBlocked),
        ),
      if (allowed.contains(TaskAction.reassign))
        OutlinedButton.icon(
          key: const Key('actionReassign'),
          onPressed: () => _reassign(context, ref),
          icon: const Icon(Icons.swap_horiz),
          label: Text(l10n.actionReassign),
        ),
      if (allowed.contains(TaskAction.cancel))
        OutlinedButton.icon(
          key: const Key('actionCancelTask'),
          onPressed: () => _withReason(
            context,
            title: l10n.cancelTaskTitle,
            confirmLabel: l10n.actionCancelTask,
            write: (reason) => _actions(ref).cancel(task, reason),
          ),
          icon: const Icon(Icons.cancel_outlined),
          label: Text(l10n.actionCancelTask),
        ),
      if (allowed.contains(TaskAction.delete))
        TextButton.icon(
          key: const Key('actionDelete'),
          onPressed: () => _delete(context, ref, discard: false),
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.actionDelete),
        ),
    ];

    Widget field(String label, String value, {Key? key}) => Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                key: const Key('taskTitle'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(l10n.taskDueAt(formatDeadline(task.deadline, l10n))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: taskLabels(context, task, now: now),
              ),
            ],
          ),
        ),
        if (task.hasPendingWrites)
          _Notice(
            key: const Key('waitingToSyncNotice'),
            icon: Icons.cloud_upload_outlined,
            color: colors.offline,
            text: l10n.waitingToSyncMessage,
          ),
        if (task.assignmentState == AssignmentState.pending)
          _Notice(
            key: const Key('pendingNotice'),
            icon: Icons.hourglass_empty,
            color: colors.syncing,
            text: l10n.assignmentPendingMessage,
            actions: [
              if (allowed.contains(TaskAction.discard))
                TextButton(
                  key: const Key('actionDiscard'),
                  onPressed: () => _delete(context, ref, discard: true),
                  child: Text(l10n.actionDelete),
                ),
            ],
          ),
        if (task.assignmentState == AssignmentState.rejected)
          _Notice(
            key: const Key('rejectedNotice'),
            icon: Icons.error_outline,
            color: theme.colorScheme.error,
            text: l10n.assignmentRejectedMessage(
              assignmentErrorMessage(task.assignmentError, l10n),
            ),
            actions: [
              if (allowed.contains(TaskAction.resubmit))
                FilledButton(
                  key: const Key('actionResubmit'),
                  onPressed: () =>
                      context.push(RoutePaths.taskEditFor(task.id)),
                  child: Text(l10n.actionEditAndResend),
                ),
              if (allowed.contains(TaskAction.discard))
                TextButton(
                  key: const Key('actionDiscard'),
                  onPressed: () => _delete(context, ref, discard: true),
                  child: Text(l10n.actionDelete),
                ),
            ],
          ),
        if (task.reassignmentNeeded)
          _Notice(
            key: const Key('reassignmentNotice'),
            icon: Icons.person_off_outlined,
            color: colors.overdue,
            text: l10n.reassignmentNeededMessage,
          ),
        if (task.status == TaskStatus.awaitingCheck)
          _Notice(
            key: const Key('awaitingCheckNotice'),
            icon: Icons.fact_check_outlined,
            color: colors.awaitingCheck,
            text: isCreator
                ? l10n.awaitingCheckCreatorMessage
                : l10n.awaitingCheckAssigneeMessage,
          ),
        if (actionButtons.isNotEmpty)
          SectionCard(
            key: const Key('taskActionsSection'),
            icon: Icons.touch_app_outlined,
            title: l10n.taskActionsTitle,
            child: Wrap(spacing: 8, runSpacing: 8, children: actionButtons),
          ),
        SectionCard(
          icon: Icons.info_outline,
          title: l10n.taskSummaryTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                field(l10n.taskFieldDescription, task.description),
              field(
                l10n.taskFieldAssignee,
                peopleNames(task.assigneeIds, people, l10n),
                key: const Key('taskAssignees'),
              ),
              field(
                l10n.taskFieldCreator,
                people[task.creatorId]?.name ?? l10n.unknownPerson,
              ),
              field(
                l10n.taskFieldDepartment,
                departments[task.deptId]?.name ?? l10n.unknownDepartment,
              ),
              if (task.assigneeIds.length > 1)
                field(
                  l10n.taskFieldCompletionMode,
                  task.completionMode == CompletionMode.all
                      ? l10n.completionModeAll
                      : l10n.completionModeAny,
                ),
              field(
                l10n.taskFieldNeedsCheck,
                task.needsCheck ? l10n.labelYes : l10n.labelNo,
              ),
              if (task.status == TaskStatus.blocked &&
                  task.blockedReason != null)
                field(l10n.blockedReasonLabel, task.blockedReason!),
              if (task.status == TaskStatus.cancelled &&
                  task.cancelReason != null)
                field(l10n.cancelReasonLabel, task.cancelReason!),
              if (task.status.isActive && task.returnReason != null)
                field(l10n.returnReasonLabel, task.returnReason!),
              if (task.reassignmentReason != null && task.reassignmentNeeded)
                field(l10n.reassignmentReasonLabel, task.reassignmentReason!),
            ],
          ),
        ),
        if (task.needsEveryAssignee)
          _ProgressSection(task: task, people: people),
        if (task.isWorkflowTask) const StepTracker(),
        if (task.assignmentState == AssignmentState.assigned)
          _ActivitySection(taskId: task.id),
        const CommentsSection(),
        const AttachmentsSection(),
      ],
    );
  }
}

/// A coloured message with optional buttons (assignment state, sync).
class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.actions = const [],
  });

  final IconData icon;
  final Color color;
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(text)),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

/// Who has finished, for tasks every assignee must finish (A-02).
class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.task, required this.people});

  final Task task;
  final Map<String, AppUser> people;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      key: const Key('progressSection'),
      icon: Icons.groups_outlined,
      title: l10n.taskProgress(
        task.completedByIds.length,
        task.assigneeIds.length,
      ),
      child: Column(
        children: [
          for (final id in task.assigneeIds)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                task.completedByIds.contains(id)
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
              ),
              title: Text(people[id]?.name ?? l10n.unknownPerson),
              subtitle: Text(
                task.completedByIds.contains(id)
                    ? l10n.progressFinished
                    : l10n.progressNotFinished,
              ),
            ),
        ],
      ),
    );
  }
}

/// The task's activity log, newest first, 20 at a time (spec 4.11).
class _ActivitySection extends ConsumerWidget {
  const _ActivitySection({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(taskActivityProvider(taskId));
    final people = ref.watch(userLookupProvider);
    final notifier = ref.read(taskActivityProvider(taskId).notifier);
    return SectionCard(
      key: const Key('activitySection'),
      icon: Icons.history,
      title: l10n.activityTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.loadedOnce && state.items.isEmpty && state.failure == null)
            EmptyState(
              compact: true,
              icon: Icons.history,
              title: l10n.activityEmpty,
            ),
          for (final AuditEntry entry in state.items)
            ActivityTile(entry: entry, people: people),
          if (state.loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.failure != null)
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text(failureMessage(state.failure!, l10n)),
              trailing: TextButton(
                key: const Key('activityRetry'),
                onPressed: notifier.loadMore,
                child: Text(l10n.actionRetry),
              ),
            )
          else if (state.hasMore)
            Center(
              child: TextButton(
                key: const Key('activityLoadMore'),
                onPressed: notifier.loadMore,
                child: Text(l10n.actionLoadMore),
              ),
            ),
        ],
      ),
    );
  }
}
