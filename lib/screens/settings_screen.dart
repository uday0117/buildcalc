import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_localizations.dart';
import '../app_settings.dart';
import '../services/review_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  final AppSettings settings;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<Locale?> onLocaleChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version}+${info.buildNumber}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _version = '1.0.0');
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      'Check out BuildCalc - Your construction calculator app!\n\n'
      'Calculate cement, bricks, sand, paint, steel, tiles and more.\n\n'
      'Download now: https://play.google.com/store/apps/details?id=com.uksolutions.buildcalc',
      subject: 'BuildCalc - Construction Calculator',
    );
  }

  void _showThemeDialog() {
    final options = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.translate(context, 'theme')),
        content: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((mode) {
              final label = mode == ThemeMode.system
                  ? AppLocalizations.translate(context, 'system')
                  : mode == ThemeMode.light
                  ? AppLocalizations.translate(context, 'light')
                  : AppLocalizations.translate(context, 'dark');

              final isSelected = widget.settings.themeMode == mode;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                title: Text(label),
                onTap: () {
                  widget.onThemeChanged(mode);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final activeLocale = widget.settings.locale;
            final isSystem = activeLocale == null;
            final deviceLanguage = Localizations.localeOf(context).languageCode;
            final deviceLangName = AppLocalizations.getNativeName(deviceLanguage);

            final filteredLanguages = AppLocalizations.supportedLanguages.where((l) {
              if (query.trim().isEmpty) return true;
              final q = query.toLowerCase().trim();
              return l.nativeName.toLowerCase().contains(q) ||
                  l.englishName.toLowerCase().contains(q) ||
                  l.code.toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              title: Text(AppLocalizations.translate(context, 'language')),
              contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
              content: SizedBox(
                width: double.maxFinite,
                height: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: AppLocalizations.translate(context, 'searchCalculators'),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (val) {
                          setDialogState(() => query = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (query.trim().isEmpty) ...[
                            ListTile(
                              leading: Icon(
                                isSystem
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isSystem
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              title: Row(
                                children: [
                                  const Text('🌐 '),
                                  Text(AppLocalizations.translate(context, 'systemDefault')),
                                ],
                              ),
                              subtitle: Text(
                                '${AppLocalizations.translate(context, 'followSystem')} ($deviceLangName)',
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                widget.onLocaleChanged(null);
                                Navigator.pop(dialogContext);
                              },
                            ),
                            const Divider(height: 1),
                          ],
                          ...filteredLanguages.map((lang) {
                            final isSelected = !isSystem && activeLocale.languageCode == lang.code;
                            return ListTile(
                              leading: Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              title: Text(lang.nativeName),
                              subtitle: Text(
                                lang.englishName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              onTap: () {
                                widget.onLocaleChanged(Locale(lang.code));
                                Navigator.pop(dialogContext);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(AppLocalizations.translate(context, 'cancel')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF111827), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF1E3A5F), Color(0xFF2C5F8D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.business_center_rounded,
                        size: 48,
                        color: Color(0xFFFFA726),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.translate(context, 'appName'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.translate(context, 'tagline'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                children: [
                  _buildSettingsSection(
                    context,
                    children: [
                      _buildSettingsTile(
                        context,
                        icon: Icons.palette_rounded,
                        title: AppLocalizations.translate(context, 'theme'),
                        subtitle: _themeLabel(
                          context,
                          widget.settings.themeMode,
                        ),
                        onTap: _showThemeDialog,
                      ),
                      const Divider(height: 1, indent: 72),
                      _buildSettingsTile(
                        context,
                        icon: Icons.language_rounded,
                        title: AppLocalizations.translate(context, 'language'),
                        subtitle: widget.settings.locale == null
                            ? '${AppLocalizations.translate(context, 'systemDefault')} (${AppLocalizations.getNativeName(Localizations.localeOf(context).languageCode)})'
                            : AppLocalizations.getNativeName(
                                widget.settings.locale!.languageCode,
                              ),
                        onTap: _showLanguageDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsSection(
                    context,
                    children: [
                      _buildSettingsTile(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: AppLocalizations.translate(context, 'about'),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: AppLocalizations.translate(
                              context,
                              'appName',
                            ),
                            applicationVersion: _version,
                            applicationIcon: const Icon(
                              Icons.business_center_rounded,
                              size: 50,
                              color: Color(0xFFFFA726),
                            ),
                            children: const [
                              Text(
                                'Your construction calculator app for cement, bricks, sand, and more.',
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 72),
                      _buildSettingsTile(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        title: AppLocalizations.translate(context, 'privacy'),
                        onTap: () => _openUrl(
                          'https://uday0117.github.io/buildcalc/privacy_policy.html',
                        ),
                      ),
                      const Divider(height: 1, indent: 72),
                      _buildSettingsTile(
                        context,
                        icon: Icons.description_outlined,
                        title: AppLocalizations.translate(context, 'terms'),
                        onTap: () => _openUrl(
                          'https://uday0117.github.io/buildcalc/terms_and_conditions.html',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsSection(
                    context,
                    children: [
                      _buildSettingsTile(
                        context,
                        icon: Icons.share_rounded,
                        title: AppLocalizations.translate(context, 'share'),
                        onTap: _shareApp,
                      ),
                      const Divider(height: 1, indent: 72),
                      _buildSettingsTile(
                        context,
                        icon: Icons.star_rounded,
                        title: AppLocalizations.translate(context, 'rateUs'),
                        subtitle: AppLocalizations.translate(
                          context,
                          'appRating',
                        ),
                        onTap: () => ReviewService.requestReview(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      AppLocalizations.translate(context, 'madeBy'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return AppLocalizations.translate(context, 'dark');
      case ThemeMode.light:
        return AppLocalizations.translate(context, 'light');
      case ThemeMode.system:
        return AppLocalizations.translate(context, 'system');
    }
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFFA726)),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
