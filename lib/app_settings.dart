import 'package:flutter/material.dart';

import 'app_localizations.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
  });

  final ThemeMode themeMode;
  /// If null, the app follows the system / device language.
  final Locale? locale;

  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }

  static ThemeMode themeModeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  static Locale? localeFromString(String? value) {
    if (value == null || value.isEmpty || value == 'system') {
      return null;
    }
    final isSupported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == value,
    );
    return isSupported ? Locale(value) : null;
  }

  static String localeToString(Locale? locale) {
    return locale?.languageCode ?? 'system';
  }
}
