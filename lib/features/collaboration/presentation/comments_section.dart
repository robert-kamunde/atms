import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';

/// Comments on a task, newest at the bottom (spec 4.7).
///
/// NOT IMPLEMENTED (Sprint 5): comments query (paginated), @mentions,
/// sending (works offline via Firestore cache), 15-minute edit window.
/// The input is disabled until sending exists.
class CommentsSection extends StatelessWidget {
  const CommentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      key: const Key('commentsSection'),
      icon: Icons.forum_outlined,
      title: l10n.commentsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmptyState(
            compact: true,
            icon: Icons.chat_bubble_outline,
            title: l10n.commentsEmpty,
          ),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              hintText: l10n.commentInputHint,
              suffixIcon: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
