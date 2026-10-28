import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buildcalc/models/plan/material_estimation_models.dart';
import 'package:buildcalc/models/plan/plan_editor_controller.dart';
import 'package:buildcalc/models/plan/plan_models.dart';
import 'package:buildcalc/models/plan/plan_templates.dart';
import 'package:buildcalc/models/plan/plan_unit.dart';
import 'package:buildcalc/services/plan_material_estimator.dart';

void main() {
  group('PlanUnit Conversions and Formatting', () {
    test('converts feet to meters, inches, and yards correctly', () {
      const feet = 10.0;
      expect(PlanUnit.meters.fromFeet(feet), closeTo(3.048, 0.001));
      expect(PlanUnit.inches.fromFeet(feet), equals(120.0));
      expect(PlanUnit.yards.fromFeet(feet), closeTo(3.333, 0.001));

      // Inverse conversions back to feet
      expect(PlanUnit.meters.toFeet(3.048), closeTo(10.0, 0.001));
      expect(PlanUnit.inches.toFeet(120.0), equals(10.0));
      expect(PlanUnit.yards.toFeet(3.33333), closeTo(10.0, 0.01));
    });

    test('area conversions between sq ft and sq meters', () {
      const sqFt = 1000.0;
      final sqM = PlanUnit.meters.areaFromSqFt(sqFt);
      expect(sqM, closeTo(92.903, 0.01));
      expect(PlanUnit.meters.areaToSqFt(sqM), closeTo(1000.0, 0.01));
    });

    test('formats dimensions and lengths cleanly', () {
      expect(PlanUnit.feet.formatLength(15.5), '15.5 ft');
      expect(PlanUnit.meters.formatLength(4.5), '1.4 m');
      expect(PlanUnit.feet.formatArea(240.0), '240.0 sq ft');
      expect(PlanUnit.feet.formatDimensions(12.0, 15.0), "12'0\" × 15'0\"");
    });
  });

  group('PlanRoom and Geometry Operations', () {
    test('room bounds, rectangle, and area properties', () {
      final room = PlanRoom(
        id: 'r_1',
        name: 'Master Bed',
        type: RoomType.masterBedroom,
        x: 5.0,
        y: 10.0,
        width: 14.0,
        length: 12.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
      );

      expect(room.areaSqFt, equals(168.0));
      expect(room.rect, equals(const Rect.fromLTWH(5.0, 10.0, 14.0, 12.0)));
      expect(room.rect.contains(const Offset(10.0, 15.0)), isTrue);
      expect(room.rect.contains(const Offset(2.0, 5.0)), isFalse);
    });

    test('detects room overlap correctly', () {
      final roomA = PlanRoom(
        id: 'r_a',
        name: 'Room A',
        type: RoomType.living,
        x: 0,
        y: 0,
        width: 10.0,
        length: 10.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
      );
      final roomB = PlanRoom(
        id: 'r_b',
        name: 'Room B',
        type: RoomType.bedroom,
        x: 8.0, // overlaps from x=8 to x=10 (2ft wide overlap)
        y: 0,
        width: 10.0,
        length: 10.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
      );
      final roomC = PlanRoom(
        id: 'r_c',
        name: 'Room C',
        type: RoomType.kitchen,
        x: 25.0, // completely separate
        y: 0,
        width: 10.0,
        length: 10.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
      );

      expect(roomA.rect.overlaps(roomB.rect), isTrue);
      expect(roomA.rect.overlaps(roomC.rect), isFalse);
    });
  });

  group('PlanEditorController Editing & History', () {
    test('adds, updates, deletes room and supports full undo and redo', () {
      final initialPlan = PlanTemplates.createPlan(
        name: 'Test Plan',
        layoutType: PlanTemplates.layout1BHK,
        plotWidthFeet: 30.0,
        plotLengthFeet: 40.0,
      );

      final controller = PlanEditorController(initialPlan: initialPlan);
      final initialRoomCount = controller.plan.rooms.length;

      // 1. Add a new room
      final newRoom = PlanRoom(
        id: 'r_new_study',
        name: 'Home Office',
        type: RoomType.study,
        x: 2.0,
        y: 2.0,
        width: 8.0,
        length: 10.0,
        colorValue: RoomType.study.defaultColor.toARGB32(),
      );
      controller.addRoom(newRoom);
      expect(controller.plan.rooms.length, equals(initialRoomCount + 1));
      expect(controller.canUndo, isTrue);

      // 2. Undo the addition
      controller.undo();
      expect(controller.plan.rooms.length, equals(initialRoomCount));
      expect(controller.canRedo, isTrue);

      // 3. Redo the addition
      controller.redo();
      expect(controller.plan.rooms.length, equals(initialRoomCount + 1));
      expect(controller.plan.rooms.any((r) => r.id == 'r_new_study'), isTrue);

      // 4. Update the room dimensions
      final updatedRoom = newRoom.copyWith(
        name: 'Executive Study',
        width: 12.0,
      );
      controller.updateRoom(updatedRoom);
      expect(
        controller.plan.rooms.firstWhere((r) => r.id == 'r_new_study').name,
        'Executive Study',
      );
      expect(
        controller.plan.rooms.firstWhere((r) => r.id == 'r_new_study').width,
        12.0,
      );

      // 5. Select and delete room
      controller.selectRoom('r_new_study');
      expect(controller.selectedRoomId, equals('r_new_study'));
      controller.deleteRoom('r_new_study');
      expect(controller.plan.rooms.any((r) => r.id == 'r_new_study'), isFalse);
      expect(controller.selectedRoomId, isNull);

      // 6. Undo the deletion
      controller.undo();
      expect(controller.plan.rooms.any((r) => r.id == 'r_new_study'), isTrue);

      // 7. Grid toggle
      final gridBefore = controller.showGrid;
      controller.toggleGrid();
      expect(controller.showGrid, equals(!gridBefore));

      controller.dispose();
    });
  });

  group('PlanMaterialEstimator Shared Wall Deduplication & Quantities', () {
    test(
      'deduplicates shared wall between two adjacent rooms so it is counted once in masonry',
      () {
        // Room 1: (0, 0) to (10, 10)
        // Room 2: (10, 0) to (20, 10) -> Shares vertical wall at x = 10 from y = 0 to 10
        final room1 = PlanRoom(
          id: 'r_1',
          name: 'Room 1',
          type: RoomType.living,
          x: 0.0,
          y: 0.0,
          width: 10.0,
          length: 10.0,
          colorValue: RoomType.living.defaultColor.toARGB32(),
        );
        final room2 = PlanRoom(
          id: 'r_2',
          name: 'Room 2',
          type: RoomType.bedroom,
          x: 10.0,
          y: 0.0,
          width: 10.0,
          length: 10.0,
          colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        );

        const assumptions = MaterialEstimationAssumptions();
        final physicalWalls = PlanMaterialEstimator.extractPhysicalWalls([
          room1,
          room2,
        ], assumptions);

        // Perimeter walls of the 20x10 block:
        // North: 0 to 20 at y=0 (exterior)
        // South: 0 to 20 at y=10 (exterior)
        // West: 0 to 10 at x=0 (exterior)
        // East: 0 to 10 at x=20 (exterior)
        // Middle partition: 0 to 10 at x=10 (interior shared)
        final sharedWalls = physicalWalls.where((w) => !w.isExterior).toList();
        final exteriorWalls = physicalWalls.where((w) => w.isExterior).toList();

        expect(
          sharedWalls.length,
          equals(1),
          reason: 'Shared wall must be deduplicated into exactly 1 segment',
        );
        final sharedWall = sharedWalls.first;
        expect(sharedWall.lengthFeet, closeTo(10.0, 0.1));
        expect(sharedWall.startX, closeTo(10.0, 0.1));
        expect(sharedWall.endX, closeTo(10.0, 0.1));

        // Exterior wall total length: 20 (N) + 20 (S) + 10 (W) + 10 (E) = 60 ft
        final totalExtLength = exteriorWalls.fold<double>(
          0.0,
          (s, w) => s + w.lengthFeet,
        );
        expect(totalExtLength, closeTo(60.0, 0.2));

        // Total physical wall length = 60 (ext) + 10 (int) = 70 ft (NOT 80 ft if double counted)
        final totalWallLength = physicalWalls.fold<double>(
          0.0,
          (s, w) => s + w.lengthFeet,
        );
        expect(totalWallLength, closeTo(70.0, 0.2));
      },
    );

    test(
      'generates comprehensive material report with line items and cost totals',
      () {
        final plan = PlanTemplates.createPlan(
          name: '2 BHK Estimate Test',
          layoutType: PlanTemplates.layout2BHK,
          plotWidthFeet: 36.0,
          plotLengthFeet: 48.0,
        );

        final report = PlanMaterialEstimator.estimateMaterials(
          plan: plan,
          assumptions: const MaterialEstimationAssumptions(),
        );

        expect(report.totalCarpetAreaSqFt, greaterThan(300.0));
        expect(
          report.totalBuiltUpAreaSqFt,
          greaterThan(report.totalCarpetAreaSqFt),
        );
        expect(report.physicalWalls, isNotEmpty);
        expect(report.lineItems, isNotEmpty);

        // Verify essential categories exist in line items
        expect(
          report.lineItems.any((i) => i.category == MaterialCategory.masonry),
          isTrue,
        );
        expect(
          report.lineItems.any((i) => i.category == MaterialCategory.mortar),
          isTrue,
        );
        expect(
          report.lineItems.any((i) => i.category == MaterialCategory.plaster),
          isTrue,
        );
        expect(
          report.lineItems.any((i) => i.category == MaterialCategory.paint),
          isTrue,
        );
        expect(
          report.lineItems.any((i) => i.category == MaterialCategory.tile),
          isTrue,
        );

        // Verify total cost is computed from line items
        expect(report.totalEstimatedCost, greaterThan(10000.0));
      },
    );
  });
}
