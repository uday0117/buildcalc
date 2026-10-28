import 'plan_models.dart';
import 'plan_unit.dart';

/// Structured metadata and geometric definition for a ready-made house plan template.
class ReadyMadePlanTemplate {
  final String id;
  final String title;
  final String bhkType; // '1 BHK', '2 BHK', '3 BHK', '4 BHK'
  final String description;
  final double plotWidthFeet;
  final double plotLengthFeet;
  final String orientation; // e.g. 'North Facing', 'East Facing'
  final double frontSetbackFeet;
  final double rearSetbackFeet;
  final double sideSetbackFeet;
  final String setbacksDescription;
  final String disclaimer;
  final List<PlanRoom> Function() roomsBuilder;

  const ReadyMadePlanTemplate({
    required this.id,
    required this.title,
    required this.bhkType,
    required this.description,
    required this.plotWidthFeet,
    required this.plotLengthFeet,
    required this.orientation,
    required this.frontSetbackFeet,
    required this.rearSetbackFeet,
    required this.sideSetbackFeet,
    required this.setbacksDescription,
    required this.disclaimer,
    required this.roomsBuilder,
  });

  String get plotDimensionsLabel =>
      '${plotWidthFeet.toInt()}\' × ${plotLengthFeet.toInt()}\'';

  double get plotAreaSqFt => plotWidthFeet * plotLengthFeet;

  double get usablePlotWidthFeet =>
      (plotWidthFeet - (sideSetbackFeet * 2)).clamp(0.0, plotWidthFeet);

  double get usablePlotLengthFeet =>
      (plotLengthFeet - (frontSetbackFeet + rearSetbackFeet)).clamp(
        0.0,
        plotLengthFeet,
      );

  double get usablePlotAreaSqFt => usablePlotWidthFeet * usablePlotLengthFeet;

  int get roomCount => roomsBuilder().length;

  /// Approximate built-up area calculated from room footprints + structural walls factor
  double get totalBuiltUpAreaSqFt {
    final rooms = roomsBuilder();
    if (rooms.isEmpty) return 0.0;
    final carpet = rooms.fold<double>(0.0, (sum, r) => sum + r.areaSqFt);
    return carpet * 1.12;
  }

  double get groundCoveragePercent {
    if (plotAreaSqFt <= 0) return 0.0;
    return (totalBuiltUpAreaSqFt / plotAreaSqFt) * 100.0;
  }

  /// Instantiates an independent, editable [FloorPlan] instance.
  /// Modifying this plan does not alter the underlying template definition.
  FloorPlan createFreshPlan({String? name, PlanUnit unit = PlanUnit.feet}) {
    final now = DateTime.now();
    final planId = 'plan_${id}_${now.microsecondsSinceEpoch}';
    final rawRooms = roomsBuilder();

    // Give each room and opening independent unique IDs for safe editing
    int roomIdx = 0;
    final freshRooms = rawRooms.map((r) {
      final freshRoomId = '${planId}_r_${roomIdx++}';
      int opIdx = 0;
      final freshOpenings = r.openings.map((op) {
        return op.copyWith(
          id: '${freshRoomId}_op_${opIdx++}',
          roomId: freshRoomId,
        );
      }).toList();

      return r.copyWith(id: freshRoomId, openings: freshOpenings);
    }).toList();

    return FloorPlan(
      id: planId,
      name: name?.trim().isNotEmpty == true ? name!.trim() : title,
      plotWidthFeet: plotWidthFeet,
      plotLengthFeet: plotLengthFeet,
      unit: unit,
      layoutType: bhkType,
      rooms: freshRooms,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Catalog of curated 1, 2, 3, and 4 BHK ready-made house plan templates.
class ReadyMadePlanCatalog {
  static const String universalDisclaimer =
      'Notice: Ready-made templates are illustrative conceptual starting layouts for spatial planning, visualization and material estimation. They are not approved municipal sanction drawings or certified structural engineering plans. Building bylaws, setbacks, FAR/FSI regulations and structural safety must be verified and approved by a certified architect and structural engineer before construction.';

  static const List<String> bhkFilterOptions = [
    'All',
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4 BHK',
  ];

  static const List<String> plotDimensionFilterOptions = [
    'All Sizes',
    '20x30 ft',
    '30x40 ft',
    '40x60 ft',
  ];

  /// The curated list of starting layouts covering common Indian & global plot sizes
  static final List<ReadyMadePlanTemplate> templates = [
    // ----------------- 1 BHK TEMPLATES -----------------
    ReadyMadePlanTemplate(
      id: 'tmpl_1bhk_20x30',
      title: '1 BHK Compact Urban',
      bhkType: '1 BHK',
      description:
          'Smart space-optimized starter home ideal for narrow 20x30 plots. Features a bright front living room, efficient open kitchen, bathroom, master bedroom and rear utility balcony.',
      plotWidthFeet: 20.0,
      plotLengthFeet: 30.0,
      orientation: 'North-Facing Entry',
      frontSetbackFeet: 3.0,
      rearSetbackFeet: 2.0,
      sideSetbackFeet: 1.5,
      setbacksDescription: 'Front: 3.0 ft, Rear: 2.0 ft, Sides: 1.5 ft',
      disclaimer: universalDisclaimer,
      roomsBuilder: _build1BHK20x30Rooms,
    ),
    ReadyMadePlanTemplate(
      id: 'tmpl_1bhk_30x40',
      title: '1 BHK Suburban Starter',
      bhkType: '1 BHK',
      description:
          'Generous single-bedroom home for 30x40 plots with ample garden setbacks, private entrance porch, large living hall, dedicated dining area, master bedroom and utility.',
      plotWidthFeet: 30.0,
      plotLengthFeet: 40.0,
      orientation: 'East-Facing Entry',
      frontSetbackFeet: 5.0,
      rearSetbackFeet: 3.0,
      sideSetbackFeet: 3.0,
      setbacksDescription: 'Front: 5.0 ft, Rear: 3.0 ft, Sides: 3.0 ft',
      disclaimer: universalDisclaimer,
      roomsBuilder: _build1BHK30x40Rooms,
    ),

    // ----------------- 2 BHK TEMPLATES -----------------
    ReadyMadePlanTemplate(
      id: 'tmpl_2bhk_20x30',
      title: '2 BHK Compact Standard',
      bhkType: '2 BHK',
      description:
          'High-efficiency 2 BHK layout designed for standard 20x30 plots. Features compact living-dining, kitchen, 2 private bedrooms and a centralized common bath.',
      plotWidthFeet: 20.0,
      plotLengthFeet: 30.0,
      orientation: 'East-Facing Entry',
      frontSetbackFeet: 2.5,
      rearSetbackFeet: 1.5,
      sideSetbackFeet: 1.0,
      setbacksDescription: 'Front: 2.5 ft, Rear: 1.5 ft, Sides: 1.0 ft',
      disclaimer: universalDisclaimer,
      roomsBuilder: _build2BHK20x30Rooms,
    ),
    ReadyMadePlanTemplate(
      id: 'tmpl_2bhk_30x40',
      title: '2 BHK Popular Classic',
      bhkType: '2 BHK',
      description:
          'The most requested standard 30x40 Indian residential plan. Entrance foyer, expansive living room, kitchen with utility, master bedroom with attached bath, second bedroom and common bath.',
      plotWidthFeet: 30.0,
      plotLengthFeet: 40.0,
      orientation: 'North-East Facing Entry',
      frontSetbackFeet: 4.0,
      rearSetbackFeet: 3.0,
      sideSetbackFeet: 2.5,
      setbacksDescription: 'Front: 4.0 ft, Rear: 3.0 ft, Sides: 2.5 ft',
      disclaimer: universalDisclaimer,
      roomsBuilder: _build2BHK30x40Rooms,
    ),
    ReadyMadePlanTemplate(
      id: 'tmpl_2bhk_40x60',
      title: '2 BHK Garden Villa',
      bhkType: '2 BHK',
      description:
          'Spacious single-story bungalow layout on 40x60 plot surrounded by green setbacks. Grand living hall, formal dining, gourmet kitchen, master suite with walk-in dressing and garden sit-out.',
      plotWidthFeet: 40.0,
      plotLengthFeet: 60.0,
      orientation: 'North-Facing Entry',
      frontSetbackFeet: 10.0,
      rearSetbackFeet: 6.0,
      sideSetbackFeet: 5.0,
      setbacksDescription: 'Front: 10.0 ft, Rear: 6.0 ft, Sides: 5.0 ft',
      disclaimer: universalDisclaimer,
      roomsBuilder: _build2BHK40x60Rooms,
    ),

    // ----------------- 3 BHK TEMPLATES -----------------
    ReadyMadePlanTemplate(
      id: 'tmpl_3bhk_30x40',
      title: '3 BHK Smart Townhouse',
      bhkType: '3 BHK',
      description:
          'Intelligently planned 3 BHK layout optimized for 30x40 plots. Living hall, kitchen-dining, master suite with attached bath, 2 additional bedrooms, common bath and utility.',
      plotWidthFeet: 30.0,
      plotLengthFeet: 40.0,
      orientation: 'East-Facing Entry',
      frontSetbackFeet: 3.5,
      rearSetbackFeet: 2.5,
      sideSetbackFeet: 2.0,
      setbacksDescription: 'Front: 3.5 ft, Rear: 2.5 ft, Sides: 2.0 ft',
      disclaimer: universalDisclaimer,
      roomsBuilder: _build3BHK30x40Rooms,
    ),
    ReadyMadePlanTemplate(
      id: 'tmpl_3bhk_40x60',
      title: '3 BHK Executive Villa',
      bhkType: '3 BHK',
      description:
          'Premium executive layout for 40x60 plots. Grand foyer, double-height living room, dedicated dining hall, gourmet kitchen with pantry, master suite with ensuite, 2 guest/family bedrooms and wide verandah.',
      plotWidthFeet: 40.0,
      plotLengthFeet: 60.0,
      orientation: 'East-Facing Entry',
      frontSetbackFeet: 8.0,
      rearSetbackFeet: 5.0,
      sideSetbackFeet: 4.0,
      setbacksDescription: 'Front: 8.0 ft, Rear: 5.0 ft, Sides: 4.0 ft',
      disclaimer: universalDisclaimer,
      roomsBuilder: _build3BHK40x60Rooms,
    ),

    // ----------------- 4 BHK TEMPLATES -----------------
    ReadyMadePlanTemplate(
      id: 'tmpl_4bhk_40x60',
      title: '4 BHK Contemporary Haven',
      bhkType: '4 BHK',
      description:
          'Luxurious 4 BHK villa layout for 40x60 plots. Foyer, formal living hall, family dining, modern kitchen with utility, pooja room, home office/study, 4 well-ventilated bedrooms, 3 bathrooms and rear patio.',
      plotWidthFeet: 40.0,
      plotLengthFeet: 60.0,
      orientation: 'North-Facing Entry',
      frontSetbackFeet: 6.0,
      rearSetbackFeet: 4.0,
      sideSetbackFeet: 3.5,
      setbacksDescription: 'Front: 6.0 ft, Rear: 4.0 ft, Sides: 3.5 ft',
      disclaimer: universalDisclaimer,
      roomsBuilder: _build4BHK40x60Rooms,
    ),
  ];

  static ReadyMadePlanTemplate? getById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Filter templates by BHK category, plot dimension tag, or search query
  static List<ReadyMadePlanTemplate> filter({
    String? bhk,
    String? dimension,
    String? query,
  }) {
    return templates.where((template) {
      if (bhk != null && bhk != 'All' && template.bhkType != bhk) {
        return false;
      }

      if (dimension != null && dimension != 'All Sizes') {
        final dimNorm = dimension.replaceAll(' ft', '').replaceAll(' ', '');
        final plotTag =
            '${template.plotWidthFeet.toInt()}x${template.plotLengthFeet.toInt()}';
        if (plotTag != dimNorm) {
          return false;
        }
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesTitle = template.title.toLowerCase().contains(q);
        final matchesDesc = template.description.toLowerCase().contains(q);
        final matchesBhk = template.bhkType.toLowerCase().contains(q);
        final matchesDim = template.plotDimensionsLabel.toLowerCase().contains(
          q,
        );
        if (!matchesTitle && !matchesDesc && !matchesBhk && !matchesDim) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ================= GEOMETRY BUILDERS =================

  // 1. 1 BHK on 20x30 plot
  static List<PlanRoom> _build1BHK20x30Rooms() {
    return [
      PlanRoom(
        id: 'r_1bhk_2030_living',
        name: 'Living & Dining',
        type: RoomType.living,
        x: 1.5,
        y: 3.0,
        width: 10.5,
        length: 13.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_2030_main_door',
            roomId: 'r_1bhk_2030_living',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 2.0,
            widthFeet: 4.0,
          ),
          PlanOpening(
            id: 'op_1bhk_2030_liv_win',
            roomId: 'r_1bhk_2030_living',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_1bhk_2030_kitchen',
        name: 'Kitchen',
        type: RoomType.kitchen,
        x: 12.0,
        y: 3.0,
        width: 6.5,
        length: 8.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_2030_kit_door',
            roomId: 'r_1bhk_2030_kitchen',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_1bhk_2030_kit_win',
            roomId: 'r_1bhk_2030_kitchen',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 1.5,
            widthFeet: 3.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_1bhk_2030_bath',
        name: 'Bathroom',
        type: RoomType.bathroom,
        x: 12.0,
        y: 11.0,
        width: 6.5,
        length: 5.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_2030_bath_door',
            roomId: 'r_1bhk_2030_bath',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_1bhk_2030_bath_vent',
            roomId: 'r_1bhk_2030_bath',
            wallSide: PlanWallSide.east,
            type: OpeningType.ventilation,
            offsetFeet: 2.0,
            widthFeet: 2.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_1bhk_2030_mbed',
        name: 'Master Bedroom',
        type: RoomType.masterBedroom,
        x: 1.5,
        y: 16.0,
        width: 11.0,
        length: 12.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_2030_bed_door',
            roomId: 'r_1bhk_2030_mbed',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_1bhk_2030_bed_win',
            roomId: 'r_1bhk_2030_mbed',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_1bhk_2030_balcony',
        name: 'Utility Balcony',
        type: RoomType.balcony,
        x: 12.5,
        y: 16.0,
        width: 6.0,
        length: 12.0,
        colorValue: RoomType.balcony.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_2030_balc_door',
            roomId: 'r_1bhk_2030_balcony',
            wallSide: PlanWallSide.west,
            type: OpeningType.slidingDoor,
            offsetFeet: 3.0,
            widthFeet: 3.5,
          ),
        ],
      ),
    ];
  }

  // 2. 1 BHK on 30x40 plot
  static List<PlanRoom> _build1BHK30x40Rooms() {
    return [
      PlanRoom(
        id: 'r_1bhk_3040_porch',
        name: 'Entrance Porch',
        type: RoomType.foyer,
        x: 3.0,
        y: 5.0,
        width: 8.0,
        length: 6.0,
        colorValue: RoomType.foyer.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_3040_entry_door',
            roomId: 'r_1bhk_3040_porch',
            wallSide: PlanWallSide.south,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_1bhk_3040_living',
        name: 'Living Room',
        type: RoomType.living,
        x: 11.0,
        y: 5.0,
        width: 16.0,
        length: 14.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_3040_liv_door',
            roomId: 'r_1bhk_3040_living',
            wallSide: PlanWallSide.west,
            type: OpeningType.doubleDoor,
            offsetFeet: 1.0,
            widthFeet: 4.0,
          ),
          PlanOpening(
            id: 'op_1bhk_3040_liv_win',
            roomId: 'r_1bhk_3040_living',
            wallSide: PlanWallSide.north,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_1bhk_3040_mbed',
        name: 'Master Bedroom',
        type: RoomType.masterBedroom,
        x: 3.0,
        y: 11.0,
        width: 12.0,
        length: 16.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_3040_bed_door',
            roomId: 'r_1bhk_3040_mbed',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 3.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_1bhk_3040_bed_win',
            roomId: 'r_1bhk_3040_mbed',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_1bhk_3040_kitchen',
        name: 'Kitchen & Dining',
        type: RoomType.kitchen,
        x: 15.0,
        y: 19.0,
        width: 12.0,
        length: 14.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_3040_kit_door',
            roomId: 'r_1bhk_3040_kitchen',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_1bhk_3040_kit_win',
            roomId: 'r_1bhk_3040_kitchen',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_1bhk_3040_bath',
        name: 'Bathroom',
        type: RoomType.bathroom,
        x: 3.0,
        y: 27.0,
        width: 8.0,
        length: 6.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_3040_bath_door',
            roomId: 'r_1bhk_3040_bath',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_1bhk_3040_bath_vent',
            roomId: 'r_1bhk_3040_bath',
            wallSide: PlanWallSide.west,
            type: OpeningType.ventilation,
            offsetFeet: 2.0,
            widthFeet: 2.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_1bhk_3040_utility',
        name: 'Utility / Wash',
        type: RoomType.utility,
        x: 11.0,
        y: 27.0,
        width: 4.0,
        length: 6.0,
        colorValue: RoomType.utility.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_1bhk_3040_util_door',
            roomId: 'r_1bhk_3040_utility',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
        ],
      ),
    ];
  }

  // 3. 2 BHK on 20x30 plot
  static List<PlanRoom> _build2BHK20x30Rooms() {
    return [
      PlanRoom(
        id: 'r_2bhk_2030_living',
        name: 'Living Hall',
        type: RoomType.living,
        x: 1.0,
        y: 2.5,
        width: 10.5,
        length: 12.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_2030_main_door',
            roomId: 'r_2bhk_2030_living',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 2.0,
            widthFeet: 4.0,
          ),
          PlanOpening(
            id: 'op_2bhk_2030_win_liv',
            roomId: 'r_2bhk_2030_living',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_2030_kitchen',
        name: 'Kitchen & Dining',
        type: RoomType.kitchen,
        x: 11.5,
        y: 2.5,
        width: 7.5,
        length: 10.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_2030_kit_door',
            roomId: 'r_2bhk_2030_kitchen',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_2bhk_2030_kit_win',
            roomId: 'r_2bhk_2030_kitchen',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 2.0,
            widthFeet: 3.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_2030_bath',
        name: 'Common Bath',
        type: RoomType.bathroom,
        x: 11.5,
        y: 12.5,
        width: 7.5,
        length: 5.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_2030_bath_door',
            roomId: 'r_2bhk_2030_bath',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_2bhk_2030_bath_vent',
            roomId: 'r_2bhk_2030_bath',
            wallSide: PlanWallSide.east,
            type: OpeningType.ventilation,
            offsetFeet: 2.0,
            widthFeet: 2.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_2030_mbed',
        name: 'Master Bedroom',
        type: RoomType.masterBedroom,
        x: 1.0,
        y: 14.5,
        width: 10.0,
        length: 13.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_2030_mbed_door',
            roomId: 'r_2bhk_2030_mbed',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_2bhk_2030_mbed_win',
            roomId: 'r_2bhk_2030_mbed',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.5,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_2030_bed2',
        name: 'Bedroom 2',
        type: RoomType.bedroom,
        x: 11.0,
        y: 17.5,
        width: 8.0,
        length: 10.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_2030_bed2_door',
            roomId: 'r_2bhk_2030_bed2',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_2bhk_2030_bed2_win',
            roomId: 'r_2bhk_2030_bed2',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 2.0,
            widthFeet: 3.5,
          ),
        ],
      ),
    ];
  }

  // 4. 2 BHK on 30x40 plot
  static List<PlanRoom> _build2BHK30x40Rooms() {
    return [
      PlanRoom(
        id: 'r_2bhk_3040_foyer',
        name: 'Entrance Foyer',
        type: RoomType.foyer,
        x: 2.5,
        y: 4.0,
        width: 7.0,
        length: 5.0,
        colorValue: RoomType.foyer.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_3040_entry',
            roomId: 'r_2bhk_3040_foyer',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 1.5,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_3040_living',
        name: 'Living Hall',
        type: RoomType.living,
        x: 9.5,
        y: 4.0,
        width: 18.0,
        length: 14.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_3040_liv_win',
            roomId: 'r_2bhk_3040_living',
            wallSide: PlanWallSide.north,
            type: OpeningType.window,
            offsetFeet: 5.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_3040_kitchen',
        name: 'Kitchen',
        type: RoomType.kitchen,
        x: 2.5,
        y: 9.0,
        width: 7.0,
        length: 9.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_3040_kit_door',
            roomId: 'r_2bhk_3040_kitchen',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_2bhk_3040_kit_win',
            roomId: 'r_2bhk_3040_kitchen',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 2.0,
            widthFeet: 3.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_3040_dining',
        name: 'Dining Area',
        type: RoomType.dining,
        x: 2.5,
        y: 18.0,
        width: 11.0,
        length: 8.0,
        colorValue: RoomType.dining.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_3040_din_win',
            roomId: 'r_2bhk_3040_dining',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 2.0,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_3040_mbed',
        name: 'Master Bedroom',
        type: RoomType.masterBedroom,
        x: 13.5,
        y: 18.0,
        width: 14.0,
        length: 12.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_3040_mbed_door',
            roomId: 'r_2bhk_3040_mbed',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_2bhk_3040_mbed_win',
            roomId: 'r_2bhk_3040_mbed',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_3040_att_bath',
        name: 'Attached Bath',
        type: RoomType.bathroom,
        x: 21.0,
        y: 30.0,
        width: 6.5,
        length: 7.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_3040_abath_door',
            roomId: 'r_2bhk_3040_att_bath',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_2bhk_3040_abath_vent',
            roomId: 'r_2bhk_3040_att_bath',
            wallSide: PlanWallSide.east,
            type: OpeningType.ventilation,
            offsetFeet: 2.0,
            widthFeet: 2.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_3040_bed2',
        name: 'Bedroom 2',
        type: RoomType.bedroom,
        x: 8.5,
        y: 26.0,
        width: 12.5,
        length: 11.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_3040_bed2_door',
            roomId: 'r_2bhk_3040_bed2',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_2bhk_3040_bed2_win',
            roomId: 'r_2bhk_3040_bed2',
            wallSide: PlanWallSide.south,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_3040_common_bath',
        name: 'Common Bath',
        type: RoomType.bathroom,
        x: 2.5,
        y: 26.0,
        width: 6.0,
        length: 6.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_3040_cbath_door',
            roomId: 'r_2bhk_3040_common_bath',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_2bhk_3040_cbath_vent',
            roomId: 'r_2bhk_3040_common_bath',
            wallSide: PlanWallSide.west,
            type: OpeningType.ventilation,
            offsetFeet: 1.5,
            widthFeet: 2.0,
          ),
        ],
      ),
    ];
  }

  // 5. 2 BHK on 40x60 plot
  static List<PlanRoom> _build2BHK40x60Rooms() {
    return [
      PlanRoom(
        id: 'r_2bhk_4060_verandah',
        name: 'Front Verandah',
        type: RoomType.foyer,
        x: 5.0,
        y: 10.0,
        width: 10.0,
        length: 8.0,
        colorValue: RoomType.foyer.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_4060_main_door',
            roomId: 'r_2bhk_4060_verandah',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 2.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_4060_living',
        name: 'Grand Living Room',
        type: RoomType.living,
        x: 15.0,
        y: 10.0,
        width: 20.0,
        length: 16.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_4060_liv_win',
            roomId: 'r_2bhk_4060_living',
            wallSide: PlanWallSide.north,
            type: OpeningType.window,
            offsetFeet: 5.0,
            widthFeet: 6.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_4060_dining',
        name: 'Formal Dining',
        type: RoomType.dining,
        x: 5.0,
        y: 18.0,
        width: 14.0,
        length: 12.0,
        colorValue: RoomType.dining.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_4060_din_win',
            roomId: 'r_2bhk_4060_dining',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_4060_kitchen',
        name: 'Open Modular Kitchen',
        type: RoomType.kitchen,
        x: 19.0,
        y: 26.0,
        width: 16.0,
        length: 12.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_4060_kit_win',
            roomId: 'r_2bhk_4060_kitchen',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_4060_mbed',
        name: 'Master Suite',
        type: RoomType.masterBedroom,
        x: 5.0,
        y: 30.0,
        width: 14.0,
        length: 15.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_4060_mbed_door',
            roomId: 'r_2bhk_4060_mbed',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 3.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_2bhk_4060_mbed_win',
            roomId: 'r_2bhk_4060_mbed',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_4060_mbath',
        name: 'Master Bath & Dressing',
        type: RoomType.bathroom,
        x: 5.0,
        y: 45.0,
        width: 8.0,
        length: 8.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_4060_mbath_door',
            roomId: 'r_2bhk_4060_mbath',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_2bhk_4060_mbath_vent',
            roomId: 'r_2bhk_4060_mbath',
            wallSide: PlanWallSide.south,
            type: OpeningType.ventilation,
            offsetFeet: 2.5,
            widthFeet: 2.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_4060_bed2',
        name: 'Bedroom 2',
        type: RoomType.bedroom,
        x: 19.0,
        y: 38.0,
        width: 16.0,
        length: 14.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_4060_bed2_door',
            roomId: 'r_2bhk_4060_bed2',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 3.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_2bhk_4060_bed2_win',
            roomId: 'r_2bhk_4060_bed2',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_2bhk_4060_cbath',
        name: 'Common Bath',
        type: RoomType.bathroom,
        x: 13.0,
        y: 45.0,
        width: 6.0,
        length: 8.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_2bhk_4060_cbath_door',
            roomId: 'r_2bhk_4060_cbath',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_2bhk_4060_cbath_vent',
            roomId: 'r_2bhk_4060_cbath',
            wallSide: PlanWallSide.south,
            type: OpeningType.ventilation,
            offsetFeet: 1.5,
            widthFeet: 2.0,
          ),
        ],
      ),
    ];
  }

  // 6. 3 BHK on 30x40 plot
  static List<PlanRoom> _build3BHK30x40Rooms() {
    return [
      PlanRoom(
        id: 'r_3bhk_3040_living',
        name: 'Living Hall',
        type: RoomType.living,
        x: 2.0,
        y: 3.5,
        width: 14.0,
        length: 14.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_3040_entry',
            roomId: 'r_3bhk_3040_living',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 2.0,
            widthFeet: 4.0,
          ),
          PlanOpening(
            id: 'op_3bhk_3040_liv_win',
            roomId: 'r_3bhk_3040_living',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_3040_kit_din',
        name: 'Kitchen & Dining',
        type: RoomType.kitchen,
        x: 16.0,
        y: 3.5,
        width: 12.0,
        length: 11.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_3040_kit_door',
            roomId: 'r_3bhk_3040_kit_din',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_3bhk_3040_kit_win',
            roomId: 'r_3bhk_3040_kit_din',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 2.5,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_3040_mbed',
        name: 'Master Bedroom',
        type: RoomType.masterBedroom,
        x: 2.0,
        y: 17.5,
        width: 13.0,
        length: 12.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_3040_mbed_door',
            roomId: 'r_3bhk_3040_mbed',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_3bhk_3040_mbed_win',
            roomId: 'r_3bhk_3040_mbed',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_3040_mbath',
        name: 'Master Bath',
        type: RoomType.bathroom,
        x: 2.0,
        y: 29.5,
        width: 6.0,
        length: 6.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_3040_mbath_door',
            roomId: 'r_3bhk_3040_mbath',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_3bhk_3040_mbath_vent',
            roomId: 'r_3bhk_3040_mbath',
            wallSide: PlanWallSide.west,
            type: OpeningType.ventilation,
            offsetFeet: 1.5,
            widthFeet: 2.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_3040_bed2',
        name: 'Bedroom 2',
        type: RoomType.bedroom,
        x: 15.0,
        y: 14.5,
        width: 13.0,
        length: 11.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_3040_bed2_door',
            roomId: 'r_3bhk_3040_bed2',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_3bhk_3040_bed2_win',
            roomId: 'r_3bhk_3040_bed2',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_3040_bed3',
        name: 'Bedroom 3 / Study',
        type: RoomType.bedroom,
        x: 15.0,
        y: 25.5,
        width: 13.0,
        length: 10.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_3040_bed3_door',
            roomId: 'r_3bhk_3040_bed3',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_3bhk_3040_bed3_win',
            roomId: 'r_3bhk_3040_bed3',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_3040_cbath',
        name: 'Common Bath',
        type: RoomType.bathroom,
        x: 8.0,
        y: 29.5,
        width: 6.0,
        length: 6.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_3040_cbath_door',
            roomId: 'r_3bhk_3040_cbath',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_3bhk_3040_cbath_vent',
            roomId: 'r_3bhk_3040_cbath',
            wallSide: PlanWallSide.south,
            type: OpeningType.ventilation,
            offsetFeet: 1.5,
            widthFeet: 2.0,
          ),
        ],
      ),
    ];
  }

  // 7. 3 BHK on 40x60 plot
  static List<PlanRoom> _build3BHK40x60Rooms() {
    return [
      PlanRoom(
        id: 'r_3bhk_4060_foyer',
        name: 'Grand Foyer',
        type: RoomType.foyer,
        x: 4.0,
        y: 8.0,
        width: 9.0,
        length: 8.0,
        colorValue: RoomType.foyer.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_4060_main_door',
            roomId: 'r_3bhk_4060_foyer',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 2.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_4060_living',
        name: 'Formal Living Hall',
        type: RoomType.living,
        x: 13.0,
        y: 8.0,
        width: 23.0,
        length: 18.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_4060_liv_win',
            roomId: 'r_3bhk_4060_living',
            wallSide: PlanWallSide.north,
            type: OpeningType.window,
            offsetFeet: 6.0,
            widthFeet: 6.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_4060_dining',
        name: 'Dining Hall',
        type: RoomType.dining,
        x: 4.0,
        y: 16.0,
        width: 13.0,
        length: 14.0,
        colorValue: RoomType.dining.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_4060_din_win',
            roomId: 'r_3bhk_4060_dining',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.5,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_4060_kitchen',
        name: 'Gourmet Kitchen',
        type: RoomType.kitchen,
        x: 4.0,
        y: 30.0,
        width: 13.0,
        length: 12.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_4060_kit_door',
            roomId: 'r_3bhk_4060_kitchen',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_3bhk_4060_kit_win',
            roomId: 'r_3bhk_4060_kitchen',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_4060_utility',
        name: 'Utility / Pantry',
        type: RoomType.utility,
        x: 4.0,
        y: 42.0,
        width: 7.0,
        length: 7.0,
        colorValue: RoomType.utility.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_4060_util_door',
            roomId: 'r_3bhk_4060_utility',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_4060_mbed',
        name: 'Master Suite',
        type: RoomType.masterBedroom,
        x: 17.0,
        y: 26.0,
        width: 19.0,
        length: 15.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_4060_mbed_door',
            roomId: 'r_3bhk_4060_mbed',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 3.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_3bhk_4060_mbed_win',
            roomId: 'r_3bhk_4060_mbed',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 5.0,
            widthFeet: 5.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_4060_mbath',
        name: 'Master Ensuite',
        type: RoomType.bathroom,
        x: 17.0,
        y: 41.0,
        width: 8.0,
        length: 8.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_4060_mbath_door',
            roomId: 'r_3bhk_4060_mbath',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_3bhk_4060_mbath_vent',
            roomId: 'r_3bhk_4060_mbath',
            wallSide: PlanWallSide.south,
            type: OpeningType.ventilation,
            offsetFeet: 2.0,
            widthFeet: 2.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_4060_bed2',
        name: 'Bedroom 2',
        type: RoomType.bedroom,
        x: 25.0,
        y: 41.0,
        width: 11.0,
        length: 13.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_4060_bed2_door',
            roomId: 'r_3bhk_4060_bed2',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_3bhk_4060_bed2_win',
            roomId: 'r_3bhk_4060_bed2',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_4060_cbath',
        name: 'Common Bath',
        type: RoomType.bathroom,
        x: 11.0,
        y: 42.0,
        width: 6.0,
        length: 7.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_4060_cbath_door',
            roomId: 'r_3bhk_4060_cbath',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_3bhk_4060_cbath_vent',
            roomId: 'r_3bhk_4060_cbath',
            wallSide: PlanWallSide.south,
            type: OpeningType.ventilation,
            offsetFeet: 1.5,
            widthFeet: 2.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_3bhk_4060_bed3',
        name: 'Bedroom 3 / Guest',
        type: RoomType.bedroom,
        x: 17.0,
        y: 49.0,
        width: 19.0,
        length: 6.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_3bhk_4060_bed3_door',
            roomId: 'r_3bhk_4060_bed3',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_3bhk_4060_bed3_win',
            roomId: 'r_3bhk_4060_bed3',
            wallSide: PlanWallSide.south,
            type: OpeningType.window,
            offsetFeet: 5.0,
            widthFeet: 5.0,
          ),
        ],
      ),
    ];
  }

  // 8. 4 BHK on 40x60 plot
  static List<PlanRoom> _build4BHK40x60Rooms() {
    return [
      PlanRoom(
        id: 'r_4bhk_4060_foyer',
        name: 'Grand Foyer',
        type: RoomType.foyer,
        x: 3.5,
        y: 6.0,
        width: 9.0,
        length: 8.0,
        colorValue: RoomType.foyer.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_main_door',
            roomId: 'r_4bhk_4060_foyer',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 2.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_living',
        name: 'Formal Living Hall',
        type: RoomType.living,
        x: 12.5,
        y: 6.0,
        width: 18.0,
        length: 16.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_liv_win',
            roomId: 'r_4bhk_4060_living',
            wallSide: PlanWallSide.north,
            type: OpeningType.window,
            offsetFeet: 5.0,
            widthFeet: 6.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_pooja',
        name: 'Pooja Room',
        type: RoomType.pooja,
        x: 30.5,
        y: 6.0,
        width: 6.0,
        length: 6.0,
        colorValue: RoomType.pooja.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_pooja_door',
            roomId: 'r_4bhk_4060_pooja',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_study',
        name: 'Home Office / Study',
        type: RoomType.study,
        x: 3.5,
        y: 14.0,
        width: 9.0,
        length: 10.0,
        colorValue: RoomType.study.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_study_door',
            roomId: 'r_4bhk_4060_study',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_4bhk_4060_study_win',
            roomId: 'r_4bhk_4060_study',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 2.5,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_dining',
        name: 'Family Dining',
        type: RoomType.dining,
        x: 12.5,
        y: 22.0,
        width: 13.0,
        length: 12.0,
        colorValue: RoomType.dining.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_din_win',
            roomId: 'r_4bhk_4060_dining',
            wallSide: PlanWallSide.south,
            type: OpeningType.window,
            offsetFeet: 3.5,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_kitchen',
        name: 'Kitchen & Pantry',
        type: RoomType.kitchen,
        x: 25.5,
        y: 12.0,
        width: 11.0,
        length: 16.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_kit_door',
            roomId: 'r_4bhk_4060_kitchen',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_4bhk_4060_kit_win',
            roomId: 'r_4bhk_4060_kitchen',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_utility',
        name: 'Utility Area',
        type: RoomType.utility,
        x: 25.5,
        y: 28.0,
        width: 11.0,
        length: 6.0,
        colorValue: RoomType.utility.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_util_door',
            roomId: 'r_4bhk_4060_utility',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_mbed',
        name: 'Master Suite 1',
        type: RoomType.masterBedroom,
        x: 3.5,
        y: 24.0,
        width: 14.0,
        length: 14.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_mbed_door',
            roomId: 'r_4bhk_4060_mbed',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_4bhk_4060_mbed_win',
            roomId: 'r_4bhk_4060_mbed',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_mbath',
        name: 'Master Ensuite 1',
        type: RoomType.bathroom,
        x: 3.5,
        y: 38.0,
        width: 7.5,
        length: 8.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_mbath_door',
            roomId: 'r_4bhk_4060_mbath',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_4bhk_4060_mbath_vent',
            roomId: 'r_4bhk_4060_mbath',
            wallSide: PlanWallSide.west,
            type: OpeningType.ventilation,
            offsetFeet: 2.0,
            widthFeet: 2.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_bed2',
        name: 'Bedroom 2',
        type: RoomType.bedroom,
        x: 17.5,
        y: 34.0,
        width: 13.0,
        length: 13.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_bed2_door',
            roomId: 'r_4bhk_4060_bed2',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_4bhk_4060_bed2_win',
            roomId: 'r_4bhk_4060_bed2',
            wallSide: PlanWallSide.south,
            type: OpeningType.window,
            offsetFeet: 3.5,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_att_bath2',
        name: 'Attached Bath 2',
        type: RoomType.bathroom,
        x: 11.0,
        y: 38.0,
        width: 6.5,
        length: 8.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_abath2_door',
            roomId: 'r_4bhk_4060_att_bath2',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 2.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_bed3',
        name: 'Bedroom 3',
        type: RoomType.bedroom,
        x: 3.5,
        y: 46.0,
        width: 14.0,
        length: 10.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_bed3_door',
            roomId: 'r_4bhk_4060_bed3',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_4bhk_4060_bed3_win',
            roomId: 'r_4bhk_4060_bed3',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.5,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_bed4',
        name: 'Bedroom 4 / Guest',
        type: RoomType.bedroom,
        x: 17.5,
        y: 47.0,
        width: 13.0,
        length: 9.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_bed4_door',
            roomId: 'r_4bhk_4060_bed4',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_4bhk_4060_bed4_win',
            roomId: 'r_4bhk_4060_bed4',
            wallSide: PlanWallSide.south,
            type: OpeningType.window,
            offsetFeet: 3.5,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_4bhk_4060_cbath',
        name: 'Common Bath',
        type: RoomType.bathroom,
        x: 30.5,
        y: 34.0,
        width: 6.0,
        length: 8.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_4bhk_4060_cbath_door',
            roomId: 'r_4bhk_4060_cbath',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_4bhk_4060_cbath_vent',
            roomId: 'r_4bhk_4060_cbath',
            wallSide: PlanWallSide.east,
            type: OpeningType.ventilation,
            offsetFeet: 2.0,
            widthFeet: 2.0,
          ),
        ],
      ),
    ];
  }
}
