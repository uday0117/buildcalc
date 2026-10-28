import 'package:flutter/material.dart';

import 'plan_models.dart';

/// Exterior architectural design concept styles
enum ElevationStyle {
  modern(
    'Modern',
    'Clean rectangular volumes, large glass apertures, cantilevered accents, and flat roof parapet.',
    Icons.apartment_rounded,
  ),
  traditional(
    'Traditional',
    'Sloped terracotta tiled roof, carved columns, arched or mullioned windows, and warm earth tones.',
    Icons.holiday_village_rounded,
  ),
  minimalist(
    'Minimalist',
    'Monolithic geometry, concealed framing, recessed balcony cuts, and subdued monochromatic tones.',
    Icons.crop_square_rounded,
  ),
  contemporary(
    'Contemporary',
    'Mixed stone veneer, warm teak timber accents, flat terrace pergola, and balanced horizontal bands.',
    Icons.villa_rounded,
  );

  final String label;
  final String description;
  final IconData icon;

  const ElevationStyle(this.label, this.description, this.icon);
}

/// Window styling options for facade
enum WindowStyle {
  modernPicture(
    'Modern Picture & Casement',
    'Slim black aluminum frames with wide glass view panels.',
    Icons.window_rounded,
  ),
  minimalistFrameless(
    'Minimalist Frameless',
    'Ultra-thin dark profiles with clean flush glazing.',
    Icons.crop_portrait_rounded,
  ),
  traditionalMullion(
    'Traditional Mullion',
    'Divided light multi-pane grid with classic wood/composite frames.',
    Icons.grid_view_rounded,
  ),
  traditionalArched(
    'Colonial Arch',
    'Graceful semicircular arched tops with decorative keystones.',
    Icons.panorama_vertical_select_rounded,
  ),
  ribbonHorizontal(
    'Horizontal Ribbon',
    'Continuous horizontal strip glazing for contemporary daylighting.',
    Icons.view_headline_rounded,
  );

  final String label;
  final String description;
  final IconData icon;

  const WindowStyle(this.label, this.description, this.icon);
}

/// Balcony and railing styling options
enum BalconyOption {
  none(
    'Flush Facade (No Balcony)',
    'Continuous exterior wall surface with flush windows.',
    Icons.crop_din_rounded,
  ),
  glassRailing(
    'Cantilevered Glass Balcony',
    'Tempered laminated glass panels with stainless steel handrails.',
    Icons.credit_card_rounded,
  ),
  metalLouver(
    'Modern Metal Louver Railing',
    'Vertical powder-coated black aluminum slat balustrade.',
    Icons.format_align_justify_rounded,
  ),
  masonryParapet(
    'Solid Plaster Parapet',
    'Solid masonry barrier with architectural groove accents.',
    Icons.horizontal_rule_rounded,
  ),
  ornateTraditional(
    'Traditional Balustrade',
    'Classical turned stone balusters or ornamental wrought iron.',
    Icons.fence_rounded,
  );

  final String label;
  final String description;
  final IconData icon;

  const BalconyOption(this.label, this.description, this.icon);
}

/// Wall texture and finish presets
enum FinishPreset {
  smoothPlaster(
    'Smooth Weathercoat Plaster',
    'Ultra-smooth elastomeric architectural exterior emulsion.',
    Color(0xFFF8FAFC),
  ),
  exposedBrick(
    'Wire-cut Terracotta Brick',
    'Warm exposed brick courses with recessed mortar joints.',
    Color(0xFFB45309),
  ),
  teakWoodSlat(
    'Natural Teak Timber Cladding',
    'Horizontal warm teakwood thermo-treated weatherboard slats.',
    Color(0xFF854D0E),
  ),
  stoneVeneer(
    'Split-Face Quartzite Stone',
    'Natural charcoal & beige ledgestone dry-stack veneer.',
    Color(0xFF64748B),
  ),
  exposedConcrete(
    'Architectural Board-Formed Concrete',
    'Fair-faced smooth grey concrete panels with tie-rod indentations.',
    Color(0xFF94A3B8),
  ),
  travertineMarble(
    'Honed Ivory Travertine',
    'Elegant off-white natural travertine stone slab panels.',
    Color(0xFFE2E8F0),
  );

  final String label;
  final String description;
  final Color swatchColor;

  const FinishPreset(this.label, this.description, this.swatchColor);
}

/// Roof silhouette styles
enum RoofStyle {
  flatParapet(
    'Flat Roof with Parapet',
    'Clean horizontal roof slab with coping stones and concealed drainage.',
    Icons.horizontal_split_rounded,
  ),
  pitchedTile(
    'Sloped Pitched Tile Eaves',
    'Classic sloping roof covered in red clay terracotta roof tiles.',
    Icons.roofing_rounded,
  ),
  terracePergola(
    'Open Terrace Pergola',
    'Architectural steel / wooden pergola shading over terrace garden.',
    Icons.table_restaurant_rounded,
  ),
  mansardHip(
    'Hip & Gable Roof Accent',
    'Multi-pitch sloped hip roof with overhang weather eaves.',
    Icons.house_siding_rounded,
  );

  final String label;
  final String description;
  final IconData icon;

  const RoofStyle(this.label, this.description, this.icon);
}

/// Preset color palettes for facade harmony
class ElevationColorPalette {
  final String id;
  final String name;
  final Color primary;
  final Color accent;
  final Color trim;
  final Color glass;

  const ElevationColorPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.accent,
    required this.trim,
    required this.glass,
  });

  static const modernIvoryWood = ElevationColorPalette(
    id: 'palette_ivory_wood',
    name: 'Ivory & Warm Teak',
    primary: Color(0xFFF8FAFC),
    accent: Color(0xFF854D0E),
    trim: Color(0xFF334155),
    glass: Color(0xFF93C5FD),
  );

  static const minimalistMonochrome = ElevationColorPalette(
    id: 'palette_monochrome',
    name: 'Minimalist Monochrome',
    primary: Color(0xFFFFFFFF),
    accent: Color(0xFF64748B),
    trim: Color(0xFF0F172A),
    glass: Color(0xFFCBD5E1),
  );

  static const warmTerracotta = ElevationColorPalette(
    id: 'palette_terracotta',
    name: 'Heritage Terracotta',
    primary: Color(0xFFFEF3C7),
    accent: Color(0xFFB45309),
    trim: Color(0xFF451A03),
    glass: Color(0xFFBAE6FD),
  );

  static const contemporarySlate = ElevationColorPalette(
    id: 'palette_slate',
    name: 'Contemporary Slate & Stone',
    primary: Color(0xFFF1F5F9),
    accent: Color(0xFF475569),
    trim: Color(0xFF1E293B),
    glass: Color(0xFF93C5FD),
  );

  static const coastalNavy = ElevationColorPalette(
    id: 'palette_coastal',
    name: 'Coastal White & Navy',
    primary: Color(0xFFF8FAFC),
    accent: Color(0xFF1E3A8A),
    trim: Color(0xFF0F172A),
    glass: Color(0xFF7DD3FC),
  );

  static const List<ElevationColorPalette> presets = [
    modernIvoryWood,
    minimalistMonochrome,
    warmTerracotta,
    contemporarySlate,
    coastalNavy,
  ];
}

/// Complete configuration for a front elevation design
class ElevationConfig {
  final String id;
  final String planId;
  final String planName;
  final String name;
  final ElevationStyle style;
  final int floorCount; // 1 = G, 2 = G+1, 3 = G+2, 4 = G+3
  final double facadeWidthFeet;
  final double floorHeightFeet;
  final double plinthHeightFeet;
  final double parapetHeightFeet;
  final Color primaryColor;
  final Color accentColor;
  final Color trimColor;
  final Color glassColor;
  final WindowStyle windowStyle;
  final BalconyOption balconyOption;
  final FinishPreset finishPreset;
  final RoofStyle roofStyle;
  final bool hasCarPorch;
  final bool hasEntrancePortico;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  const ElevationConfig({
    required this.id,
    required this.planId,
    required this.planName,
    required this.name,
    this.style = ElevationStyle.modern,
    this.floorCount = 2,
    this.facadeWidthFeet = 30.0,
    this.floorHeightFeet = 10.0,
    this.plinthHeightFeet = 2.5,
    this.parapetHeightFeet = 3.5,
    this.primaryColor = const Color(0xFFF8FAFC),
    this.accentColor = const Color(0xFF854D0E),
    this.trimColor = const Color(0xFF334155),
    this.glassColor = const Color(0xFF93C5FD),
    this.windowStyle = WindowStyle.modernPicture,
    this.balconyOption = BalconyOption.glassRailing,
    this.finishPreset = FinishPreset.smoothPlaster,
    this.roofStyle = RoofStyle.flatParapet,
    this.hasCarPorch = true,
    this.hasEntrancePortico = true,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  /// Factory seed from FloorPlan
  factory ElevationConfig.fromFloorPlan(FloorPlan plan) {
    final now = DateTime.now();
    // Default facade width to plot width or reasonable house frontage
    final frontage = plan.plotWidthFeet > 0 ? plan.plotWidthFeet : 30.0;

    return ElevationConfig(
      id: 'elev_${plan.id}_${now.millisecondsSinceEpoch}',
      planId: plan.id,
      planName: plan.name,
      name: '${plan.name} - Front Elevation',
      style: ElevationStyle.modern,
      floorCount: 2,
      facadeWidthFeet: frontage,
      floorHeightFeet: 10.0,
      plinthHeightFeet: 2.5,
      parapetHeightFeet: 3.5,
      primaryColor: ElevationColorPalette.modernIvoryWood.primary,
      accentColor: ElevationColorPalette.modernIvoryWood.accent,
      trimColor: ElevationColorPalette.modernIvoryWood.trim,
      glassColor: ElevationColorPalette.modernIvoryWood.glass,
      windowStyle: WindowStyle.modernPicture,
      balconyOption: BalconyOption.glassRailing,
      finishPreset: FinishPreset.smoothPlaster,
      roofStyle: RoofStyle.flatParapet,
      hasCarPorch: frontage >= 25.0,
      hasEntrancePortico: true,
      notes: 'Initial elevation concept based on floor plan layout.',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Total structural building height from Ground Level (GL) to highest ridge/parapet
  double get totalHeightFeet {
    final roofAdditionalHeight = roofStyle == RoofStyle.pitchedTile
        ? 6.0
        : parapetHeightFeet;
    return plinthHeightFeet +
        (floorCount * floorHeightFeet) +
        roofAdditionalHeight;
  }

  /// Formatted floor label (e.g. Ground Floor, G+1, G+2)
  String get floorCountLabel {
    switch (floorCount) {
      case 1:
        return 'Ground Floor Only (G)';
      case 2:
        return 'Double Story (G+1)';
      case 3:
        return 'Triple Story (G+2)';
      case 4:
        return 'Four Story (G+3)';
      default:
        return '$floorCount Floors';
    }
  }

  /// AI Prompt synthesizer for architectural diffusion / visual generation
  String generateAIPrompt() {
    final buffer = StringBuffer();
    buffer.write(
      'Architectural exterior front elevation photography of a ${style.label.toLowerCase()} house, ',
    );
    buffer.write('${floorCountLabel.toLowerCase()}, ');
    buffer.write('${facadeWidthFeet.toStringAsFixed(0)} feet wide facade. ');
    buffer.write(
      'Exterior finish: ${finishPreset.label.toLowerCase()} with accent details. ',
    );
    buffer.write(
      'Windows: ${windowStyle.label.toLowerCase()} with dark slim frames. ',
    );
    if (floorCount > 1) {
      buffer.write('Balcony: ${balconyOption.label.toLowerCase()}. ');
    }
    buffer.write('Roof: ${roofStyle.label.toLowerCase()}. ');
    if (hasCarPorch) {
      buffer.write('Includes modern covered car porch on ground level. ');
    }
    if (hasEntrancePortico) {
      buffer.write('Features grand entrance door with portico canopy. ');
    }
    buffer.write(
      'Colors: main facade #${primaryColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}, ',
    );
    buffer.write(
      'accent details #${accentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}. ',
    );
    buffer.write(
      'Lighting: warm architectural evening accent sconces, soft ambient daylighting, landscaped front courtyard. ',
    );
    buffer.write(
      'Straight-on orthographic eye-level facade angle, hyperrealistic 8k architectural rendering.',
    );
    return buffer.toString();
  }

  ElevationConfig copyWith({
    String? id,
    String? planId,
    String? planName,
    String? name,
    ElevationStyle? style,
    int? floorCount,
    double? facadeWidthFeet,
    double? floorHeightFeet,
    double? plinthHeightFeet,
    double? parapetHeightFeet,
    Color? primaryColor,
    Color? accentColor,
    Color? trimColor,
    Color? glassColor,
    WindowStyle? windowStyle,
    BalconyOption? balconyOption,
    FinishPreset? finishPreset,
    RoofStyle? roofStyle,
    bool? hasCarPorch,
    bool? hasEntrancePortico,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return ElevationConfig(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      name: name ?? this.name,
      style: style ?? this.style,
      floorCount: floorCount ?? this.floorCount,
      facadeWidthFeet: facadeWidthFeet ?? this.facadeWidthFeet,
      floorHeightFeet: floorHeightFeet ?? this.floorHeightFeet,
      plinthHeightFeet: plinthHeightFeet ?? this.plinthHeightFeet,
      parapetHeightFeet: parapetHeightFeet ?? this.parapetHeightFeet,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      trimColor: trimColor ?? this.trimColor,
      glassColor: glassColor ?? this.glassColor,
      windowStyle: windowStyle ?? this.windowStyle,
      balconyOption: balconyOption ?? this.balconyOption,
      finishPreset: finishPreset ?? this.finishPreset,
      roofStyle: roofStyle ?? this.roofStyle,
      hasCarPorch: hasCarPorch ?? this.hasCarPorch,
      hasEntrancePortico: hasEntrancePortico ?? this.hasEntrancePortico,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'planName': planName,
    'name': name,
    'style': style.name,
    'floorCount': floorCount,
    'facadeWidthFeet': facadeWidthFeet,
    'floorHeightFeet': floorHeightFeet,
    'plinthHeightFeet': plinthHeightFeet,
    'parapetHeightFeet': parapetHeightFeet,
    'primaryColor': primaryColor.toARGB32(),
    'accentColor': accentColor.toARGB32(),
    'trimColor': trimColor.toARGB32(),
    'glassColor': glassColor.toARGB32(),
    'windowStyle': windowStyle.name,
    'balconyOption': balconyOption.name,
    'finishPreset': finishPreset.name,
    'roofStyle': roofStyle.name,
    'hasCarPorch': hasCarPorch,
    'hasEntrancePortico': hasEntrancePortico,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isFavorite': isFavorite,
  };

  factory ElevationConfig.fromJson(
    Map<String, dynamic> json,
  ) => ElevationConfig(
    id: json['id'] as String,
    planId: json['planId'] as String? ?? '',
    planName: json['planName'] as String? ?? 'Untitled Plan',
    name: json['name'] as String? ?? 'Front Elevation',
    style: ElevationStyle.values.firstWhere(
      (e) => e.name == json['style'],
      orElse: () => ElevationStyle.modern,
    ),
    floorCount: (json['floorCount'] as num?)?.toInt() ?? 2,
    facadeWidthFeet: (json['facadeWidthFeet'] as num?)?.toDouble() ?? 30.0,
    floorHeightFeet: (json['floorHeightFeet'] as num?)?.toDouble() ?? 10.0,
    plinthHeightFeet: (json['plinthHeightFeet'] as num?)?.toDouble() ?? 2.5,
    parapetHeightFeet: (json['parapetHeightFeet'] as num?)?.toDouble() ?? 3.5,
    primaryColor: Color(
      json['primaryColor'] as int? ?? const Color(0xFFF8FAFC).toARGB32(),
    ),
    accentColor: Color(
      json['accentColor'] as int? ?? const Color(0xFF854D0E).toARGB32(),
    ),
    trimColor: Color(
      json['trimColor'] as int? ?? const Color(0xFF334155).toARGB32(),
    ),
    glassColor: Color(
      json['glassColor'] as int? ?? const Color(0xFF93C5FD).toARGB32(),
    ),
    windowStyle: WindowStyle.values.firstWhere(
      (e) => e.name == json['windowStyle'],
      orElse: () => WindowStyle.modernPicture,
    ),
    balconyOption: BalconyOption.values.firstWhere(
      (e) => e.name == json['balconyOption'],
      orElse: () => BalconyOption.glassRailing,
    ),
    finishPreset: FinishPreset.values.firstWhere(
      (e) => e.name == json['finishPreset'],
      orElse: () => FinishPreset.smoothPlaster,
    ),
    roofStyle: RoofStyle.values.firstWhere(
      (e) => e.name == json['roofStyle'],
      orElse: () => RoofStyle.flatParapet,
    ),
    hasCarPorch: json['hasCarPorch'] as bool? ?? true,
    hasEntrancePortico: json['hasEntrancePortico'] as bool? ?? true,
    notes: json['notes'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    isFavorite: json['isFavorite'] as bool? ?? false,
  );
}

/// Elevation display view mode
enum ElevationViewMode {
  illustrative(
    'Illustrative Design Concept',
    'Rendered with architectural colors, finishes, depth, and landscaping.',
  ),
  dimensioned(
    'Dimensioned Construction Draft',
    'Orthographic CAD elevation with datum levels, heights, and structural lines.',
  );

  final String label;
  final String description;

  const ElevationViewMode(this.label, this.description);
}
