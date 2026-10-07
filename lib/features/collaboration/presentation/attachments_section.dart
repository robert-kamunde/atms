import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';

/// Attachments on a task (spec 4.7): photos compressed to ~300 KB, PDFs and
/// Office files up to 10 MB, queued while offline.
///
/// NOT IMPLEMENTED (Sprint 5): needs `firebase_storage` and an image
/// compression package (to be chosen in Sprint 5). The add button is
/// disabled until then.
class AttachmentsSection extends StatelessWidget {
  const AttachmentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      key: const Key('attachmentsSection'),
      icon: Icons.attach_file,
      title: l10n.attachmentsTitle,
      trailing: IconButton(
        tooltip: l10n.actionAddAttachment,
        onPressed: null,
        icon: const Icon(Icons.add),
      ),
      child: EmptyState(
        compact: true,
        icon: Icons.insert_drive_file_outlined,
        title: l10n.attachmentsEmpty,
      ),
    );
  }
}
