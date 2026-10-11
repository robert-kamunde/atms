import 'dart:async';

import 'package:atms/shared/providers/sync_providers.dart';
import 'package:atms/shared/services/sync_status_source.dart';
import 'package:atms/shared/widgets/sync_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Lets a stream event reach the provider, the listener and the frame.
Future<void> flush(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

class ControlledSyncSource implements SyncStatusSource {
  final controller = StreamController<SyncState>.broadcast();

  @override
  Stream<SyncState> watch() => controller.stream;
}

void main() {
  for (final locale in testLocales) {
    group('SyncBanner [$locale]', () {
      final l10n = l10nFor(locale);

      Future<ControlledSyncSource> pump(WidgetTester tester) async {
        final source = ControlledSyncSource();
        addTearDown(source.controller.close);
        await pumpLocalized(
          tester,
          const Scaffold(body: SyncBanner()),
          locale: locale,
          overrides: [syncStatusSourceProvider.overrideWithValue(source)],
        );
        return source;
      }

      testWidgets('offline, syncing, then "all saved" which then hides', (
        tester,
      ) async {
        final source = await pump(tester);
        expect(find.byKey(const Key('syncBanner')), findsNothing);

        source.controller.add(SyncState.offline);
        await flush(tester);
        expect(find.text(l10n.syncOffline), findsOneWidget);

        source.controller.add(SyncState.syncing);
        await flush(tester);
        expect(find.text(l10n.syncSyncing), findsOneWidget);

        source.controller.add(SyncState.synced);
        await flush(tester);
        expect(find.text(l10n.syncAllSaved), findsOneWidget);

        await tester.pump(SyncBanner.syncedVisibleFor);
        expect(find.byKey(const Key('syncBanner')), findsNothing);
      });

      testWidgets('in sync from the start: nothing to say', (tester) async {
        final source = await pump(tester);
        source.controller.add(SyncState.synced);
        await flush(tester);
        expect(find.byKey(const Key('syncBanner')), findsNothing);
      });

      testWidgets('unknown hides the banner (never claims unchecked state)', (
        tester,
      ) async {
        final source = await pump(tester);
        source.controller.add(SyncState.offline);
        await flush(tester);
        source.controller.add(SyncState.unknown);
        await flush(tester);
        expect(find.byKey(const Key('syncBanner')), findsNothing);
      });

      testWidgets('signed out: the default source keeps it hidden', (
        tester,
      ) async {
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
