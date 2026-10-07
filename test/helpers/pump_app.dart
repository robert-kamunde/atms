import 'package:atms/core/localization/l10n.dart';
import 'package:atms/core/localization/locale_provider.dart';
import 'package:atms/core/theme/app_theme.dart';
import 'package:atms/features/auth/domain/auth_state.dart';
import 'package:atms/features/auth/presentation/auth_providers.dart';
import 'package:atms/shared/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Both supported languages; widget tests run once per locale.
const testLocales = [AppLocales.english, AppLocales.swahili];

/// Localized strings for [locale] without a widget tree.
AppLocalizations l10nFor(Locale locale) => lookupAppLocalizations(locale);

/// Override that puts the app in the signed-in state for [role].
Override signedInAs(UserRole role) => authControllerProvider.overrideWithBuild(
  (ref, notifier) => AuthSignedIn(role),
);

/// Pumps [child] inside ProviderScope + MaterialApp with the ATMS theme and
/// localizations for [locale]. No Firebase is touched.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  required Locale locale,
  List<Override> overrides = const [],
}) async {
  // A typical small Android phone (360 x 740 dp).
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
