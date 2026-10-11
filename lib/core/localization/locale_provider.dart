import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Languages ATMS supports (spec 1: Swahili or English).
abstract final class AppLocales {
  static const Locale english = Locale('en');
  static const Locale swahili = Locale('sw');
  static const List<Locale> supported = [english, swahili];

  /// Maps a stored language code (`AppUser.language`) to a supported locale.
  static Locale fromCode(String? code) =>
      code == swahili.languageCode ? swahili : english;
}

/// The app's current language. English until the user picks one (A-18).
///
/// After sign-in `AuthController` sets it from the user's document
/// (`AppUser.language`), and `AuthController.changeLanguage` writes the
/// user's choice back to that document.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => AppLocales.english;

  void setLocale(Locale locale) {
    state = AppLocales.fromCode(locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
