import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/models/task_priority.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/enum_labels.dart';
import '../../../shared/widgets/failure_snackbar.dart';

/// Create / edit task (spec 4.3 step 1): title, deadline, priority and
/// assignee are required; description is optional.
///
/// NOT IMPLEMENTED (Sprint 2): saving (TaskRepository with
/// `Task.toClientCreateMap()`), loading an existing task for edit,
/// attachments, the confidential flag and participants (Sprint 5), and the
/// "all / any one person" completion mode when several people are chosen.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  /// Null when creating a task.
  final String? taskId;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _deadline;
  TaskPriority? _priority;
  final List<String> _assigneeIds = const [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDeadline(DateTime? current) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
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

  Future<void> _pickAssignees() async {
    final l10n = context.l10n;
    // NOT IMPLEMENTED (Sprint 2): list people the user may assign to
    // (paginated users query). No data source yet, so the sheet is empty.
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: EmptyState(
          compact: true,
          icon: Icons.group_outlined,
          title: l10n.assigneePickerEmpty,
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // NOT IMPLEMENTED (Sprint 2): write the task. Nothing is saved yet, and
    // the UI says so instead of pretending.
    showMessageSnackBar(context, context.l10n.featureNotAvailableYet);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.taskId != null;
    final dateFormat = DateFormat.yMMMEd(l10n.localeName).add_Hm();
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.taskEditTitle : l10n.taskCreateTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('taskTitleField'),
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 120,
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
                  if (v.isBefore(DateTime.now())) {
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
                          : dateFormat.format(field.value!),
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
                  onTap: _pickAssignees,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.taskFieldAssignee,
                      errorText: field.errorText,
                      suffixIcon: const Icon(Icons.person_add_alt),
                    ),
                    child: Text(
                      (field.value?.isEmpty ?? true)
                          ? l10n.taskFieldAssigneeHint
                          : l10n.assigneeCount(field.value!.length),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.taskFieldDescription,
                  helperText: l10n.optionalFieldHint,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('taskSaveButton'),
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(l10n.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
