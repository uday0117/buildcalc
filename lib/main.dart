import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';
import 'app_settings.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/app_settings_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AdService.initialize();

  final initialSettings = await AppSettingsService.loadSettings();

  runApp(BuildCalcApp(initialSettings: initialSettings));
}

class BuildCalcApp extends StatefulWidget {
  final AppSettings? initialSettings;
  const BuildCalcApp({super.key, this.initialSettings});

  @override
  State<BuildCalcApp> createState() => _BuildCalcAppState();
}

class _BuildCalcAppState extends State<BuildCalcApp> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings ?? const AppSettings();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettingsService.loadSettings();
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  void _updateSettings(AppSettings settings) async {
    setState(() => _settings = settings);
    await AppSettingsService.saveThemeMode(settings.themeMode);
    await AppSettingsService.saveLocale(settings.locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildCalc',
      debugShowCheckedModeBanner: false,
      themeMode: _settings.themeMode,
      locale: _settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (_settings.locale != null) {
          return _settings.locale;
        }
        if (deviceLocale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == deviceLocale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('en');
      },
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: SplashScreen(
        settings: _settings,
        onSettingsChanged: _updateSettings,
      ),
    );
  }
}
