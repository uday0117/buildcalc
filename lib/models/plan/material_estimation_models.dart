import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'plan_models.dart';

/// Categories of construction materials
enum MaterialCategory {
  masonry('Masonry (Bricks & Blocks)', Icons.view_module_rounded, Color(0xFFC05C46)),
  mortar('Mortar & Cementitious Mixes', Icons.format_paint_rounded, Color(0xFF64748B)),
  plaster('Wall & Ceiling Plaster', Icons.brush_rounded, Color(0xFF78716C)),
  paint('Paints & Primers', Icons.palette_rounded, Color(0xFF0284C7)),
  tile('Flooring & Wall Tiles', Icons.grid_view_rounded, Color(0xFF0D9488)),
  concrete('Explicit Concrete Elements', Icons.foundation_rounded, Color(0xFF4F46E5));

  final String title;
  final IconData icon;
  final Color color;

  const MaterialCategory(this.title, this.icon, this.color);
}

/// Supported masonry unit types with realistic default dimensions (in inches)
enum MasonryUnitType {
  standardRedBrick(
    label: 'Standard Red Clay Brick (9" × 4.25" × 2.75")',
    lengthInches: 9.0,
    widthInches: 4.25,
    heightInches: 2.75,
  ),
  modularBrick(
    label: 'Modular Clay Brick (190 × 90 × 90 mm)',
    lengthInches: 7.48, // 190 mm
    widthInches: 3.54, // 90 mm
    heightInches: 3.54, // 90 mm
  ),
  flyAshBrick(
    label: 'Fly Ash Brick (9" × 4" × 3")',
    lengthInches: 9.0,
    widthInches: 4.0,
    heightInches: 3.0,
  ),
  aacBlock8Inch(
    label: 'AAC Block (24" × 8" × 8")',
    lengthInches: 24.0,
    widthInches: 8.0,
    heightInches: 8.0,
  ),
  aacBlock4Inch(
    label: 'AAC Block (24" × 8" × 4")',
    lengthInches: 24.0,
    widthInches: 4.0,
    heightInches: 8.0,
  ),
  concreteHollowBlock(
    label: 'Concrete Hollow Block (16" × 8" × 8")',
    lengthInches: 16.0,
    widthInches: 8.0,
    heightInches: 8.0,
  ),
  custom(
    label: 'Custom Block / Brick Dimensions',
    lengthInches: 9.0,
    widthInches: 4.25,
    heightInches: 2.75,
  );

  final String label;
  final double lengthInches;
  final double widthInches;
  final double heightInches;

  const MasonryUnitType({
    required this.label,
    required this.lengthInches,
    required this.widthInches,
    required this.heightInches,
  });
}

/// Standard Mortar Mix Ratios (Cement : Sand)
enum MortarMixRatio {
  ratio1_3('1:3 (High Strength / Foundation)', 1, 3),
  ratio1_4('1:4 (Load-bearing / Plaster)', 1, 4),
  ratio1_5('1:5 (Standard Masonry)', 1, 5),
  ratio1_6('1:6 (Partition Wall / General)', 1, 6);

  final String label;
  final double cementParts;
  final double sandParts;

  const MortarMixRatio(this.label, this.cementParts, this.sandParts);

  double get totalParts => cementParts + sandParts;
  double get cementFraction => cementParts / totalParts;
  double get sandFraction => sandParts / totalParts;
}

/// Standard Concrete Grade Mixes (Cement : Sand : Coarse Aggregate)
enum ConcreteGradeMix {
  m15('M15 (1 : 2 : 4) - PCC & Bedding', 1, 2, 4),
  m20('M20 (1 : 1.5 : 3) - Standard RCC Slabs & Beams', 1, 1.5, 3),
  m25('M25 (1 : 1 : 2) - Heavy Duty Structural', 1, 1, 2);

  final String label;
  final double cementParts;
  final double sandParts;
  final double aggregateParts;

  const ConcreteGradeMix(this.label, this.cementParts, this.sandParts, this.aggregateParts);

  double get totalParts => cementParts + sandParts + aggregateParts;
  double get cementFraction => cementParts / totalParts;
  double get sandFraction => sandParts / totalParts;
  double get aggregateFraction => aggregateParts / totalParts;
}

/// Configurable assumptions and rates for material estimation
class MaterialEstimationAssumptions {
  // --- Dimensional & Wall Assumptions ---
  final double wallHeightFeet;
  final double exteriorWallThicknessFeet;
  final double interiorWallThicknessFeet;

  // --- Masonry Assumptions ---
  final MasonryUnitType masonryType;
  final double customBrickLengthInches;
  final double customBrickWidthInches;
  final double customBrickHeightInches;
  final double mortarJointThicknessInches; // e.g. 10 mm = 0.394"
  final MortarMixRatio mortarMix;
  final double brickWastagePercent; // e.g. 7%
  final double mortarDryFactor; // standard 1.33

  // --- Plaster Assumptions ---
  final double interiorPlasterThicknessInches; // e.g. 0.5" = 12 mm
  final double exteriorPlasterThicknessInches; // e.g. 0.75" = 18 mm
  final MortarMixRatio plasterMix;
  final bool includeCeilingPlaster;
  final double plasterWastagePercent; // e.g. 8%
  final double plasterDryFactor; // standard 1.35

  // --- Paint Assumptions ---
  final int interiorPaintCoats;
  final int exteriorPaintCoats;
  final double interiorPaintCoverageSqFtPerLiter; // e.g. 110 sq ft/L for 2 coats
  final double exteriorPaintCoverageSqFtPerLiter; // e.g. 90 sq ft/L for 2 coats
  final double primerCoverageSqFtPerLiter; // e.g. 140 sq ft/L
  final bool includePrimer;
  final bool includeCeilingPaint;
  final double paintWastagePercent; // e.g. 5%

  // --- Tile Assumptions ---
  final double floorTileLengthInches;
  final double floorTileWidthInches;
  final int tilesPerBox;
  final double tileWastagePercent; // e.g. 10%
  final bool includeBathroomWallTiles;
  final double bathroomDadoHeightFeet; // e.g. 7 ft
  final bool includeKitchenBacksplash;
  final double kitchenBacksplashAreaSqFt; // e.g. 30 sq ft

  // --- Explicit Concrete Elements Only ---
  final bool includeRoofSlab;
  final double roofSlabThicknessInches; // e.g. 5" = 0.417 ft
  final double roofSlabOverhangFeet; // e.g. 1.0 ft
  final bool includeLintelBeams;
  final double lintelDepthInches; // e.g. 6" = 0.5 ft
  final double lintelBearingFeet; // bearing length each side (e.g. 0.5 ft)
  final bool includePlinthBeam;
  final double plinthBeamWidthInches; // e.g. 9"
  final double plinthBeamDepthInches; // e.g. 12"
  final ConcreteGradeMix concreteGrade;
  final double concreteDryFactor; // standard 1.54
  final double concreteWastagePercent; // e.g. 5%

  // --- User-Provided Unit Rates & Currency ---
  final String currencySymbol;
  final double brickRatePerUnit; // price per brick/block
  final double cementRatePerBag; // price per 50kg bag
  final double sandRatePerCuFt; // price per cu ft
  final double aggregateRatePerCuFt; // price per cu ft
  final double interiorPaintRatePerLiter;
  final double exteriorPaintRatePerLiter;
  final double primerRatePerLiter;
  final double floorTileRatePerSqFt;
  final double wallTileRatePerSqFt;

  const MaterialEstimationAssumptions({
    this.wallHeightFeet = 10.0,
    this.exteriorWallThicknessFeet = 0.75, // 9 inches
    this.interiorWallThicknessFeet = 0.375, // 4.5 inches
    this.masonryType = MasonryUnitType.standardRedBrick,
    this.customBrickLengthInches = 9.0,
    this.customBrickWidthInches = 4.25,
    this.customBrickHeightInches = 2.75,
    this.mortarJointThicknessInches = 0.394, // 10 mm
    this.mortarMix = MortarMixRatio.ratio1_5,
    this.brickWastagePercent = 7.0,
    this.mortarDryFactor = 1.33,
    this.interiorPlasterThicknessInches = 0.5, // 12 mm
    this.exteriorPlasterThicknessInches = 0.75, // 18 mm
    this.plasterMix = MortarMixRatio.ratio1_5,
    this.includeCeilingPlaster = true,
    this.plasterWastagePercent = 8.0,
    this.plasterDryFactor = 1.35,
    this.interiorPaintCoats = 2,
    this.exteriorPaintCoats = 2,
    this.interiorPaintCoverageSqFtPerLiter = 110.0,
    this.exteriorPaintCoverageSqFtPerLiter = 90.0,
    this.primerCoverageSqFtPerLiter = 140.0,
    this.includePrimer = true,
    this.includeCeilingPaint = true,
    this.paintWastagePercent = 5.0,
    this.floorTileLengthInches = 24.0, // 2x2 ft
    this.floorTileWidthInches = 24.0,
    this.tilesPerBox = 4,
    this.tileWastagePercent = 10.0,
    this.includeBathroomWallTiles = true,
    this.bathroomDadoHeightFeet = 7.0,
    this.includeKitchenBacksplash = true,
    this.kitchenBacksplashAreaSqFt = 30.0,
    this.includeRoofSlab = true,
    this.roofSlabThicknessInches = 5.0, // 5 inches
    this.roofSlabOverhangFeet = 1.0,
    this.includeLintelBeams = true,
    this.lintelDepthInches = 6.0,
    this.lintelBearingFeet = 0.5,
    this.includePlinthBeam = false,
    this.plinthBeamWidthInches = 9.0,
    this.plinthBeamDepthInches = 12.0,
    this.concreteGrade = ConcreteGradeMix.m20,
    this.concreteDryFactor = 1.54,
    this.concreteWastagePercent = 5.0,
    this.currencySymbol = '₹',
    this.brickRatePerUnit = 9.5,
    this.cementRatePerBag = 380.0,
    this.sandRatePerCuFt = 45.0,
    this.aggregateRatePerCuFt = 38.0,
    this.interiorPaintRatePerLiter = 320.0,
    this.exteriorPaintRatePerLiter = 410.0,
    this.primerRatePerLiter = 180.0,
    this.floorTileRatePerSqFt = 65.0,
    this.wallTileRatePerSqFt = 55.0,
  });

  /// Active brick length in inches
  double get effectiveBrickLengthInches =>
      masonryType == MasonryUnitType.custom
          ? customBrickLengthInches
          : masonryType.lengthInches;

  /// Active brick width in inches
  double get effectiveBrickWidthInches =>
      masonryType == MasonryUnitType.custom
          ? customBrickWidthInches
          : masonryType.widthInches;

  /// Active brick height in inches
  double get effectiveBrickHeightInches =>
      masonryType == MasonryUnitType.custom
          ? customBrickHeightInches
          : masonryType.heightInches;

  /// Volume of 1 brick in cubic feet (without mortar)
  double get brickVolumeCuFt =>
      (effectiveBrickLengthInches / 12.0) *
      (effectiveBrickWidthInches / 12.0) *
      (effectiveBrickHeightInches / 12.0);

  /// Volume of 1 brick with mortar joint in cubic feet
  double get brickWithMortarVolumeCuFt {
    final l = (effectiveBrickLengthInches + mortarJointThicknessInches) / 12.0;
    final w = (effectiveBrickWidthInches + mortarJointThicknessInches) / 12.0;
    final h = (effectiveBrickHeightInches + mortarJointThicknessInches) / 12.0;
    return l * w * h;
  }

  /// Area of 1 floor tile in square feet
  double get floorTileAreaSqFt =>
      (floorTileLengthInches / 12.0) * (floorTileWidthInches / 12.0);

  MaterialEstimationAssumptions copyWith({
    double? wallHeightFeet,
    double? exteriorWallThicknessFeet,
    double? interiorWallThicknessFeet,
    MasonryUnitType? masonryType,
    double? customBrickLengthInches,
    double? customBrickWidthInches,
    double? customBrickHeightInches,
    double? mortarJointThicknessInches,
    MortarMixRatio? mortarMix,
    double? brickWastagePercent,
    double? mortarDryFactor,
    double? interiorPlasterThicknessInches,
    double? exteriorPlasterThicknessInches,
    MortarMixRatio? plasterMix,
    bool? includeCeilingPlaster,
    double? plasterWastagePercent,
    double? plasterDryFactor,
    int? interiorPaintCoats,
    int? exteriorPaintCoats,
    double? interiorPaintCoverageSqFtPerLiter,
    double? exteriorPaintCoverageSqFtPerLiter,
    double? primerCoverageSqFtPerLiter,
    bool? includePrimer,
    bool? includeCeilingPaint,
    double? paintWastagePercent,
    double? floorTileLengthInches,
    double? floorTileWidthInches,
    int? tilesPerBox,
    double? tileWastagePercent,
    bool? includeBathroomWallTiles,
    double? bathroomDadoHeightFeet,
    bool? includeKitchenBacksplash,
    double? kitchenBacksplashAreaSqFt,
    bool? includeRoofSlab,
    double? roofSlabThicknessInches,
    double? roofSlabOverhangFeet,
    bool? includeLintelBeams,
    double? lintelDepthInches,
    double? lintelBearingFeet,
    bool? includePlinthBeam,
    double? plinthBeamWidthInches,
    double? plinthBeamDepthInches,
    ConcreteGradeMix? concreteGrade,
    double? concreteDryFactor,
    double? concreteWastagePercent,
    String? currencySymbol,
    double? brickRatePerUnit,
    double? cementRatePerBag,
    double? sandRatePerCuFt,
    double? aggregateRatePerCuFt,
    double? interiorPaintRatePerLiter,
    double? exteriorPaintRatePerLiter,
    double? primerRatePerLiter,
    double? floorTileRatePerSqFt,
    double? wallTileRatePerSqFt,
  }) {
    return MaterialEstimationAssumptions(
      wallHeightFeet: wallHeightFeet ?? this.wallHeightFeet,
      exteriorWallThicknessFeet: exteriorWallThicknessFeet ?? this.exteriorWallThicknessFeet,
      interiorWallThicknessFeet: interiorWallThicknessFeet ?? this.interiorWallThicknessFeet,
      masonryType: masonryType ?? this.masonryType,
      customBrickLengthInches: customBrickLengthInches ?? this.customBrickLengthInches,
      customBrickWidthInches: customBrickWidthInches ?? this.customBrickWidthInches,
      customBrickHeightInches: customBrickHeightInches ?? this.customBrickHeightInches,
      mortarJointThicknessInches: mortarJointThicknessInches ?? this.mortarJointThicknessInches,
      mortarMix: mortarMix ?? this.mortarMix,
      brickWastagePercent: brickWastagePercent ?? this.brickWastagePercent,
      mortarDryFactor: mortarDryFactor ?? this.mortarDryFactor,
      interiorPlasterThicknessInches: interiorPlasterThicknessInches ?? this.interiorPlasterThicknessInches,
      exteriorPlasterThicknessInches: exteriorPlasterThicknessInches ?? this.exteriorPlasterThicknessInches,
      plasterMix: plasterMix ?? this.plasterMix,
      includeCeilingPlaster: includeCeilingPlaster ?? this.includeCeilingPlaster,
      plasterWastagePercent: plasterWastagePercent ?? this.plasterWastagePercent,
      plasterDryFactor: plasterDryFactor ?? this.plasterDryFactor,
      interiorPaintCoats: interiorPaintCoats ?? this.interiorPaintCoats,
      exteriorPaintCoats: exteriorPaintCoats ?? this.exteriorPaintCoats,
      interiorPaintCoverageSqFtPerLiter: interiorPaintCoverageSqFtPerLiter ?? this.interiorPaintCoverageSqFtPerLiter,
      exteriorPaintCoverageSqFtPerLiter: exteriorPaintCoverageSqFtPerLiter ?? this.exteriorPaintCoverageSqFtPerLiter,
      primerCoverageSqFtPerLiter: primerCoverageSqFtPerLiter ?? this.primerCoverageSqFtPerLiter,
      includePrimer: includePrimer ?? this.includePrimer,
      includeCeilingPaint: includeCeilingPaint ?? this.includeCeilingPaint,
      paintWastagePercent: paintWastagePercent ?? this.paintWastagePercent,
      floorTileLengthInches: floorTileLengthInches ?? this.floorTileLengthInches,
      floorTileWidthInches: floorTileWidthInches ?? this.floorTileWidthInches,
      tilesPerBox: tilesPerBox ?? this.tilesPerBox,
      tileWastagePercent: tileWastagePercent ?? this.tileWastagePercent,
      includeBathroomWallTiles: includeBathroomWallTiles ?? this.includeBathroomWallTiles,
      bathroomDadoHeightFeet: bathroomDadoHeightFeet ?? this.bathroomDadoHeightFeet,
      includeKitchenBacksplash: includeKitchenBacksplash ?? this.includeKitchenBacksplash,
      kitchenBacksplashAreaSqFt: kitchenBacksplashAreaSqFt ?? this.kitchenBacksplashAreaSqFt,
      includeRoofSlab: includeRoofSlab ?? this.includeRoofSlab,
      roofSlabThicknessInches: roofSlabThicknessInches ?? this.roofSlabThicknessInches,
      roofSlabOverhangFeet: roofSlabOverhangFeet ?? this.roofSlabOverhangFeet,
      includeLintelBeams: includeLintelBeams ?? this.includeLintelBeams,
      lintelDepthInches: lintelDepthInches ?? this.lintelDepthInches,
      lintelBearingFeet: lintelBearingFeet ?? this.lintelBearingFeet,
      includePlinthBeam: includePlinthBeam ?? this.includePlinthBeam,
      plinthBeamWidthInches: plinthBeamWidthInches ?? this.plinthBeamWidthInches,
      plinthBeamDepthInches: plinthBeamDepthInches ?? this.plinthBeamDepthInches,
      concreteGrade: concreteGrade ?? this.concreteGrade,
      concreteDryFactor: concreteDryFactor ?? this.concreteDryFactor,
      concreteWastagePercent: concreteWastagePercent ?? this.concreteWastagePercent,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      brickRatePerUnit: brickRatePerUnit ?? this.brickRatePerUnit,
      cementRatePerBag: cementRatePerBag ?? this.cementRatePerBag,
      sandRatePerCuFt: sandRatePerCuFt ?? this.sandRatePerCuFt,
      aggregateRatePerCuFt: aggregateRatePerCuFt ?? this.aggregateRatePerCuFt,
      interiorPaintRatePerLiter: interiorPaintRatePerLiter ?? this.interiorPaintRatePerLiter,
      exteriorPaintRatePerLiter: exteriorPaintRatePerLiter ?? this.exteriorPaintRatePerLiter,
      primerRatePerLiter: primerRatePerLiter ?? this.primerRatePerLiter,
      floorTileRatePerSqFt: floorTileRatePerSqFt ?? this.floorTileRatePerSqFt,
      wallTileRatePerSqFt: wallTileRatePerSqFt ?? this.wallTileRatePerSqFt,
    );
  }

  Map<String, dynamic> toJson() => {
        'wallHeightFeet': wallHeightFeet,
        'exteriorWallThicknessFeet': exteriorWallThicknessFeet,
        'interiorWallThicknessFeet': interiorWallThicknessFeet,
        'masonryType': masonryType.name,
        'customBrickLengthInches': customBrickLengthInches,
        'customBrickWidthInches': customBrickWidthInches,
        'customBrickHeightInches': customBrickHeightInches,
        'mortarJointThicknessInches': mortarJointThicknessInches,
        'mortarMix': mortarMix.name,
        'brickWastagePercent': brickWastagePercent,
        'mortarDryFactor': mortarDryFactor,
        'interiorPlasterThicknessInches': interiorPlasterThicknessInches,
        'exteriorPlasterThicknessInches': exteriorPlasterThicknessInches,
        'plasterMix': plasterMix.name,
        'includeCeilingPlaster': includeCeilingPlaster,
        'plasterWastagePercent': plasterWastagePercent,
        'plasterDryFactor': plasterDryFactor,
        'interiorPaintCoats': interiorPaintCoats,
        'exteriorPaintCoats': exteriorPaintCoats,
        'interiorPaintCoverageSqFtPerLiter': interiorPaintCoverageSqFtPerLiter,
        'exteriorPaintCoverageSqFtPerLiter': exteriorPaintCoverageSqFtPerLiter,
        'primerCoverageSqFtPerLiter': primerCoverageSqFtPerLiter,
        'includePrimer': includePrimer,
        'includeCeilingPaint': includeCeilingPaint,
        'paintWastagePercent': paintWastagePercent,
        'floorTileLengthInches': floorTileLengthInches,
        'floorTileWidthInches': floorTileWidthInches,
        'tilesPerBox': tilesPerBox,
        'tileWastagePercent': tileWastagePercent,
        'includeBathroomWallTiles': includeBathroomWallTiles,
        'bathroomDadoHeightFeet': bathroomDadoHeightFeet,
        'includeKitchenBacksplash': includeKitchenBacksplash,
        'kitchenBacksplashAreaSqFt': kitchenBacksplashAreaSqFt,
        'includeRoofSlab': includeRoofSlab,
        'roofSlabThicknessInches': roofSlabThicknessInches,
        'roofSlabOverhangFeet': roofSlabOverhangFeet,
        'includeLintelBeams': includeLintelBeams,
        'lintelDepthInches': lintelDepthInches,
        'lintelBearingFeet': lintelBearingFeet,
        'includePlinthBeam': includePlinthBeam,
        'plinthBeamWidthInches': plinthBeamWidthInches,
        'plinthBeamDepthInches': plinthBeamDepthInches,
        'concreteGrade': concreteGrade.name,
        'concreteDryFactor': concreteDryFactor,
        'concreteWastagePercent': concreteWastagePercent,
        'currencySymbol': currencySymbol,
        'brickRatePerUnit': brickRatePerUnit,
        'cementRatePerBag': cementRatePerBag,
        'sandRatePerCuFt': sandRatePerCuFt,
        'aggregateRatePerCuFt': aggregateRatePerCuFt,
        'interiorPaintRatePerLiter': interiorPaintRatePerLiter,
        'exteriorPaintRatePerLiter': exteriorPaintRatePerLiter,
        'primerRatePerLiter': primerRatePerLiter,
        'floorTileRatePerSqFt': floorTileRatePerSqFt,
        'wallTileRatePerSqFt': wallTileRatePerSqFt,
      };

  factory MaterialEstimationAssumptions.fromJson(Map<String, dynamic> json) =>
      MaterialEstimationAssumptions(
        wallHeightFeet: (json['wallHeightFeet'] as num?)?.toDouble() ?? 10.0,
        exteriorWallThicknessFeet:
            (json['exteriorWallThicknessFeet'] as num?)?.toDouble() ?? 0.75,
        interiorWallThicknessFeet:
            (json['interiorWallThicknessFeet'] as num?)?.toDouble() ?? 0.375,
        masonryType: MasonryUnitType.values.firstWhere(
          (e) => e.name == json['masonryType'],
          orElse: () => MasonryUnitType.standardRedBrick,
        ),
        customBrickLengthInches:
            (json['customBrickLengthInches'] as num?)?.toDouble() ?? 9.0,
        customBrickWidthInches:
            (json['customBrickWidthInches'] as num?)?.toDouble() ?? 4.25,
        customBrickHeightInches:
            (json['customBrickHeightInches'] as num?)?.toDouble() ?? 2.75,
        mortarJointThicknessInches:
            (json['mortarJointThicknessInches'] as num?)?.toDouble() ?? 0.394,
        mortarMix: MortarMixRatio.values.firstWhere(
          (e) => e.name == json['mortarMix'],
          orElse: () => MortarMixRatio.ratio1_5,
        ),
        brickWastagePercent:
            (json['brickWastagePercent'] as num?)?.toDouble() ?? 7.0,
        mortarDryFactor: (json['mortarDryFactor'] as num?)?.toDouble() ?? 1.33,
        interiorPlasterThicknessInches:
            (json['interiorPlasterThicknessInches'] as num?)?.toDouble() ?? 0.5,
        exteriorPlasterThicknessInches:
            (json['exteriorPlasterThicknessInches'] as num?)?.toDouble() ?? 0.75,
        plasterMix: MortarMixRatio.values.firstWhere(
          (e) => e.name == json['plasterMix'],
          orElse: () => MortarMixRatio.ratio1_5,
        ),
        includeCeilingPlaster: json['includeCeilingPlaster'] as bool? ?? true,
        plasterWastagePercent:
            (json['plasterWastagePercent'] as num?)?.toDouble() ?? 8.0,
        plasterDryFactor:
            (json['plasterDryFactor'] as num?)?.toDouble() ?? 1.35,
        interiorPaintCoats: (json['interiorPaintCoats'] as num?)?.toInt() ?? 2,
        exteriorPaintCoats: (json['exteriorPaintCoats'] as num?)?.toInt() ?? 2,
        interiorPaintCoverageSqFtPerLiter:
            (json['interiorPaintCoverageSqFtPerLiter'] as num?)?.toDouble() ?? 110.0,
        exteriorPaintCoverageSqFtPerLiter:
            (json['exteriorPaintCoverageSqFtPerLiter'] as num?)?.toDouble() ?? 90.0,
        primerCoverageSqFtPerLiter:
            (json['primerCoverageSqFtPerLiter'] as num?)?.toDouble() ?? 140.0,
        includePrimer: json['includePrimer'] as bool? ?? true,
        includeCeilingPaint: json['includeCeilingPaint'] as bool? ?? true,
        paintWastagePercent:
            (json['paintWastagePercent'] as num?)?.toDouble() ?? 5.0,
        floorTileLengthInches:
            (json['floorTileLengthInches'] as num?)?.toDouble() ?? 24.0,
        floorTileWidthInches:
            (json['floorTileWidthInches'] as num?)?.toDouble() ?? 24.0,
        tilesPerBox: (json['tilesPerBox'] as num?)?.toInt() ?? 4,
        tileWastagePercent:
            (json['tileWastagePercent'] as num?)?.toDouble() ?? 10.0,
        includeBathroomWallTiles:
            json['includeBathroomWallTiles'] as bool? ?? true,
        bathroomDadoHeightFeet:
            (json['bathroomDadoHeightFeet'] as num?)?.toDouble() ?? 7.0,
        includeKitchenBacksplash:
            json['includeKitchenBacksplash'] as bool? ?? true,
        kitchenBacksplashAreaSqFt:
            (json['kitchenBacksplashAreaSqFt'] as num?)?.toDouble() ?? 30.0,
        includeRoofSlab: json['includeRoofSlab'] as bool? ?? true,
        roofSlabThicknessInches:
            (json['roofSlabThicknessInches'] as num?)?.toDouble() ?? 5.0,
        roofSlabOverhangFeet:
            (json['roofSlabOverhangFeet'] as num?)?.toDouble() ?? 1.0,
        includeLintelBeams: json['includeLintelBeams'] as bool? ?? true,
        lintelDepthInches:
            (json['lintelDepthInches'] as num?)?.toDouble() ?? 6.0,
        lintelBearingFeet:
            (json['lintelBearingFeet'] as num?)?.toDouble() ?? 0.5,
        includePlinthBeam: json['includePlinthBeam'] as bool? ?? false,
        plinthBeamWidthInches:
            (json['plinthBeamWidthInches'] as num?)?.toDouble() ?? 9.0,
        plinthBeamDepthInches:
            (json['plinthBeamDepthInches'] as num?)?.toDouble() ?? 12.0,
        concreteGrade: ConcreteGradeMix.values.firstWhere(
          (e) => e.name == json['concreteGrade'],
          orElse: () => ConcreteGradeMix.m20,
        ),
        concreteDryFactor:
            (json['concreteDryFactor'] as num?)?.toDouble() ?? 1.54,
        concreteWastagePercent:
            (json['concreteWastagePercent'] as num?)?.toDouble() ?? 5.0,
        currencySymbol: json['currencySymbol'] as String? ?? '₹',
        brickRatePerUnit:
            (json['brickRatePerUnit'] as num?)?.toDouble() ?? 9.5,
        cementRatePerBag:
            (json['cementRatePerBag'] as num?)?.toDouble() ?? 380.0,
        sandRatePerCuFt:
            (json['sandRatePerCuFt'] as num?)?.toDouble() ?? 45.0,
        aggregateRatePerCuFt:
            (json['aggregateRatePerCuFt'] as num?)?.toDouble() ?? 38.0,
        interiorPaintRatePerLiter:
            (json['interiorPaintRatePerLiter'] as num?)?.toDouble() ?? 320.0,
        exteriorPaintRatePerLiter:
            (json['exteriorPaintRatePerLiter'] as num?)?.toDouble() ?? 410.0,
        primerRatePerLiter:
            (json['primerRatePerLiter'] as num?)?.toDouble() ?? 180.0,
        floorTileRatePerSqFt:
            (json['floorTileRatePerSqFt'] as num?)?.toDouble() ?? 65.0,
        wallTileRatePerSqFt:
            (json['wallTileRatePerSqFt'] as num?)?.toDouble() ?? 55.0,
      );
}

/// A single calculated material line item with formula breakdown and cost
class MaterialLineItem {
  final MaterialCategory category;
  final String name;
  final double netQuantity;
  final double wastagePercent;
  final double totalQuantity;
  final String unit;
  final double unitRate;
  final double totalCost;
  final String formulaBreakdown;
  final String assumptionsSummary;

  const MaterialLineItem({
    required this.category,
    required this.name,
    required this.netQuantity,
    required this.wastagePercent,
    required this.totalQuantity,
    required this.unit,
    required this.unitRate,
    required this.totalCost,
    required this.formulaBreakdown,
    required this.assumptionsSummary,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'name': name,
        'netQuantity': netQuantity,
        'wastagePercent': wastagePercent,
        'totalQuantity': totalQuantity,
        'unit': unit,
        'unitRate': unitRate,
        'totalCost': totalCost,
        'formulaBreakdown': formulaBreakdown,
        'assumptionsSummary': assumptionsSummary,
      };

  factory MaterialLineItem.fromJson(Map<String, dynamic> json) =>
      MaterialLineItem(
        category: MaterialCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => MaterialCategory.masonry,
        ),
        name: json['name'] as String,
        netQuantity: (json['netQuantity'] as num).toDouble(),
        wastagePercent: (json['wastagePercent'] as num).toDouble(),
        totalQuantity: (json['totalQuantity'] as num).toDouble(),
        unit: json['unit'] as String,
        unitRate: (json['unitRate'] as num).toDouble(),
        totalCost: (json['totalCost'] as num).toDouble(),
        formulaBreakdown: json['formulaBreakdown'] as String,
        assumptionsSummary: json['assumptionsSummary'] as String,
      );
}

/// Room-wise floor, wall surface and opening breakdown
class RoomQuantityBreakdown {
  final String roomId;
  final String roomName;
  final RoomType roomType;
  final double widthFeet;
  final double lengthFeet;
  final double carpetAreaSqFt;
  final double perimeterFeet;
  final int openingsCount;
  final double openingsAreaSqFt;
  final double grossWallSurfaceSqFt; // 4 interior wall surfaces
  final double netWallSurfaceSqFt; // gross - openings
  final double ceilingAreaSqFt;
  final double floorTileAreaSqFt;
  final double wallTileAreaSqFt;

  const RoomQuantityBreakdown({
    required this.roomId,
    required this.roomName,
    required this.roomType,
    required this.widthFeet,
    required this.lengthFeet,
    required this.carpetAreaSqFt,
    required this.perimeterFeet,
    required this.openingsCount,
    required this.openingsAreaSqFt,
    required this.grossWallSurfaceSqFt,
    required this.netWallSurfaceSqFt,
    required this.ceilingAreaSqFt,
    required this.floorTileAreaSqFt,
    required this.wallTileAreaSqFt,
  });

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'roomName': roomName,
        'roomType': roomType.name,
        'widthFeet': widthFeet,
        'lengthFeet': lengthFeet,
        'carpetAreaSqFt': carpetAreaSqFt,
        'perimeterFeet': perimeterFeet,
        'openingsCount': openingsCount,
        'openingsAreaSqFt': openingsAreaSqFt,
        'grossWallSurfaceSqFt': grossWallSurfaceSqFt,
        'netWallSurfaceSqFt': netWallSurfaceSqFt,
        'ceilingAreaSqFt': ceilingAreaSqFt,
        'floorTileAreaSqFt': floorTileAreaSqFt,
        'wallTileAreaSqFt': wallTileAreaSqFt,
      };

  factory RoomQuantityBreakdown.fromJson(Map<String, dynamic> json) =>
      RoomQuantityBreakdown(
        roomId: json['roomId'] as String,
        roomName: json['roomName'] as String,
        roomType: RoomType.values.firstWhere(
          (e) => e.name == json['roomType'],
          orElse: () => RoomType.custom,
        ),
        widthFeet: (json['widthFeet'] as num).toDouble(),
        lengthFeet: (json['lengthFeet'] as num).toDouble(),
        carpetAreaSqFt: (json['carpetAreaSqFt'] as num).toDouble(),
        perimeterFeet: (json['perimeterFeet'] as num).toDouble(),
        openingsCount: (json['openingsCount'] as num).toInt(),
        openingsAreaSqFt: (json['openingsAreaSqFt'] as num).toDouble(),
        grossWallSurfaceSqFt: (json['grossWallSurfaceSqFt'] as num).toDouble(),
        netWallSurfaceSqFt: (json['netWallSurfaceSqFt'] as num).toDouble(),
        ceilingAreaSqFt: (json['ceilingAreaSqFt'] as num).toDouble(),
        floorTileAreaSqFt: (json['floorTileAreaSqFt'] as num).toDouble(),
        wallTileAreaSqFt: (json['wallTileAreaSqFt'] as num).toDouble(),
      );
}

/// Deduplicated physical wall segment (exterior or interior shared partition)
class PhysicalWallSegment {
  final String id;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double lengthFeet;
  final double heightFeet;
  final double thicknessFeet;
  final bool isExterior;
  final List<String> roomIds;
  final List<PlanOpening> openings;

  const PhysicalWallSegment({
    required this.id,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.lengthFeet,
    required this.heightFeet,
    required this.thicknessFeet,
    required this.isExterior,
    required this.roomIds,
    this.openings = const [],
  });

  double get grossAreaSqFt => lengthFeet * heightFeet;
  double get grossVolumeCuFt => grossAreaSqFt * thicknessFeet;

  double get openingsAreaSqFt {
    return openings.fold<double>(0.0, (sum, op) {
      final h = _getOpeningHeightFeet(op.type);
      return sum + (op.widthFeet * h);
    });
  }

  double get openingsVolumeCuFt => openingsAreaSqFt * thicknessFeet;

  double get netAreaSqFt => math.max(0.0, grossAreaSqFt - openingsAreaSqFt);
  double get netVolumeCuFt => math.max(0.0, grossVolumeCuFt - openingsVolumeCuFt);

  static double _getOpeningHeightFeet(OpeningType type) {
    switch (type) {
      case OpeningType.door:
      case OpeningType.doubleDoor:
      case OpeningType.slidingDoor:
        return 7.0;
      case OpeningType.window:
        return 4.0;
      case OpeningType.ventilation:
        return 2.0;
    }
  }
}

/// Complete material estimate report for a floor plan
class PlanMaterialEstimateReport {
  final String planId;
  final String planName;
  final DateTime generatedAt;
  final MaterialEstimationAssumptions assumptions;

  // Geometry Totals
  final double totalPlotAreaSqFt;
  final double totalBuiltUpAreaSqFt;
  final double totalCarpetAreaSqFt;
  final double overlappingAreaSqFt;
  final double exteriorWallLengthFeet;
  final double interiorSharedWallLengthFeet;
  final double totalPhysicalWallLengthFeet;
  final double grossMasonryVolumeCuFt;
  final double openingsDeductionVolumeCuFt;
  final double netMasonryVolumeCuFt;
  final double totalOpeningsAreaSqFt;
  final int totalOpeningsCount;

  // Deduplicated Physical Walls & Room Breakdowns
  final List<PhysicalWallSegment> physicalWalls;
  final List<RoomQuantityBreakdown> roomBreakdowns;

  // Material Line Items
  final List<MaterialLineItem> lineItems;

  const PlanMaterialEstimateReport({
    required this.planId,
    required this.planName,
    required this.generatedAt,
    required this.assumptions,
    required this.totalPlotAreaSqFt,
    required this.totalBuiltUpAreaSqFt,
    required this.totalCarpetAreaSqFt,
    required this.overlappingAreaSqFt,
    required this.exteriorWallLengthFeet,
    required this.interiorSharedWallLengthFeet,
    required this.totalPhysicalWallLengthFeet,
    required this.grossMasonryVolumeCuFt,
    required this.openingsDeductionVolumeCuFt,
    required this.netMasonryVolumeCuFt,
    required this.totalOpeningsAreaSqFt,
    required this.totalOpeningsCount,
    required this.physicalWalls,
    required this.roomBreakdowns,
    required this.lineItems,
  });

  /// Total Estimated Cost across all materials
  double get totalEstimatedCost {
    return lineItems.fold<double>(0.0, (sum, item) => sum + item.totalCost);
  }

  /// Line items grouped by category
  Map<MaterialCategory, List<MaterialLineItem>> get itemsByCategory {
    final Map<MaterialCategory, List<MaterialLineItem>> map = {};
    for (final cat in MaterialCategory.values) {
      map[cat] = [];
    }
    for (final item in lineItems) {
      map[item.category]?.add(item);
    }
    return map;
  }

  /// Cost grouped by category
  Map<MaterialCategory, double> get costByCategory {
    final Map<MaterialCategory, double> map = {};
    for (final cat in MaterialCategory.values) {
      final items = itemsByCategory[cat] ?? [];
      map[cat] = items.fold<double>(0.0, (sum, i) => sum + i.totalCost);
    }
    return map;
  }

  /// Professional Engineering Disclaimer
  static const String disclaimerText =
      'NOTICE & DISCLAIMER: This preliminary material estimate is generated automatically from 2D architectural room geometry for planning, estimation, and budgeting purposes only. It is NOT a certified Bill of Quantities (BOQ), structural design, or tender document. Reinforcement steel, structural foundations, sub-surface conditions, MEP (mechanical/electrical/plumbing), and local building codes must be determined from certified structural engineering drawings and licensed architectural specifications.';
}
