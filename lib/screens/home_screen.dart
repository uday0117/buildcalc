import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../app_settings.dart';
import '../services/ad_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/calculator_card.dart';
import 'calculators/area_calculator.dart';
import 'calculators/brick_calculator.dart';
import 'calculators/cement_calculator.dart';
import 'calculators/cost_estimator.dart';
import 'calculators/paint_calculator.dart';
import 'calculators/sand_calculator.dart';
import 'calculators/steel_calculator.dart';
import 'calculators/tile_calculator.dart';
import 'history_screen.dart';
import 'project_management_screen.dart';
import 'saved_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    AdService.preloadInterstitial();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.translate;

    final screens = [
      HomeContent(),
      const HistoryScreen(),
      const SavedScreen(),
      SettingsScreen(
        settings: _settings,
        onThemeChanged: (mode) {
          final nextSettings = _settings.copyWith(themeMode: mode);
          setState(() => _settings = nextSettings);
          widget.onSettingsChanged(nextSettings);
        },
        onLocaleChanged: (locale) {
          final nextSettings = _settings.copyWith(locale: locale);
          setState(() => _settings = nextSettings);
          widget.onSettingsChanged(nextSettings);
        },
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBannerAd(),
            BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_rounded),
                  label: l10n(context, 'home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.history_rounded),
                  label: l10n(context, 'history'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.bookmark_rounded),
                  label: l10n(context, 'saved'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_rounded),
                  label: l10n(context, 'settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF1E3A5F), const Color(0xFF2A5D99)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A5F).withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.business_center_rounded,
                      color: Color(0xFFFFA726),
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.translate(
                            context,
                            'projectDashboard',
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.translate(context, 'smartTools'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: AppLocalizations.translate(context, 'calculators'),
                    value: '08',
                    color: const Color(0xFF38BDF8),
                    icon: Icons.calculate_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: AppLocalizations.translate(context, 'materials'),
                    value: '12',
                    color: const Color(0xFF4ADE80),
                    icon: Icons.layers_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: AppLocalizations.translate(context, 'projects'),
                    value: '24',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.insights_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: AppLocalizations.translate(context, 'insights'),
                    value: '91%',
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              AppLocalizations.translate(context, 'calculators'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                CalculatorCard(
                  icon: Icons.architecture_rounded,
                  title: 'Cement\nCalculator',
                  iconColor: const Color(0xFF795548),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CementCalculator(),
                    ),
                  ),
                ),
                CalculatorCard(
                  icon: Icons.grid_4x4_rounded,
                  title: 'Brick\nCalculator',
                  iconColor: const Color(0xFFD32F2F),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrickCalculator(),
                    ),
                  ),
                ),
                CalculatorCard(
                  icon: Icons.terrain_rounded,
                  title: 'Sand\nCalculator',
                  iconColor: const Color(0xFFFFA726),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SandCalculator(),
                    ),
                  ),
                ),
                CalculatorCard(
                  icon: Icons.format_paint_rounded,
                  title: 'Paint\nCalculator',
                  iconColor: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaintCalculator(),
                    ),
                  ),
                ),
                CalculatorCard(
                  icon: Icons.fence_rounded,
                  title: 'Steel\nCalculator',
                  iconColor: const Color(0xFF607D8B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SteelCalculator(),
                    ),
                  ),
                ),
                CalculatorCard(
                  icon: Icons.dashboard_rounded,
                  title: 'Tile\nCalculator',
                  iconColor: const Color(0xFF8D6E63),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TileCalculator(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CalculatorCard(
              icon: Icons.square_foot_rounded,
              title: 'Area Calculator',
              iconColor: const Color(0xFF66BB6A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AreaCalculator()),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CostEstimator(),
                  ),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFA726,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calculate_rounded,
                          size: 30,
                          color: Color(0xFFFFA726),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Construction Cost\nEstimator',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProjectManagementScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_shared_rounded,
                          size: 30,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Project\nManagement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
