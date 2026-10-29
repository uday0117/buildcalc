import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_localizations.dart';
import '../app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/update_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.settings = const AppSettings(),
    required this.onSettingsChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    _navigationTimer = Timer(const Duration(seconds: 2), () async {
      await _navigateToHome();
    });
  }

  Future<void> _navigateToHome() async {
    if (!mounted) return;

    final hasUpdate = await UpdateService.hasUpdate();
    if (!mounted) return;

    final latestSettings = await AppSettingsService.loadSettings();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          settings: latestSettings,
          onSettingsChanged: widget.onSettingsChanged,
        ),
      ),
    );

    if (hasUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            title: Text(AppLocalizations.translate(dialogCtx, 'updateAvailable')),
            content: const Text(
              'A newer version of BuildCalc is ready to install with improved features and fixes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(AppLocalizations.translate(dialogCtx, 'later')),
              ),
              FilledButton(
                onPressed: () async {
                  final url = Uri.parse(UpdateService.playStoreUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                },
                child: Text(AppLocalizations.translate(dialogCtx, 'installUpdate')),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = info.version);
    } catch (_) {
      if (!mounted) return;
      setState(() => _version = '1.0.0');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.secondary;
    final textColor = isDark ? Colors.white : const Color(0xFF1E3A5F);
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Text(
                  'BuildCalc',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.translate(context, 'professional'),
                  style: TextStyle(fontSize: 16, color: secondaryTextColor),
                ),
                const SizedBox(height: 54),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppLocalizations.translate(context, 'loading'),
                  style: TextStyle(fontSize: 15, color: secondaryTextColor),
                ),
                const SizedBox(height: 14),
                Text(
                  'v$_version',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.1,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
