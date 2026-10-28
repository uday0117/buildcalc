import 'package:flutter/material.dart';

import 'plan_unit.dart';

enum RoomType {
  living,
  masterBedroom,
  bedroom,
  kitchen,
  dining,
  bathroom,
  balcony,
  foyer,
  pooja,
  study,
  utility,
  custom;

  String get displayName {
    switch (this) {
      case RoomType.living:
        return 'Living Room';
      case RoomType.masterBedroom:
        return 'Master Bedroom';
      case RoomType.bedroom:
        return 'Bedroom';
      case RoomType.kitchen:
        return 'Kitchen';
      case RoomType.dining:
        return 'Dining Area';
      case RoomType.bathroom:
        return 'Bathroom / Toilet';
      case RoomType.balcony:
        return 'Balcony';
      case RoomType.foyer:
        return 'Entry Foyer';
      case RoomType.pooja:
        return 'Pooja Room';
      case RoomType.study:
        return 'Study / Home Office';
      case RoomType.utility:
        return 'Utility / Wash';
      case RoomType.custom:
        return 'Custom Room';
    }
  }

  Color get defaultColor {
    switch (this) {
      case RoomType.living:
        return const Color(0xFFE3F2FD); // Light Blue
      case RoomType.masterBedroom:
        return const Color(0xFFEDE7F6); // Light Purple
      case RoomType.bedroom:
        return const Color(0xFFE8EAF6); // Soft Indigo
      case RoomType.kitchen:
        return const Color(0xFFFFF3E0); // Warm Orange tint
      case RoomType.dining:
        return const Color(0xFFFFFDE7); // Soft Yellow
      case RoomType.bathroom:
        return const Color(0xFFE0F7FA); // Soft Cyan
      case RoomType.balcony:
        return const Color(0xFFE8F5E9); // Light Green
      case RoomType.foyer:
        return const Color(0xFFF3E5F5); // Light Violet
      case RoomType.pooja:
        return const Color(0xFFFFF8E1); // Amber tint
      case RoomType.study:
        return const Color(0xFFF1F8E9); // Light Lime
      case RoomType.utility:
        return const Color(0xFFECEFF1); // Blue Grey tint
      case RoomType.custom:
        return const Color(0xFFFAFAFA); // Off White
    }
  }

  IconData get icon {
    switch (this) {
      case RoomType.living:
        return Icons.weekend_rounded;
      case RoomType.masterBedroom:
        return Icons.king_bed_rounded;
      case RoomType.bedroom:
        return Icons.bed_rounded;
      case RoomType.kitchen:
        return Icons.kitchen_rounded;
      case RoomType.dining:
        return Icons.restaurant_rounded;
      case RoomType.bathroom:
        return Icons.bathtub_rounded;
      case RoomType.balcony:
        return Icons.deck_rounded;
      case RoomType.foyer:
        return Icons.door_front_door_rounded;
      case RoomType.pooja:
        return Icons.brightness_high_rounded;
      case RoomType.study:
        return Icons.menu_book_rounded;
      case RoomType.utility:
        return Icons.local_laundry_service_rounded;
      case RoomType.custom:
        return Icons.crop_square_rounded;
    }
  }
}

enum PlanWallSide {
  north, // Top
  south, // Bottom
  east, // Right
  west; // Left

  String get label {
    switch (this) {
      case PlanWallSide.north:
        return 'North (Top)';
      case PlanWallSide.south:
        return 'South (Bottom)';
      case PlanWallSide.east:
        return 'East (Right)';
      case PlanWallSide.west:
        return 'West (Left)';
    }
  }

  PlanWallSide get opposite {
    switch (this) {
      case PlanWallSide.north:
        return PlanWallSide.south;
      case PlanWallSide.south:
        return PlanWallSide.north;
      case PlanWallSide.east:
        return PlanWallSide.west;
      case PlanWallSide.west:
        return PlanWallSide.east;
    }
  }

  bool get isHorizontal =>
      this == PlanWallSide.north || this == PlanWallSide.south;
  bool get isVertical => this == PlanWallSide.east || this == PlanWallSide.west;
}

enum OpeningType {
  door,
  doubleDoor,
  slidingDoor,
  window,
  ventilation;

  String get label {
    switch (this) {
      case OpeningType.door:
        return 'Single Door';
      case OpeningType.doubleDoor:
        return 'Double Door';
      case OpeningType.slidingDoor:
        return 'Sliding Door';
      case OpeningType.window:
        return 'Window';
      case OpeningType.ventilation:
        return 'Ventilator';
    }
  }

  double get defaultWidthFeet {
    switch (this) {
      case OpeningType.door:
        return 3.0; // 3 ft standard door
      case OpeningType.doubleDoor:
        return 5.0; // 5 ft entrance door
      case OpeningType.slidingDoor:
        return 6.0; // 6 ft sliding patio
      case OpeningType.window:
        return 4.0; // 4 ft window
      case OpeningType.ventilation:
        return 2.0; // 2 ft ventilator
    }
  }

  bool get isDoor =>
      this == OpeningType.door ||
      this == OpeningType.doubleDoor ||
      this == OpeningType.slidingDoor;

  bool get isWindow =>
      this == OpeningType.window || this == OpeningType.ventilation;

  IconData get icon {
    switch (this) {
      case OpeningType.door:
        return Icons.sensor_door_outlined;
      case OpeningType.doubleDoor:
        return Icons.meeting_room_outlined;
      case OpeningType.slidingDoor:
        return Icons.door_sliding_outlined;
      case OpeningType.window:
        return Icons.window_outlined;
      case OpeningType.ventilation:
        return Icons.air_rounded;
    }
  }
}

class PlanOpening {
  final String id;
  final String roomId;
  final PlanWallSide wallSide;
  final OpeningType type;
  final double offsetFeet; // Distance along wall from wall's start
  final double widthFeet;
  final bool swingInward;
  final bool flipSwing;

  const PlanOpening({
    required this.id,
    required this.roomId,
    required this.wallSide,
    required this.type,
    required this.offsetFeet,
    required this.widthFeet,
    this.swingInward = true,
    this.flipSwing = false,
  });

  PlanOpening copyWith({
    String? id,
    String? roomId,
    PlanWallSide? wallSide,
    OpeningType? type,
    double? offsetFeet,
    double? widthFeet,
    bool? swingInward,
    bool? flipSwing,
  }) {
    return PlanOpening(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      wallSide: wallSide ?? this.wallSide,
      type: type ?? this.type,
      offsetFeet: offsetFeet ?? this.offsetFeet,
      widthFeet: widthFeet ?? this.widthFeet,
      swingInward: swingInward ?? this.swingInward,
      flipSwing: flipSwing ?? this.flipSwing,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'wallSide': wallSide.name,
    'type': type.name,
    'offsetFeet': offsetFeet,
    'widthFeet': widthFeet,
    'swingInward': swingInward,
    'flipSwing': flipSwing,
  };

  factory PlanOpening.fromJson(Map<String, dynamic> json) => PlanOpening(
    id: json['id'] as String,
    roomId: json['roomId'] as String,
    wallSide: PlanWallSide.values.firstWhere(
      (e) => e.name == json['wallSide'],
      orElse: () => PlanWallSide.north,
    ),
    type: OpeningType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => OpeningType.door,
    ),
    offsetFeet: (json['offsetFeet'] as num).toDouble(),
    widthFeet: (json['widthFeet'] as num).toDouble(),
    swingInward: json['swingInward'] as bool? ?? true,
    flipSwing: json['flipSwing'] as bool? ?? false,
  );
}

class PlanRoom {
  final String id;
  final String name;
  final RoomType type;
  final double x; // in feet, top-left relative to plot
  final double y; // in feet, top-left relative to plot
  final double width; // in feet (horizontal)
  final double length; // in feet (vertical)
  final int colorValue;
  final List<PlanOpening> openings;

  const PlanRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.length,
    required this.colorValue,
    this.openings = const [],
  });

  double get areaSqFt => width * length;

  Rect get rect => Rect.fromLTWH(x, y, width, length);

  Color get color => Color(colorValue);

  double wallLength(PlanWallSide side) {
    return side.isHorizontal ? width : length;
  }

  PlanRoom copyWith({
    String? id,
    String? name,
    RoomType? type,
    double? x,
    double? y,
    double? width,
    double? length,
    int? colorValue,
    List<PlanOpening>? openings,
  }) {
    return PlanRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      length: length ?? this.length,
      colorValue: colorValue ?? this.colorValue,
      openings: openings ?? this.openings,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'x': x,
    'y': y,
    'width': width,
    'length': length,
    'colorValue': colorValue,
    'openings': openings.map((o) => o.toJson()).toList(),
  };

  factory PlanRoom.fromJson(Map<String, dynamic> json) => PlanRoom(
    id: json['id'] as String,
    name: json['name'] as String,
    type: RoomType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => RoomType.custom,
    ),
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    length: (json['length'] as num).toDouble(),
    colorValue:
        (json['colorValue'] as num?)?.toInt() ??
        const Color(0xFFFAFAFA).toARGB32(),
    openings:
        (json['openings'] as List<dynamic>?)
            ?.map((o) => PlanOpening.fromJson(Map<String, dynamic>.from(o)))
            .toList() ??
        const [],
  );
}

class PlanWall {
  final String id;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double thicknessFeet;
  final bool isExterior;

  const PlanWall({
    required this.id,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.thicknessFeet = 0.75, // 9 inches in feet
    this.isExterior = true,
  });

  double get length {
    final dx = endX - startX;
    final dy = endY - startY;
    return (dx * dx + dy * dy) > 0 ? (dx * dx + dy * dy) : 0.0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startX': startX,
    'startY': startY,
    'endX': endX,
    'endY': endY,
    'thicknessFeet': thicknessFeet,
    'isExterior': isExterior,
  };

  factory PlanWall.fromJson(Map<String, dynamic> json) => PlanWall(
    id: json['id'] as String,
    startX: (json['startX'] as num).toDouble(),
    startY: (json['startY'] as num).toDouble(),
    endX: (json['endX'] as num).toDouble(),
    endY: (json['endY'] as num).toDouble(),
    thicknessFeet: (json['thicknessFeet'] as num?)?.toDouble() ?? 0.75,
    isExterior: json['isExterior'] as bool? ?? true,
  );
}

class FloorPlan {
  final String id;
  final String name;
  final double plotWidthFeet;
  final double plotLengthFeet;
  final PlanUnit unit;
  final String layoutType;
  final List<PlanRoom> rooms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool gridSnap;
  final double snapStepFeet;

  const FloorPlan({
    required this.id,
    required this.name,
    required this.plotWidthFeet,
    required this.plotLengthFeet,
    this.unit = PlanUnit.feet,
    this.layoutType = 'Custom',
    this.rooms = const [],
    required this.createdAt,
    required this.updatedAt,
    this.gridSnap = true,
    this.snapStepFeet = 0.5,
  });

  double get totalPlotAreaSqFt => plotWidthFeet * plotLengthFeet;

  double get totalRoomAreaSqFt {
    return rooms.fold<double>(0.0, (sum, room) => sum + room.areaSqFt);
  }

  /// Total built-up area including standard structural wall footprint factor (approx 12-15% over carpet area)
  double get totalBuiltUpAreaSqFt {
    // Exact sum of room footprints plus estimated partition wall envelope
    if (rooms.isEmpty) return 0.0;
    return totalRoomAreaSqFt * 1.12;
  }

  double get groundCoveragePercent {
    if (totalPlotAreaSqFt <= 0) return 0.0;
    return (totalBuiltUpAreaSqFt / totalPlotAreaSqFt) * 100.0;
  }

  List<PlanOpening> get allOpenings {
    return rooms.expand((room) => room.openings).toList();
  }

  PlanRoom? findRoom(String roomId) {
    try {
      return rooms.firstWhere((r) => r.id == roomId);
    } catch (_) {
      return null;
    }
  }

  PlanOpening? findOpening(String openingId) {
    for (final r in rooms) {
      for (final o in r.openings) {
        if (o.id == openingId) return o;
      }
    }
    return null;
  }

  FloorPlan copyWith({
    String? id,
    String? name,
    double? plotWidthFeet,
    double? plotLengthFeet,
    PlanUnit? unit,
    String? layoutType,
    List<PlanRoom>? rooms,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? gridSnap,
    double? snapStepFeet,
  }) {
    return FloorPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      plotWidthFeet: plotWidthFeet ?? this.plotWidthFeet,
      plotLengthFeet: plotLengthFeet ?? this.plotLengthFeet,
      unit: unit ?? this.unit,
      layoutType: layoutType ?? this.layoutType,
      rooms: rooms ?? this.rooms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gridSnap: gridSnap ?? this.gridSnap,
      snapStepFeet: snapStepFeet ?? this.snapStepFeet,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'plotWidthFeet': plotWidthFeet,
    'plotLengthFeet': plotLengthFeet,
    'unit': unit.name,
    'layoutType': layoutType,
    'rooms': rooms.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'gridSnap': gridSnap,
    'snapStepFeet': snapStepFeet,
  };

  factory FloorPlan.fromJson(Map<String, dynamic> json) => FloorPlan(
    id: json['id'] as String,
    name: json['name'] as String,
    plotWidthFeet: (json['plotWidthFeet'] as num).toDouble(),
    plotLengthFeet: (json['plotLengthFeet'] as num).toDouble(),
    unit: PlanUnit.values.firstWhere(
      (e) => e.name == json['unit'],
      orElse: () => PlanUnit.feet,
    ),
    layoutType: json['layoutType'] as String? ?? 'Custom',
    rooms:
        (json['rooms'] as List<dynamic>?)
            ?.map((r) => PlanRoom.fromJson(Map<String, dynamic>.from(r)))
            .toList() ??
        const [],
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    gridSnap: json['gridSnap'] as bool? ?? true,
    snapStepFeet: (json['snapStepFeet'] as num?)?.toDouble() ?? 0.5,
  );
}
