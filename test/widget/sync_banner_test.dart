import 'dart:async';

import 'package:atms/shared/providers/sync_providers.dart';
import 'package:atms/shared/services/sync_status_source.dart';
import 'package:atms/shared/widgets/sync_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

class ControlledSyncSource implements SyncStatusSource {
  final controller = StreamController<SyncState>.broadcast();

  @override
  Stream<SyncState> watch() => controller.stream;
}

void main() {
  for (final locale in testLocales) {
    group('SyncBanner [$locale]', () {
      final l10n = l10nFor(locale);

      testWidgets('shows each state from the provider', (tester) async {
        final source = ControlledSyncSource();
        addTearDown(source.controller.close);
        await pumpLocalized(
          tester,
          const Scaffold(body: SyncBanner()),
          locale: locale,
          overrides: [syncStatusSourceProvider.overrideWithValue(source)],
        );
        expect(find.text(l10n.syncOffline), findsNothing);

        source.controller.add(SyncState.offline);
        await tester.pumpAndSettle();
        expect(find.text(l10n.syncOffline), findsOneWidget);

        source.controller.add(SyncState.syncing);
        await tester.pumpAndSettle();
        expect(find.text(l10n.syncSyncing), findsOneWidget);

        source.controller.add(SyncState.synced);
        await tester.pumpAndSettle();
        expect(find.text(l10n.syncAllSaved), findsOneWidget);
      });

      testWidgets('default source keeps the banner hidden', (tester) async {
        await pumpLocalized(
          tester,
          const Scaffold(body: SyncBanner()),
          locale: locale,
        );
        for (final text in [
          l10n.syncOffline,
          l10n.syncSyncing,
          l10n.syncAllSaved,
        ]) {
          expect(find.text(text), findsNothing);
        }
      });
    });
  }

  test('English texts match spec 4.9', () {
    final en = l10nFor(testLocales.first);
    expect(en.syncOffline, 'Offline: changes saved on this phone');
    expect(en.syncSyncing, 'Syncing...');
    expect(en.syncAllSaved, 'All changes saved');
  });
}
