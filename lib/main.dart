import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';
import 'app_settings.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/app_settings_service.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          brightness: Brightness.light,
          primary: const Color(0xFF1E3A5F),
          secondary: const Color(0xFFFF8C00),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF1E3A5F)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E3A5F),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8C00),
          brightness: Brightness.dark,
          primary: const Color(0xFFFF8C00),
          secondary: const Color(0xFFFFA726),
          surface: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          color: const Color(0xFF1E293B),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(
        settings: _settings,
        onSettingsChanged: _updateSettings,
      ),
    );
  }
}
