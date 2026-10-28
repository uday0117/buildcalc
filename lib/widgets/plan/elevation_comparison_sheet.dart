import 'package:flutter/material.dart';

import '../../models/plan/elevation_models.dart';
import 'elevation_canvas_painter.dart';

class ElevationComparisonSheet extends StatefulWidget {
  final ElevationConfig currentConfig;
  final List<ElevationConfig> availableConfigs;
  final ValueChanged<ElevationConfig> onSelectConcept;

  const ElevationComparisonSheet({
    super.key,
    required this.currentConfig,
    required this.availableConfigs,
    required this.onSelectConcept,
  });

  @override
  State<ElevationComparisonSheet> createState() =>
      _ElevationComparisonSheetState();
}

class _ElevationComparisonSheetState extends State<ElevationComparisonSheet> {
  late ElevationConfig _conceptA;
  late ElevationConfig _conceptB;
  ElevationViewMode _viewMode = ElevationViewMode.illustrative;

  @override
  void initState() {
    super.initState();
    _conceptA = widget.currentConfig;

    // Pick a different default for Concept B
    final other = widget.availableConfigs.firstWhere(
      (c) => c.style != _conceptA.style,
      orElse: () => widget.availableConfigs.length > 1
          ? widget.availableConfigs[1]
          : _conceptA.copyWith(
              style: ElevationStyle.traditional,
              roofStyle: RoofStyle.pitchedTile,
              finishPreset: FinishPreset.exposedBrick,
            ),
    );
    _conceptB = other;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.compare_arrows_rounded,
                    color: Color(0xFFFF8C00),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Compare Facade Concepts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Mode toggle
                  SegmentedButton<ElevationViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: ElevationViewMode.illustrative,
                        icon: Icon(Icons.palette_outlined, size: 14),
                      ),
                      ButtonSegment(
                        value: ElevationViewMode.dimensioned,
                        icon: Icon(Icons.straighten_rounded, size: 14),
                      ),
                    ],
                    selected: {_viewMode},
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onSelectionChanged: (val) {
                      setState(() => _viewMode = val.first);
                    },
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Concept Selection Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFF8C00)),
                      ),
                      child: Text(
                        'A: ${_conceptA.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8C00),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ElevationConfig>(
                          value: _conceptB,
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          items: widget.availableConfigs.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                'B: ${c.name}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _conceptB = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Side-by-side visual preview canvases
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Canvas A
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            CustomPaint(
                              size: Size.infinite,
                              painter: ElevationCanvasPainter(
                                config: _conceptA,
                                mode: _viewMode,
                                isDark: isDark,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8C00),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CONCEPT A',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Canvas B
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            CustomPaint(
                              size: Size.infinite,
                              painter: ElevationCanvasPainter(
                                config: _conceptB,
                                mode: _viewMode,
                                isDark: isDark,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CONCEPT B',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Side-by-side Architectural Specification Table
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildCompareRow(
                      'Design Style',
                      _conceptA.style.label,
                      _conceptB.style.label,
                      isDark,
                    ),
                    _buildCompareRow(
                      'Floor Typology',
                      _conceptA.floorCountLabel,
                      _conceptB.floorCountLabel,
                      isDark,
                    ),
                    _buildCompareRow(
                      'Total Height',
                      '${_conceptA.totalHeightFeet.toStringAsFixed(1)} ft',
                      '${_conceptB.totalHeightFeet.toStringAsFixed(1)} ft',
                      isDark,
                    ),
                    _buildCompareRow(
                      'Wall Finish',
                      _conceptA.finishPreset.label,
                      _conceptB.finishPreset.label,
                      isDark,
                    ),
                    _buildCompareRow(
                      'Roof Silhouette',
                      _conceptA.roofStyle.label,
                      _conceptB.roofStyle.label,
                      isDark,
                    ),
                    _buildCompareRow(
                      'Window Style',
                      _conceptA.windowStyle.label,
                      _conceptB.windowStyle.label,
                      isDark,
                    ),
                    _buildCompareRow(
                      'Balcony Enclosure',
                      _conceptA.balconyOption.label,
                      _conceptB.balconyOption.label,
                      isDark,
                    ),
                    _buildColorCompareRow(
                      'Base Palette',
                      _conceptA,
                      _conceptB,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),

            // Footer Switch Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        widget.onSelectConcept(_conceptB);
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C00),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Switch to Concept B'),
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

  Widget _buildCompareRow(String label, String valA, String valB, bool isDark) {
    final isDifferent = valA != valB;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valA,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isDifferent ? FontWeight.bold : FontWeight.normal,
                color: isDifferent ? const Color(0xFFFF8C00) : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              valB,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isDifferent ? FontWeight.bold : FontWeight.normal,
                color: isDifferent ? Colors.blue.shade700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCompareRow(
    String label,
    ElevationConfig a,
    ElevationConfig b,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _dot(a.primaryColor),
                const SizedBox(width: 3),
                _dot(a.accentColor),
                const SizedBox(width: 3),
                _dot(a.trimColor),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                _dot(b.primaryColor),
                const SizedBox(width: 3),
                _dot(b.accentColor),
                const SizedBox(width: 3),
                _dot(b.trimColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}
