import 'dart:math' as math;

import '../models/plan/material_estimation_models.dart';
import '../models/plan/plan_models.dart';

class PlanMaterialEstimator {
  static const double cuFtPerCementBag = 1.226; // 1 bag (50 kg) of cement = 1.226 cu ft (~0.0347 m3)
  static const double tolerance = 0.05; // 0.05 ft geometry tolerance

  /// Generate the complete material estimation report from floor plan geometry and assumptions
  static PlanMaterialEstimateReport estimateMaterials({
    required FloorPlan plan,
    MaterialEstimationAssumptions assumptions = const MaterialEstimationAssumptions(),
  }) {
    if (plan.rooms.isEmpty) {
      return PlanMaterialEstimateReport(
        planId: plan.id,
        planName: plan.name,
        generatedAt: DateTime.now(),
        assumptions: assumptions,
        totalPlotAreaSqFt: plan.totalPlotAreaSqFt,
        totalBuiltUpAreaSqFt: 0.0,
        totalCarpetAreaSqFt: 0.0,
        overlappingAreaSqFt: 0.0,
        exteriorWallLengthFeet: 0.0,
        interiorSharedWallLengthFeet: 0.0,
        totalPhysicalWallLengthFeet: 0.0,
        grossMasonryVolumeCuFt: 0.0,
        openingsDeductionVolumeCuFt: 0.0,
        netMasonryVolumeCuFt: 0.0,
        totalOpeningsAreaSqFt: 0.0,
        totalOpeningsCount: 0,
        physicalWalls: const [],
        roomBreakdowns: const [],
        lineItems: const [],
      );
    }

    // 1. Calculate room-wise carpet areas and overlapping area
    final overlappingAreaSqFt = _calculateOverlappingArea(plan.rooms);
    final rawCarpetAreaSqFt = plan.rooms.fold<double>(0.0, (s, r) => s + r.areaSqFt);
    final netCarpetAreaSqFt = math.max(0.0, rawCarpetAreaSqFt - overlappingAreaSqFt);

    // 2. Extract deduplicated physical walls (exterior vs shared interior partition walls)
    final physicalWalls = extractPhysicalWalls(plan.rooms, assumptions);

    // Wall length metrics
    double exteriorWallLength = 0.0;
    double interiorSharedWallLength = 0.0;
    double grossMasonryVol = 0.0;
    double openingsDeductionVol = 0.0;
    double netMasonryVol = 0.0;
    double totalOpeningsArea = 0.0;
    int totalOpeningsCount = 0;

    for (final wall in physicalWalls) {
      if (wall.isExterior) {
        exteriorWallLength += wall.lengthFeet;
      } else {
        interiorSharedWallLength += wall.lengthFeet;
      }
      grossMasonryVol += wall.grossVolumeCuFt;
      openingsDeductionVol += wall.openingsVolumeCuFt;
      netMasonryVol += wall.netVolumeCuFt;
      totalOpeningsArea += wall.openingsAreaSqFt;
      totalOpeningsCount += wall.openings.length;
    }

    final totalPhysicalWallLength = exteriorWallLength + interiorSharedWallLength;

    // Built-up area: net room carpet + physical wall footprint
    double wallFootprintArea = 0.0;
    for (final wall in physicalWalls) {
      wallFootprintArea += wall.lengthFeet * wall.thicknessFeet;
    }
    final totalBuiltUpAreaSqFt = netCarpetAreaSqFt + wallFootprintArea;

    // 3. Room-wise breakdowns
    final roomBreakdowns = _buildRoomBreakdowns(plan.rooms, assumptions);

    // 4. Generate material line items
    final lineItems = _calculateLineItems(
      assumptions: assumptions,
      physicalWalls: physicalWalls,
      roomBreakdowns: roomBreakdowns,
      totalBuiltUpAreaSqFt: totalBuiltUpAreaSqFt,
      netCarpetAreaSqFt: netCarpetAreaSqFt,
      exteriorWallLengthFeet: exteriorWallLength,
      totalPhysicalWallLengthFeet: totalPhysicalWallLength,
      netMasonryVolumeCuFt: netMasonryVol,
    );

    return PlanMaterialEstimateReport(
      planId: plan.id,
      planName: plan.name,
      generatedAt: DateTime.now(),
      assumptions: assumptions,
      totalPlotAreaSqFt: plan.totalPlotAreaSqFt,
      totalBuiltUpAreaSqFt: totalBuiltUpAreaSqFt,
      totalCarpetAreaSqFt: netCarpetAreaSqFt,
      overlappingAreaSqFt: overlappingAreaSqFt,
      exteriorWallLengthFeet: exteriorWallLength,
      interiorSharedWallLengthFeet: interiorSharedWallLength,
      totalPhysicalWallLengthFeet: totalPhysicalWallLength,
      grossMasonryVolumeCuFt: grossMasonryVol,
      openingsDeductionVolumeCuFt: openingsDeductionVol,
      netMasonryVolumeCuFt: netMasonryVol,
      totalOpeningsAreaSqFt: totalOpeningsArea,
      totalOpeningsCount: totalOpeningsCount,
      physicalWalls: physicalWalls,
      roomBreakdowns: roomBreakdowns,
      lineItems: lineItems,
    );
  }

  /// Extracts non-overlapping physical wall segments from room polygons
  /// Deduplicates shared partition walls so they are counted only once in masonry.
  static List<PhysicalWallSegment> extractPhysicalWalls(
    List<PlanRoom> rooms,
    MaterialEstimationAssumptions assumptions,
  ) {
    if (rooms.isEmpty) return [];

    final List<_RawWallSegment> rawSegments = [];

    // 1. Process Horizontal Edges
    final horizontalClusters = _clusterEdges(
      rooms,
      isHorizontal: true,
    );

    for (final cluster in horizontalClusters.entries) {
      final y = cluster.key;
      final edges = cluster.value; // List of _RoomEdge along this horizontal line

      // Collect all key x-coordinates (endpoints of edges and room bounds intersecting this line)
      final Set<double> xPoints = {};
      for (final e in edges) {
        xPoints.add(_roundCoord(e.start));
        xPoints.add(_roundCoord(e.end));
      }
      for (final r in rooms) {
        if (r.y - tolerance <= y && y <= (r.y + r.length + tolerance)) {
          xPoints.add(_roundCoord(r.x));
          xPoints.add(_roundCoord(r.x + r.width));
        }
      }

      final sortedX = xPoints.toList()..sort();

      for (int i = 0; i < sortedX.length - 1; i++) {
        final x1 = sortedX[i];
        final x2 = sortedX[i + 1];
        final len = x2 - x1;
        if (len < tolerance) continue;

        final midX = (x1 + x2) / 2.0;

        // Check if midpoint is inside any other room interior (ignore boundary)
        final isInsideAnyRoom = rooms.any((r) =>
            (r.x + tolerance) < midX &&
            midX < (r.x + r.width - tolerance) &&
            (r.y + tolerance) < y &&
            y < (r.y + r.length - tolerance));

        if (isInsideAnyRoom) continue;

        // Check which rooms have an edge covering this segment
        final coveringEdges = edges
            .where((e) => e.start <= x1 + tolerance && e.end >= x2 - tolerance)
            .toList();

        if (coveringEdges.isEmpty) continue;

        final roomIds = coveringEdges.map((e) => e.roomId).toSet().toList();
        final isExterior = coveringEdges.length == 1;

        rawSegments.add(_RawWallSegment(
          startX: x1,
          startY: y,
          endX: x2,
          endY: y,
          isHorizontal: true,
          isExterior: isExterior,
          roomIds: roomIds,
        ));
      }
    }

    // 2. Process Vertical Edges
    final verticalClusters = _clusterEdges(
      rooms,
      isHorizontal: false,
    );

    for (final cluster in verticalClusters.entries) {
      final x = cluster.key;
      final edges = cluster.value;

      final Set<double> yPoints = {};
      for (final e in edges) {
        yPoints.add(_roundCoord(e.start));
        yPoints.add(_roundCoord(e.end));
      }
      for (final r in rooms) {
        if (r.x - tolerance <= x && x <= (r.x + r.width + tolerance)) {
          yPoints.add(_roundCoord(r.y));
          yPoints.add(_roundCoord(r.y + r.length));
        }
      }

      final sortedY = yPoints.toList()..sort();

      for (int i = 0; i < sortedY.length - 1; i++) {
        final y1 = sortedY[i];
        final y2 = sortedY[i + 1];
        final len = y2 - y1;
        if (len < tolerance) continue;

        final midY = (y1 + y2) / 2.0;

        final isInsideAnyRoom = rooms.any((r) =>
            (r.x + tolerance) < x &&
            x < (r.x + r.width - tolerance) &&
            (r.y + tolerance) < midY &&
            midY < (r.y + r.length - tolerance));

        if (isInsideAnyRoom) continue;

        final coveringEdges = edges
            .where((e) => e.start <= y1 + tolerance && e.end >= y2 - tolerance)
            .toList();

        if (coveringEdges.isEmpty) continue;

        final roomIds = coveringEdges.map((e) => e.roomId).toSet().toList();
        final isExterior = coveringEdges.length == 1;

        rawSegments.add(_RawWallSegment(
          startX: x,
          startY: y1,
          endX: x,
          endY: y2,
          isHorizontal: false,
          isExterior: isExterior,
          roomIds: roomIds,
        ));
      }
    }

    // 3. Merge adjacent collinear raw segments having the same properties
    final mergedSegments = _mergeAdjacentSegments(rawSegments);

    // 4. Attach openings and build PhysicalWallSegments
    final List<PhysicalWallSegment> physicalWalls = [];
    int wallIdx = 1;

    for (final seg in mergedSegments) {
      final thickness = seg.isExterior
          ? assumptions.exteriorWallThicknessFeet
          : assumptions.interiorWallThicknessFeet;

      final length = seg.length;
      final openings = _findOpeningsForSegment(seg, rooms);

      physicalWalls.add(PhysicalWallSegment(
        id: 'wall_${seg.isExterior ? 'ext' : 'int'}_${wallIdx++}',
        startX: seg.startX,
        startY: seg.startY,
        endX: seg.endX,
        endY: seg.endY,
        lengthFeet: length,
        heightFeet: assumptions.wallHeightFeet,
        thicknessFeet: thickness,
        isExterior: seg.isExterior,
        roomIds: seg.roomIds,
        openings: openings,
      ));
    }

    return physicalWalls;
  }

  /// Groups edges of rooms along lines (within tolerance)
  static Map<double, List<_RoomEdge>> _clusterEdges(
    List<PlanRoom> rooms, {
    required bool isHorizontal,
  }) {
    final Map<double, List<_RoomEdge>> clusters = {};

    for (final room in rooms) {
      if (isHorizontal) {
        // North edge (y = room.y)
        _addEdgeToClusters(
          clusters,
          room.y,
          _RoomEdge(
            roomId: room.id,
            start: math.min(room.x, room.x + room.width),
            end: math.max(room.x, room.x + room.width),
            wallSide: PlanWallSide.north,
          ),
        );
        // South edge (y = room.y + room.length)
        _addEdgeToClusters(
          clusters,
          room.y + room.length,
          _RoomEdge(
            roomId: room.id,
            start: math.min(room.x, room.x + room.width),
            end: math.max(room.x, room.x + room.width),
            wallSide: PlanWallSide.south,
          ),
        );
      } else {
        // West edge (x = room.x)
        _addEdgeToClusters(
          clusters,
          room.x,
          _RoomEdge(
            roomId: room.id,
            start: math.min(room.y, room.y + room.length),
            end: math.max(room.y, room.y + room.length),
            wallSide: PlanWallSide.west,
          ),
        );
        // East edge (x = room.x + room.width)
        _addEdgeToClusters(
          clusters,
          room.x + room.width,
          _RoomEdge(
            roomId: room.id,
            start: math.min(room.y, room.y + room.length),
            end: math.max(room.y, room.y + room.length),
            wallSide: PlanWallSide.east,
          ),
        );
      }
    }

    return clusters;
  }

  static void _addEdgeToClusters(
    Map<double, List<_RoomEdge>> clusters,
    double coordinate,
    _RoomEdge edge,
  ) {
    for (final key in clusters.keys) {
      if ((key - coordinate).abs() <= tolerance) {
        clusters[key]!.add(edge);
        return;
      }
    }
    clusters[_roundCoord(coordinate)] = [edge];
  }

  static double _roundCoord(double val) {
    return (val * 1000.0).round() / 1000.0;
  }

  /// Merges adjacent collinear segments with identical exterior status
  static List<_RawWallSegment> _mergeAdjacentSegments(List<_RawWallSegment> segments) {
    if (segments.isEmpty) return [];

    // Separate horizontal and vertical
    final hSegments = segments.where((s) => s.isHorizontal).toList();
    final vSegments = segments.where((s) => !s.isHorizontal).toList();

    final List<_RawWallSegment> merged = [];

    // Merge horizontal by Y
    final Map<double, List<_RawWallSegment>> hGroups = {};
    for (final s in hSegments) {
      bool added = false;
      for (final k in hGroups.keys) {
        if ((k - s.startY).abs() <= tolerance) {
          hGroups[k]!.add(s);
          added = true;
          break;
        }
      }
      if (!added) {
        hGroups[s.startY] = [s];
      }
    }

    for (final list in hGroups.values) {
      list.sort((a, b) => a.startX.compareTo(b.startX));
      _mergeCollinearList(list, merged, isHorizontal: true);
    }

    // Merge vertical by X
    final Map<double, List<_RawWallSegment>> vGroups = {};
    for (final s in vSegments) {
      bool added = false;
      for (final k in vGroups.keys) {
        if ((k - s.startX).abs() <= tolerance) {
          vGroups[k]!.add(s);
          added = true;
          break;
        }
      }
      if (!added) {
        vGroups[s.startX] = [s];
      }
    }

    for (final list in vGroups.values) {
      list.sort((a, b) => a.startY.compareTo(b.startY));
      _mergeCollinearList(list, merged, isHorizontal: false);
    }

    return merged;
  }

  static void _mergeCollinearList(
    List<_RawWallSegment> sorted,
    List<_RawWallSegment> output, {
    required bool isHorizontal,
  }) {
    if (sorted.isEmpty) return;

    _RawWallSegment current = sorted.first;

    for (int i = 1; i < sorted.length; i++) {
      final next = sorted[i];

      final isContiguous = isHorizontal
          ? (next.startX - current.endX).abs() <= tolerance
          : (next.startY - current.endY).abs() <= tolerance;

      final sameType = current.isExterior == next.isExterior;

      if (isContiguous && sameType) {
        // Merge into current
        final combinedRooms = {...current.roomIds, ...next.roomIds}.toList();
        current = _RawWallSegment(
          startX: current.startX,
          startY: current.startY,
          endX: isHorizontal ? next.endX : current.endX,
          endY: isHorizontal ? current.endY : next.endY,
          isHorizontal: isHorizontal,
          isExterior: current.isExterior,
          roomIds: combinedRooms,
        );
      } else {
        output.add(current);
        current = next;
      }
    }
    output.add(current);
  }

  /// Finds openings positioned on a physical wall segment with duplicate protection
  static List<PlanOpening> _findOpeningsForSegment(
    _RawWallSegment seg,
    List<PlanRoom> rooms,
  ) {
    final List<PlanOpening> matched = [];
    final List<_Interval1D> recordedIntervals = [];

    for (final roomId in seg.roomIds) {
      PlanRoom? room;
      try {
        room = rooms.firstWhere((r) => r.id == roomId);
      } catch (_) {
        continue;
      }

      for (final op in room.openings) {
        // Check if opening aligns with this segment
        final opInterval = _getOpeningWorldInterval(room, op, seg.isHorizontal);
        if (opInterval == null) continue;

        // Verify coordinate alignment
        final isCoordAligned = seg.isHorizontal
            ? (opInterval.perpCoord - seg.startY).abs() <= tolerance
            : (opInterval.perpCoord - seg.startX).abs() <= tolerance;

        if (!isCoordAligned) continue;

        // Check range overlap with segment
        final segStart = seg.isHorizontal ? seg.startX : seg.startY;
        final segEnd = seg.isHorizontal ? seg.endX : seg.endY;

        final hasOverlap = opInterval.start >= segStart - tolerance &&
            opInterval.end <= segEnd + tolerance;

        if (hasOverlap) {
          // Check if this opening is already accounted for (e.g. shared wall door defined on both rooms)
          final isDuplicate = recordedIntervals.any((iv) =>
              (iv.start - opInterval.start).abs() <= 0.3 &&
              (iv.end - opInterval.end).abs() <= 0.3);

          if (!isDuplicate) {
            matched.add(op);
            recordedIntervals.add(opInterval);
          }
        }
      }
    }

    return matched;
  }

  static _Interval1D? _getOpeningWorldInterval(
    PlanRoom room,
    PlanOpening op,
    bool wantHorizontal,
  ) {
    if (wantHorizontal) {
      if (op.wallSide == PlanWallSide.north) {
        final startX = room.x + op.offsetFeet;
        return _Interval1D(
          start: startX,
          end: startX + op.widthFeet,
          perpCoord: room.y,
        );
      } else if (op.wallSide == PlanWallSide.south) {
        final startX = room.x + op.offsetFeet;
        return _Interval1D(
          start: startX,
          end: startX + op.widthFeet,
          perpCoord: room.y + room.length,
        );
      }
    } else {
      if (op.wallSide == PlanWallSide.west) {
        final startY = room.y + op.offsetFeet;
        return _Interval1D(
          start: startY,
          end: startY + op.widthFeet,
          perpCoord: room.x,
        );
      } else if (op.wallSide == PlanWallSide.east) {
        final startY = room.y + op.offsetFeet;
        return _Interval1D(
          start: startY,
          end: startY + op.widthFeet,
          perpCoord: room.x + room.width,
        );
      }
    }
    return null;
  }

  /// Calculates overlapping area between room rectangles
  static double _calculateOverlappingArea(List<PlanRoom> rooms) {
    double totalOverlap = 0.0;
    for (int i = 0; i < rooms.length; i++) {
      for (int j = i + 1; j < rooms.length; j++) {
        final rA = rooms[i].rect;
        final rB = rooms[j].rect;
        final intersection = rA.intersect(rB);
        // Only count if positive area and width/length > tolerance
        if (intersection.width > tolerance && intersection.height > tolerance) {
          totalOverlap += intersection.width * intersection.height;
        }
      }
    }
    return totalOverlap;
  }

  /// Builds room-wise floor area, interior wall surfaces and openings breakdowns
  static List<RoomQuantityBreakdown> _buildRoomBreakdowns(
    List<PlanRoom> rooms,
    MaterialEstimationAssumptions assumptions,
  ) {
    final List<RoomQuantityBreakdown> list = [];

    for (final room in rooms) {
      final carpetArea = room.width * room.length;
      final perimeter = 2.0 * (room.width + room.length);
      final grossWall = perimeter * assumptions.wallHeightFeet;

      double openingsArea = 0.0;
      double doorOpeningsArea = 0.0;
      for (final op in room.openings) {
        final h = _getOpeningHeightFeet(op.type);
        final a = op.widthFeet * h;
        openingsArea += a;
        if (op.type.isDoor) {
          doorOpeningsArea += a;
        }
      }

      final netWall = math.max(0.0, grossWall - openingsArea);
      final ceilingArea = carpetArea;

      // Floor tiles: default all rooms
      final floorTileArea = carpetArea;

      // Wall tiles: Bathroom dado and kitchen backsplash
      double wallTileArea = 0.0;
      if (room.type == RoomType.bathroom && assumptions.includeBathroomWallTiles) {
        final grossDado = perimeter * assumptions.bathroomDadoHeightFeet;
        wallTileArea = math.max(0.0, grossDado - doorOpeningsArea);
      } else if (room.type == RoomType.kitchen && assumptions.includeKitchenBacksplash) {
        wallTileArea = assumptions.kitchenBacksplashAreaSqFt;
      }

      list.add(RoomQuantityBreakdown(
        roomId: room.id,
        roomName: room.name,
        roomType: room.type,
        widthFeet: room.width,
        lengthFeet: room.length,
        carpetAreaSqFt: carpetArea,
        perimeterFeet: perimeter,
        openingsCount: room.openings.length,
        openingsAreaSqFt: openingsArea,
        grossWallSurfaceSqFt: grossWall,
        netWallSurfaceSqFt: netWall,
        ceilingAreaSqFt: ceilingArea,
        floorTileAreaSqFt: floorTileArea,
        wallTileAreaSqFt: wallTileArea,
      ));
    }

    return list;
  }

  /// Builds the complete list of material line items with formulas, wastage, and cost
  static List<MaterialLineItem> _calculateLineItems({
    required MaterialEstimationAssumptions assumptions,
    required List<PhysicalWallSegment> physicalWalls,
    required List<RoomQuantityBreakdown> roomBreakdowns,
    required double totalBuiltUpAreaSqFt,
    required double netCarpetAreaSqFt,
    required double exteriorWallLengthFeet,
    required double totalPhysicalWallLengthFeet,
    required double netMasonryVolumeCuFt,
  }) {
    final List<MaterialLineItem> items = [];

    // ==========================================
    // 1. MASONRY: Bricks / Blocks & Mortar
    // ==========================================
    final brickVolWithMortar = assumptions.brickWithMortarVolumeCuFt;
    final brickVolActual = assumptions.brickVolumeCuFt;

    final rawBricks = brickVolWithMortar > 0
        ? (netMasonryVolumeCuFt / brickVolWithMortar)
        : 0.0;
    final totalBricks = (rawBricks * (1.0 + assumptions.brickWastagePercent / 100.0)).ceilToDouble();
    final brickCost = totalBricks * assumptions.brickRatePerUnit;

    items.add(MaterialLineItem(
      category: MaterialCategory.masonry,
      name: assumptions.masonryType.label,
      netQuantity: rawBricks.roundToDouble(),
      wastagePercent: assumptions.brickWastagePercent,
      totalQuantity: totalBricks,
      unit: 'pieces',
      unitRate: assumptions.brickRatePerUnit,
      totalCost: brickCost,
      formulaBreakdown:
          'Net Wall Vol (${netMasonryVolumeCuFt.toStringAsFixed(1)} cu ft) ÷ Unit Vol with Mortar (${(brickVolWithMortar * 1728).toStringAsFixed(1)} cu in) = ${rawBricks.round()} units. With ${assumptions.brickWastagePercent.toStringAsFixed(1)}% wastage = ${totalBricks.toInt()} units.',
      assumptionsSummary:
          'Size: ${assumptions.effectiveBrickLengthInches.toStringAsFixed(1)}"×${assumptions.effectiveBrickWidthInches.toStringAsFixed(1)}"×${assumptions.effectiveBrickHeightInches.toStringAsFixed(1)}" | Mortar Joint: ${assumptions.mortarJointThicknessInches.toStringAsFixed(2)}" | Wastage: ${assumptions.brickWastagePercent.toStringAsFixed(1)}%',
    ));

    // Mortar for Masonry:
    // Wet mortar volume = Net Wall Volume - (raw bricks * actual brick volume)
    final brickOccupiedVol = rawBricks * brickVolActual;
    final wetMortarVolCuFt = math.max(0.0, netMasonryVolumeCuFt - brickOccupiedVol);
    final dryMortarVolCuFt = wetMortarVolCuFt * assumptions.mortarDryFactor;

    final mortarCementCuFt = dryMortarVolCuFt * assumptions.mortarMix.cementFraction;
    final rawMortarCementBags = mortarCementCuFt / cuFtPerCementBag;
    final totalMortarCementBags = (rawMortarCementBags * 1.05).ceilToDouble(); // 5% bag wastage
    final mortarCementCost = totalMortarCementBags * assumptions.cementRatePerBag;

    items.add(MaterialLineItem(
      category: MaterialCategory.mortar,
      name: 'Cement (Masonry Mortar)',
      netQuantity: (rawMortarCementBags * 10).round() / 10.0,
      wastagePercent: 5.0,
      totalQuantity: totalMortarCementBags,
      unit: 'bags (50 kg)',
      unitRate: assumptions.cementRatePerBag,
      totalCost: mortarCementCost,
      formulaBreakdown:
          'Dry Mortar Vol (${dryMortarVolCuFt.toStringAsFixed(1)} cu ft) × Cement Share (${assumptions.mortarMix.cementParts}/${assumptions.mortarMix.totalParts.toInt()}) = ${mortarCementCuFt.toStringAsFixed(2)} cu ft cement ÷ 1.226 cu ft/bag = ${rawMortarCementBags.toStringAsFixed(1)} bags. +5% wastage = ${totalMortarCementBags.toInt()} bags.',
      assumptionsSummary:
          'Mortar Mix ${assumptions.mortarMix.label} | Dry Factor: ${assumptions.mortarDryFactor} | 1 bag = 50 kg (1.226 cu ft)',
    ));

    final rawMortarSandCuFt = dryMortarVolCuFt * assumptions.mortarMix.sandFraction;
    final totalMortarSandCuFt = (rawMortarSandCuFt * 1.08).ceilToDouble(); // 8% sand wastage
    final mortarSandCost = totalMortarSandCuFt * assumptions.sandRatePerCuFt;

    items.add(MaterialLineItem(
      category: MaterialCategory.mortar,
      name: 'Sand / Aggregates (Masonry Mortar)',
      netQuantity: (rawMortarSandCuFt * 10).round() / 10.0,
      wastagePercent: 8.0,
      totalQuantity: totalMortarSandCuFt,
      unit: 'cu ft',
      unitRate: assumptions.sandRatePerCuFt,
      totalCost: mortarSandCost,
      formulaBreakdown:
          'Dry Mortar Vol (${dryMortarVolCuFt.toStringAsFixed(1)} cu ft) × Sand Share (${assumptions.mortarMix.sandParts.toInt()}/${assumptions.mortarMix.totalParts.toInt()}) = ${rawMortarSandCuFt.toStringAsFixed(1)} cu ft. +8% handling wastage = ${totalMortarSandCuFt.toInt()} cu ft.',
      assumptionsSummary: 'Mortar Mix ${assumptions.mortarMix.label} | Bulk Density ~1600 kg/m3',
    ));

    // ==========================================
    // 2. PLASTER: Interior & Exterior
    // ==========================================
    double totalInteriorWallPlasterSqFt = 0.0;
    double totalCeilingPlasterSqFt = 0.0;
    for (final rb in roomBreakdowns) {
      totalInteriorWallPlasterSqFt += rb.netWallSurfaceSqFt;
      if (assumptions.includeCeilingPlaster) {
        totalCeilingPlasterSqFt += rb.ceilingAreaSqFt;
      }
    }
    final totalInteriorPlasterAreaSqFt = totalInteriorWallPlasterSqFt + totalCeilingPlasterSqFt;

    double totalExteriorPlasterAreaSqFt = 0.0;
    for (final wall in physicalWalls) {
      if (wall.isExterior) {
        totalExteriorPlasterAreaSqFt += wall.netAreaSqFt;
      }
    }

    final interiorPlasterThickFeet = assumptions.interiorPlasterThicknessInches / 12.0;
    final exteriorPlasterThickFeet = assumptions.exteriorPlasterThicknessInches / 12.0;

    final wetPlasterVolCuFt =
        (totalInteriorPlasterAreaSqFt * interiorPlasterThickFeet) +
        (totalExteriorPlasterAreaSqFt * exteriorPlasterThickFeet);
    final dryPlasterVolCuFt = wetPlasterVolCuFt * assumptions.plasterDryFactor;

    final rawPlasterCementBags =
        (dryPlasterVolCuFt * assumptions.plasterMix.cementFraction) / cuFtPerCementBag;
    final totalPlasterCementBags =
        (rawPlasterCementBags * (1.0 + assumptions.plasterWastagePercent / 100.0)).ceilToDouble();
    final plasterCementCost = totalPlasterCementBags * assumptions.cementRatePerBag;

    items.add(MaterialLineItem(
      category: MaterialCategory.plaster,
      name: 'Cement (Interior & Exterior Plaster)',
      netQuantity: (rawPlasterCementBags * 10).round() / 10.0,
      wastagePercent: assumptions.plasterWastagePercent,
      totalQuantity: totalPlasterCementBags,
      unit: 'bags (50 kg)',
      unitRate: assumptions.cementRatePerBag,
      totalCost: plasterCementCost,
      formulaBreakdown:
          'Plaster Surface: Int (${totalInteriorPlasterAreaSqFt.toStringAsFixed(0)} sq ft @ ${assumptions.interiorPlasterThicknessInches}") + Ext (${totalExteriorPlasterAreaSqFt.toStringAsFixed(0)} sq ft @ ${assumptions.exteriorPlasterThicknessInches}"). Dry Vol: ${dryPlasterVolCuFt.toStringAsFixed(1)} cu ft. With ${assumptions.plasterWastagePercent.toStringAsFixed(1)}% wastage = ${totalPlasterCementBags.toInt()} bags.',
      assumptionsSummary:
          'Plaster Mix ${assumptions.plasterMix.label} | Dry Factor: ${assumptions.plasterDryFactor} | Ceiling included: ${assumptions.includeCeilingPlaster}',
    ));

    final rawPlasterSandCuFt = dryPlasterVolCuFt * assumptions.plasterMix.sandFraction;
    final totalPlasterSandCuFt =
        (rawPlasterSandCuFt * (1.0 + assumptions.plasterWastagePercent / 100.0)).ceilToDouble();
    final plasterSandCost = totalPlasterSandCuFt * assumptions.sandRatePerCuFt;

    items.add(MaterialLineItem(
      category: MaterialCategory.plaster,
      name: 'Sand / Fine Aggregates (Plastering)',
      netQuantity: (rawPlasterSandCuFt * 10).round() / 10.0,
      wastagePercent: assumptions.plasterWastagePercent,
      totalQuantity: totalPlasterSandCuFt,
      unit: 'cu ft',
      unitRate: assumptions.sandRatePerCuFt,
      totalCost: plasterSandCost,
      formulaBreakdown:
          'Dry Plaster Vol (${dryPlasterVolCuFt.toStringAsFixed(1)} cu ft) × Sand Share (${assumptions.plasterMix.sandParts.toInt()}/${assumptions.plasterMix.totalParts.toInt()}) = ${rawPlasterSandCuFt.toStringAsFixed(1)} cu ft. With ${assumptions.plasterWastagePercent.toStringAsFixed(1)}% wastage = ${totalPlasterSandCuFt.toInt()} cu ft.',
      assumptionsSummary: 'Screened Plastering Sand (<2.36 mm) | Mix ${assumptions.plasterMix.label}',
    ));

    // ==========================================
    // 3. PAINT: Interior, Exterior & Primer
    // ==========================================
    double interiorPaintAreaSqFt = 0.0;
    for (final rb in roomBreakdowns) {
      interiorPaintAreaSqFt += rb.netWallSurfaceSqFt;
      if (assumptions.includeCeilingPaint) {
        interiorPaintAreaSqFt += rb.ceilingAreaSqFt;
      }
    }

    if (assumptions.includePrimer) {
      final rawPrimerLiters = interiorPaintAreaSqFt / assumptions.primerCoverageSqFtPerLiter;
      final totalPrimerLiters =
          (rawPrimerLiters * (1.0 + assumptions.paintWastagePercent / 100.0)).ceilToDouble();
      final primerCost = totalPrimerLiters * assumptions.primerRatePerLiter;

      items.add(MaterialLineItem(
        category: MaterialCategory.paint,
        name: 'Interior Wall Primer (1 Coat)',
        netQuantity: (rawPrimerLiters * 10).round() / 10.0,
        wastagePercent: assumptions.paintWastagePercent,
        totalQuantity: totalPrimerLiters,
        unit: 'liters',
        unitRate: assumptions.primerRatePerLiter,
        totalCost: primerCost,
        formulaBreakdown:
            'Interior Surface (${interiorPaintAreaSqFt.toStringAsFixed(0)} sq ft) ÷ Coverage (${assumptions.primerCoverageSqFtPerLiter.toStringAsFixed(0)} sq ft/L) = ${rawPrimerLiters.toStringAsFixed(1)} L. With ${assumptions.paintWastagePercent.toStringAsFixed(1)}% wastage = ${totalPrimerLiters.toInt()} L.',
        assumptionsSummary: '1 Base Coat | Acrylic Primer | Coverage ${assumptions.primerCoverageSqFtPerLiter.toStringAsFixed(0)} sq ft/L',
      ));
    }

    // Interior Paint
    final rawInteriorPaintLiters =
        (interiorPaintAreaSqFt * (assumptions.interiorPaintCoats / 2.0)) /
        assumptions.interiorPaintCoverageSqFtPerLiter;
    final totalInteriorPaintLiters =
        (rawInteriorPaintLiters * (1.0 + assumptions.paintWastagePercent / 100.0)).ceilToDouble();
    final interiorPaintCost = totalInteriorPaintLiters * assumptions.interiorPaintRatePerLiter;

    items.add(MaterialLineItem(
      category: MaterialCategory.paint,
      name: 'Interior Emulsion Paint (${assumptions.interiorPaintCoats} Coats)',
      netQuantity: (rawInteriorPaintLiters * 10).round() / 10.0,
      wastagePercent: assumptions.paintWastagePercent,
      totalQuantity: totalInteriorPaintLiters,
      unit: 'liters',
      unitRate: assumptions.interiorPaintRatePerLiter,
      totalCost: interiorPaintCost,
      formulaBreakdown:
          'Interior Surface (${interiorPaintAreaSqFt.toStringAsFixed(0)} sq ft) ÷ Coverage (${assumptions.interiorPaintCoverageSqFtPerLiter.toStringAsFixed(0)} sq ft/L for 2 coats) × ${assumptions.interiorPaintCoats}/2 = ${rawInteriorPaintLiters.toStringAsFixed(1)} L. With ${assumptions.paintWastagePercent.toStringAsFixed(1)}% wastage = ${totalInteriorPaintLiters.toInt()} L.',
      assumptionsSummary:
          '${assumptions.interiorPaintCoats} Coats | Coverage ${assumptions.interiorPaintCoverageSqFtPerLiter.toStringAsFixed(0)} sq ft/L (2 coats) | Ceiling: ${assumptions.includeCeilingPaint}',
    ));

    // Exterior Weatherproof Paint
    final rawExteriorPaintLiters =
        (totalExteriorPlasterAreaSqFt * (assumptions.exteriorPaintCoats / 2.0)) /
        assumptions.exteriorPaintCoverageSqFtPerLiter;
    final totalExteriorPaintLiters =
        (rawExteriorPaintLiters * (1.0 + assumptions.paintWastagePercent / 100.0)).ceilToDouble();
    final exteriorPaintCost = totalExteriorPaintLiters * assumptions.exteriorPaintRatePerLiter;

    items.add(MaterialLineItem(
      category: MaterialCategory.paint,
      name: 'Exterior Weatherproof Paint (${assumptions.exteriorPaintCoats} Coats)',
      netQuantity: (rawExteriorPaintLiters * 10).round() / 10.0,
      wastagePercent: assumptions.paintWastagePercent,
      totalQuantity: totalExteriorPaintLiters,
      unit: 'liters',
      unitRate: assumptions.exteriorPaintRatePerLiter,
      totalCost: exteriorPaintCost,
      formulaBreakdown:
          'Exterior Surface (${totalExteriorPlasterAreaSqFt.toStringAsFixed(0)} sq ft) ÷ Coverage (${assumptions.exteriorPaintCoverageSqFtPerLiter.toStringAsFixed(0)} sq ft/L) × ${assumptions.exteriorPaintCoats}/2 = ${rawExteriorPaintLiters.toStringAsFixed(1)} L. With ${assumptions.paintWastagePercent.toStringAsFixed(1)}% wastage = ${totalExteriorPaintLiters.toInt()} L.',
      assumptionsSummary:
          '${assumptions.exteriorPaintCoats} Coats | All-Weather Silicon Emulsion | Coverage ${assumptions.exteriorPaintCoverageSqFtPerLiter.toStringAsFixed(0)} sq ft/L',
    ));

    // ==========================================
    // 4. TILES: Flooring & Wall Dado
    // ==========================================
    final floorTileAreaSqFt = assumptions.floorTileAreaSqFt;
    final totalFloorAreaToTile = netCarpetAreaSqFt;

    final rawFloorTiles = floorTileAreaSqFt > 0 ? (totalFloorAreaToTile / floorTileAreaSqFt) : 0.0;
    final totalFloorTiles =
        (rawFloorTiles * (1.0 + assumptions.tileWastagePercent / 100.0)).ceilToDouble();
    final totalFloorBoxes =
        (totalFloorTiles / assumptions.tilesPerBox).ceilToDouble();
    final floorTileCost = totalFloorAreaToTile * assumptions.floorTileRatePerSqFt;

    items.add(MaterialLineItem(
      category: MaterialCategory.tile,
      name: 'Vitrified Floor Tiles (${assumptions.floorTileLengthInches.toStringAsFixed(0)}" × ${assumptions.floorTileWidthInches.toStringAsFixed(0)}")',
      netQuantity: (totalFloorAreaToTile * 10).round() / 10.0,
      wastagePercent: assumptions.tileWastagePercent,
      totalQuantity: totalFloorBoxes,
      unit: 'boxes (${totalFloorTiles.toInt()} tiles)',
      unitRate: assumptions.floorTileRatePerSqFt,
      totalCost: floorTileCost,
      formulaBreakdown:
          'Floor Area (${totalFloorAreaToTile.toStringAsFixed(0)} sq ft) ÷ Tile Area (${floorTileAreaSqFt.toStringAsFixed(2)} sq ft) = ${rawFloorTiles.round()} tiles. With ${assumptions.tileWastagePercent.toStringAsFixed(1)}% cut wastage = ${totalFloorTiles.toInt()} tiles (${totalFloorBoxes.toInt()} boxes of ${assumptions.tilesPerBox}).',
      assumptionsSummary:
          'Tile Size: ${assumptions.floorTileLengthInches.toStringAsFixed(0)}"×${assumptions.floorTileWidthInches.toStringAsFixed(0)}" (${floorTileAreaSqFt.toStringAsFixed(2)} sq ft) | ${assumptions.tilesPerBox} tiles/box | Rate per sq ft',
    ));

    // Wall Dado Tiles (Bathrooms & Kitchen)
    double totalWallTileAreaSqFt = 0.0;
    for (final rb in roomBreakdowns) {
      totalWallTileAreaSqFt += rb.wallTileAreaSqFt;
    }

    if (totalWallTileAreaSqFt > 0) {
      // Standard wall tile (12" x 18" = 1.5 sq ft per tile, 6 tiles per box)
      const wallTileUnitArea = 1.5;
      final rawWallTiles = totalWallTileAreaSqFt / wallTileUnitArea;
      final totalWallTiles =
          (rawWallTiles * (1.0 + assumptions.tileWastagePercent / 100.0)).ceilToDouble();
      final totalWallBoxes = (totalWallTiles / 6.0).ceilToDouble();
      final wallTileCost = totalWallTileAreaSqFt * assumptions.wallTileRatePerSqFt;

      items.add(MaterialLineItem(
        category: MaterialCategory.tile,
        name: 'Ceramic Wall Dado Tiles (Bathrooms & Kitchen)',
        netQuantity: (totalWallTileAreaSqFt * 10).round() / 10.0,
        wastagePercent: assumptions.tileWastagePercent,
        totalQuantity: totalWallBoxes,
        unit: 'boxes (${totalWallTiles.toInt()} tiles)',
        unitRate: assumptions.wallTileRatePerSqFt,
        totalCost: wallTileCost,
        formulaBreakdown:
            'Wall Dado Area (${totalWallTileAreaSqFt.toStringAsFixed(0)} sq ft) ÷ 1.5 sq ft/tile = ${rawWallTiles.round()} tiles. With ${assumptions.tileWastagePercent.toStringAsFixed(1)}% wastage = ${totalWallTiles.toInt()} tiles (${totalWallBoxes.toInt()} boxes of 6).',
        assumptionsSummary:
            'Bathroom Dado: ${assumptions.bathroomDadoHeightFeet} ft height | Kitchen Backsplash: ${assumptions.kitchenBacksplashAreaSqFt} sq ft | Standard 12"×18" ceramic',
      ));
    }

    // ==========================================
    // 5. EXPLICIT CONCRETE ELEMENTS ONLY
    // (Roof Slab, Lintel Beams, Plinth Beam)
    // Note: No reinforcement inference per user requirement
    // ==========================================
    double totalConcreteVolumeCuFt = 0.0;
    final List<String> concreteBreakdownParts = [];

    // A. Roof Slab
    if (assumptions.includeRoofSlab) {
      // Built-up area + overhang allowance
      final overhangFootprintArea = totalBuiltUpAreaSqFt *
          (assumptions.roofSlabOverhangFeet > 0 ? 1.08 : 1.0);
      final slabThickFeet = assumptions.roofSlabThicknessInches / 12.0;
      final slabVol = overhangFootprintArea * slabThickFeet;
      totalConcreteVolumeCuFt += slabVol;
      concreteBreakdownParts.add(
        'Roof Slab (${overhangFootprintArea.toStringAsFixed(0)} sq ft × ${assumptions.roofSlabThicknessInches.toStringAsFixed(1)}" = ${slabVol.toStringAsFixed(1)} cu ft)',
      );
    }

    // B. Lintel Beams over Openings
    if (assumptions.includeLintelBeams) {
      double lintelVol = 0.0;
      final lintelDepthFeet = assumptions.lintelDepthInches / 12.0;
      final bearingFeet = assumptions.lintelBearingFeet * 2.0;

      for (final wall in physicalWalls) {
        for (final op in wall.openings) {
          final lintelLength = op.widthFeet + bearingFeet;
          lintelVol += lintelLength * wall.thicknessFeet * lintelDepthFeet;
        }
      }
      totalConcreteVolumeCuFt += lintelVol;
      concreteBreakdownParts.add(
        'Lintel Beams (${lintelVol.toStringAsFixed(1)} cu ft over door/window openings with ${assumptions.lintelBearingFeet} ft bearing)',
      );
    }

    // C. Plinth Beam / Tie Band
    if (assumptions.includePlinthBeam) {
      final plinthWidthFeet = assumptions.plinthBeamWidthInches / 12.0;
      final plinthDepthFeet = assumptions.plinthBeamDepthInches / 12.0;
      final plinthVol = totalPhysicalWallLengthFeet * plinthWidthFeet * plinthDepthFeet;
      totalConcreteVolumeCuFt += plinthVol;
      concreteBreakdownParts.add(
        'Plinth Beam (${totalPhysicalWallLengthFeet.toStringAsFixed(1)} ft length × ${assumptions.plinthBeamWidthInches}" × ${assumptions.plinthBeamDepthInches}" = ${plinthVol.toStringAsFixed(1)} cu ft)',
      );
    }

    if (totalConcreteVolumeCuFt > 0) {
      final dryConcreteVolCuFt = totalConcreteVolumeCuFt * assumptions.concreteDryFactor;

      final rawConcreteCementBags =
          (dryConcreteVolCuFt * assumptions.concreteGrade.cementFraction) / cuFtPerCementBag;
      final totalConcreteCementBags =
          (rawConcreteCementBags * (1.0 + assumptions.concreteWastagePercent / 100.0)).ceilToDouble();
      final concreteCementCost = totalConcreteCementBags * assumptions.cementRatePerBag;

      items.add(MaterialLineItem(
        category: MaterialCategory.concrete,
        name: 'Cement (Concrete - ${assumptions.concreteGrade.label})',
        netQuantity: (rawConcreteCementBags * 10).round() / 10.0,
        wastagePercent: assumptions.concreteWastagePercent,
        totalQuantity: totalConcreteCementBags,
        unit: 'bags (50 kg)',
        unitRate: assumptions.cementRatePerBag,
        totalCost: concreteCementCost,
        formulaBreakdown:
            'Explicit Concrete Vol (${totalConcreteVolumeCuFt.toStringAsFixed(1)} cu ft) × Dry Factor (${assumptions.concreteDryFactor}) = ${dryConcreteVolCuFt.toStringAsFixed(1)} cu ft. Cement Share (${assumptions.concreteGrade.cementParts}/${assumptions.concreteGrade.totalParts.toStringAsFixed(1)}) = ${rawConcreteCementBags.toStringAsFixed(1)} bags. With ${assumptions.concreteWastagePercent.toStringAsFixed(1)}% wastage = ${totalConcreteCementBags.toInt()} bags.',
        assumptionsSummary:
            'Mix: ${assumptions.concreteGrade.label} | Dry Factor: ${assumptions.concreteDryFactor} | Reinforcement steel NOT inferred',
      ));

      final rawConcreteSandCuFt = dryConcreteVolCuFt * assumptions.concreteGrade.sandFraction;
      final totalConcreteSandCuFt =
          (rawConcreteSandCuFt * (1.0 + assumptions.concreteWastagePercent / 100.0)).ceilToDouble();
      final concreteSandCost = totalConcreteSandCuFt * assumptions.sandRatePerCuFt;

      items.add(MaterialLineItem(
        category: MaterialCategory.concrete,
        name: 'Sand (Concrete - Fine Aggregates)',
        netQuantity: (rawConcreteSandCuFt * 10).round() / 10.0,
        wastagePercent: assumptions.concreteWastagePercent,
        totalQuantity: totalConcreteSandCuFt,
        unit: 'cu ft',
        unitRate: assumptions.sandRatePerCuFt,
        totalCost: concreteSandCost,
        formulaBreakdown:
            'Dry Concrete Vol (${dryConcreteVolCuFt.toStringAsFixed(1)} cu ft) × Sand Share (${assumptions.concreteGrade.sandParts}/${assumptions.concreteGrade.totalParts.toStringAsFixed(1)}) = ${rawConcreteSandCuFt.toStringAsFixed(1)} cu ft. With ${assumptions.concreteWastagePercent.toStringAsFixed(1)}% wastage = ${totalConcreteSandCuFt.toInt()} cu ft.',
        assumptionsSummary: 'Zone II River Sand / M-Sand for concrete mix',
      ));

      final rawConcreteAggCuFt = dryConcreteVolCuFt * assumptions.concreteGrade.aggregateFraction;
      final totalConcreteAggCuFt =
          (rawConcreteAggCuFt * (1.0 + assumptions.concreteWastagePercent / 100.0)).ceilToDouble();
      final concreteAggCost = totalConcreteAggCuFt * assumptions.aggregateRatePerCuFt;

      items.add(MaterialLineItem(
        category: MaterialCategory.concrete,
        name: 'Coarse Aggregate / Blue Metal Stone (10-20 mm)',
        netQuantity: (rawConcreteAggCuFt * 10).round() / 10.0,
        wastagePercent: assumptions.concreteWastagePercent,
        totalQuantity: totalConcreteAggCuFt,
        unit: 'cu ft',
        unitRate: assumptions.aggregateRatePerCuFt,
        totalCost: concreteAggCost,
        formulaBreakdown:
            'Dry Concrete Vol (${dryConcreteVolCuFt.toStringAsFixed(1)} cu ft) × Stone Share (${assumptions.concreteGrade.aggregateParts}/${assumptions.concreteGrade.totalParts.toStringAsFixed(1)}) = ${rawConcreteAggCuFt.toStringAsFixed(1)} cu ft. With ${assumptions.concreteWastagePercent.toStringAsFixed(1)}% wastage = ${totalConcreteAggCuFt.toInt()} cu ft.',
        assumptionsSummary:
            'Elements: ${concreteBreakdownParts.join(', ')} | 20mm graded stone aggregates',
      ));
    }

    return items;
  }

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

class _RawWallSegment {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final bool isHorizontal;
  final bool isExterior;
  final List<String> roomIds;

  const _RawWallSegment({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.isHorizontal,
    required this.isExterior,
    required this.roomIds,
  });

  double get length {
    final dx = endX - startX;
    final dy = endY - startY;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class _RoomEdge {
  final String roomId;
  final double start;
  final double end;
  final PlanWallSide wallSide;

  const _RoomEdge({
    required this.roomId,
    required this.start,
    required this.end,
    required this.wallSide,
  });
}

class _Interval1D {
  final double start;
  final double end;
  final double perpCoord;

  const _Interval1D({
    required this.start,
    required this.end,
    required this.perpCoord,
  });
}
