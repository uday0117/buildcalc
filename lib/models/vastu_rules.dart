import 'package:flutter/material.dart';

enum VastuDirection {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest,
  center;

  String get displayName {
    switch (this) {
      case VastuDirection.north:
        return 'North (Uttar)';
      case VastuDirection.northEast:
        return 'North-East (Ishanya)';
      case VastuDirection.east:
        return 'East (Purva)';
      case VastuDirection.southEast:
        return 'South-East (Agneya)';
      case VastuDirection.south:
        return 'South (Dakshin)';
      case VastuDirection.southWest:
        return 'South-West (Nairutya)';
      case VastuDirection.west:
        return 'West (Paschim)';
      case VastuDirection.northWest:
        return 'North-West (Vayavya)';
      case VastuDirection.center:
        return 'Center (Brahmasthan)';
    }
  }

  String get shortName {
    switch (this) {
      case VastuDirection.north:
        return 'North';
      case VastuDirection.northEast:
        return 'North-East';
      case VastuDirection.east:
        return 'East';
      case VastuDirection.southEast:
        return 'South-East';
      case VastuDirection.south:
        return 'South';
      case VastuDirection.southWest:
        return 'South-West';
      case VastuDirection.west:
        return 'West';
      case VastuDirection.northWest:
        return 'North-West';
      case VastuDirection.center:
        return 'Center';
    }
  }

  String get sanskritName {
    switch (this) {
      case VastuDirection.north:
        return 'Kubera / Uttar';
      case VastuDirection.northEast:
        return 'Ishanya (God)';
      case VastuDirection.east:
        return 'Indra / Surya';
      case VastuDirection.southEast:
        return 'Agneya (Fire)';
      case VastuDirection.south:
        return 'Yama';
      case VastuDirection.southWest:
        return 'Nairutya (Earth)';
      case VastuDirection.west:
        return 'Varuna (Water/Sky)';
      case VastuDirection.northWest:
        return 'Vayavya (Air)';
      case VastuDirection.center:
        return 'Brahmasthan (Cosmic)';
    }
  }

  String get element {
    switch (this) {
      case VastuDirection.north:
        return 'Water (Jal)';
      case VastuDirection.northEast:
        return 'Water (Jal / Pure)';
      case VastuDirection.east:
        return 'Air / Solar Light';
      case VastuDirection.southEast:
        return 'Fire (Agni)';
      case VastuDirection.south:
        return 'Fire & Earth';
      case VastuDirection.southWest:
        return 'Earth (Prithvi)';
      case VastuDirection.west:
        return 'Space / Metal (Akash)';
      case VastuDirection.northWest:
        return 'Air (Vayu)';
      case VastuDirection.center:
        return 'Ether (Akash / Space)';
    }
  }

  Color get elementColor {
    switch (this) {
      case VastuDirection.north:
        return const Color(0xFF0288D1);
      case VastuDirection.northEast:
        return const Color(0xFF00ACC1);
      case VastuDirection.east:
        return const Color(0xFF43A047);
      case VastuDirection.southEast:
        return const Color(0xFFE53935);
      case VastuDirection.south:
        return const Color(0xFFD81B60);
      case VastuDirection.southWest:
        return const Color(0xFF8D6E63);
      case VastuDirection.west:
        return const Color(0xFF5E35B1);
      case VastuDirection.northWest:
        return const Color(0xFF3949AB);
      case VastuDirection.center:
        return const Color(0xFFFFB300);
    }
  }

  double get degreeAngle {
    switch (this) {
      case VastuDirection.north:
        return 0;
      case VastuDirection.northEast:
        return 45;
      case VastuDirection.east:
        return 90;
      case VastuDirection.southEast:
        return 135;
      case VastuDirection.south:
        return 180;
      case VastuDirection.southWest:
        return 225;
      case VastuDirection.west:
        return 270;
      case VastuDirection.northWest:
        return 315;
      case VastuDirection.center:
        return 0;
    }
  }
}

enum VastuSuitability {
  excellent,
  good,
  average,
  defect;

  String get label {
    switch (this) {
      case VastuSuitability.excellent:
        return 'Best (Auspicious)';
      case VastuSuitability.good:
        return 'Good / Acceptable';
      case VastuSuitability.average:
        return 'Neutral';
      case VastuSuitability.defect:
        return 'Defect (Major Dosha)';
    }
  }

  Color get color {
    switch (this) {
      case VastuSuitability.excellent:
        return const Color(0xFF16A34A);
      case VastuSuitability.good:
        return const Color(0xFF2563EB);
      case VastuSuitability.average:
        return const Color(0xFFEAB308);
      case VastuSuitability.defect:
        return const Color(0xFFDC2626);
    }
  }

  int get score {
    switch (this) {
      case VastuSuitability.excellent:
        return 100;
      case VastuSuitability.good:
        return 80;
      case VastuSuitability.average:
        return 50;
      case VastuSuitability.defect:
        return 15;
    }
  }
}

class RoomVastuRule {
  final String roomKey;
  final String roomName;
  final IconData icon;
  final VastuDirection bestDirection;
  final Map<VastuDirection, VastuSuitability> suitability;
  final String why;
  final String remedy;

  const RoomVastuRule({
    required this.roomKey,
    required this.roomName,
    required this.icon,
    required this.bestDirection,
    required this.suitability,
    required this.why,
    required this.remedy,
  });
}

class VastuKnowledgeBase {
  static const List<RoomVastuRule> roomRules = [
    RoomVastuRule(
      roomKey: 'kitchen',
      roomName: 'Kitchen (Cooking)',
      icon: Icons.kitchen_rounded,
      bestDirection: VastuDirection.southEast,
      suitability: {
        VastuDirection.southEast: VastuSuitability.excellent,
        VastuDirection.northWest: VastuSuitability.good,
        VastuDirection.east: VastuSuitability.average,
        VastuDirection.south: VastuSuitability.average,
        VastuDirection.west: VastuSuitability.average,
        VastuDirection.north: VastuSuitability.defect,
        VastuDirection.northEast: VastuSuitability.defect,
        VastuDirection.southWest: VastuSuitability.defect,
        VastuDirection.center: VastuSuitability.defect,
      },
      why:
          'South-East is ruled by Lord Agni (Fire element). Morning sun rays in South-East/East kill bacteria and maintain hygiene. Placing fire in North-East (Water zone) creates severe health/wealth clashes.',
      remedy:
          'If kitchen is in North-East or North, paint the wall light green/lemon yellow, keep a bronze Surya yantra, and place a small yellow marble slab under the gas stove.',
    ),
    RoomVastuRule(
      roomKey: 'master_bedroom',
      roomName: 'Master Bedroom',
      icon: Icons.bed_rounded,
      bestDirection: VastuDirection.southWest,
      suitability: {
        VastuDirection.southWest: VastuSuitability.excellent,
        VastuDirection.south: VastuSuitability.good,
        VastuDirection.west: VastuSuitability.good,
        VastuDirection.northWest: VastuSuitability.average,
        VastuDirection.north: VastuSuitability.average,
        VastuDirection.east: VastuSuitability.average,
        VastuDirection.southEast: VastuSuitability.defect,
        VastuDirection.northEast: VastuSuitability.defect,
        VastuDirection.center: VastuSuitability.defect,
      },
      why:
          'South-West represents Earth element (Prithvi) and heavy stability. The head of the family needs grounding energy for decision-making and peaceful sleep. Sleeping in North-East causes restless mind.',
      remedy:
          'Always sleep with head towards South or East (never North due to Earth magnetic polarity). If bedroom is in South-East, use cooling cream/pastel tones and avoid red curtains.',
    ),
    RoomVastuRule(
      roomKey: 'puja_room',
      roomName: 'Puja / Prayer Room',
      icon: Icons.self_improvement_rounded,
      bestDirection: VastuDirection.northEast,
      suitability: {
        VastuDirection.northEast: VastuSuitability.excellent,
        VastuDirection.east: VastuSuitability.good,
        VastuDirection.north: VastuSuitability.good,
        VastuDirection.west: VastuSuitability.average,
        VastuDirection.northWest: VastuSuitability.average,
        VastuDirection.southEast: VastuSuitability.defect,
        VastuDirection.south: VastuSuitability.defect,
        VastuDirection.southWest: VastuSuitability.defect,
        VastuDirection.center: VastuSuitability.average,
      },
      why:
          'North-East (Ishanya) receives pure early morning infrared and ultraviolet sunlight. It has the highest positive magnetic field, fostering tranquility, wisdom, and spiritual clarity.',
      remedy:
          'Keep the temple clean and uncluttered. Use white, light yellow, or light blue marble/paint. Never place temple directly under a staircase or adjacent to a toilet wall.',
    ),
    RoomVastuRule(
      roomKey: 'toilet',
      roomName: 'Toilet & Bathroom',
      icon: Icons.bathtub_rounded,
      bestDirection: VastuDirection.northWest,
      suitability: {
        VastuDirection.northWest: VastuSuitability.excellent,
        VastuDirection.west: VastuSuitability.good,
        VastuDirection.south: VastuSuitability.average,
        VastuDirection.southEast: VastuSuitability.average,
        VastuDirection.north: VastuSuitability.defect,
        VastuDirection.east: VastuSuitability.defect,
        VastuDirection.northEast: VastuSuitability.defect,
        VastuDirection.southWest: VastuSuitability.defect,
        VastuDirection.center: VastuSuitability.defect,
      },
      why:
          'North-West (Vayavya) governs disposal and air movement. A toilet in North-East drains away positive cosmic energy and causes health and financial stagnation.',
      remedy:
          'Keep a bowl of raw sea salt in a glass/ceramic bowl inside the toilet (replace monthly). Keep toilet lid and door closed at all times. Use zinc or brass strips on doorway if in North-East.',
    ),
    RoomVastuRule(
      roomKey: 'living_room',
      roomName: 'Living Room / Hall',
      icon: Icons.weekend_rounded,
      bestDirection: VastuDirection.northEast,
      suitability: {
        VastuDirection.northEast: VastuSuitability.excellent,
        VastuDirection.north: VastuSuitability.good,
        VastuDirection.east: VastuSuitability.good,
        VastuDirection.northWest: VastuSuitability.good,
        VastuDirection.west: VastuSuitability.average,
        VastuDirection.southEast: VastuSuitability.average,
        VastuDirection.south: VastuSuitability.average,
        VastuDirection.southWest: VastuSuitability.defect,
        VastuDirection.center: VastuSuitability.average,
      },
      why:
          'Living rooms welcome guests and external energy. North and East orientation promotes pleasant, open conversations and warmth. Heavy furniture should be kept towards South and West walls.',
      remedy:
          'Place heavy sofas against South and West walls. Keep North and East corners light, with fresh indoor plants (like Money Plant) and adequate natural light.',
    ),
    RoomVastuRule(
      roomKey: 'staircase',
      roomName: 'Staircase',
      icon: Icons.stairs_rounded,
      bestDirection: VastuDirection.southWest,
      suitability: {
        VastuDirection.southWest: VastuSuitability.excellent,
        VastuDirection.south: VastuSuitability.good,
        VastuDirection.west: VastuSuitability.good,
        VastuDirection.northWest: VastuSuitability.average,
        VastuDirection.southEast: VastuSuitability.average,
        VastuDirection.north: VastuSuitability.defect,
        VastuDirection.east: VastuSuitability.defect,
        VastuDirection.northEast: VastuSuitability.defect,
        VastuDirection.center: VastuSuitability.defect,
      },
      why:
          'Staircases carry heavy load. South and West are meant to be the heaviest parts of a building. Placing stairs in North-East or Center (Brahmasthan) suppresses the head of the house.',
      remedy:
          'Staircase should always turn clockwise (in the direction of the sun) while climbing up. Never build a puja room, toilet, or study directly beneath stairs.',
    ),
    RoomVastuRule(
      roomKey: 'main_door',
      roomName: 'Main Entrance Door',
      icon: Icons.meeting_room_rounded,
      bestDirection: VastuDirection.northEast,
      suitability: {
        VastuDirection.northEast: VastuSuitability.excellent,
        VastuDirection.north: VastuSuitability.good,
        VastuDirection.east: VastuSuitability.good,
        VastuDirection.west: VastuSuitability.average,
        VastuDirection.northWest: VastuSuitability.average,
        VastuDirection.southEast: VastuSuitability.average,
        VastuDirection.south: VastuSuitability.average,
        VastuDirection.southWest: VastuSuitability.defect,
        VastuDirection.center: VastuSuitability.average,
      },
      why:
          'The main entrance is the gateway for Pranic (life) energy. North-East and North doors bring prosperity and positive opportunities. South-West entrances invite instability.',
      remedy:
          'Main door should open clockwise inward. Keep threshold well-lit and clean with an auspicious Swastik, Om, or Toran. If South-West entrance, install Lead metal pyramids or yellow paint.',
    ),
    RoomVastuRule(
      roomKey: 'water_tank',
      roomName: 'Overhead Water Tank',
      icon: Icons.water_drop_rounded,
      bestDirection: VastuDirection.southWest,
      suitability: {
        VastuDirection.southWest: VastuSuitability.excellent,
        VastuDirection.west: VastuSuitability.good,
        VastuDirection.south: VastuSuitability.good,
        VastuDirection.northWest: VastuSuitability.average,
        VastuDirection.southEast: VastuSuitability.average,
        VastuDirection.north: VastuSuitability.defect,
        VastuDirection.east: VastuSuitability.defect,
        VastuDirection.northEast: VastuSuitability.defect,
        VastuDirection.center: VastuSuitability.defect,
      },
      why:
          'An overhead tank is the heaviest object on the roof. Placing heavy load in South-West balances the building and grants stability. Overhead weight in North-East causes severe mental pressure.',
      remedy:
          'Keep overhead tank elevated by at least 1-2 feet above slab in South-West. If accidentally in North-East, paint it blue or shift to West side.',
    ),
    RoomVastuRule(
      roomKey: 'underground_sump',
      roomName: 'Underground Sump / Borewell',
      icon: Icons.layers_rounded,
      bestDirection: VastuDirection.northEast,
      suitability: {
        VastuDirection.northEast: VastuSuitability.excellent,
        VastuDirection.north: VastuSuitability.good,
        VastuDirection.east: VastuSuitability.good,
        VastuDirection.northWest: VastuSuitability.average,
        VastuDirection.west: VastuSuitability.defect,
        VastuDirection.southEast: VastuSuitability.defect,
        VastuDirection.south: VastuSuitability.defect,
        VastuDirection.southWest: VastuSuitability.defect,
        VastuDirection.center: VastuSuitability.defect,
      },
      why:
          'Underground water sources and depression are auspicious in North and North-East. Having underground pits in South-West weakens the foundation and earth element.',
      remedy:
          'Ensure underground sump is cleanly covered in North-East quadrant. Never dig sumps or pits in South-West or Central Brahmasthan.',
    ),
  ];

  static RoomVastuRule? getRuleForRoom(String roomKey) {
    try {
      return roomRules.firstWhere((r) => r.roomKey == roomKey);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> evaluatePlan(
    Map<String, VastuDirection> roomPlacements,
  ) {
    int totalScore = 0;
    int maxPossible = 0;
    final List<Map<String, dynamic>> results = [];

    for (final rule in roomRules) {
      final direction = roomPlacements[rule.roomKey];
      if (direction == null) continue;

      final suit = rule.suitability[direction] ?? VastuSuitability.average;
      totalScore += suit.score;
      maxPossible += 100;

      results.add({
        'rule': rule,
        'direction': direction,
        'suitability': suit,
        'score': suit.score,
      });
    }

    final overallPercentage =
        maxPossible > 0 ? ((totalScore / maxPossible) * 100).round() : 100;

    String ratingText;
    Color ratingColor;
    if (overallPercentage >= 85) {
      ratingText = 'Highly Auspicious & Harmonious';
      ratingColor = const Color(0xFF16A34A);
    } else if (overallPercentage >= 70) {
      ratingText = 'Good Vastu Compliance';
      ratingColor = const Color(0xFF2563EB);
    } else if (overallPercentage >= 50) {
      ratingText = 'Moderate (Minor Remedies Needed)';
      ratingColor = const Color(0xFFEAB308);
    } else {
      ratingText = 'Significant Doshas (Remedies Recommended)';
      ratingColor = const Color(0xFFDC2626);
    }

    return {
      'score': overallPercentage,
      'ratingText': ratingText,
      'ratingColor': ratingColor,
      'results': results,
    };
  }
}

