import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class OnboardingSheet extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingSheet({super.key, this.onComplete});

  static Future<void> showIfNeeded(BuildContext context) async {
    final hasSeen = await StorageService.hasSeenOnboarding();
    if (!hasSeen && context.mounted) {
      await show(context);
    }
  }

  static Future<void> show(BuildContext context, {VoidCallback? onComplete}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: true,
      builder: (ctx) => OnboardingSheet(onComplete: onComplete),
    );
  }

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      icon: Icons.calculate_rounded,
      badge: 'PRECISION ENGINES',
      badgeColor: AppColors.accent,
      title: '10 Precision Civil Calculators',
      description:
          'Compute exact material quantities for cement, bricks, sand, paint, steel, tiles, excavation & staircases with standard IS/metric formulas.',
      highlights: [
        'Exact mix ratios & wastage buffers',
        'Multi-unit support (metric & imperial)',
        'Bookmark calculations for quick access',
      ],
    ),
    _OnboardingItem(
      icon: Icons.architecture_rounded,
      badge: '2D & 3D STUDIO',
      badgeColor: Color(0xFF0284C7),
      title: 'Floor Plan & 3D Visualizer',
      description:
          'Design 1 to 4 BHK blueprint layouts with walls, rooms, doors and windows. Preview your building in real-time 3D and front elevations.',
      highlights: [
        'Ready-made templates for 1 to 4 BHK',
        'Real-time interactive 3D orbit & cutaway views',
        'Architectural & illustrative front elevations',
      ],
    ),
    _OnboardingItem(
      icon: Icons.assignment_turned_in_rounded,
      badge: 'COST & ESTIMATION',
      badgeColor: Color(0xFF10B981),
      title: 'Automatic BOQ & Projects',
      description:
          'Generate instant material takeoffs, track budget expenses per site, and export professional PDF & image reports for clients.',
      highlights: [
        'Instant cost estimations by quality tier',
        'Detailed project budget tracking',
        'Professional PDF & Image blueprint exports',
      ],
    ),
  ];

  void _finish() async {
    await StorageService.setSeenOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = _currentPage == _items.length - 1;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Grab Bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row: App badge & Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.construction_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'BuildCalc Pro',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _finish,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Slides View
            Flexible(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          // Big Hero Icon Tile
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  item.badgeColor.withValues(alpha: 0.15),
                                  item.badgeColor.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: item.badgeColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              size: 46,
                              color: item.badgeColor,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Pill Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: item.badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.badgeColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Title
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.primaryDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Description
                          Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Key highlights
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : AppColors.primarySoft.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Column(
                              children: item.highlights.map((h) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 16,
                                        color: item.badgeColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          h,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.9)
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (idx) {
                      final isSelected = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: isSelected ? 24 : 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : (isDark ? Colors.white24 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLastPage) {
                          _finish();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isLastPage ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final String title;
  final String description;
  final List<String> highlights;

  const _OnboardingItem({
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.description,
    required this.highlights,
  });
}
