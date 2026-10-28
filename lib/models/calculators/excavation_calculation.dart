enum ExcavationType {
  isolatedFooting(name: 'Isolated Column Footings'),
  trench(name: 'Strip / Foundation Trench'),
  basementRaft(name: 'Basement / Raft Excavation');

  final String name;
  const ExcavationType({required this.name});
}

class ExcavationInput {
  final ExcavationType type;
  final double length; // in meters
  final double width; // in meters
  final double depth; // in meters
  final int quantity; // number of pits/trenches
  final double workingSpace; // side clearance around pit (in meters, e.g. 0.3)
  final double structureVolumeM3; // inside concrete structure volume for backfill
  final double bulkingFactorPercent; // soil expansion % (e.g. 20%)
  final double compactionFactorPercent; // soil compaction % for backfill (e.g. 15%)
  final double truckCapacityM3; // dumper capacity in m³ (e.g. 5.0)

  const ExcavationInput({
    this.type = ExcavationType.isolatedFooting,
    required this.length,
    required this.width,
    required this.depth,
    this.quantity = 1,
    this.workingSpace = 0.3,
    this.structureVolumeM3 = 0.0,
    this.bulkingFactorPercent = 20.0,
    this.compactionFactorPercent = 15.0,
    this.truckCapacityM3 = 5.0,
  });
}

class ExcavationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> warnings;

  // Dimensional results
  final double effectiveLengthMeters;
  final double effectiveWidthMeters;
  final double pitAreaM2;

  // Volume results
  final double inSituExcavationM3;
  final double looseSoilM3; // with bulking factor
  final double inSituBackfillVoidM3;
  final double requiredCompactedBackfillM3;
  final double surplusSoilM3;
  final int truckTrips;

  const ExcavationResult({
    required this.isValid,
    this.errorMessage,
    this.warnings = const [],
    this.effectiveLengthMeters = 0,
    this.effectiveWidthMeters = 0,
    this.pitAreaM2 = 0,
    this.inSituExcavationM3 = 0,
    this.looseSoilM3 = 0,
    this.inSituBackfillVoidM3 = 0,
    this.requiredCompactedBackfillM3 = 0,
    this.surplusSoilM3 = 0,
    this.truckTrips = 0,
  });

  factory ExcavationResult.failure(String message) {
    return ExcavationResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

