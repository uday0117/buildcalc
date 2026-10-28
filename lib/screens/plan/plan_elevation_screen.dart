import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/plan/elevation_models.dart';
import '../../models/plan/plan_models.dart';
import '../../services/elevation_builder.dart';
import '../../services/elevation_storage_service.dart';
import '../../widgets/plan/elevation_ai_studio_sheet.dart';
import '../../widgets/plan/elevation_comparison_sheet.dart';
import '../../widgets/plan/elevation_config_sheet.dart';
import '../../widgets/plan/elevation_interactive_viewport.dart';

class PlanElevationScreen extends StatefulWidget {
  final FloorPlan plan;
  final ElevationConfig? initialConfig;

  const PlanElevationScreen({
    super.key,
    required this.plan,
    this.initialConfig,
  });

  @override
  State<PlanElevationScreen> createState() => _PlanElevationScreenState();
}

class _PlanElevationScreenState extends State<PlanElevationScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  late ElevationConfig _config;
  ElevationViewMode _viewMode = ElevationViewMode.illustrative;
  List<ElevationConfig> _savedConcepts = [];
  bool _isBannerDismissed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _config =
        widget.initialConfig ??
        ElevationBuilder.buildElevationFromPlan(widget.plan);
    _loadSavedConcepts();
  }

  Future<void> _loadSavedConcepts() async {
    final list = await ElevationStorageService.getElevationsForPlan(
      widget.plan.id,
    );
    if (!mounted) return;
    setState(() {
      _savedConcepts = list;
    });
  }

  void _openConfigSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ElevationConfigSheet(
        initialConfig: _config,
        onConfigUpdated: (updated) {
          setState(() => _config = updated);
        },
      ),
    );
  }

  void _openComparisonSheet() {
    // Collect available comparison concepts: saved concepts + preset styles
    final presets = ElevationBuilder.getPresetVariations(widget.plan);
    final combined = <ElevationConfig>[..._savedConcepts];
    for (final p in presets) {
      if (!combined.any((c) => c.style == p.style && c.name == p.name)) {
        combined.add(p);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ElevationComparisonSheet(
        currentConfig: _config,
        availableConfigs: combined,
        onSelectConcept: (selected) {
          setState(() => _config = selected);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Switched to "${selected.name}"')),
          );
        },
      ),
    );
  }

  void _openAIStudioSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          ElevationAIStudioSheet(config: _config, onExportImage: _exportImage),
    );
  }

  Future<void> _saveConcept() async {
    final nameCtrl = TextEditingController(text: _config.name);
    final notesCtrl = TextEditingController(text: _config.notes);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Elevation Concept'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save this facade concept to compare later or link with this floor plan.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Concept Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes & Finishes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
            ),
            child: const Text('Save Concept'),
          ),
        ],
      ),
    );

    if (shouldSave == true && mounted) {
      setState(() => _isSaving = true);
      final updated = _config.copyWith(
        name: nameCtrl.text.trim().isNotEmpty
            ? nameCtrl.text.trim()
            : _config.name,
        notes: notesCtrl.text.trim(),
      );
      await ElevationStorageService.saveElevation(updated);
      await _loadSavedConcepts();
      if (!mounted) return;
      setState(() {
        _config = updated;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Elevation "${updated.name}" saved successfully!'),
        ),
      );
    }
  }

  Future<void> _exportImage() async {
    try {
      final boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = File(
        '${tempDir.path}/elevation_${widget.plan.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: '${_config.name} - ${widget.plan.name} Elevation Design Preview',
      );
    } catch (e) {
      // Fallback to text specification share if file sharing fails
      final report = ElevationBuilder.generateSpecificationReport(_config);
      await Share.share(
        report,
        subject: '${_config.name} - Front Elevation Specification',
      );
    }
  }

  void _showComplianceInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.info_outline_rounded,
          color: Color(0xFFFF8C00),
          size: 36,
        ),
        title: const Text('Architectural Elevation Notice'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Illustrative Concepts vs Dimensioned Drawings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text(
              '• Illustrative Design Mode provides color harmony, material textures, facade massing, and artistic visualization.\n\n'
              '• CAD Elevation Draft Mode shows true proportional heights, floor datum levels (GL, PL, FF, SF), and dimension chains.\n\n'
              '• AI-generated facade previews are illustrative artistic impressions and are NOT structurally certified or geometrically construction-ready.\n\n'
              '• Always consult a licensed civil engineer or architect for structural load calculations and local building bye-law compliance.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
            ),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = widget.plan;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    plan.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _config.style.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${_config.facadeWidthFeet.toStringAsFixed(1)} ft Frontage • ${_config.floorCountLabel}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          // Comparison Action
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: 'Compare Facade Concepts',
            onPressed: _openComparisonSheet,
          ),
          // AI Studio & Export
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFF8C00),
            ),
            tooltip: 'AI Concept Studio & Export',
            onPressed: _openAIStudioSheet,
          ),
          // Save Concept
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bookmark_border_rounded),
            tooltip: 'Save Concept',
            onPressed: _isSaving ? null : _saveConcept,
          ),
          // Info Dialog
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Compliance Info',
            onPressed: _showComplianceInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Informational Notice Banner
            if (!_isBannerDismissed)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.villa_outlined,
                      size: 18,
                      color: Color(0xFFFF8C00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Illustrative facade based on ${plan.name} (${_config.facadeWidthFeet.toStringAsFixed(0)} ft frontage). Toggle CAD mode for structural datum levels.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          setState(() => _isBannerDismissed = true),
                    ),
                  ],
                ),
              ),

            // Main Interactive Elevation Canvas with RepaintBoundary for PNG export
            Expanded(
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: ElevationInteractiveViewport(
                  config: _config,
                  mode: _viewMode,
                  onModeChanged: (mode) {
                    setState(() => _viewMode = mode);
                  },
                ),
              ),
            ),

            // Bottom Styling & Presets Bar
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Style Chips Row & Customize Button
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ElevationStyle.values.map((style) {
                              final isSelected = _config.style == style;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  avatar: Icon(
                                    style.icon,
                                    size: 14,
                                    color: isSelected ? Colors.white : null,
                                  ),
                                  label: Text(
                                    style.label,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFFFF8C00),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : null,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      final palette =
                                          style == ElevationStyle.traditional
                                          ? ElevationColorPalette.warmTerracotta
                                          : style == ElevationStyle.minimalist
                                          ? ElevationColorPalette
                                                .minimalistMonochrome
                                          : style == ElevationStyle.contemporary
                                          ? ElevationColorPalette
                                                .contemporarySlate
                                          : ElevationColorPalette
                                                .modernIvoryWood;
                                      setState(() {
                                        _config = _config.copyWith(
                                          style: style,
                                          primaryColor: palette.primary,
                                          accentColor: palette.accent,
                                          trimColor: palette.trim,
                                          glassColor: palette.glass,
                                          roofStyle:
                                              style ==
                                                  ElevationStyle.traditional
                                              ? RoofStyle.pitchedTile
                                              : RoofStyle.flatParapet,
                                          finishPreset:
                                              style ==
                                                  ElevationStyle.traditional
                                              ? FinishPreset.exposedBrick
                                              : FinishPreset.smoothPlaster,
                                        );
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Customize button
                      FilledButton.tonalIcon(
                        onPressed: _openConfigSheet,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text(
                          'Customize',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
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
