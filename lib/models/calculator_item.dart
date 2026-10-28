import 'package:flutter/material.dart';

import '../screens/calculators/area_calculator.dart';
import '../screens/calculators/brick_calculator.dart';
import '../screens/calculators/cement_calculator.dart';
import '../screens/calculators/cost_estimator.dart';
import '../screens/calculators/excavation_calculator.dart';
import '../screens/calculators/paint_calculator.dart';
import '../screens/calculators/sand_calculator.dart';
import '../screens/calculators/staircase_calculator.dart';
import '../screens/calculators/steel_calculator.dart';
import '../screens/calculators/tile_calculator.dart';

class CalculatorCategory {
  static const String all = 'All';
  static const String favorites = 'Favorites';
  static const String masonry = 'Masonry & Concrete';
  static const String finishing = 'Finishing & Surfaces';
  static const String structural = 'Structural & Sizing';
  static const String estimation = 'Estimation & Cost';

  static const List<String> categories = [
    all,
    favorites,
    masonry,
    finishing,
    structural,
    estimation,
  ];
}

class CalculatorItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color iconColor;
  final List<String> keywords;
  final WidgetBuilder builder;

  const CalculatorItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.keywords,
    required this.builder,
  });

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final clean = query.trim().toLowerCase();
    if (title.toLowerCase().contains(clean)) return true;
    if (category.toLowerCase().contains(clean)) return true;
    if (description.toLowerCase().contains(clean)) return true;
    for (final kw in keywords) {
      if (kw.toLowerCase().contains(clean)) return true;
    }
    return false;
  }

  static List<CalculatorItem> get allCalculators => [
    CalculatorItem(
      id: 'cement',
      title: 'Cement Calculator',
      category: CalculatorCategory.masonry,
      description: 'Cement bags and sand volume for concrete & mortar',
      icon: Icons.architecture_rounded,
      iconColor: const Color(0xFF795548),
      keywords: ['cement', 'concrete', 'mortar', 'bags', 'slab', 'mix', 'sand'],
      builder: (context) => const CementCalculator(),
    ),
    CalculatorItem(
      id: 'brick',
      title: 'Brick Calculator',
      category: CalculatorCategory.masonry,
      description: 'Brick count with wall thickness and wastage',
      icon: Icons.grid_4x4_rounded,
      iconColor: const Color(0xFFD32F2F),
      keywords: ['brick', 'bricks', 'wall', 'masonry', 'blocks', 'thickness'],
      builder: (context) => const BrickCalculator(),
    ),
    CalculatorItem(
      id: 'sand',
      title: 'Sand Calculator',
      category: CalculatorCategory.masonry,
      description: 'Sand volume in cubic meters, cubic feet & tonnes',
      icon: Icons.terrain_rounded,
      iconColor: const Color(0xFFFFA726),
      keywords: [
        'sand',
        'aggregate',
        'tonnes',
        'cubic feet',
        'plaster',
        'filling',
      ],
      builder: (context) => const SandCalculator(),
    ),
    CalculatorItem(
      id: 'paint',
      title: 'Paint Calculator',
      category: CalculatorCategory.finishing,
      description: 'Liters of paint required by wall area & coats',
      icon: Icons.format_paint_rounded,
      iconColor: const Color(0xFF42A5F5),
      keywords: [
        'paint',
        'primer',
        'coats',
        'wall',
        'coverage',
        'room',
        'color',
      ],
      builder: (context) => const PaintCalculator(),
    ),
    CalculatorItem(
      id: 'tile',
      title: 'Tile Calculator',
      category: CalculatorCategory.finishing,
      description: 'Flooring tile counts and boxes with 10% wastage',
      icon: Icons.dashboard_rounded,
      iconColor: const Color(0xFF8D6E63),
      keywords: [
        'tile',
        'tiles',
        'floor',
        'flooring',
        'boxes',
        'ceramic',
        'porcelain',
      ],
      builder: (context) => const TileCalculator(),
    ),
    CalculatorItem(
      id: 'steel',
      title: 'Steel Calculator',
      category: CalculatorCategory.structural,
      description: 'Rebar weight per bar and total steel in kg & tonnes',
      icon: Icons.fence_rounded,
      iconColor: const Color(0xFF607D8B),
      keywords: [
        'steel',
        'rebar',
        'iron',
        'rod',
        'reinforcement',
        'diameter',
        'weight',
      ],
      builder: (context) => const SteelCalculator(),
    ),
    CalculatorItem(
      id: 'area',
      title: 'Area Calculator',
      category: CalculatorCategory.structural,
      description:
          'Area and perimeter for rectangle, square, circle & triangle',
      icon: Icons.square_foot_rounded,
      iconColor: const Color(0xFF66BB6A),
      keywords: [
        'area',
        'perimeter',
        'square',
        'rectangle',
        'circle',
        'triangle',
        'dimensions',
      ],
      builder: (context) => const AreaCalculator(),
    ),
    CalculatorItem(
      id: 'cost_estimator',
      title: 'Cost Estimator',
      category: CalculatorCategory.estimation,
      description: 'Construction budget estimation by area & quality tier',
      icon: Icons.calculate_rounded,
      iconColor: const Color(0xFFFF9800),
      keywords: [
        'cost',
        'budget',
        'estimator',
        'rate',
        'price',
        'total',
        'construction',
      ],
      builder: (context) => const CostEstimator(),
    ),
    CalculatorItem(
      id: 'staircase',
      title: 'Staircase Calculator',
      category: CalculatorCategory.structural,
      description: 'Riser, tread, waist slab, flight angle & concrete volume',
      icon: Icons.stairs_rounded,
      iconColor: const Color(0xFFFF8C00),
      keywords: [
        'stair',
        'stairs',
        'staircase',
        'riser',
        'tread',
        'flight',
        'landing',
        'steps',
        'waist',
      ],
      builder: (context) => const StaircaseCalculator(),
    ),
    CalculatorItem(
      id: 'excavation',
      title: 'Excavation & Backfilling',
      category: CalculatorCategory.masonry,
      description: 'Earthwork volume, soil bulking, backfill & truck trips',
      icon: Icons.agriculture_rounded,
      iconColor: const Color(0xFF8D6E63),
      keywords: [
        'excavation',
        'earthwork',
        'trench',
        'backfill',
        'soil',
        'foundation',
        'pit',
        'truck',
        'dumper',
      ],
      builder: (context) => const ExcavationCalculator(),
    ),
  ];

  static CalculatorItem? findById(String id) {
    try {
      return allCalculators.firstWhere((calc) => calc.id == id);
    } catch (_) {
      return null;
    }
  }
}
