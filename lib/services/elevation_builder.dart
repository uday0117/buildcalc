import 'package:flutter/material.dart';

import '../models/plan/elevation_models.dart';
import '../models/plan/plan_models.dart';

class ElevationBuilder {
  /// Extract front facade geometry and characteristics from a floor plan
  static ElevationConfig buildElevationFromPlan(
    FloorPlan plan, {
    ElevationStyle style = ElevationStyle.modern,
  }) {
    final now = DateTime.now();

    // 1. Determine facade frontage from rooms or plot width
    double facadeWidth = plan.plotWidthFeet > 0 ? plan.plotWidthFeet : 30.0;
    if (plan.rooms.isNotEmpty) {
      double minX = double.infinity;
      double maxX = 0.0;
      for (final r in plan.rooms) {
        if (r.x < minX) minX = r.x;
        if (r.x + r.width > maxX) maxX = r.x + r.width;
      }
      final roomsSpan = maxX - minX;
      if (roomsSpan > 10.0) {
        facadeWidth = roomsSpan;
      }
    }

    // 2. Check for front balcony or porch rooms
    final hasBalconyRoom = plan.rooms.any((r) => r.type == RoomType.balcony);
    final hasFoyer = plan.rooms.any((r) => r.type == RoomType.foyer || r.name.toLowerCase().contains('foyer') || r.name.toLowerCase().contains('porch'));

    // 3. Select appropriate style attributes
    final palette = style == ElevationStyle.traditional
        ? ElevationColorPalette.warmTerracotta
        : style == ElevationStyle.minimalist
            ? ElevationColorPalette.minimalistMonochrome
            : style == ElevationStyle.contemporary
                ? ElevationColorPalette.contemporarySlate
                : ElevationColorPalette.modernIvoryWood;

    final windowStyle = style == ElevationStyle.traditional
        ? WindowStyle.traditionalMullion
        : style == ElevationStyle.minimalist
            ? WindowStyle.minimalistFrameless
            : WindowStyle.modernPicture;

    final roofStyle = style == ElevationStyle.traditional
        ? RoofStyle.pitchedTile
        : style == ElevationStyle.contemporary
            ? RoofStyle.terracePergola
            : RoofStyle.flatParapet;

    final finishPreset = style == ElevationStyle.traditional
        ? FinishPreset.exposedBrick
        : style == ElevationStyle.minimalist
            ? FinishPreset.exposedConcrete
            : style == ElevationStyle.contemporary
                ? FinishPreset.teakWoodSlat
                : FinishPreset.smoothPlaster;

    final balconyOption = hasBalconyRoom
        ? (style == ElevationStyle.traditional
            ? BalconyOption.ornateTraditional
            : BalconyOption.glassRailing)
        : BalconyOption.metalLouver;

    return ElevationConfig(
      id: 'elev_${plan.id}_${now.millisecondsSinceEpoch}',
      planId: plan.id,
      planName: plan.name,
      name: '${plan.name} - ${style.label} Concept',
      style: style,
      floorCount: 2,
      facadeWidthFeet: facadeWidth,
      floorHeightFeet: 10.0,
      plinthHeightFeet: 2.5,
      parapetHeightFeet: 3.5,
      primaryColor: palette.primary,
      accentColor: palette.accent,
      trimColor: palette.trim,
      glassColor: palette.glass,
      windowStyle: windowStyle,
      balconyOption: balconyOption,
      finishPreset: finishPreset,
      roofStyle: roofStyle,
      hasCarPorch: facadeWidth >= 26.0,
      hasEntrancePortico: hasFoyer || facadeWidth >= 20.0,
      notes: 'Generated from "${plan.name}" with frontage of ${facadeWidth.toStringAsFixed(1)} ft.',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get curated design variations for quick selection
  static List<ElevationConfig> getPresetVariations(FloorPlan plan) {
    return [
      buildElevationFromPlan(plan, style: ElevationStyle.modern),
      buildElevationFromPlan(plan, style: ElevationStyle.traditional),
      buildElevationFromPlan(plan, style: ElevationStyle.minimalist),
      buildElevationFromPlan(plan, style: ElevationStyle.contemporary),
    ];
  }

  /// Generate comprehensive architectural specification report text
  static String generateSpecificationReport(ElevationConfig config) {
    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('     BUILDCALC FRONT ELEVATION SPECIFICATION');
    buffer.writeln('====================================================');
    buffer.writeln('Project Plan:      ${config.planName}');
    buffer.writeln('Concept Name:      ${config.name}');
    buffer.writeln('Design Style:      ${config.style.label}');
    buffer.writeln('Floor Typology:    ${config.floorCountLabel}');
    buffer.writeln('');
    buffer.writeln('📐 DIMENSIONS & LEVELS:');
    buffer.writeln('• Facade Frontage:      ${config.facadeWidthFeet.toStringAsFixed(1)} ft');
    buffer.writeln('• Plinth Level (PL):    +${config.plinthHeightFeet.toStringAsFixed(1)} ft above Ground Level (GL)');
    buffer.writeln('• Floor-to-Floor Height: ${config.floorHeightFeet.toStringAsFixed(1)} ft typical');
    buffer.writeln('• Parapet / Roof Ridge: +${config.parapetHeightFeet.toStringAsFixed(1)} ft');
    buffer.writeln('• Total Height (GL-Top): ${config.totalHeightFeet.toStringAsFixed(1)} ft');
    buffer.writeln('');
    buffer.writeln('🎨 FINISHES & MATERIALS:');
    buffer.writeln('• Primary Facade Finish: ${config.finishPreset.label}');
    buffer.writeln('• Base Color Palette:    ${_colorHex(config.primaryColor)}');
    buffer.writeln('• Accent Feature Color:  ${_colorHex(config.accentColor)}');
    buffer.writeln('• Trim & Frame Color:    ${_colorHex(config.trimColor)}');
    buffer.writeln('• Glazing Tint:          ${_colorHex(config.glassColor)}');
    buffer.writeln('');
    buffer.writeln('🚪 FENESTRATIONS & OPENINGS:');
    buffer.writeln('• Window Styling:        ${config.windowStyle.label}');
    buffer.writeln('• Balcony Enclosure:     ${config.balconyOption.label}');
    buffer.writeln('• Roof Silhouette:       ${config.roofStyle.label}');
    buffer.writeln('• Covered Car Porch:     ${config.hasCarPorch ? "Included" : "None"}');
    buffer.writeln('• Entrance Portico:      ${config.hasEntrancePortico ? "Featured Entrance" : "Standard"}');
    if (config.notes.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('📝 ARCHITECTURAL NOTES:');
      buffer.writeln(config.notes);
    }
    buffer.writeln('');
    buffer.writeln('====================================================');
    buffer.writeln('⚠️ COMPLIANCE & LEGAL NOTICE:');
    buffer.writeln('This elevation preview is an illustrative design concept');
    buffer.writeln('intended for aesthetic and spatial visualization only.');
    buffer.writeln('It does not constitute structural engineering drawings,');
    buffer.writeln('working blueprints, or municipal building permit documents.');
    buffer.writeln('All dimensions, structural spans, and local setback');
    buffer.writeln('regulations must be verified by a licensed architect');
    buffer.writeln('or certified structural engineer prior to construction.');
    buffer.writeln('====================================================');

    return buffer.toString();
  }

  static String _colorHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}

