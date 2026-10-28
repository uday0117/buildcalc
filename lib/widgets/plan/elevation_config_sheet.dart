import 'package:flutter/material.dart';

import '../../models/plan/elevation_models.dart';

class ElevationConfigSheet extends StatefulWidget {
  final ElevationConfig initialConfig;
  final ValueChanged<ElevationConfig> onConfigUpdated;

  const ElevationConfigSheet({
    super.key,
    required this.initialConfig,
    required this.onConfigUpdated,
  });

  @override
  State<ElevationConfigSheet> createState() => _ElevationConfigSheetState();
}

class _ElevationConfigSheetState extends State<ElevationConfigSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ElevationConfig _current;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _current = widget.initialConfig;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _update(ElevationConfig updated) {
    setState(() {
      _current = updated;
    });
    widget.onConfigUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sheet Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: Color(0xFFFF8C00), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Customize Facade Concept',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFFFF8C00),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF8C00),
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Style'),
                Tab(text: 'Floors & Roof'),
                Tab(text: 'Finishes'),
                Tab(text: 'Windows & Balcony'),
                Tab(text: 'Colors'),
              ],
            ),

            // Tab Content
            SizedBox(
              height: 340,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStyleTab(isDark),
                  _buildFloorsAndRoofTab(isDark),
                  _buildFinishesTab(isDark),
                  _buildWindowsAndBalconyTab(isDark),
                  _buildColorsTab(isDark),
                ],
              ),
            ),

            // Action footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Apply Changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Style Tab
  Widget _buildStyleTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Exterior Design Concept',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...ElevationStyle.values.map((style) {
          final isSelected = _current.style == style;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isSelected
                  ? const Color(0xFFFF8C00).withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  // Switch style and auto-suggest matching defaults
                  final palette = style == ElevationStyle.traditional
                      ? ElevationColorPalette.warmTerracotta
                      : style == ElevationStyle.minimalist
                          ? ElevationColorPalette.minimalistMonochrome
                          : style == ElevationStyle.contemporary
                              ? ElevationColorPalette.contemporarySlate
                              : ElevationColorPalette.modernIvoryWood;

                  _update(
                    _current.copyWith(
                      style: style,
                      primaryColor: palette.primary,
                      accentColor: palette.accent,
                      trimColor: palette.trim,
                      glassColor: palette.glass,
                      roofStyle: style == ElevationStyle.traditional ? RoofStyle.pitchedTile : RoofStyle.flatParapet,
                      finishPreset: style == ElevationStyle.traditional ? FinishPreset.exposedBrick : FinishPreset.smoothPlaster,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF8C00) : (isDark ? Colors.white12 : Colors.grey.shade200),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF8C00) : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          style.icon,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              style.label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? const Color(0xFFFF8C00) : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              style.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFFFF8C00), size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // 2. Floors & Roof Tab
  Widget _buildFloorsAndRoofTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Floor Count',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [1, 2, 3, 4].map((count) {
            final isSelected = _current.floorCount == count;
            final label = count == 1 ? 'G (1)' : count == 2 ? 'G+1 (2)' : count == 3 ? 'G+2 (3)' : 'G+3 (4)';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(label, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF8C00),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                  onSelected: (val) {
                    if (val) _update(_current.copyWith(floorCount: count));
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(height: 24),
        const Text(
          'Roof Silhouette',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RoofStyle.values.map((r) {
            final isSelected = _current.roofStyle == r;
            return ChoiceChip(
              avatar: Icon(r.icon, size: 16, color: isSelected ? Colors.white : null),
              label: Text(r.label, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              selectedColor: const Color(0xFFFF8C00),
              labelStyle: TextStyle(color: isSelected ? Colors.white : null),
              onSelected: (val) {
                if (val) _update(_current.copyWith(roofStyle: r));
              },
            );
          }).toList(),
        ),
        const Divider(height: 24),
        const Text(
          'Ground Level Features',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Covered Car Porch', style: TextStyle(fontSize: 13)),
          subtitle: const Text('Include structural porch columns on ground level', style: TextStyle(fontSize: 11)),
          value: _current.hasCarPorch,
          activeThumbColor: const Color(0xFFFF8C00),
          onChanged: (val) => _update(_current.copyWith(hasCarPorch: val)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Entrance Portico Canopy', style: TextStyle(fontSize: 13)),
          subtitle: const Text('Featured architectural canopy above entrance door', style: TextStyle(fontSize: 11)),
          value: _current.hasEntrancePortico,
          activeThumbColor: const Color(0xFFFF8C00),
          onChanged: (val) => _update(_current.copyWith(hasEntrancePortico: val)),
        ),
      ],
    );
  }

  // 3. Finishes Tab
  Widget _buildFinishesTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Facade Wall Finish & Cladding',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...FinishPreset.values.map((finish) {
          final isSelected = _current.finishPreset == finish;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isSelected
                  ? const Color(0xFFFF8C00).withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => _update(_current.copyWith(finishPreset: finish)),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF8C00) : (isDark ? Colors.white12 : Colors.grey.shade200),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: finish.swatchColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              finish.label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? const Color(0xFFFF8C00) : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              finish.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFFFF8C00), size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // 4. Windows & Balcony Tab
  Widget _buildWindowsAndBalconyTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Window Style',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WindowStyle.values.map((w) {
            final isSelected = _current.windowStyle == w;
            return ChoiceChip(
              avatar: Icon(w.icon, size: 16, color: isSelected ? Colors.white : null),
              label: Text(w.label, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              selectedColor: const Color(0xFFFF8C00),
              labelStyle: TextStyle(color: isSelected ? Colors.white : null),
              onSelected: (val) {
                if (val) _update(_current.copyWith(windowStyle: w));
              },
            );
          }).toList(),
        ),
        const Divider(height: 24),
        const Text(
          'Balcony & Railing Option',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BalconyOption.values.map((b) {
            final isSelected = _current.balconyOption == b;
            return ChoiceChip(
              avatar: Icon(b.icon, size: 16, color: isSelected ? Colors.white : null),
              label: Text(b.label, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              selectedColor: const Color(0xFFFF8C00),
              labelStyle: TextStyle(color: isSelected ? Colors.white : null),
              onSelected: (val) {
                if (val) _update(_current.copyWith(balconyOption: b));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // 5. Colors Tab
  Widget _buildColorsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Curated Color Harmonies',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...ElevationColorPalette.presets.map((palette) {
          final isSelected = _current.primaryColor == palette.primary && _current.accentColor == palette.accent;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isSelected
                  ? const Color(0xFFFF8C00).withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  _update(
                    _current.copyWith(
                      primaryColor: palette.primary,
                      accentColor: palette.accent,
                      trimColor: palette.trim,
                      glassColor: palette.glass,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF8C00) : (isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          _buildSwatch(palette.primary),
                          const SizedBox(width: 4),
                          _buildSwatch(palette.accent),
                          const SizedBox(width: 4),
                          _buildSwatch(palette.trim),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          palette.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFFFF8C00) : null,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFFFF8C00), size: 18),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSwatch(Color c) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}
