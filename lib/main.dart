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

  runApp(const BuildCalcApp());
}

class BuildCalcApp extends StatefulWidget {
  const BuildCalcApp({super.key});

  @override
  State<BuildCalcApp> createState() => _BuildCalcAppState();
}

class _BuildCalcAppState extends State<BuildCalcApp> {
  AppSettings _settings = const AppSettings();

  @override
  void initState() {
    super.initState();
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
      localizationsDelegates: [
        const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          brightness: Brightness.light,
          primary: const Color(0xFF1E3A5F),
          secondary: const Color(0xFFFFA726),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1E3A5F)),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 0,
          color: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFA726),
          brightness: Brightness.dark,
          primary: const Color(0xFFFFA726),
          secondary: const Color(0xFF7DD3FC),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 0,
          color: const Color(0xFF111827),
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
