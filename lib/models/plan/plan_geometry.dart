import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'plan_models.dart';

enum ResizeHandle {
  none,
  nw,
  ne,
  sw,
  se,
  n,
  s,
  e,
  w;

  bool get isCorner =>
      this == ResizeHandle.nw ||
      this == ResizeHandle.ne ||
      this == ResizeHandle.sw ||
      this == ResizeHandle.se;

  bool get isEdge =>
      this == ResizeHandle.n ||
      this == ResizeHandle.s ||
      this == ResizeHandle.e ||
      this == ResizeHandle.w;
}

class PlanGeometry {
  static const double minRoomDimensionFeet = 3.0; // 3 ft minimum width/length
  static const double maxRoomDimensionFeet = 150.0;
  static const double defaultHandleRadiusFeet = 0.9;

  /// Snap a coordinate or dimension to the nearest step increment (e.g. 0.5 ft or 1.0 ft)
  static double snap(double value, double step) {
    if (step <= 0) return value;
    return (value / step).round() * step;
  }

  static Offset snapPoint(Offset point, double step) {
    if (step <= 0) return point;
    return Offset(snap(point.dx, step), snap(point.dy, step));
  }

  /// Check whether a room is within plot boundaries
  static bool isRoomWithinPlot(
    PlanRoom room,
    double plotWidth,
    double plotLength,
  ) {
    if (room.x < 0 || room.y < 0) return false;
    if (room.x + room.width > plotWidth + 0.01) return false;
    if (room.y + room.length > plotLength + 0.01) return false;
    return true;
  }

  /// Clamps room position and size so it remains inside plot limits
  static PlanRoom clampRoomToPlot(
    PlanRoom room,
    double plotWidth,
    double plotLength, {
    double minDim = minRoomDimensionFeet,
  }) {
    final w = room.width
        .clamp(minDim, math.max<double>(minDim, plotWidth))
        .toDouble();
    final l = room.length
        .clamp(minDim, math.max<double>(minDim, plotLength))
        .toDouble();
    final maxX = math.max<double>(0.0, plotWidth - w);
    final maxY = math.max<double>(0.0, plotLength - l);
    final x = room.x.clamp(0.0, maxX).toDouble();
    final y = room.y.clamp(0.0, maxY).toDouble();

    return room.copyWith(x: x, y: y, width: w, length: l);
  }

  /// Checks if two rooms overlap their interior (ignoring touching wall borders)
  static bool roomsOverlap(PlanRoom a, PlanRoom b, {double tolerance = 0.05}) {
    if (a.id == b.id) return false;
    final rA = a.rect;
    final rB = b.rect;

    // Deflate slightly to ignore pure adjacent touching walls
    final shrunkA = rA.deflate(tolerance);
    final shrunkB = rB.deflate(tolerance);

    return shrunkA.overlaps(shrunkB);
  }

  /// Find all pairs of overlapping rooms
  static List<List<PlanRoom>> findOverlappingPairs(List<PlanRoom> rooms) {
    final List<List<PlanRoom>> pairs = [];
    for (int i = 0; i < rooms.length; i++) {
      for (int j = i + 1; j < rooms.length; j++) {
        if (roomsOverlap(rooms[i], rooms[j])) {
          pairs.add([rooms[i], rooms[j]]);
        }
      }
    }
    return pairs;
  }

  /// Hit test for selecting a room by tap point
  static PlanRoom? findRoomAtPoint(Offset pointFeet, List<PlanRoom> rooms) {
    // Search in reverse order so top-most room is picked first
    for (int i = rooms.length - 1; i >= 0; i--) {
      if (rooms[i].rect.contains(pointFeet)) {
        return rooms[i];
      }
    }
    return null;
  }

  /// Hit test for resize handles around a room's bounding box
  static ResizeHandle hitTestHandle(
    Offset pointFeet,
    PlanRoom room, {
    double radiusFeet = defaultHandleRadiusFeet,
  }) {
    final r = room.rect;

    bool near(Offset p1, Offset p2) => (p1 - p2).distance <= radiusFeet;

    // Check 4 corners first
    if (near(pointFeet, r.topLeft)) return ResizeHandle.nw;
    if (near(pointFeet, r.topRight)) return ResizeHandle.ne;
    if (near(pointFeet, r.bottomLeft)) return ResizeHandle.sw;
    if (near(pointFeet, r.bottomRight)) return ResizeHandle.se;

    // Check 4 edge centers
    if (near(pointFeet, Offset(r.center.dx, r.top))) return ResizeHandle.n;
    if (near(pointFeet, Offset(r.center.dx, r.bottom))) return ResizeHandle.s;
    if (near(pointFeet, Offset(r.left, r.center.dy))) return ResizeHandle.w;
    if (near(pointFeet, Offset(r.right, r.center.dy))) return ResizeHandle.e;

    return ResizeHandle.none;
  }

  /// Apply resizing delta according to active handle
  static PlanRoom applyResize(
    PlanRoom room,
    ResizeHandle handle,
    double dx,
    double dy, {
    double minDim = minRoomDimensionFeet,
    double maxPlotWidth = 500,
    double maxPlotLength = 500,
  }) {
    double x = room.x;
    double y = room.y;
    double w = room.width;
    double l = room.length;

    switch (handle) {
      case ResizeHandle.nw:
        final newW = math.max(minDim, w - dx);
        final newL = math.max(minDim, l - dy);
        x = x + (w - newW);
        y = y + (l - newL);
        w = newW;
        l = newL;
        break;
      case ResizeHandle.ne:
        w = math.max(minDim, w + dx);
        final newL = math.max(minDim, l - dy);
        y = y + (l - newL);
        l = newL;
        break;
      case ResizeHandle.sw:
        final newW = math.max(minDim, w - dx);
        x = x + (w - newW);
        w = newW;
        l = math.max(minDim, l + dy);
        break;
      case ResizeHandle.se:
        w = math.max(minDim, w + dx);
        l = math.max(minDim, l + dy);
        break;
      case ResizeHandle.n:
        final newL = math.max(minDim, l - dy);
        y = y + (l - newL);
        l = newL;
        break;
      case ResizeHandle.s:
        l = math.max(minDim, l + dy);
        break;
      case ResizeHandle.w:
        final newW = math.max(minDim, w - dx);
        x = x + (w - newW);
        w = newW;
        break;
      case ResizeHandle.e:
        w = math.max(minDim, w + dx);
        break;
      case ResizeHandle.none:
        break;
    }

    // Keep non-negative coords
    x = math.max(0.0, x);
    y = math.max(0.0, y);

    return room.copyWith(x: x, y: y, width: w, length: l);
  }

  /// Calculate world-space segment for an opening on a room's wall
  static Rect getOpeningRect(
    PlanRoom room,
    PlanOpening opening, {
    double thicknessFeet = 0.8,
  }) {
    final r = room.rect;
    final halfThick = thicknessFeet / 2;

    switch (opening.wallSide) {
      case PlanWallSide.north:
        final startX = r.left + opening.offsetFeet;
        return Rect.fromLTWH(
          startX,
          r.top - halfThick,
          opening.widthFeet,
          thicknessFeet,
        );
      case PlanWallSide.south:
        final startX = r.left + opening.offsetFeet;
        return Rect.fromLTWH(
          startX,
          r.bottom - halfThick,
          opening.widthFeet,
          thicknessFeet,
        );
      case PlanWallSide.west:
        final startY = r.top + opening.offsetFeet;
        return Rect.fromLTWH(
          r.left - halfThick,
          startY,
          thicknessFeet,
          opening.widthFeet,
        );
      case PlanWallSide.east:
        final startY = r.top + opening.offsetFeet;
        return Rect.fromLTWH(
          r.right - halfThick,
          startY,
          thicknessFeet,
          opening.widthFeet,
        );
    }
  }

  /// Hit test for openings in a room or across all rooms
  static PlanOpening? hitTestOpening(
    Offset pointFeet,
    List<PlanRoom> rooms, {
    double hitRadiusFeet = 0.8,
  }) {
    for (final room in rooms.reversed) {
      for (final opening in room.openings) {
        final openingRect = getOpeningRect(room, opening, thicknessFeet: 1.2);
        if (openingRect.inflate(hitRadiusFeet).contains(pointFeet)) {
          return opening;
        }
      }
    }
    return null;
  }

  /// Clamps opening offset and width so it fits safely along its designated wall
  static PlanOpening clampOpening(PlanOpening opening, PlanRoom room) {
    final wallLen = room.wallLength(opening.wallSide);
    final w = opening.widthFeet
        .clamp(1.5, math.max<double>(1.5, wallLen - 0.2))
        .toDouble();
    final maxOffset = math.max<double>(0.0, wallLen - w);
    final offset = opening.offsetFeet.clamp(0.0, maxOffset).toDouble();

    return opening.copyWith(offsetFeet: offset, widthFeet: w);
  }

  /// Extract wall segments (exterior vs interior) from a collection of rooms
  static List<PlanWall> extractWallSegments(List<PlanRoom> rooms) {
    final List<PlanWall> walls = [];
    int wallId = 0;

    for (final room in rooms) {
      final r = room.rect;

      // North wall
      walls.add(
        PlanWall(
          id: 'wall_${wallId++}',
          startX: r.left,
          startY: r.top,
          endX: r.right,
          endY: r.top,
        ),
      );
      // South wall
      walls.add(
        PlanWall(
          id: 'wall_${wallId++}',
          startX: r.left,
          startY: r.bottom,
          endX: r.right,
          endY: r.bottom,
        ),
      );
      // West wall
      walls.add(
        PlanWall(
          id: 'wall_${wallId++}',
          startX: r.left,
          startY: r.top,
          endX: r.left,
          endY: r.bottom,
        ),
      );
      // East wall
      walls.add(
        PlanWall(
          id: 'wall_${wallId++}',
          startX: r.right,
          startY: r.top,
          endX: r.right,
          endY: r.bottom,
        ),
      );
    }

    return walls;
  }
}
