import 'package:flutter/material.dart';

import 'empty_state.dart';
import 'sync_banner.dart';

/// Layout skeleton shared by list screens whose data source is not built
/// yet: app bar, sync banner, empty state and an optional action button.
/// All text is passed in already localized.
class EmptyListScreen extends StatelessWidget {
  const EmptyListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.emptyTitle,
    this.emptyMessage,
    this.header,
    this.floatingActionButton,
  });

  final String title;
  final IconData icon;
  final String emptyTitle;
  final String? emptyMessage;

  /// Optional widget above the empty state (e.g. filters, search).
  final Widget? header;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          const SyncBanner(),
          ?header,
          Expanded(
            child: EmptyState(
              icon: icon,
              title: emptyTitle,
              message: emptyMessage,
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
