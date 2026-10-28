import 'package:flutter_test/flutter_test.dart';

import 'package:buildcalc/models/calculators/excavation_calculation.dart';
import 'package:buildcalc/models/calculators/staircase_calculation.dart';
import 'package:buildcalc/services/calculators/excavation_calculator_service.dart';
import 'package:buildcalc/services/calculators/staircase_calculator_service.dart';

void main() {
  group('Cement & Concrete Mathematical Validation', () {
    test('standard 1:6 mortar mix volume, cement bags, and sand volume', () {
      // Input: 5m length, 4m width, 100mm thickness (0.1m)
      const length = 5.0;
      const width = 4.0;
      const thicknessMm = 100.0;
      const thicknessM = thicknessMm / 1000.0; // 0.1 m

      final wetVolume = length * width * thicknessM; // 2.0 m³
      expect(wetVolume, closeTo(2.0, 0.001));

      // Dry volume factor for mortar / concrete: 1.54
      final dryVolume = wetVolume * 1.54; // 3.08 m³
      expect(dryVolume, closeTo(3.08, 0.001));

      // Cement volume (1 part of 1:6 ratio = 1/7)
      final cementVolume = (dryVolume * 1.0) / 7.0; // 0.44 m³
      expect(cementVolume, closeTo(0.44, 0.001));

      // 1 bag cement (50kg) = 0.0347 m³
      final cementBags = cementVolume / 0.0347;
      expect(cementBags, closeTo(12.68, 0.01));

      // Sand volume (6 parts of 7)
      final sandVolume = (dryVolume * 6.0) / 7.0;
      expect(sandVolume, closeTo(2.64, 0.01));
    });
  });

  group('Brick Calculator Mathematical Validation', () {
    test('single brick wall (115mm) has 50 bricks/m2 plus 10% wastage', () {
      const length = 10.0;
      const height = 3.0;
      const wallArea = length * height; // 30 m²

      const bricksPerSqm = 50.0;
      final rawBricks = wallArea * bricksPerSqm; // 1500
      final totalBricks = rawBricks * 1.1; // 1650

      expect(wallArea, equals(30.0));
      expect(totalBricks, closeTo(1650.0, 0.01));
    });

    test('double brick wall (230mm) has 100 bricks/m2 plus 10% wastage', () {
      const length = 8.0;
      const height = 3.0;
      const wallArea = length * height; // 24 m²

      const bricksPerSqm = 100.0;
      final totalBricks = wallArea * bricksPerSqm * 1.1;

      expect(totalBricks, equals(2640.0));
    });
  });

  group('Sand Calculator Mathematical Validation', () {
    test('cubic meters, cubic feet, tonnes and 20% wastage factor', () {
      const length = 4.0;
      const width = 3.0;
      const depth = 0.5;

      final netVolumeM3 = length * width * depth; // 6.0 m³
      final netCuFt = netVolumeM3 * 35.3147; // 211.8882 ft³
      final netTonnes = netVolumeM3 * 1.6; // 9.6 tonnes

      // + 20% wastage
      final totalM3 = netVolumeM3 * 1.2;
      final totalCuFt = netCuFt * 1.2;
      final totalTonnes = netTonnes * 1.2;

      expect(totalM3, closeTo(7.2, 0.001));
      expect(totalCuFt, closeTo(254.266, 0.01));
      expect(totalTonnes, closeTo(11.52, 0.001));
    });
  });

  group('Paint Calculator Mathematical Validation', () {
    test('room wall area with deducted doors/windows and multiple coats', () {
      const length = 5.0; // 5m x 5m room (4 walls)
      const height = 3.0;
      const deductedArea = 4.0; // 4 m² doors and windows
      const coats = 2.0;
      const coveragePerLiter = 10.0;

      final grossWallArea =
          (2 * (length + length)) * height; // 4 * 5 * 3 = 60 m²
      final netWallArea = grossWallArea - deductedArea; // 56 m²
      expect(netWallArea, equals(56.0));

      final paintLiters =
          (netWallArea * coats) / coveragePerLiter; // (56 * 2) / 10 = 11.2 L
      final totalWith10PercentExtra = paintLiters * 1.1; // 12.32 L
      expect(totalWith10PercentExtra, closeTo(12.32, 0.01));
    });
  });

  group('Tile Calculator Mathematical Validation', () {
    test('flooring tiles and boxes with 10% wastage', () {
      const floorLength = 6.0;
      const floorWidth = 4.0;
      const floorArea = floorLength * floorWidth; // 24.0 m²

      // 600mm x 600mm tiles
      const tileLengthM = 600.0 / 1000.0; // 0.6 m
      const tileWidthM = 600.0 / 1000.0; // 0.6 m
      const tileArea = tileLengthM * tileWidthM; // 0.36 m²

      final rawTiles = floorArea / tileArea; // 66.6667 tiles
      final totalTiles = rawTiles * 1.1; // 73.3333 tiles
      final boxes = totalTiles / 10.0; // 7.3333 boxes

      expect(floorArea, equals(24.0));
      expect(totalTiles, closeTo(73.33, 0.01));
      expect(boxes, closeTo(7.33, 0.01));
    });
  });

  group('Steel Rebar Calculator Mathematical Validation', () {
    test('rebar weight per bar formula D^2 * L / 162 and batch total', () {
      const diameter = 16.0; // 16 mm rebar
      const length = 12.0; // 12 m standard length
      const quantity = 50.0; // 50 bars

      // Formula: D² * L / 162
      final weightPerBar =
          (diameter * diameter * length) /
          162.0; // (256 * 12) / 162 = 18.96296 kg
      expect(weightPerBar, closeTo(18.963, 0.01));

      final totalWeightKg = weightPerBar * quantity; // ~948.15 kg
      expect(totalWeightKg, closeTo(948.15, 0.05));

      final totalTonnes = totalWeightKg / 1000.0;
      expect(totalTonnes, closeTo(0.948, 0.001));
    });

    test(
      'rebar 10mm and 12mm standard unit weights verify against engineering tables',
      () {
        // 10mm rebar 1m length -> 10^2 / 162 = 0.617 kg/m
        final w10 = (10.0 * 10.0 * 1.0) / 162.0;
        expect(w10, closeTo(0.617, 0.001));

        // 12mm rebar 1m length -> 12^2 / 162 = 0.888 kg/m
        final w12 = (12.0 * 12.0 * 1.0) / 162.0;
        expect(w12, closeTo(0.889, 0.001));
      },
    );
  });

  group('Area Calculator Mathematical Validation', () {
    test('rectangle area and perimeter', () {
      const l = 12.0;
      const w = 8.0;
      expect(l * w, equals(96.0));
      expect(2 * (l + w), equals(40.0));
    });

    test('circle area and circumference', () {
      const r = 7.0;
      final area = 3.14159 * r * r;
      final circumference = 2 * 3.14159 * r;
      expect(area, closeTo(153.938, 0.01));
      expect(circumference, closeTo(43.98, 0.01));
    });

    test('triangle area and perimeter', () {
      const base = 6.0;
      const height = 4.0;
      const side3 = 5.0;
      expect(0.5 * base * height, equals(12.0));
      expect(base + height + side3, equals(15.0));
    });
  });

  group('Staircase Service Engineering Validation', () {
    test(
      'computes risers, treads, Blondel formula, and concrete volume for standard residential height',
      () {
        final input = StaircaseInput(
          totalHeight: 3.0, // 3 meters
          targetRiser: 160.0, // 160 mm target
          targetTread: 280.0, // 280 mm target
          flightWidth: 1.0, // 1 meter flight width
          waistThickness: 150.0, // 150 mm waist slab
          landingLength: 1.0, // 1 meter landing
          flightCount: 1, // Single flight
          concreteGrade: ConcreteGrade.m20,
        );

        final res = StaircaseCalculatorService.calculate(input);

        expect(res.isValid, isTrue);
        // 3.0 / 0.16 = 18.75 -> 19 risers
        expect(res.totalRisers, equals(19));
        expect(res.actualRiserMm, closeTo(157.89, 0.01));
        // In single flight, treads = risers - 1 = 18
        expect(res.totalTreads, equals(18));
        expect(res.actualTreadMm, equals(280.0));

        // Blondel index = 2R + T = 2 * 157.89 + 280 = 595.79 mm (within 550-680 comfort zone)
        expect(res.blondelComfortIndexMm, closeTo(595.79, 0.05));
        expect(res.warnings, isEmpty);

        // Total going = 18 * 0.28 = 5.04 m
        expect(res.totalGoingMeters, closeTo(5.04, 0.01));
        // Incline length = sqrt(5.04^2 + 3^2) = 5.865 m
        expect(res.inclineLengthMeters, closeTo(5.865, 0.01));
        // Pitch angle = atan2(3, 5.04) = 30.76 degrees
        expect(res.pitchAngleDegrees, closeTo(30.76, 0.1));

        // Concrete volume should be positive and include dry volume 1.54 factor
        expect(res.totalWetVolumeM3, greaterThan(1.0));
        expect(
          res.totalDryVolumeM3,
          closeTo(res.totalWetVolumeM3 * 1.54, 0.001),
        );
        expect(res.cementBags, greaterThan(0.0));
        expect(res.sandM3, greaterThan(0.0));
        expect(res.aggregateM3, greaterThan(0.0));
        expect(res.estimatedSteelKg, greaterThan(0.0));
      },
    );

    test(
      'warns when pitch angle or riser height exceeds safety guidelines',
      () {
        final steepInput = StaircaseInput(
          totalHeight: 3.5,
          targetRiser: 220.0, // Very steep riser (> 200 mm)
          targetTread: 200.0, // Narrow tread (< 250 mm)
          flightWidth: 0.9,
          waistThickness: 150.0,
          landingLength: 0.8,
          flightCount: 1,
          concreteGrade: ConcreteGrade.m20,
        );

        final res = StaircaseCalculatorService.calculate(steepInput);
        expect(res.isValid, isTrue);
        expect(res.warnings, isNotEmpty);
        expect(res.warnings.any((w) => w.contains('Riser')), isTrue);
        expect(res.warnings.any((w) => w.contains('Tread')), isTrue);
      },
    );

    test('rejects negative or zero total height gracefully', () {
      final invalidInput = StaircaseInput(
        totalHeight: -1.0,
        targetRiser: 160.0,
        targetTread: 280.0,
        flightWidth: 1.0,
        waistThickness: 150.0,
        landingLength: 1.0,
      );

      final res = StaircaseCalculatorService.calculate(invalidInput);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, isNotNull);
    });
  });

  group('Excavation & Backfilling Engineering Validation', () {
    test(
      'calculates pit volume, working space expansion, bulking, backfill, and haul trips',
      () {
        final input = ExcavationInput(
          type: ExcavationType.isolatedFooting,
          length: 2.0, // 2m footing
          width: 2.0, // 2m footing
          depth: 1.5, // 1.5m depth
          quantity: 4, // 4 footing pits
          workingSpace: 0.3, // 0.3m working space each side
          structureVolumeM3: 3.2, // Concrete footings taking 3.2 m³ total
          bulkingFactorPercent: 20.0, // 20% soil swell
          compactionFactorPercent: 15.0, // 15% compaction
          truckCapacityM3: 5.0, // 5 m³ dump truck
        );

        final res = ExcavationCalculatorService.calculate(input);

        expect(res.isValid, isTrue);
        // Effective length = 2.0 + 2 * 0.3 = 2.6 m
        expect(res.effectiveLengthMeters, closeTo(2.6, 0.001));
        expect(res.effectiveWidthMeters, closeTo(2.6, 0.001));

        // Single pit in situ volume = 2.6 * 2.6 * 1.5 = 10.14 m³
        // Total 4 pits = 40.56 m³
        expect(res.inSituExcavationM3, closeTo(40.56, 0.01));

        // Loose soil with 20% bulking = 40.56 * 1.2 = 48.672 m³
        expect(res.looseSoilM3, closeTo(48.672, 0.01));

        // Backfill void = In situ (40.56) - structure (3.2) = 37.36 m³
        expect(res.inSituBackfillVoidM3, closeTo(37.36, 0.01));

        // Compacted backfill with 15% shrinkage = 37.36 * 1.15 = 42.964 m³
        expect(res.requiredCompactedBackfillM3, closeTo(42.964, 0.01));

        // Surplus soil = 48.672 - (37.36 * 1.2) = 48.672 - 44.832 = 3.84 m³
        expect(res.surplusSoilM3, closeTo(3.84, 0.01));

        // Truck trips for 3.84 m³ in 5.0 m³ truck = ceil(3.84 / 5.0) = 1 trip
        expect(res.truckTrips, equals(1));

        // Safety warning should be present because depth >= 1.5 m
        expect(
          res.warnings.any((w) => w.contains('1.5 m') || w.contains('shoring')),
          isTrue,
        );
      },
    );

    test('rejects negative or zero dimensions', () {
      final invalid = ExcavationInput(
        length: 0.0,
        width: 2.0,
        depth: 1.0,
        quantity: 1,
      );
      final res = ExcavationCalculatorService.calculate(invalid);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, isNotNull);
    });
  });
}
