import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/firebase_providers.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/services/offline_write.dart';
import '../../../shared/models/assignment_state.dart';
import '../../../shared/models/completion_mode.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/task_priority.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/enum_labels.dart';
import '../../../shared/widgets/failure_snackbar.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../users/presentation/user_providers.dart';
import '../domain/task_policy.dart';
import '../domain/task_repository.dart';
import 'task_providers.dart';
import 'widgets/task_dialogs.dart';
import 'widgets/task_tile.dart';

/// Create / edit task (spec 4.3 step 1). Title, deadline, priority and
/// assignee are required, so a task can be saved in under 30 seconds;
/// description, "all or any one person" (several assignees) and "check the
/// work before it is done" (D-06) are optional.
///
/// With [taskId]: edits an open task (title, description, priority,
/// deadline, check; assignees change through Reassign), or, for a task the
/// server refused to assign, corrects every field and sends it again
/// (A-01). Confidential tasks are Sprint 5: tasks made here are never
/// confidential.
class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({super.key, this.taskId});

  /// Null when creating a task.
  final String? taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = taskId;
    if (id == null) return const _TaskForm(task: null);
    final async = ref.watch(taskDetailProvider(id));
    final actor = ref.watch(taskActorProvider);
    return switch (async) {
      AsyncValue(hasValue: true, :final value) =>
        value != null &&
                actor != null &&
                (TaskPolicy.can(TaskAction.edit, value, actor) ||
                    TaskPolicy.can(TaskAction.resubmit, value, actor))
            ? _TaskForm(key: ValueKey(value.id), task: value)
            : Scaffold(
                appBar: AppBar(title: Text(l10n.taskEditTitle)),
                body: EmptyState(
                  key: const Key('taskCannotEdit'),
                  icon: Icons.edit_off_outlined,
                  title: value == null
                      ? l10n.errorNotFound
                      : l10n.taskCannotEditMessage,
                ),
              ),
      AsyncValue(hasError: true) => Scaffold(
        appBar: AppBar(title: Text(l10n.taskEditTitle)),
        body: EmptyState(
          key: const Key('taskCannotEdit'),
          icon: Icons.search_off,
          title: l10n.errorNotFound,
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(title: Text(l10n.taskEditTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({super.key, required this.task});

  /// The task being edited or sent again; null when creating.
  final Task? task;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  DateTime? _deadline;
  TaskPriority? _priority;
  List<String> _assigneeIds = [];
  CompletionMode _completionMode = CompletionMode.all;
  bool _needsCheck = false;
  bool _saving = false;

  Task? get _task => widget.task;

  /// Fixing a refused task: every field may change.
  bool get _isResubmit =>
      _task != null && _task!.assignmentState == AssignmentState.rejected;

  /// Assignees and completion mode can be chosen (new or refused task).
  bool get _canChooseAssignees => _task == null || _isResubmit;

  @override
  void initState() {
    super.initState();
    final task = _task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _deadline = task?.deadline.toLocal();
    _priority = task?.priority;
    _assigneeIds = List.of(task?.assigneeIds ?? const <String>[]);
    _completionMode = task?.completionMode ?? CompletionMode.all;
    _needsCheck = task?.needsCheck ?? false;
    if (task == null) {
      // Staff (and admins without a second factor) may only assign
      // themselves: fill it in so the form needs one tap less.
      final actor = ref.read(taskActorProvider);
      if (actor != null && assigneeScopeFor(actor) == AssigneeScope.selfOnly) {
        _assigneeIds = [actor.uid];
      }
    }
    final me = ref.read(currentSessionProvider)?.user;
    Future.microtask(() {
      if (!mounted) return;
      final lookup = ref.read(userLookupProvider.notifier);
      if (me != null) lookup.put(me);
      lookup.ensure(_assigneeIds);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDeadline(DateTime? current) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = current == null || current.isBefore(today) ? now : current;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        current ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickAssignees(FormFieldState<List<String>> field) async {
    final l10n = context.l10n;
    final picked = await showAssigneePicker(
      context,
      title: l10n.taskFieldAssignee,
      initial: _assigneeIds,
    );
    if (picked == null || !mounted) return;
    setState(() => _assigneeIds = picked);
    field.didChange(picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final session = ref.read(currentSessionProvider);
    if (session == null) return;
    final draft = TaskDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: _deadline!.toUtc(),
      priority: _priority!,
      assigneeIds: _assigneeIds,
      deptId: _task?.deptId ?? session.user.deptId,
      completionMode: _assigneeIds.length > 1
          ? _completionMode
          : CompletionMode.all,
      needsCheck: _needsCheck,
    );
    setState(() => _saving = true);
    final actions = ref.read(taskActionsProvider.notifier);
    try {
      final task = _task;
      final WriteOutcome outcome;
      if (task == null) {
        outcome = (await actions.create(draft)).outcome;
      } else if (_isResubmit) {
        outcome = await actions.resubmit(task, draft);
      } else {
        outcome = await actions.edit(task, draft);
      }
      if (!mounted) return;
      showWriteOutcomeSnackBar(context, outcome);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.tasks);
      }
    } catch (error, stackTrace) {
      if (mounted) showFailureSnackBar(context, mapError(error, stackTrace));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = _task != null;
    final people = ref.watch(userLookupProvider);
    final dateFormat = DateFormat.yMMMEd(l10n.localeName).add_Hm();
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isResubmit
              ? l10n.taskResubmitTitle
              : isEdit
              ? l10n.taskEditTitle
              : l10n.taskCreateTitle,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            key: const Key('taskFormList'),
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('taskTitleField'),
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: Task.maxTitleLength,
                decoration: InputDecoration(
                  labelText: l10n.taskFieldTitle,
                  helperText: l10n.requiredFieldHint,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.validationTitleRequired
                    : null,
              ),
              const SizedBox(height: 16),
              FormField<DateTime>(
                key: const Key('taskDeadlineField'),
                initialValue: _deadline,
                validator: (v) {
                  if (v == null) return l10n.validationDeadlineRequired;
                  final unchanged =
                      _task != null && v.isAtSameMomentAs(_task!.deadline);
                  if (!unchanged && v.isBefore(now)) {
                    return l10n.validationDeadlineInPast;
                  }
                  return null;
                },
                builder: (field) => InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await _pickDeadline(field.value);
                    if (picked != null) {
                      setState(() => _deadline = picked);
                      field.didChange(picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.taskFieldDeadline,
                      errorText: field.errorText,
                      suffixIcon: const Icon(Icons.event),
                    ),
                    child: Text(
                      field.value == null
                          ? l10n.taskFieldDeadlineHint
                          : dateFormat.format(field.value!.toLocal()),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                key: const Key('taskPriorityField'),
                initialValue: _priority,
                decoration: InputDecoration(labelText: l10n.taskFieldPriority),
                items: [
                  for (final p in TaskPriority.values)
                    DropdownMenuItem(value: p, child: Text(p.label(l10n))),
                ],
                onChanged: (v) => setState(() => _priority = v),
                validator: (v) =>
                    v == null ? l10n.validationPriorityRequired : null,
              ),
              const SizedBox(height: 16),
              FormField<List<String>>(
                key: const Key('taskAssigneeField'),
                initialValue: _assigneeIds,
                validator: (v) => (v == null || v.isEmpty)
                    ? l10n.validationAssigneeRequired
                    : null,
                builder: (field) => InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _canChooseAssignees
                      ? () => _pickAssignees(field)
                      : null,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.taskFieldAssignee,
                      errorText: field.errorText,
                      helperText: _canChooseAssignees
                          ? null
                          : l10n.assigneesChangeWithReassign,
                      suffixIcon: _canChooseAssignees
                          ? const Icon(Icons.person_add_alt)
                          : null,
                    ),
                    child: Text(
                      _assigneeIds.isEmpty
                          ? l10n.taskFieldAssigneeHint
                          : peopleNames(_assigneeIds, people, l10n),
                    ),
                  ),
                ),
              ),
              if (_assigneeIds.length > 1 && _canChooseAssignees) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.taskFieldCompletionMode,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                RadioGroup<CompletionMode>(
                  groupValue: _completionMode,
                  onChanged: (v) {
                    if (v != null) setState(() => _completionMode = v);
                  },
                  child: Column(
                    children: [
                      RadioListTile<CompletionMode>(
                        key: const Key('completionModeAll'),
                        value: CompletionMode.all,
                        title: Text(l10n.completionModeAll),
                      ),
                      RadioListTile<CompletionMode>(
                        key: const Key('completionModeAny'),
                        value: CompletionMode.any,
                        title: Text(l10n.completionModeAny),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('needsCheckSwitch'),
                contentPadding: EdgeInsets.zero,
                value: _needsCheck,
                onChanged: (v) => setState(() => _needsCheck = v),
                title: Text(l10n.taskFieldNeedsCheck),
                subtitle: Text(l10n.taskFieldNeedsCheckHelp),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('taskDescriptionField'),
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                maxLength: Task.maxDescriptionLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.taskFieldDescription,
                  helperText: l10n.optionalFieldHint,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('taskSaveButton'),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(
                  _isResubmit ? l10n.actionEditAndResend : l10n.actionSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
