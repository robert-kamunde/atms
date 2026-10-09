import 'package:flutter/material.dart';

import '../../core/errors/failure_messages.dart';
import '../../core/localization/l10n.dart';
import '../providers/paged_list_controller.dart';
import 'empty_state.dart';

/// Renders a [PagedListState]: items, then a "Load more" button while more
/// pages exist, a spinner while loading, or the error with a retry button.
/// Items are never loaded automatically beyond the first page.
class PagedListView<T> extends StatelessWidget {
  const PagedListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.empty,
    this.items,
    this.header,
    this.footerNote,
    this.padding = const EdgeInsets.only(bottom: 88),
  });

  final PagedListState<T> state;

  /// Items to show; defaults to all loaded items (pass a filtered list for
  /// search within loaded pages).
  final List<T>? items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onLoadMore;

  /// Shown when the first page is empty.
  final Widget empty;
  final Widget? header;

  /// Shown above "Load more" (e.g. "search covers loaded people only").
  final String? footerNote;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visible = items ?? state.items;
    if (state.loadedOnce && state.items.isEmpty && state.failure == null) {
      return Column(
        children: [
          ?header,
          Expanded(child: empty),
        ],
      );
    }
    if (!state.loadedOnce && state.failure != null) {
      return Column(
        children: [
          ?header,
          Expanded(
            child: EmptyState(
              icon: Icons.error_outline,
              title: failureMessage(state.failure!, l10n),
              action: OutlinedButton(
                key: const Key('retryButton'),
                onPressed: onLoadMore,
                child: Text(l10n.actionRetry),
              ),
            ),
          ),
        ],
      );
    }
    final footer = <Widget>[
      if (state.loading)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (state.failure != null)
        ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text(failureMessage(state.failure!, l10n)),
          trailing: TextButton(
            key: const Key('retryButton'),
            onPressed: onLoadMore,
            child: Text(l10n.actionRetry),
          ),
        )
      else if (state.hasMore) ...[
        if (footerNote != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              footerNote!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: OutlinedButton(
              key: const Key('loadMoreButton'),
              onPressed: onLoadMore,
              child: Text(l10n.actionLoadMore),
            ),
          ),
        ),
      ],
    ];
    return ListView(
      padding: padding,
      children: [
        ?header,
        for (final item in visible) itemBuilder(context, item),
        ...footer,
      ],
    );
  }
}
