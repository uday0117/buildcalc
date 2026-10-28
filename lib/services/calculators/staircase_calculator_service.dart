import 'dart:math' as math;

import '../../models/calculators/staircase_calculation.dart';

class StaircaseCalculatorService {
  static StaircaseResult calculate(StaircaseInput input) {
    if (input.totalHeight <= 0) {
      return StaircaseResult.failure('Total height must be greater than zero.');
    }
    if (input.targetRiser <= 0) {
      return StaircaseResult.failure('Target riser must be greater than zero.');
    }
    if (input.targetTread <= 0) {
      return StaircaseResult.failure('Target tread must be greater than zero.');
    }
    if (input.flightWidth <= 0) {
      return StaircaseResult.failure('Flight width must be greater than zero.');
    }
    if (input.waistThickness <= 0) {
      return StaircaseResult.failure('Waist slab thickness must be greater than zero.');
    }
    if (input.landingLength < 0) {
      return StaircaseResult.failure('Landing length cannot be negative.');
    }

    final targetRiserMeters = input.targetRiser / 1000.0;
    var numRisers = (input.totalHeight / targetRiserMeters).round();
    if (numRisers < 1) numRisers = 1;

    final actualRiserMm = (input.totalHeight / numRisers) * 1000.0;
    final actualTreadMm = input.targetTread;

    // In a single flight, treads = risers - 1. In dog-legged (2 flights), treads = risers - 2.
    final numTreads = input.flightCount > 1
        ? math.max(1, numRisers - 2)
        : math.max(1, numRisers - 1);

    final totalGoingMeters = numTreads * (actualTreadMm / 1000.0);
    final inclineLengthMeters = math.sqrt(
      (totalGoingMeters * totalGoingMeters) +
          (input.totalHeight * input.totalHeight),
    );

    final pitchAngleRad = math.atan2(input.totalHeight, totalGoingMeters);
    final pitchAngleDegrees = pitchAngleRad * (180.0 / math.pi);
    final blondelIndex = (2 * actualRiserMm) + actualTreadMm;

    final warnings = <String>[];
    if (pitchAngleDegrees < 25.0 || pitchAngleDegrees > 42.0) {
      warnings.add(
        'Pitch angle (${pitchAngleDegrees.toStringAsFixed(1)}°) is outside the standard 25°–40° range.',
      );
    }
    if (blondelIndex < 550.0 || blondelIndex > 680.0) {
      warnings.add(
        'Blondel comfort (2R + T = ${blondelIndex.toStringAsFixed(0)} mm) is outside the 550–680 mm ergonomic range.',
      );
    }
    if (actualRiserMm > 200.0) {
      warnings.add(
        'Riser (${actualRiserMm.toStringAsFixed(1)} mm) is steep and exceeds recommended 190 mm maximum.',
      );
    }
    if (actualTreadMm < 250.0) {
      warnings.add(
        'Tread (${actualTreadMm.toStringAsFixed(1)} mm) is narrow and less than recommended 250 mm minimum.',
      );
    }

    // Concrete volume calculations
    final waistThicknessMeters = input.waistThickness / 1000.0;
    final waistSlabVol = inclineLengthMeters * input.flightWidth * waistThicknessMeters;

    final singleStepVolume = 0.5 *
        (actualRiserMm / 1000.0) *
        (actualTreadMm / 1000.0) *
        input.flightWidth;
    final stepsVol = singleStepVolume * numTreads;

    final landingVol = input.landingLength *
        input.flightWidth *
        waistThicknessMeters *
        input.flightCount;

    final totalWetVolume = waistSlabVol + stepsVol + landingVol;
    final totalDryVolume = totalWetVolume * 1.54;

    final grade = input.concreteGrade;
    final cementVolume = (totalDryVolume * grade.cementRatio) / grade.totalRatio;
    final cementBags = cementVolume / 0.0347;

    final sandM3 = (totalDryVolume * grade.sandRatio) / grade.totalRatio;
    final sandTonnes = sandM3 * 1.6;

    final aggregateM3 = (totalDryVolume * grade.aggRatio) / grade.totalRatio;
    final aggregateTonnes = aggregateM3 * 1.5;

    // Structural rule of thumb: ~85 kg steel per m³ of wet concrete
    final estimatedSteelKg = totalWetVolume * 85.0;

    return StaircaseResult(
      isValid: true,
      warnings: warnings,
      totalRisers: numRisers,
      totalTreads: numTreads,
      actualRiserMm: actualRiserMm,
      actualTreadMm: actualTreadMm,
      totalGoingMeters: totalGoingMeters,
      inclineLengthMeters: inclineLengthMeters,
      pitchAngleDegrees: pitchAngleDegrees,
      blondelComfortIndexMm: blondelIndex,
      waistSlabVolumeM3: waistSlabVol,
      stepsVolumeM3: stepsVol,
      landingVolumeM3: landingVol,
      totalWetVolumeM3: totalWetVolume,
      totalDryVolumeM3: totalDryVolume,
      cementBags: cementBags,
      sandM3: sandM3,
      sandTonnes: sandTonnes,
      aggregateM3: aggregateM3,
      aggregateTonnes: aggregateTonnes,
      estimatedSteelKg: estimatedSteelKg,
    );
  }
}

