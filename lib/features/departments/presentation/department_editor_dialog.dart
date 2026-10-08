import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/models/department.dart';
import '../../users/presentation/user_providers.dart';
import '../../users/presentation/widgets/user_picker.dart';

/// What the department editor returns.
@immutable
class DepartmentEditorResult {
  const DepartmentEditorResult({required this.name, this.headUserId});

  final String name;
  final String? headUserId;
}

/// Name and head of a department (create when [department] is null).
class DepartmentEditorDialog extends ConsumerStatefulWidget {
  const DepartmentEditorDialog({super.key, this.department});

  final Department? department;

  @override
  ConsumerState<DepartmentEditorDialog> createState() =>
      _DepartmentEditorDialogState();
}

class _DepartmentEditorDialogState
    extends ConsumerState<DepartmentEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.department?.name ?? '',
  );
  late String? _headUserId = widget.department?.headUserId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickHead() async {
    final user = await showUserPicker(
      context,
      title: context.l10n.departmentFieldHead,
    );
    if (user == null || !mounted) return;
    ref.read(userLookupProvider.notifier).put(user);
    setState(() => _headUserId = user.id);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      DepartmentEditorResult(name: _name.text.trim(), headUserId: _headUserId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final people = ref.watch(userLookupProvider);
    final head = _headUserId == null ? null : people[_headUserId];
    return AlertDialog(
      title: Text(
        widget.department == null
            ? l10n.departmentCreateTitle
            : l10n.departmentEditTitle,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('departmentNameField'),
              controller: _name,
              autofocus: widget.department == null,
              maxLength: Department.maxNameLength,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.departmentFieldName),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.validationNameRequired
                  : null,
            ),
            ListTile(
              key: const Key('departmentHeadTile'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.departmentFieldHead),
              subtitle: Text(
                _headUserId == null
                    ? l10n.departmentNoHead
                    : head?.name ?? l10n.valueNotLoaded,
              ),
              onTap: _pickHead,
              trailing: _headUserId == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      tooltip: l10n.actionClear,
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _headUserId = null),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('saveDepartmentButton'),
          onPressed: _save,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
