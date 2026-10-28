import 'dart:math' as math;

import '../../models/calculators/excavation_calculation.dart';

class ExcavationCalculatorService {
  static ExcavationResult calculate(ExcavationInput input) {
    if (input.length <= 0) {
      return ExcavationResult.failure('Length must be greater than zero.');
    }
    if (input.width <= 0) {
      return ExcavationResult.failure('Width must be greater than zero.');
    }
    if (input.depth <= 0) {
      return ExcavationResult.failure('Depth must be greater than zero.');
    }
    if (input.quantity <= 0) {
      return ExcavationResult.failure('Quantity must be at least 1.');
    }
    if (input.workingSpace < 0) {
      return ExcavationResult.failure(
        'Working space allowance cannot be negative.',
      );
    }
    if (input.truckCapacityM3 <= 0) {
      return ExcavationResult.failure(
        'Truck capacity must be greater than zero.',
      );
    }

    final warnings = <String>[];
    if (input.depth >= 1.5) {
      warnings.add(
        'Excavation depth (${input.depth.toStringAsFixed(2)} m) exceeds 1.5 m. Timber shoring, strutting, or stepped benching is strongly advised for trench wall safety.',
      );
    }

    final effectiveLength = input.length + (2 * input.workingSpace);
    final effectiveWidth = input.width + (2 * input.workingSpace);
    final singlePitInSituM3 = effectiveLength * effectiveWidth * input.depth;
    final totalInSituExcavationM3 = singlePitInSituM3 * input.quantity;

    if (input.structureVolumeM3 > totalInSituExcavationM3) {
      warnings.add(
        'Structure volume (${input.structureVolumeM3.toStringAsFixed(2)} m³) is larger than total pit volume (${totalInSituExcavationM3.toStringAsFixed(2)} m³).',
      );
    }

    final bulkingMultiplier = 1.0 + (input.bulkingFactorPercent / 100.0);
    final totalLooseSoilM3 = totalInSituExcavationM3 * bulkingMultiplier;

    // Void to be backfilled after concrete structure is erected
    final inSituBackfillVoidM3 = math.max(
      0.0,
      totalInSituExcavationM3 - input.structureVolumeM3,
    );

    // Required loose soil needed to produce compacted backfill
    final compactionMultiplier = 1.0 + (input.compactionFactorPercent / 100.0);
    final requiredCompactedBackfillM3 =
        inSituBackfillVoidM3 * compactionMultiplier;

    // Loose volume consumed for backfilling
    final looseSoilConsumedForBackfill =
        inSituBackfillVoidM3 * bulkingMultiplier;

    final surplusSoilM3 = math.max(
      0.0,
      totalLooseSoilM3 - looseSoilConsumedForBackfill,
    );

    final truckTrips = (surplusSoilM3 / input.truckCapacityM3).ceil();

    return ExcavationResult(
      isValid: true,
      warnings: warnings,
      effectiveLengthMeters: effectiveLength,
      effectiveWidthMeters: effectiveWidth,
      pitAreaM2: effectiveLength * effectiveWidth,
      inSituExcavationM3: totalInSituExcavationM3,
      looseSoilM3: totalLooseSoilM3,
      inSituBackfillVoidM3: inSituBackfillVoidM3,
      requiredCompactedBackfillM3: requiredCompactedBackfillM3,
      surplusSoilM3: surplusSoilM3,
      truckTrips: truckTrips,
    );
  }
}
