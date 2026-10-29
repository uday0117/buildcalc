import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_settings.dart';

class AppSettingsService {
  static const String _themeKey = 'app_theme_mode';
  static const String _localeKey = 'app_locale';

  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = AppSettings.themeModeFromString(
      prefs.getString(_themeKey),
    );
    final locale = AppSettings.localeFromString(prefs.getString(_localeKey));
    return AppSettings(themeMode: themeMode, locale: locale);
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, AppSettings.themeModeToString(mode));
  }

  static Future<void> saveLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString(_localeKey, 'system');
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }
}
