import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/task.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/enum_labels.dart';
import '../../../../shared/widgets/paged_list_view.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../users/presentation/widgets/user_picker.dart';
import '../task_providers.dart';

/// Asks for a required reason (blocked, cancelled, returned; spec 4.3).
/// Returns the trimmed reason, or null when dismissed.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
}) => showDialog<String>(
  context: context,
  builder: (_) => _ReasonDialog(title: title, confirmLabel: confirmLabel),
);

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.confirmLabel});

  final String title;
  final String confirmLabel;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('reasonField'),
          controller: _controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: Task.maxReasonLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.reasonFieldLabel),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? l10n.validationReasonRequired
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('reasonConfirmButton'),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Asks "are you sure?" for a change that cannot be undone from the app.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('confirmDialogButton'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Lets the user choose one or more people they may assign (spec 2
/// matrix), 20 at a time; the search box filters the loaded pages only.
/// Returns the chosen ids in order, or null when dismissed.
Future<List<String>?> showAssigneePicker(
  BuildContext context, {
  required String title,
  required List<String> initial,
}) => showModalBottomSheet<List<String>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _AssigneePickerSheet(title: title, initial: initial),
);

class _AssigneePickerSheet extends ConsumerStatefulWidget {
  const _AssigneePickerSheet({required this.title, required this.initial});

  final String title;
  final List<String> initial;

  @override
  ConsumerState<_AssigneePickerSheet> createState() =>
      _AssigneePickerSheetState();
}

class _AssigneePickerSheetState extends ConsumerState<_AssigneePickerSheet> {
  late final List<String> _selected = List.of(widget.initial);
  String _query = '';

  void _toggle(AppUser user) => setState(() {
    if (_selected.contains(user.id)) {
      _selected.remove(user.id);
    } else if (_selected.length < Task.maxAssignees) {
      _selected.add(user.id);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actor = ref.watch(taskActorProvider);
    final state = ref.watch(assignablePeopleProvider);
    final visible = state.items
        .where((u) => u.active)
        .where((u) => nameMatches(u.name, _query))
        .toList();
    // Managers are not in their own team list: offer themselves first.
    final me = ref.watch(currentSessionProvider)?.user;
    final showMe =
        me != null &&
        actor != null &&
        !state.items.any((u) => u.id == me.id) &&
        nameMatches(me.name, _query);
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            trailing: IconButton(
              tooltip: l10n.actionClose,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('assigneePickerSearch'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.searchByName,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: PagedListView<AppUser>(
              state: state,
              items: visible,
              onLoadMore: () =>
                  ref.read(assignablePeopleProvider.notifier).loadMore(),
              footerNote: _query.isEmpty ? null : l10n.searchLoadedOnlyNote,
              header: showMe ? _personTile(context, me, isMe: true) : null,
              empty: EmptyState(
                icon: Icons.people_outline,
                title: l10n.assigneePickerEmpty,
              ),
              itemBuilder: (context, user) =>
                  _personTile(context, user, isMe: user.id == me?.id),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('assigneePickerDone'),
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  child: Text(l10n.assigneePickerDone(_selected.length)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personTile(BuildContext context, AppUser user, {required bool isMe}) {
    final l10n = context.l10n;
    return CheckboxListTile(
      key: ValueKey('assignee-${user.id}'),
      value: _selected.contains(user.id),
      onChanged: (_) => _toggle(user),
      title: Text(isMe ? l10n.assigneeMe(user.name) : user.name),
      subtitle: Text(user.jobRole ?? user.role.label(l10n)),
    );
  }
}
