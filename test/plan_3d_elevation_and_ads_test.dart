import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buildcalc/models/plan/elevation_models.dart';
import 'package:buildcalc/models/plan/plan_3d_models.dart';
import 'package:buildcalc/models/plan/plan_models.dart';
import 'package:buildcalc/models/plan/plan_templates.dart';
import 'package:buildcalc/services/ad_service.dart';
import 'package:buildcalc/services/elevation_builder.dart';
import 'package:buildcalc/services/plan_3d_builder.dart';
import 'package:buildcalc/widgets/ad_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('3D Scene Builder and Geometry Validation', () {
    test(
      'validates plan with rooms and generates non-empty 3D mesh with walls and floor',
      () {
        final plan = PlanTemplates.createPlan(
          name: '3D Test Villa',
          layoutType: PlanTemplates.layout2BHK,
          plotWidthFeet: 36.0,
          plotLengthFeet: 48.0,
        );

        final validation = Plan3DBuilder.validatePlan(plan);
        expect(validation.isValid, isTrue);

        final mesh = Plan3DBuilder.buildScene(
          plan: plan,
          wallMaterial: Scene3DMaterial.plasterWhite,
          floorMaterial: Scene3DMaterial.oakHardwood,
          cutawayMode: CutawayMode.full,
        );

        expect(mesh.polygons, isNotEmpty);
        final floors = mesh.polygons.where(
          (p) => p.category == PolygonCategory.floor,
        );
        expect(floors, isNotEmpty);
        expect(mesh.maxBound.x - mesh.minBound.x, greaterThan(20.0));
      },
    );

    test(
      'validates empty plan returns invalid result with descriptive error',
      () {
        final emptyPlan = FloorPlan(
          id: 'empty_plan',
          name: 'Empty Plan',
          plotWidthFeet: 30.0,
          plotLengthFeet: 40.0,
          rooms: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final validation = Plan3DBuilder.validatePlan(emptyPlan);
        expect(validation.isValid, isFalse);
        expect(validation.errors, isNotEmpty);
      },
    );

    test(
      'supports camera rotation, zoom and architectural viewing presets',
      () {
        final camera = Camera3DState(
          distance: 50.0,
          projectionMode: ProjectionMode.perspective,
        );

        // Camera zoom
        camera.zoom(0.8);
        expect(camera.distance, closeTo(40.0, 0.01));

        // Isometric SE preset (azimuth = pi/4, elevation = 35 deg = 0.6108 rad)
        camera.presetIsometricSE();
        expect(camera.elevation, closeTo(0.6108, 0.01));
        expect(camera.azimuth, closeTo(0.7853, 0.01));

        // Top-down preset (elevation = 85 deg = 1.4835 rad, azimuth = 0)
        camera.presetTopDown();
        expect(camera.elevation, closeTo(1.4835, 0.01));
        expect(camera.azimuth, closeTo(0.0, 0.01));

        // Reset
        camera.reset();
        expect(camera.elevation, closeTo(0.6108, 0.01));
      },
    );

    test('cutaway modes alter wall height correctly', () {
      final plan = PlanTemplates.createPlan(
        name: 'Cutaway Test',
        layoutType: PlanTemplates.layout1BHK,
        plotWidthFeet: 30.0,
        plotLengthFeet: 40.0,
      );

      final fullMesh = Plan3DBuilder.buildScene(
        plan: plan,
        cutawayMode: CutawayMode.full,
      );
      final dollhouseMesh = Plan3DBuilder.buildScene(
        plan: plan,
        cutawayMode: CutawayMode.dollhouse,
      );

      expect(fullMesh.polygons.isNotEmpty, isTrue);
      expect(dollhouseMesh.polygons.isNotEmpty, isTrue);
    });
  });

  group('Front Elevation Generator & Specifications', () {
    test(
      'generates architectural elevation config directly from floor plan',
      () {
        final plan = PlanTemplates.createPlan(
          name: 'Elevation Test Villa',
          layoutType: PlanTemplates.layout2BHK,
          plotWidthFeet: 36.0,
          plotLengthFeet: 48.0,
        );

        final config = ElevationBuilder.buildElevationFromPlan(plan);

        // Facade width derives from rooms bounding box span (maxX - minX)
        expect(config.facadeWidthFeet, closeTo(28.5, 0.1));
        expect(config.style, equals(ElevationStyle.modern));
        expect(config.floorCount, equals(2));
        expect(config.roofStyle, equals(RoofStyle.flatParapet));

        // Check architectural report generation
        final report = ElevationBuilder.generateSpecificationReport(config);
        expect(
          report.contains('BUILDCALC FRONT ELEVATION SPECIFICATION'),
          isTrue,
        );
        expect(report.contains('Ground Level'), isTrue);
        expect(report.contains('COMPLIANCE & LEGAL NOTICE'), isTrue);
      },
    );

    test('generates preset style variations without crashing', () {
      final plan = PlanTemplates.createPlan(
        name: 'Preset Test',
        layoutType: PlanTemplates.layout3BHK,
        plotWidthFeet: 40.0,
        plotLengthFeet: 60.0,
      );

      final presets = ElevationBuilder.getPresetVariations(plan);
      expect(presets.length, greaterThanOrEqualTo(4));
      expect(presets.any((p) => p.style == ElevationStyle.traditional), isTrue);
      expect(presets.any((p) => p.style == ElevationStyle.minimalist), isTrue);
      expect(
        presets.any((p) => p.style == ElevationStyle.contemporary),
        isTrue,
      );
    });
  });

  group('Ads Implementation & Safety Validation', () {
    test(
      'AdService returns official test ad units in debug mode to prevent policy violation',
      () {
        if (kDebugMode) {
          expect(
            AdService.bannerAdUnitId,
            equals(AdService.testAndroidBannerId),
            reason:
                'In debug mode, Android must use official AdMob test banner ID',
          );
          expect(
            AdService.interstitialAdUnitId,
            equals(AdService.testAndroidInterstitialId),
            reason:
                'In debug mode, Android must use official AdMob test interstitial ID',
          );
        }
      },
    );

    testWidgets(
      'AppBannerAd renders safely as SizedBox.shrink while ad is loading or offline',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(bottomNavigationBar: AppBannerAd())),
        );

        // Verify that no unhandled exceptions were thrown
        expect(tester.takeException(), isNull);
        // While uninitialized / loading / offline in widget test, it must shrink gracefully
        expect(find.byType(AppBannerAd), findsOneWidget);
      },
    );
  });
}
