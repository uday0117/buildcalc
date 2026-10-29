import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_localizations.dart';
import '../app_settings.dart';
import '../models/calculation.dart';
import '../models/calculator_item.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/calculator_card.dart';
import '../widgets/empty_state.dart';
import 'calculators/cost_estimator.dart';
import 'history_screen.dart';
import 'plan/plan_editor_screen.dart';
import 'plan/plan_templates_screen.dart';
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
      const HomeContent(),
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
          final nextSettings = _settings.copyWith(
            locale: locale,
            clearLocale: locale == null,
          );
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
              selectedItemColor: const Color(0xFFFF8C00),
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

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = CalculatorCategory.all;
  Set<String> _favoriteIds = {};
  List<Calculation> _recentCalculations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final favorites = await StorageService.getFavoriteCalculatorIds();
    final recent = await StorageService.getRecentCalculations(limit: 3);
    if (!mounted) return;
    setState(() {
      _favoriteIds = favorites;
      _recentCalculations = recent;
    });
  }

  Future<void> _toggleFavorite(String id) async {
    final isFav = await StorageService.toggleFavoriteCalculator(id);
    if (!mounted) return;
    setState(() {
      if (isFav) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
    });
  }

  List<CalculatorItem> _getFilteredCalculators() {
    final all = CalculatorItem.allCalculators;
    return all.where((calc) {
      // Category filter
      if (_selectedCategory == CalculatorCategory.favorites) {
        if (!_favoriteIds.contains(calc.id)) return false;
      } else if (_selectedCategory != CalculatorCategory.all) {
        if (calc.category != _selectedCategory) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty && !calc.matchesSearch(_searchQuery, context)) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showRecentCalculationModal(Calculation calc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final matchingItem = CalculatorItem.findById(calc.type);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1E3A5F),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      matchingItem?.icon ?? Icons.calculate_rounded,
                      color: const Color(0xFFFF8C00),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matchingItem?.localizedTitle(context) ?? calc.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy • hh:mm a',
                          ).format(calc.timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),
              const Text(
                'Inputs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA726),
                ),
              ),
              const SizedBox(height: 8),
              ...calc.inputs.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        e.value.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.white24, height: 24),
              const Text(
                'Results',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA726),
                ),
              ),
              const SizedBox(height: 8),
              ...calc.results.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        e.value is double
                            ? (e.value as double).toStringAsFixed(2)
                            : e.value.toString(),
                        style: const TextStyle(
                          color: Color(0xFFFF8C00),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  if (matchingItem != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: matchingItem.builder),
                          ).then((_) => _loadData());
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Open Calculator'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _getFilteredCalculators();
    final favoriteCalculators = CalculatorItem.allCalculators
        .where((c) => _favoriteIds.contains(c.id))
        .toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Construction Header & Search Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand / Tagline Bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1E293B),
                                  const Color(0xFF0F172A),
                                ]
                              : [
                                  const Color(0xFF1E3A5F),
                                  const Color(0xFF2C5F8D),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.08,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF8C00,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.construction_rounded,
                              size: 30,
                              color: Color(0xFFFFA726),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'BuildCalc Pro',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF8C00),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'SUITE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppLocalizations.translate(
                                    context,
                                    'tagline',
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Modern Search Field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.translate(context, 'searchCalculators'),
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFFF8C00),
                          size: 22,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF8C00),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Chips Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: CalculatorCategory.categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          final isFavCategory =
                              cat == CalculatorCategory.favorites;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              selected: isSelected,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isFavCategory) ...[
                                    Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFFF8C00),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    CalculatorCategory.localizedCategory(
                                      context,
                                      cat,
                                    ),
                                  ),
                                  if (isFavCategory &&
                                      _favoriteIds.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withValues(
                                                alpha: 0.25,
                                              )
                                            : const Color(
                                                0xFFFF8C00,
                                              ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${_favoriteIds.length}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFFFF8C00),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF1E3A5F)),
                              ),
                              backgroundColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              selectedColor: const Color(0xFFFF8C00),
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark
                                            ? Colors.white12
                                            : Colors.grey.shade300),
                                ),
                              ),
                              onSelected: (_) {
                                setState(() => _selectedCategory = cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Favorites Carousel (only show on "All" when favorites exist and not searching)
            if (_selectedCategory == CalculatorCategory.all &&
                _searchQuery.isEmpty &&
                favoriteCalculators.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFF8C00),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.translate(
                                  context,
                                  'quickFavorites',
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              setState(
                                () => _selectedCategory =
                                    CalculatorCategory.favorites,
                              );
                            },
                            child: Text(
                              AppLocalizations.translate(context, 'viewAll'),
                              style: const TextStyle(
                                color: Color(0xFFFF8C00),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 95,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: favoriteCalculators.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final item = favoriteCalculators[index];
                            return Material(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: item.builder),
                                ).then((_) => _loadData()),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 170,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: item.iconColor.withValues(
                                            alpha: 0.14,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: item.iconColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item.localizedTitle(context),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Recent Calculations Section (when on "All" and not searching)
            if (_selectedCategory == CalculatorCategory.all &&
                _searchQuery.isEmpty &&
                _recentCalculations.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                color: Color(0xFF42A5F5),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.translate(
                                  context,
                                  'recentCalculations',
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              final parent = context
                                  .findAncestorStateOfType<_HomeScreenState>();
                              parent?.setState(() => parent._currentIndex = 1);
                            },
                            child: Text(
                              AppLocalizations.translate(context, 'viewAll'),
                              style: const TextStyle(
                                color: Color(0xFFFF8C00),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ..._recentCalculations.map((calc) {
                        final item = CalculatorItem.findById(calc.type);
                        final firstResult = calc.results.entries.firstOrNull;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            onTap: () => _showRecentCalculationModal(calc),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    (item?.iconColor ?? const Color(0xFFFF8C00))
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item?.icon ?? Icons.calculate_rounded,
                                color:
                                    item?.iconColor ?? const Color(0xFFFF8C00),
                                size: 22,
                              ),
                            ),
                            title: Text(
                              item?.localizedTitle(context) ?? calc.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat(
                                'MMM dd • hh:mm a',
                              ).format(calc.timestamp),
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: firstResult != null
                                ? Text(
                                    firstResult.value is double
                                        ? (firstResult.value as double)
                                              .toStringAsFixed(1)
                                        : firstResult.value.toString(),
                                    style: const TextStyle(
                                      color: Color(0xFFFF8C00),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  )
                                : const Icon(Icons.chevron_right_rounded),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],

            // Featured 2D House Plan Generator Banner
            if (_selectedCategory == CalculatorCategory.all &&
                _searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Material(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlanEditorScreen(),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFFFF8C00,
                            ).withValues(alpha: isDark ? 0.35 : 0.25),
                          ),
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF1E293B),
                                    const Color(0xFF0F172A),
                                  ]
                                : [Colors.white, const Color(0xFFFFF8F0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF8C00,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.architecture_rounded,
                                color: Color(0xFFFF8C00),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Flexible(
                                        child: Text(
                                          '2D House Plan Generator',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF8C00),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'NEW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Interactive 1, 2, 3 & 4 BHK blueprint designer with walls, rooms, doors & windows',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      ActionChip(
                                        avatar: const Icon(
                                          Icons.auto_awesome_mosaic_rounded,
                                          size: 13,
                                          color: Color(0xFFFF8C00),
                                        ),
                                        label: const Text(
                                          'Ready-Made Templates (1-4 BHK)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        backgroundColor: const Color(
                                          0xFFFF8C00,
                                        ).withValues(alpha: 0.1),
                                        side: BorderSide.none,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PlanTemplatesScreen(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Color(0xFFFF8C00),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Featured Planning & Cost Estimator Banner
            if (_selectedCategory == CalculatorCategory.all &&
                _searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      // Cost Estimator card
                      Expanded(
                        child: Material(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CostEstimator(),
                              ),
                            ).then((_) => _loadData()),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFF9800,
                                  ).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF9800,
                                      ).withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calculate_rounded,
                                      color: Color(0xFFFF9800),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Cost Estimator',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Budget by area tier',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Project Management card
                      Expanded(
                        child: Material(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProjectManagementScreen(),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1E3A5F,
                                  ).withValues(alpha: isDark ? 0.4 : 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1E3A5F,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.business_center_rounded,
                                      color: Color(0xFF1E3A5F),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Projects',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Track material costs',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Calculators Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == CalculatorCategory.all
                          ? 'All Calculators (${filtered.length})'
                          : '$_selectedCategory (${filtered.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Calculators Grid or Empty State
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateView(
                  icon: _selectedCategory == CalculatorCategory.favorites
                      ? Icons.star_border_rounded
                      : Icons.search_off_rounded,
                  title: _selectedCategory == CalculatorCategory.favorites
                      ? AppLocalizations.translate(context, 'favorites')
                      : AppLocalizations.translate(context, 'noCalculationsYet'),
                  message: _selectedCategory == CalculatorCategory.favorites
                      ? 'Tap the star icon on any calculator to pin it to your favorites!'
                      : 'Try a different search keyword or switch category filters.',
                  actionLabel: _selectedCategory != CalculatorCategory.all
                      ? 'Show all calculators'
                      : null,
                  onAction: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedCategory = CalculatorCategory.all;
                    });
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final crossAxisCount = width > 900
                        ? 4
                        : width > 600
                        ? 3
                        : 2;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = filtered[index];
                        final isFav = _favoriteIds.contains(item.id);

                        return CalculatorCard(
                          icon: item.icon,
                          title: item.localizedTitle(context),
                          iconColor: item.iconColor,
                          category: CalculatorCategory.localizedCategory(
                            context,
                            item.category,
                          ),
                          isFavorite: isFav,
                          onFavoriteToggle: () => _toggleFavorite(item.id),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: item.builder),
                          ).then((_) => _loadData()),
                        );
                      }, childCount: filtered.length),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
