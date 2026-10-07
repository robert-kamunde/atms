import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';

/// Admin: one workflow template and its steps (spec 4.4).
///
/// NOT IMPLEMENTED (Sprint 3): load template [templateId]; edit steps
/// (name, owner type user/role/supervisor, needs approval, time limit).
class TemplateDetailScreen extends StatelessWidget {
  const TemplateDetailScreen({super.key, required this.templateId});

  final String templateId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.templateDetailTitle)),
      body: ListView(
        children: [
          SectionCard(
            icon: Icons.format_list_numbered,
            title: l10n.templateStepsTitle,
            child: EmptyState(
              compact: true,
              icon: Icons.account_tree_outlined,
              title: l10n.templateStepsEmpty,
            ),
          ),
        ],
      ),
    );
  }
}
