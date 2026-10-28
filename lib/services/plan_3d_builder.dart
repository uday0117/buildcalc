import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/plan/plan_3d_models.dart';
import '../models/plan/plan_geometry.dart';
import '../models/plan/plan_models.dart';
import '../models/plan/plan_unit.dart';

class Plan3DBuilder {
  static const double defaultWallHeightFeet = 10.0;
  static const double defaultWallThicknessFeet = 0.65; // ~8 inches
  static const double defaultDoorHeightFeet = 7.0;
  static const double defaultWindowSillHeightFeet = 3.0;
  static const double defaultWindowHeightFeet = 4.0;

  /// Validates a floor plan for 3D reconstruction
  static Plan3DValidationResult validatePlan(FloorPlan plan) {
    final List<String> errors = [];
    final List<String> warnings = [];

    if (plan.rooms.isEmpty) {
      errors.add('Floor plan contains no rooms. Add rooms in the 2D editor to generate 3D geometry.');
    }

    if (plan.plotWidthFeet <= 0 || plan.plotLengthFeet <= 0) {
      errors.add('Plot dimensions must be greater than zero (${plan.plotWidthFeet} × ${plan.plotLengthFeet} ft).');
    }

    for (final room in plan.rooms) {
      if (room.width <= 0 || room.length <= 0) {
        errors.add('Room "${room.name}" has invalid dimensions: ${room.width.toStringAsFixed(1)} × ${room.length.toStringAsFixed(1)} ft.');
      }

      if (!PlanGeometry.isRoomWithinPlot(room, plan.plotWidthFeet, plan.plotLengthFeet)) {
        warnings.add('Room "${room.name}" extends beyond the plot boundary.');
      }

      for (final op in room.openings) {
        final wallLen = room.wallLength(op.wallSide);
        if (op.widthFeet > wallLen) {
          warnings.add('Opening (${op.type.label}) in "${room.name}" exceeds wall length (${op.widthFeet} > $wallLen ft).');
        }
        if (op.offsetFeet + op.widthFeet > wallLen + 0.1) {
          warnings.add('Opening (${op.type.label}) in "${room.name}" extends past wall boundary and will be clipped.');
        }
      }
    }

    final overlappingPairs = PlanGeometry.findOverlappingPairs(plan.rooms);
    for (final pair in overlappingPairs) {
      warnings.add('Rooms "${pair[0].name}" and "${pair[1].name}" overlap. Shared interior boundaries may intersect.');
    }

    return Plan3DValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Builds a complete 3D mesh from a floor plan and optional building levels
  static Mesh3D buildScene({
    required FloorPlan plan,
    List<BuildingFloorLevel>? customLevels,
    Scene3DMaterial wallMaterial = Scene3DMaterial.plasterWhite,
    Scene3DMaterial floorMaterial = Scene3DMaterial.oakHardwood,
    CutawayMode cutawayMode = CutawayMode.full,
    bool showGroundPlot = true,
    bool showRoomLabels = true,
    PlanUnit displayUnit = PlanUnit.feet,
  }) {
    if (plan.rooms.isEmpty) {
      return Mesh3D.empty();
    }

    // Support ground floor first, extensible to multi-level
    final levels = customLevels ??
        [
          BuildingFloorLevel(
            levelIndex: 0,
            name: 'Ground Floor',
            elevationFeet: 0.0,
            heightFeet: defaultWallHeightFeet,
            rooms: plan.rooms,
          ),
        ];

    final List<Polygon3D> polygons = [];
    final List<RoomAnnotation3D> annotations = [];

    double minX = 0.0;
    double minY = 0.0;
    double minZ = 0.0;
    double maxX = plan.plotWidthFeet;
    double maxY = plan.plotLengthFeet;
    double maxZ = 0.0;

    // 1. Ground Plot Base Foundation
    if (showGroundPlot) {
      final plotPad = 1.5;
      final plotLeft = -plotPad;
      final plotTop = -plotPad;
      final plotRight = plan.plotWidthFeet + plotPad;
      final plotBottom = plan.plotLengthFeet + plotPad;
      const baseTopZ = 0.0;
      const baseBotZ = -0.3;

      // Top ground grass / gravel surface
      polygons.add(
        Polygon3D.fromVertices(
          vertices: [
            Point3D(plotLeft, plotTop, baseTopZ),
            Point3D(plotRight, plotTop, baseTopZ),
            Point3D(plotRight, plotBottom, baseTopZ),
            Point3D(plotLeft, plotBottom, baseTopZ),
          ],
          baseColor: const Color(0xFFE2E8F0), // Clean architectural lawn / courtyard slate
          category: PolygonCategory.groundPlot,
          edgeColor: const Color(0xFFCBD5E1),
          edgeWidth: 1.0,
        ),
      );

      // Plot perimeter curb
      _addBoxFaces(
        polygons: polygons,
        minPt: Point3D(plotLeft, plotTop, baseBotZ),
        maxPt: Point3D(plotRight, plotBottom, baseTopZ),
        color: const Color(0xFF94A3B8),
        category: PolygonCategory.plinthBase,
        edgeColor: const Color(0xFF64748B),
      );
    }

    // 2. Iterate through levels (Ground Floor first)
    for (final level in levels) {
      final baseZ = level.elevationFeet;
      final effectiveWallHeight = math.min(level.heightFeet, cutawayMode.wallHeightFeet);
      final levelTopZ = baseZ + effectiveWallHeight;

      if (levelTopZ > maxZ) maxZ = levelTopZ;

      for (final room in level.rooms) {
        final r = room.rect;
        if (r.left < minX) minX = r.left;
        if (r.top < minY) minY = r.top;
        if (r.right > maxX) maxX = r.right;
        if (r.bottom > maxY) maxY = r.bottom;

        // Room Floor Slab
        final roomFloorZ = baseZ + 0.02; // Slight raise above plot base to eliminate z-fighting
        polygons.add(
          Polygon3D.fromVertices(
            vertices: [
              Point3D(r.left, r.top, roomFloorZ),
              Point3D(r.right, r.top, roomFloorZ),
              Point3D(r.right, r.bottom, roomFloorZ),
              Point3D(r.left, r.bottom, roomFloorZ),
            ],
            baseColor: _blendFloorColor(room.color, floorMaterial.color),
            category: PolygonCategory.floor,
            edgeColor: Colors.black26,
            edgeWidth: 1.0,
            metadata: room.id,
          ),
        );

        // Add 3D Room Label
        if (showRoomLabels) {
          annotations.add(
            RoomAnnotation3D(
              id: room.id,
              name: room.name,
              dimensionsText: displayUnit.formatDimensions(room.width, room.length),
              position: Point3D(
                r.left + room.width / 2,
                r.top + room.length / 2,
                roomFloorZ + 0.15,
              ),
              color: room.color,
            ),
          );
        }

        // Room 4 Walls with Door / Window Openings
        _buildRoomWalls(
          polygons: polygons,
          room: room,
          baseZ: baseZ,
          wallHeight: effectiveWallHeight,
          wallMaterial: wallMaterial,
          cutawayMode: cutawayMode,
        );
      }
    }

    final minBound = Point3D(minX, minY, minZ);
    final maxBound = Point3D(maxX, maxY, maxZ);
    final center = Point3D(
      (minX + maxX) / 2,
      (minY + maxY) / 2,
      (minZ + maxZ) / 2,
    );

    return Mesh3D(
      polygons: polygons,
      minBound: minBound,
      maxBound: maxBound,
      center: center,
      roomAnnotations: annotations,
    );
  }

  /// Builds the 4 walls of a room, accounting for all openings
  static void _buildRoomWalls({
    required List<Polygon3D> polygons,
    required PlanRoom room,
    required double baseZ,
    required double wallHeight,
    required Scene3DMaterial wallMaterial,
    required CutawayMode cutawayMode,
  }) {
    final r = room.rect;
    const thickness = defaultWallThicknessFeet;
    final halfThick = thickness / 2;

    // Group openings by wall side
    final Map<PlanWallSide, List<PlanOpening>> openingsBySide = {
      PlanWallSide.north: [],
      PlanWallSide.south: [],
      PlanWallSide.east: [],
      PlanWallSide.west: [],
    };

    for (final op in room.openings) {
      openingsBySide[op.wallSide]?.add(op);
    }

    // 1. North Wall (Top horizontal: Left to Right along X, normal points North/-Y)
    _buildSingleWall(
      polygons: polygons,
      pStart: Offset(r.left, r.top),
      pEnd: Offset(r.right, r.top),
      normal2D: const Offset(0, -1),
      openings: openingsBySide[PlanWallSide.north] ?? [],
      wallLength: room.width,
      halfThickness: halfThick,
      baseZ: baseZ,
      wallHeight: wallHeight,
      wallMaterial: wallMaterial,
      cutawayMode: cutawayMode,
      roomName: room.name,
    );

    // 2. South Wall (Bottom horizontal: Left to Right along X, normal points South/+Y)
    _buildSingleWall(
      polygons: polygons,
      pStart: Offset(r.left, r.bottom),
      pEnd: Offset(r.right, r.bottom),
      normal2D: const Offset(0, 1),
      openings: openingsBySide[PlanWallSide.south] ?? [],
      wallLength: room.width,
      halfThickness: halfThick,
      baseZ: baseZ,
      wallHeight: wallHeight,
      wallMaterial: wallMaterial,
      cutawayMode: cutawayMode,
      roomName: room.name,
    );

    // 3. West Wall (Left vertical: Top to Bottom along Y, normal points West/-X)
    _buildSingleWall(
      polygons: polygons,
      pStart: Offset(r.left, r.top),
      pEnd: Offset(r.left, r.bottom),
      normal2D: const Offset(-1, 0),
      openings: openingsBySide[PlanWallSide.west] ?? [],
      wallLength: room.length,
      halfThickness: halfThick,
      baseZ: baseZ,
      wallHeight: wallHeight,
      wallMaterial: wallMaterial,
      cutawayMode: cutawayMode,
      roomName: room.name,
    );

    // 4. East Wall (Right vertical: Top to Bottom along Y, normal points East/+X)
    _buildSingleWall(
      polygons: polygons,
      pStart: Offset(r.right, r.top),
      pEnd: Offset(r.right, r.bottom),
      normal2D: const Offset(1, 0),
      openings: openingsBySide[PlanWallSide.east] ?? [],
      wallLength: room.length,
      halfThickness: halfThick,
      baseZ: baseZ,
      wallHeight: wallHeight,
      wallMaterial: wallMaterial,
      cutawayMode: cutawayMode,
      roomName: room.name,
    );
  }

  /// Builds a single wall linear run with openings (doors, windows)
  static void _buildSingleWall({
    required List<Polygon3D> polygons,
    required Offset pStart,
    required Offset pEnd,
    required Offset normal2D,
    required List<PlanOpening> openings,
    required double wallLength,
    required double halfThickness,
    required double baseZ,
    required double wallHeight,
    required Scene3DMaterial wallMaterial,
    required CutawayMode cutawayMode,
    required String roomName,
  }) {
    final dir = (pEnd - pStart) / wallLength; // Unit direction along wall
    final perp = Offset(-dir.dy, dir.dx); // Perpendicular unit vector

    // Sort openings by offset along the wall
    final sortedOpenings = List<PlanOpening>.from(openings)
      ..sort((a, b) => a.offsetFeet.compareTo(b.offsetFeet));

    double currentOffset = 0.0;

    for (final op in sortedOpenings) {
      // Clamped opening position
      final opStart = op.offsetFeet.clamp(0.0, wallLength).toDouble();
      final opWidth = op.widthFeet.clamp(0.5, math.max<double>(0.5, wallLength - opStart)).toDouble();
      final opEnd = (opStart + opWidth).clamp(0.0, wallLength).toDouble();

      // Solid wall segment before opening
      if (opStart > currentOffset + 0.05) {
        _addWallSegmentBox(
          polygons: polygons,
          pA: pStart + dir * currentOffset,
          pB: pStart + dir * opStart,
          perp: perp,
          halfThickness: halfThickness,
          zBottom: baseZ,
          zTop: baseZ + wallHeight,
          color: wallMaterial.color,
          category: PolygonCategory.wallExterior,
        );
      }

      // Opening Segment (Doorway or Window)
      final opPointA = pStart + dir * opStart;
      final opPointB = pStart + dir * opEnd;

      if (op.type.isDoor) {
        _buildDoorOpening(
          polygons: polygons,
          pA: opPointA,
          pB: opPointB,
          dir: dir,
          perp: perp,
          halfThickness: halfThickness,
          baseZ: baseZ,
          wallHeight: wallHeight,
          wallColor: wallMaterial.color,
          doorWidth: opWidth,
          swingInward: op.swingInward,
          cutawayMode: cutawayMode,
        );
      } else {
        // Window or Ventilator
        _buildWindowOpening(
          polygons: polygons,
          pA: opPointA,
          pB: opPointB,
          dir: dir,
          perp: perp,
          halfThickness: halfThickness,
          baseZ: baseZ,
          wallHeight: wallHeight,
          wallColor: wallMaterial.color,
          isVentilator: op.type == OpeningType.ventilation,
          cutawayMode: cutawayMode,
        );
      }

      currentOffset = math.max(currentOffset, opEnd);
    }

    // Remaining solid wall segment after last opening
    if (wallLength > currentOffset + 0.05) {
      _addWallSegmentBox(
        polygons: polygons,
        pA: pStart + dir * currentOffset,
        pB: pEnd,
        perp: perp,
        halfThickness: halfThickness,
        zBottom: baseZ,
        zTop: baseZ + wallHeight,
        color: wallMaterial.color,
        category: PolygonCategory.wallExterior,
      );
    }
  }

  /// Builds a 3D door opening: cutout, header lintel above door, frame, and door leaf panel
  static void _buildDoorOpening({
    required List<Polygon3D> polygons,
    required Offset pA,
    required Offset pB,
    required Offset dir,
    required Offset perp,
    required double halfThickness,
    required double baseZ,
    required double wallHeight,
    required Color wallColor,
    required double doorWidth,
    required bool swingInward,
    required CutawayMode cutawayMode,
  }) {
    final doorHeaderZ = baseZ + math.min(wallHeight, defaultDoorHeightFeet);
    final wallTopZ = baseZ + wallHeight;

    // 1. Lintel wall segment above door (only if wall height exceeds door height)
    if (wallTopZ > doorHeaderZ + 0.1) {
      _addWallSegmentBox(
        polygons: polygons,
        pA: pA,
        pB: pB,
        perp: perp,
        halfThickness: halfThickness,
        zBottom: doorHeaderZ,
        zTop: wallTopZ,
        color: wallColor,
        category: PolygonCategory.wallLintel,
      );
    }

    // 2. Door Frame Trim (Jambs and Top Header)
    const frameThick = 0.15; // ~2 inches frame
    final frameColor = const Color(0xFF4A3728); // Rich dark timber door frame
    final jambHeight = math.min(wallHeight, defaultDoorHeightFeet);

    // Left Jamb
    _addWallSegmentBox(
      polygons: polygons,
      pA: pA,
      pB: pA + dir * frameThick,
      perp: perp,
      halfThickness: halfThickness * 1.05,
      zBottom: baseZ,
      zTop: baseZ + jambHeight,
      color: frameColor,
      category: PolygonCategory.doorFrame,
    );

    // Right Jamb
    _addWallSegmentBox(
      polygons: polygons,
      pA: pB - dir * frameThick,
      pB: pB,
      perp: perp,
      halfThickness: halfThickness * 1.05,
      zBottom: baseZ,
      zTop: baseZ + jambHeight,
      color: frameColor,
      category: PolygonCategory.doorFrame,
    );

    // 3. 3D Door Leaf (Angled 45 degrees ajar to clearly showcase open door and swing)
    final swingDir = swingInward ? -1.0 : 1.0;
    final hingePoint = pA + dir * frameThick;
    final doorSwingAngle = math.pi / 4; // 45 degrees open
    final leafDir = Offset(
      dir.dx * math.cos(doorSwingAngle) - perp.dx * math.sin(doorSwingAngle) * swingDir,
      dir.dy * math.cos(doorSwingAngle) - perp.dy * math.sin(doorSwingAngle) * swingDir,
    );
    final leafEnd = hingePoint + leafDir * (doorWidth - frameThick * 2);
    final doorLeafHeight = math.min(wallHeight, defaultDoorHeightFeet - 0.1);

    if (cutawayMode != CutawayMode.floorOnly) {
      _addWallSegmentBox(
        polygons: polygons,
        pA: hingePoint,
        pB: leafEnd,
        perp: perp,
        halfThickness: 0.08, // Door leaf thickness
        zBottom: baseZ + 0.05,
        zTop: baseZ + doorLeafHeight,
        color: const Color(0xFF8B5A2B), // Natural wood door panel
        category: PolygonCategory.doorLeaf,
        edgeColor: const Color(0xFF5C381E),
      );
    }
  }

  /// Builds a 3D window opening: sill wall below, opening cutout with glass & frame, lintel above
  static void _buildWindowOpening({
    required List<Polygon3D> polygons,
    required Offset pA,
    required Offset pB,
    required Offset dir,
    required Offset perp,
    required double halfThickness,
    required double baseZ,
    required double wallHeight,
    required Color wallColor,
    required bool isVentilator,
    required CutawayMode cutawayMode,
  }) {
    final sillHeight = isVentilator ? 6.5 : defaultWindowSillHeightFeet;
    final winHeight = isVentilator ? 2.0 : defaultWindowHeightFeet;

    final zSillTop = baseZ + math.min(wallHeight, sillHeight);
    final zWinTop = baseZ + math.min(wallHeight, sillHeight + winHeight);
    final zWallTop = baseZ + wallHeight;

    // 1. Sill Wall below window
    if (zSillTop > baseZ + 0.05) {
      _addWallSegmentBox(
        polygons: polygons,
        pA: pA,
        pB: pB,
        perp: perp,
        halfThickness: halfThickness,
        zBottom: baseZ,
        zTop: zSillTop,
        color: wallColor,
        category: PolygonCategory.wallSill,
      );
    }

    // 2. Lintel Wall above window (if wall reaches above window)
    if (zWallTop > zWinTop + 0.05) {
      _addWallSegmentBox(
        polygons: polygons,
        pA: pA,
        pB: pB,
        perp: perp,
        halfThickness: halfThickness,
        zBottom: zWinTop,
        zTop: zWallTop,
        color: wallColor,
        category: PolygonCategory.wallLintel,
      );
    }

    // 3. Window Glass Pane & Frame (if cutaway allows window span)
    if (zWinTop > zSillTop + 0.2 && cutawayMode != CutawayMode.floorOnly) {
      // Aluminum / UPVC window frame
      const frameColor = Color(0xFF334155); // Dark architectural charcoal frame

      // Left Frame Member
      _addWallSegmentBox(
        polygons: polygons,
        pA: pA,
        pB: pA + dir * 0.12,
        perp: perp,
        halfThickness: halfThickness * 0.7,
        zBottom: zSillTop,
        zTop: zWinTop,
        color: frameColor,
        category: PolygonCategory.windowFrame,
      );

      // Right Frame Member
      _addWallSegmentBox(
        polygons: polygons,
        pA: pB - dir * 0.12,
        pB: pB,
        perp: perp,
        halfThickness: halfThickness * 0.7,
        zBottom: zSillTop,
        zTop: zWinTop,
        color: frameColor,
        category: PolygonCategory.windowFrame,
      );

      // Translucent Window Glass Pane
      final glassLeft = pA + dir * 0.12;
      final glassRight = pB - dir * 0.12;
      const glassColor = Color(0xFF67B7D1); // Soft Sky Tinted Glass

      polygons.add(
        Polygon3D.fromVertices(
          vertices: [
            Point3D(glassLeft.dx, glassLeft.dy, zSillTop + 0.1),
            Point3D(glassRight.dx, glassRight.dy, zSillTop + 0.1),
            Point3D(glassRight.dx, glassRight.dy, zWinTop - 0.1),
            Point3D(glassLeft.dx, glassLeft.dy, zWinTop - 0.1),
          ],
          baseColor: glassColor,
          category: PolygonCategory.windowGlass,
          opacity: 0.45,
          edgeColor: const Color(0xFF38BDF8),
          edgeWidth: 1.0,
        ),
      );
    }
  }

  /// Adds a 3D wall segment box (6 faces) between two 2D points with wall thickness
  static void _addWallSegmentBox({
    required List<Polygon3D> polygons,
    required Offset pA,
    required Offset pB,
    required Offset perp,
    required double halfThickness,
    required double zBottom,
    required double zTop,
    required Color color,
    required PolygonCategory category,
    Color? edgeColor,
  }) {
    if (zTop <= zBottom + 0.01) return;

    // 4 base corners
    final c1 = pA + perp * halfThickness; // Outer start
    final c2 = pB + perp * halfThickness; // Outer end
    final c3 = pB - perp * halfThickness; // Inner end
    final c4 = pA - perp * halfThickness; // Inner start

    final pC1Bot = Point3D(c1.dx, c1.dy, zBottom);
    final pC2Bot = Point3D(c2.dx, c2.dy, zBottom);
    final pC3Bot = Point3D(c3.dx, c3.dy, zBottom);
    final pC4Bot = Point3D(c4.dx, c4.dy, zBottom);

    final pC1Top = Point3D(c1.dx, c1.dy, zTop);
    final pC2Top = Point3D(c2.dx, c2.dy, zTop);
    final pC3Top = Point3D(c3.dx, c3.dy, zTop);
    final pC4Top = Point3D(c4.dx, c4.dy, zTop);

    final border = edgeColor ?? Colors.black.withValues(alpha: 0.18);

    // Face 1: Outer Vertical Face (Facing perp)
    polygons.add(
      Polygon3D.fromVertices(
        vertices: [pC1Bot, pC2Bot, pC2Top, pC1Top],
        baseColor: color,
        category: category,
        edgeColor: border,
      ),
    );

    // Face 2: Inner Vertical Face (Facing -perp)
    polygons.add(
      Polygon3D.fromVertices(
        vertices: [pC3Bot, pC4Bot, pC4Top, pC3Top],
        baseColor: color,
        category: category,
        edgeColor: border,
      ),
    );

    // Face 3: Top Cap Face (Facing +Z)
    polygons.add(
      Polygon3D.fromVertices(
        vertices: [pC1Top, pC2Top, pC3Top, pC4Top],
        baseColor: color,
        category: category,
        edgeColor: border,
      ),
    );

    // Face 4: Start End Cap (Facing -dir)
    polygons.add(
      Polygon3D.fromVertices(
        vertices: [pC4Bot, pC1Bot, pC1Top, pC4Top],
        baseColor: color,
        category: category,
        edgeColor: border,
      ),
    );

    // Face 5: End Cap (Facing +dir)
    polygons.add(
      Polygon3D.fromVertices(
        vertices: [pC2Bot, pC3Bot, pC3Top, pC2Top],
        baseColor: color,
        category: category,
        edgeColor: border,
      ),
    );
  }

  /// Adds a generic 3D axis-aligned box
  static void _addBoxFaces({
    required List<Polygon3D> polygons,
    required Point3D minPt,
    required Point3D maxPt,
    required Color color,
    required PolygonCategory category,
    Color? edgeColor,
  }) {
    final c1 = Point3D(minPt.x, minPt.y, minPt.z);
    final c2 = Point3D(maxPt.x, minPt.y, minPt.z);
    final c3 = Point3D(maxPt.x, maxPt.y, minPt.z);
    final c4 = Point3D(minPt.x, maxPt.y, minPt.z);

    final c5 = Point3D(minPt.x, minPt.y, maxPt.z);
    final c6 = Point3D(maxPt.x, minPt.y, maxPt.z);
    final c7 = Point3D(maxPt.x, maxPt.y, maxPt.z);
    final c8 = Point3D(minPt.x, maxPt.y, maxPt.z);

    final border = edgeColor ?? Colors.black.withValues(alpha: 0.15);

    // Top
    polygons.add(Polygon3D.fromVertices(vertices: [c5, c6, c7, c8], baseColor: color, category: category, edgeColor: border));
    // North
    polygons.add(Polygon3D.fromVertices(vertices: [c1, c2, c6, c5], baseColor: color, category: category, edgeColor: border));
    // South
    polygons.add(Polygon3D.fromVertices(vertices: [c3, c4, c8, c7], baseColor: color, category: category, edgeColor: border));
    // West
    polygons.add(Polygon3D.fromVertices(vertices: [c4, c1, c5, c8], baseColor: color, category: category, edgeColor: border));
    // East
    polygons.add(Polygon3D.fromVertices(vertices: [c2, c3, c7, c6], baseColor: color, category: category, edgeColor: border));
  }

  /// Blends the room's identity color with selected floor material
  static Color _blendFloorColor(Color roomColor, Color materialColor) {
    return Color.lerp(materialColor, roomColor, 0.35) ?? materialColor;
  }
}
