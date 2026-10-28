enum StaircaseUnit { metric, imperial }

enum ConcreteGrade {
  m15(name: 'M15 (1:2:4)', cementRatio: 1.0, sandRatio: 2.0, aggRatio: 4.0),
  m20(name: 'M20 (1:1.5:3)', cementRatio: 1.0, sandRatio: 1.5, aggRatio: 3.0),
  m25(name: 'M25 (1:1:2)', cementRatio: 1.0, sandRatio: 1.0, aggRatio: 2.0);

  final String name;
  final double cementRatio;
  final double sandRatio;
  final double aggRatio;

  const ConcreteGrade({
    required this.name,
    required this.cementRatio,
    required this.sandRatio,
    required this.aggRatio,
  });

  double get totalRatio => cementRatio + sandRatio + aggRatio;
}

class StaircaseInput {
  final double totalHeight; // in meters
  final double targetRiser; // in mm
  final double targetTread; // in mm
  final double flightWidth; // in meters
  final double waistThickness; // in mm
  final double landingLength; // in meters
  final int flightCount; // 1 (straight) or 2 (dog-legged)
  final ConcreteGrade concreteGrade;
  final StaircaseUnit unit;

  const StaircaseInput({
    required this.totalHeight,
    this.targetRiser = 160.0,
    this.targetTread = 280.0,
    this.flightWidth = 1.0,
    this.waistThickness = 150.0,
    this.landingLength = 1.0,
    this.flightCount = 1,
    this.concreteGrade = ConcreteGrade.m20,
    this.unit = StaircaseUnit.metric,
  });
}

class StaircaseResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> warnings;

  // Geometry
  final int totalRisers;
  final int totalTreads;
  final double actualRiserMm;
  final double actualTreadMm;
  final double totalGoingMeters;
  final double inclineLengthMeters;
  final double pitchAngleDegrees;
  final double blondelComfortIndexMm; // 2R + T (optimum: 600 - 640 mm)

  // Concrete & Materials
  final double waistSlabVolumeM3;
  final double stepsVolumeM3;
  final double landingVolumeM3;
  final double totalWetVolumeM3;
  final double totalDryVolumeM3;
  final double cementBags; // 50 kg bags
  final double sandM3;
  final double sandTonnes;
  final double aggregateM3;
  final double aggregateTonnes;
  final double estimatedSteelKg;

  const StaircaseResult({
    required this.isValid,
    this.errorMessage,
    this.warnings = const [],
    this.totalRisers = 0,
    this.totalTreads = 0,
    this.actualRiserMm = 0,
    this.actualTreadMm = 0,
    this.totalGoingMeters = 0,
    this.inclineLengthMeters = 0,
    this.pitchAngleDegrees = 0,
    this.blondelComfortIndexMm = 0,
    this.waistSlabVolumeM3 = 0,
    this.stepsVolumeM3 = 0,
    this.landingVolumeM3 = 0,
    this.totalWetVolumeM3 = 0,
    this.totalDryVolumeM3 = 0,
    this.cementBags = 0,
    this.sandM3 = 0,
    this.sandTonnes = 0,
    this.aggregateM3 = 0,
    this.aggregateTonnes = 0,
    this.estimatedSteelKg = 0,
  });

  factory StaircaseResult.failure(String message) {
    return StaircaseResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

