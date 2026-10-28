import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'plan_models.dart';

enum ProjectionMode {
  perspective,
  isometric;

  String get label =>
      this == ProjectionMode.perspective ? 'Perspective' : 'Isometric';
}

enum CutawayMode {
  full(10.0, 'Full Height (10 ft)', Icons.home_rounded),
  dollhouse(4.0, 'Dollhouse Cutaway (4 ft)', Icons.view_in_ar_rounded),
  floorOnly(0.5, 'Floor Slab (0.5 ft)', Icons.layers_outlined);

  final double wallHeightFeet;
  final String label;
  final IconData icon;

  const CutawayMode(this.wallHeightFeet, this.label, this.icon);
}

enum MaterialTextureType { smooth, brick, wood, tile, concrete, marble, glass }

class Scene3DMaterial {
  final String id;
  final String name;
  final Color color;
  final MaterialTextureType textureType;
  final double roughness; // 0.0 (smooth) to 1.0 (rough)

  const Scene3DMaterial({
    required this.id,
    required this.name,
    required this.color,
    this.textureType = MaterialTextureType.smooth,
    this.roughness = 0.5,
  });

  // Built-in Wall Material Presets
  static const plasterWhite = Scene3DMaterial(
    id: 'wall_plaster_white',
    name: 'Modern White Plaster',
    color: Color(0xFFF5F6F8),
    textureType: MaterialTextureType.smooth,
    roughness: 0.3,
  );

  static const warmSandstone = Scene3DMaterial(
    id: 'wall_warm_sandstone',
    name: 'Warm Sandstone',
    color: Color(0xFFE8DEC4),
    textureType: MaterialTextureType.smooth,
    roughness: 0.5,
  );

  static const terracottaBrick = Scene3DMaterial(
    id: 'wall_terracotta_brick',
    name: 'Terracotta Brick',
    color: Color(0xFFC05C46),
    textureType: MaterialTextureType.brick,
    roughness: 0.8,
  );

  static const slateCharcoal = Scene3DMaterial(
    id: 'wall_slate_charcoal',
    name: 'Modern Slate Charcoal',
    color: Color(0xFF475569),
    textureType: MaterialTextureType.smooth,
    roughness: 0.4,
  );

  static const softSage = Scene3DMaterial(
    id: 'wall_soft_sage',
    name: 'Soft Sage Green',
    color: Color(0xFFB7C7B6),
    textureType: MaterialTextureType.smooth,
    roughness: 0.4,
  );

  static const coastalNavy = Scene3DMaterial(
    id: 'wall_coastal_navy',
    name: 'Contemporary Navy',
    color: Color(0xFF1E3A5F),
    textureType: MaterialTextureType.smooth,
    roughness: 0.3,
  );

  static const List<Scene3DMaterial> wallPresets = [
    plasterWhite,
    warmSandstone,
    terracottaBrick,
    slateCharcoal,
    softSage,
    coastalNavy,
  ];

  // Built-in Floor Material Presets
  static const oakHardwood = Scene3DMaterial(
    id: 'floor_oak_hardwood',
    name: 'Light Oak Wood',
    color: Color(0xFFD4A373),
    textureType: MaterialTextureType.wood,
    roughness: 0.3,
  );

  static const polishedMarble = Scene3DMaterial(
    id: 'floor_polished_marble',
    name: 'Polished Marble',
    color: Color(0xFFEDE8E0),
    textureType: MaterialTextureType.marble,
    roughness: 0.1,
  );

  static const ceramicTile = Scene3DMaterial(
    id: 'floor_ceramic_tile',
    name: 'Ceramic Floor Tiles',
    color: Color(0xFFCBD5E1),
    textureType: MaterialTextureType.tile,
    roughness: 0.3,
  );

  static const industrialConcrete = Scene3DMaterial(
    id: 'floor_industrial_concrete',
    name: 'Polished Concrete',
    color: Color(0xFFA0AEC0),
    textureType: MaterialTextureType.concrete,
    roughness: 0.6,
  );

  static const terracottaTile = Scene3DMaterial(
    id: 'floor_terracotta_tile',
    name: 'Rustic Terracotta',
    color: Color(0xFFD97746),
    textureType: MaterialTextureType.tile,
    roughness: 0.7,
  );

  static const List<Scene3DMaterial> floorPresets = [
    oakHardwood,
    polishedMarble,
    ceramicTile,
    industrialConcrete,
    terracottaTile,
  ];

  Scene3DMaterial copyWith({
    String? id,
    String? name,
    Color? color,
    MaterialTextureType? textureType,
    double? roughness,
  }) {
    return Scene3DMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      textureType: textureType ?? this.textureType,
      roughness: roughness ?? this.roughness,
    );
  }
}

/// Building level structure designed for Ground Floor first and extensible to multi-floor buildings
class BuildingFloorLevel {
  final int levelIndex; // 0 for Ground Floor, 1 for First Floor
  final String name;
  final double elevationFeet; // base height in feet
  final double heightFeet; // floor-to-ceiling height
  final List<PlanRoom> rooms;

  const BuildingFloorLevel({
    this.levelIndex = 0,
    this.name = 'Ground Floor',
    this.elevationFeet = 0.0,
    this.heightFeet = 10.0,
    required this.rooms,
  });

  BuildingFloorLevel copyWith({
    int? levelIndex,
    String? name,
    double? elevationFeet,
    double? heightFeet,
    List<PlanRoom>? rooms,
  }) {
    return BuildingFloorLevel(
      levelIndex: levelIndex ?? this.levelIndex,
      name: name ?? this.name,
      elevationFeet: elevationFeet ?? this.elevationFeet,
      heightFeet: heightFeet ?? this.heightFeet,
      rooms: rooms ?? this.rooms,
    );
  }

  Map<String, dynamic> toJson() => {
    'levelIndex': levelIndex,
    'name': name,
    'elevationFeet': elevationFeet,
    'heightFeet': heightFeet,
    'rooms': rooms.map((r) => r.toJson()).toList(),
  };

  factory BuildingFloorLevel.fromJson(Map<String, dynamic> json) =>
      BuildingFloorLevel(
        levelIndex: json['levelIndex'] as int? ?? 0,
        name: json['name'] as String? ?? 'Ground Floor',
        elevationFeet: (json['elevationFeet'] as num?)?.toDouble() ?? 0.0,
        heightFeet: (json['heightFeet'] as num?)?.toDouble() ?? 10.0,
        rooms:
            (json['rooms'] as List<dynamic>?)
                ?.map((r) => PlanRoom.fromJson(Map<String, dynamic>.from(r)))
                .toList() ??
            const [],
      );
}

class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D(this.x, this.y, this.z);

  Point3D operator +(Point3D other) =>
      Point3D(x + other.x, y + other.y, z + other.z);
  Point3D operator -(Point3D other) =>
      Point3D(x - other.x, y - other.y, z - other.z);
  Point3D operator *(double scalar) =>
      Point3D(x * scalar, y * scalar, z * scalar);

  double dot(Point3D other) => x * other.x + y * other.y + z * other.z;

  Point3D cross(Point3D other) => Point3D(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  double get length => math.sqrt(x * x + y * y + z * z);

  Point3D get normalized {
    final len = length;
    if (len == 0) return const Point3D(0, 0, 1);
    return Point3D(x / len, y / len, z / len);
  }

  @override
  String toString() =>
      'Point3D(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}

enum PolygonCategory {
  groundPlot,
  floor,
  wallExterior,
  wallInterior,
  wallLintel,
  wallSill,
  doorFrame,
  doorLeaf,
  windowFrame,
  windowGlass,
  plinthBase;

  bool get isGlass => this == PolygonCategory.windowGlass;
}

class Polygon3D {
  final List<Point3D> vertices;
  final Point3D normal;
  final Color baseColor;
  final PolygonCategory category;
  final double opacity;
  final Color? edgeColor;
  final double edgeWidth;
  final String? metadata;

  // Cached depth value during 3D camera transformation
  double sortDepth = 0.0;

  Polygon3D({
    required this.vertices,
    required this.normal,
    required this.baseColor,
    required this.category,
    this.opacity = 1.0,
    this.edgeColor,
    this.edgeWidth = 1.0,
    this.metadata,
  });

  /// Computes center / centroid point of the polygon
  Point3D get center {
    if (vertices.isEmpty) return const Point3D(0, 0, 0);
    double sumX = 0;
    double sumY = 0;
    double sumZ = 0;
    for (final v in vertices) {
      sumX += v.x;
      sumY += v.y;
      sumZ += v.z;
    }
    final count = vertices.length.toDouble();
    return Point3D(sumX / count, sumY / count, sumZ / count);
  }

  /// Create a polygon with normal automatically computed from first 3 vertices
  factory Polygon3D.fromVertices({
    required List<Point3D> vertices,
    required Color baseColor,
    required PolygonCategory category,
    double opacity = 1.0,
    Color? edgeColor,
    double edgeWidth = 1.0,
    String? metadata,
  }) {
    Point3D normal = const Point3D(0, 0, 1);
    if (vertices.length >= 3) {
      final v0 = vertices[0];
      final v1 = vertices[1];
      final v2 = vertices[2];
      final edge1 = v1 - v0;
      final edge2 = v2 - v0;
      normal = edge1.cross(edge2).normalized;
    }
    return Polygon3D(
      vertices: vertices,
      normal: normal,
      baseColor: baseColor,
      category: category,
      opacity: opacity,
      edgeColor: edgeColor,
      edgeWidth: edgeWidth,
      metadata: metadata,
    );
  }
}

class RoomAnnotation3D {
  final String id;
  final String name;
  final String dimensionsText;
  final Point3D position;
  final Color color;

  const RoomAnnotation3D({
    required this.id,
    required this.name,
    required this.dimensionsText,
    required this.position,
    required this.color,
  });
}

class Mesh3D {
  final List<Polygon3D> polygons;
  final Point3D minBound;
  final Point3D maxBound;
  final Point3D center;
  final List<RoomAnnotation3D> roomAnnotations;

  const Mesh3D({
    required this.polygons,
    required this.minBound,
    required this.maxBound,
    required this.center,
    this.roomAnnotations = const [],
  });

  static Mesh3D empty() {
    return const Mesh3D(
      polygons: [],
      minBound: Point3D(0, 0, 0),
      maxBound: Point3D(0, 0, 0),
      center: Point3D(0, 0, 0),
    );
  }
}

class Camera3DState {
  double azimuth; // Radians, rotation around vertical axis (0..2*pi)
  double elevation; // Radians, tilt above ground plane (clamped 0.15..1.48 rad)
  double distance; // Camera distance from target
  Offset pan; // Screen space offset
  ProjectionMode projectionMode;
  CutawayMode cutawayMode;

  Camera3DState({
    this.azimuth = 0.785398, // 45 degrees
    this.elevation = 0.610865, // 35 degrees
    this.distance = 70.0,
    this.pan = Offset.zero,
    this.projectionMode = ProjectionMode.perspective,
    this.cutawayMode = CutawayMode.full,
  });

  Camera3DState copyWith({
    double? azimuth,
    double? elevation,
    double? distance,
    Offset? pan,
    ProjectionMode? projectionMode,
    CutawayMode? cutawayMode,
  }) {
    return Camera3DState(
      azimuth: azimuth ?? this.azimuth,
      elevation: elevation ?? this.elevation,
      distance: distance ?? this.distance,
      pan: pan ?? this.pan,
      projectionMode: projectionMode ?? this.projectionMode,
      cutawayMode: cutawayMode ?? this.cutawayMode,
    );
  }

  void rotate(double deltaAzimuth, double deltaElevation) {
    azimuth += deltaAzimuth;
    // Normalize azimuth
    while (azimuth < 0) {
      azimuth += 2 * math.pi;
    }
    while (azimuth >= 2 * math.pi) {
      azimuth -= 2 * math.pi;
    }

    // Clamp elevation between ~10 degrees (0.17 rad) and ~85 degrees (1.48 rad)
    elevation = (elevation + deltaElevation).clamp(0.1745, 1.4835);
  }

  void zoom(double factor) {
    distance = (distance * factor).clamp(15.0, 300.0);
  }

  void panBy(Offset delta) {
    pan += delta;
  }

  // Camera Presets
  void presetIsometricSE() {
    azimuth = math.pi / 4; // 45°
    elevation = 35 * math.pi / 180;
    pan = Offset.zero;
  }

  void presetIsometricNW() {
    azimuth = 5 * math.pi / 4; // 225°
    elevation = 35 * math.pi / 180;
    pan = Offset.zero;
  }

  void presetFrontSouth() {
    azimuth = 0.0; // Facing North, looking from South
    elevation = 20 * math.pi / 180;
    pan = Offset.zero;
  }

  void presetBackNorth() {
    azimuth = math.pi; // Facing South, looking from North
    elevation = 20 * math.pi / 180;
    pan = Offset.zero;
  }

  void presetRightEast() {
    azimuth = math.pi / 2; // 90°
    elevation = 20 * math.pi / 180;
    pan = Offset.zero;
  }

  void presetLeftWest() {
    azimuth = 3 * math.pi / 2; // 270°
    elevation = 20 * math.pi / 180;
    pan = Offset.zero;
  }

  void presetTopDown() {
    azimuth = 0.0;
    elevation = 85 * math.pi / 180; // 85° near-zenith
    pan = Offset.zero;
  }

  void reset() {
    presetIsometricSE();
  }
}

class Plan3DValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const Plan3DValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}
