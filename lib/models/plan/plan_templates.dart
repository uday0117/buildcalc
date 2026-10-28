import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'plan_models.dart';
import 'plan_unit.dart';
import 'ready_made_template_models.dart';

export 'ready_made_template_models.dart';

class PlanTemplates {
  static const String layout1BHK = '1 BHK';
  static const String layout2BHK = '2 BHK';
  static const String layout3BHK = '3 BHK';
  static const String layout4BHK = '4 BHK';
  static const String layoutCustom = 'Custom';

  static const List<String> availableTemplates = [
    layout1BHK,
    layout2BHK,
    layout3BHK,
    layout4BHK,
    layoutCustom,
  ];

  /// Curated ready-made templates
  static List<ReadyMadePlanTemplate> get readyMadeTemplates =>
      ReadyMadePlanCatalog.templates;

  /// Get recommended default plot size (in feet) for template
  static Size getDefaultPlotSize(String layoutType) {
    switch (layoutType) {
      case layout1BHK:
        return const Size(30.0, 40.0);
      case layout2BHK:
        return const Size(36.0, 48.0);
      case layout3BHK:
        return const Size(42.0, 54.0);
      case layout4BHK:
        return const Size(50.0, 60.0);
      default:
        return const Size(35.0, 45.0);
    }
  }

  static int _idCounter = 0;

  /// Create a floor plan according to BHK template and plot size
  static FloorPlan createPlan({
    required String name,
    required String layoutType,
    required double plotWidthFeet,
    required double plotLengthFeet,
    PlanUnit unit = PlanUnit.feet,
  }) {
    final now = DateTime.now();
    final planId = 'plan_${now.microsecondsSinceEpoch}_${_idCounter++}';

    List<PlanRoom> rawRooms = [];

    switch (layoutType) {
      case layout1BHK:
        rawRooms = _build1BHKRooms();
        break;
      case layout2BHK:
        rawRooms = _build2BHKRooms();
        break;
      case layout3BHK:
        rawRooms = _build3BHKRooms();
        break;
      case layout4BHK:
        rawRooms = _build4BHKRooms();
        break;
      case layoutCustom:
      default:
        rawRooms = _buildCustomRooms();
        break;
    }

    // Adapt / center rooms neatly into the target plot dimensions
    final fittedRooms = _fitRoomsToPlot(
      rawRooms,
      plotWidthFeet,
      plotLengthFeet,
    );

    return FloorPlan(
      id: planId,
      name: name.trim().isEmpty ? '$layoutType Floor Plan' : name.trim(),
      plotWidthFeet: plotWidthFeet,
      plotLengthFeet: plotLengthFeet,
      unit: unit,
      layoutType: layoutType,
      rooms: fittedRooms,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ================= 1 BHK TEMPLATE =================
  static List<PlanRoom> _build1BHKRooms() {
    return [
      PlanRoom(
        id: 'r_living_1',
        name: 'Living Room',
        type: RoomType.living,
        x: 0,
        y: 0,
        width: 14.0,
        length: 15.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_entry_1',
            roomId: 'r_living_1',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 2.0,
            widthFeet: 4.0,
          ),
          PlanOpening(
            id: 'op_win_liv_1',
            roomId: 'r_living_1',
            wallSide: PlanWallSide.south,
            type: OpeningType.window,
            offsetFeet: 8.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_kitchen_1',
        name: 'Kitchen',
        type: RoomType.kitchen,
        x: 14.5,
        y: 0,
        width: 10.0,
        length: 10.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_kit_door_1',
            roomId: 'r_kitchen_1',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_kit_win_1',
            roomId: 'r_kitchen_1',
            wallSide: PlanWallSide.north,
            type: OpeningType.window,
            offsetFeet: 2.5,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_bath_1',
        name: 'Bathroom',
        type: RoomType.bathroom,
        x: 14.5,
        y: 10.5,
        width: 10.0,
        length: 6.5,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_bath_door_1',
            roomId: 'r_bath_1',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
          PlanOpening(
            id: 'op_bath_vent_1',
            roomId: 'r_bath_1',
            wallSide: PlanWallSide.east,
            type: OpeningType.ventilation,
            offsetFeet: 2.5,
            widthFeet: 2.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_bed_1',
        name: 'Master Bedroom',
        type: RoomType.masterBedroom,
        x: 0,
        y: 15.5,
        width: 14.0,
        length: 13.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_bed_door_1',
            roomId: 'r_bed_1',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_bed_win_1',
            roomId: 'r_bed_1',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_balcony_1',
        name: 'Balcony',
        type: RoomType.balcony,
        x: 14.5,
        y: 17.5,
        width: 10.0,
        length: 5.5,
        colorValue: RoomType.balcony.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_balc_door_1',
            roomId: 'r_balcony_1',
            wallSide: PlanWallSide.west,
            type: OpeningType.slidingDoor,
            offsetFeet: 1.0,
            widthFeet: 3.5,
          ),
        ],
      ),
    ];
  }

  // ================= 2 BHK TEMPLATE =================
  static List<PlanRoom> _build2BHKRooms() {
    return [
      PlanRoom(
        id: 'r_living_2',
        name: 'Living & Dining',
        type: RoomType.living,
        x: 0,
        y: 0,
        width: 17.0,
        length: 16.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_entry_2',
            roomId: 'r_living_2',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 2.5,
            widthFeet: 4.5,
          ),
          PlanOpening(
            id: 'op_liv_win_2',
            roomId: 'r_living_2',
            wallSide: PlanWallSide.south,
            type: OpeningType.window,
            offsetFeet: 9.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_kitchen_2',
        name: 'Kitchen',
        type: RoomType.kitchen,
        x: 17.5,
        y: 0,
        width: 11.0,
        length: 10.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_kit_door_2',
            roomId: 'r_kitchen_2',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_kit_win_2',
            roomId: 'r_kitchen_2',
            wallSide: PlanWallSide.north,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_utility_2',
        name: 'Utility Area',
        type: RoomType.utility,
        x: 17.5,
        y: 10.5,
        width: 11.0,
        length: 5.5,
        colorValue: RoomType.utility.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_util_door_2',
            roomId: 'r_utility_2',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_master_bed_2',
        name: 'Master Bedroom',
        type: RoomType.masterBedroom,
        x: 0,
        y: 16.5,
        width: 14.0,
        length: 14.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_mbed_door_2',
            roomId: 'r_master_bed_2',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_mbed_win_2',
            roomId: 'r_master_bed_2',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_att_bath_2',
        name: 'Attached Bath',
        type: RoomType.bathroom,
        x: 0,
        y: 31.0,
        width: 8.5,
        length: 6.5,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_mbath_door_2',
            roomId: 'r_att_bath_2',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_bed2_2',
        name: 'Bedroom 2',
        type: RoomType.bedroom,
        x: 14.5,
        y: 16.5,
        width: 14.0,
        length: 13.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_bed2_door_2',
            roomId: 'r_bed2_2',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_bed2_win_2',
            roomId: 'r_bed2_2',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_common_bath_2',
        name: 'Common Bath',
        type: RoomType.bathroom,
        x: 14.5,
        y: 30.0,
        width: 8.5,
        length: 6.5,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_cbath_door_2',
            roomId: 'r_common_bath_2',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
        ],
      ),
    ];
  }

  // ================= 3 BHK TEMPLATE =================
  static List<PlanRoom> _build3BHKRooms() {
    return [
      PlanRoom(
        id: 'r_foyer_3',
        name: 'Entrance Foyer',
        type: RoomType.foyer,
        x: 0,
        y: 0,
        width: 8.0,
        length: 6.0,
        colorValue: RoomType.foyer.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_main_door_3',
            roomId: 'r_foyer_3',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 1.5,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_living_3',
        name: 'Spacious Living Room',
        type: RoomType.living,
        x: 8.5,
        y: 0,
        width: 17.5,
        length: 16.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_liv_win_3',
            roomId: 'r_living_3',
            wallSide: PlanWallSide.north,
            type: OpeningType.window,
            offsetFeet: 5.0,
            widthFeet: 5.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_dining_3',
        name: 'Dining Area',
        type: RoomType.dining,
        x: 26.5,
        y: 0,
        width: 11.5,
        length: 12.0,
        colorValue: RoomType.dining.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_din_win_3',
            roomId: 'r_dining_3',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 2.5,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_kitchen_3',
        name: 'Modern Kitchen',
        type: RoomType.kitchen,
        x: 26.5,
        y: 12.5,
        width: 11.5,
        length: 11.5,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_kit_door_3',
            roomId: 'r_kitchen_3',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_kit_win_3',
            roomId: 'r_kitchen_3',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_mbed_3',
        name: 'Master Suite',
        type: RoomType.masterBedroom,
        x: 0,
        y: 6.5,
        width: 15.0,
        length: 15.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_mbed_door_3',
            roomId: 'r_mbed_3',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_mbed_win_3',
            roomId: 'r_mbed_3',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 5.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_mbath_3',
        name: 'Master Bath',
        type: RoomType.bathroom,
        x: 0,
        y: 22.0,
        width: 8.5,
        length: 7.5,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_mbath_door_3',
            roomId: 'r_mbath_3',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_bed2_3',
        name: 'Bedroom 2',
        type: RoomType.bedroom,
        x: 15.5,
        y: 16.5,
        width: 13.0,
        length: 14.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_bed2_door_3',
            roomId: 'r_bed2_3',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_bed2_win_3',
            roomId: 'r_bed2_3',
            wallSide: PlanWallSide.south,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_bed3_3',
        name: 'Bedroom 3 / Guest',
        type: RoomType.bedroom,
        x: 26.5,
        y: 24.5,
        width: 12.0,
        length: 13.5,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_bed3_door_3',
            roomId: 'r_bed3_3',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_bed3_win_3',
            roomId: 'r_bed3_3',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_cbath_3',
        name: 'Common Bath',
        type: RoomType.bathroom,
        x: 9.0,
        y: 22.0,
        width: 6.0,
        length: 7.5,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_cbath_door_3',
            roomId: 'r_cbath_3',
            wallSide: PlanWallSide.south,
            type: OpeningType.door,
            offsetFeet: 1.0,
            widthFeet: 2.5,
          ),
        ],
      ),
    ];
  }

  // ================= 4 BHK TEMPLATE =================
  static List<PlanRoom> _build4BHKRooms() {
    return [
      PlanRoom(
        id: 'r_foyer_4',
        name: 'Grand Foyer',
        type: RoomType.foyer,
        x: 0,
        y: 0,
        width: 10.0,
        length: 8.0,
        colorValue: RoomType.foyer.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_main_door_4',
            roomId: 'r_foyer_4',
            wallSide: PlanWallSide.south,
            type: OpeningType.doubleDoor,
            offsetFeet: 2.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_living_4',
        name: 'Formal Living Room',
        type: RoomType.living,
        x: 10.5,
        y: 0,
        width: 20.0,
        length: 18.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_liv_win_4',
            roomId: 'r_living_4',
            wallSide: PlanWallSide.north,
            type: OpeningType.window,
            offsetFeet: 6.0,
            widthFeet: 6.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_dining_4',
        name: 'Dining Hall',
        type: RoomType.dining,
        x: 31.0,
        y: 0,
        width: 14.0,
        length: 14.0,
        colorValue: RoomType.dining.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_din_win_4',
            roomId: 'r_dining_4',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 5.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_kitchen_4',
        name: 'Kitchen & Pantry',
        type: RoomType.kitchen,
        x: 31.0,
        y: 14.5,
        width: 14.0,
        length: 12.0,
        colorValue: RoomType.kitchen.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_kit_door_4',
            roomId: 'r_kitchen_4',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_kit_win_4',
            roomId: 'r_kitchen_4',
            wallSide: PlanWallSide.east,
            type: OpeningType.window,
            offsetFeet: 3.0,
            widthFeet: 4.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_study_4',
        name: 'Study / Office',
        type: RoomType.study,
        x: 0,
        y: 8.5,
        width: 10.0,
        length: 11.0,
        colorValue: RoomType.study.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_study_door_4',
            roomId: 'r_study_4',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_mbed_4',
        name: 'Master Suite',
        type: RoomType.masterBedroom,
        x: 0,
        y: 20.0,
        width: 16.0,
        length: 16.0,
        colorValue: RoomType.masterBedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_mbed_door_4',
            roomId: 'r_mbed_4',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 3.0,
            widthFeet: 3.0,
          ),
          PlanOpening(
            id: 'op_mbed_win_4',
            roomId: 'r_mbed_4',
            wallSide: PlanWallSide.west,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 6.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_mbath_4',
        name: 'Master Bath',
        type: RoomType.bathroom,
        x: 0,
        y: 36.5,
        width: 9.0,
        length: 8.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_mbath_door_4',
            roomId: 'r_mbath_4',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 2.5,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_bed2_4',
        name: 'Bedroom 2',
        type: RoomType.bedroom,
        x: 16.5,
        y: 18.5,
        width: 14.0,
        length: 14.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_bed2_door_4',
            roomId: 'r_bed2_4',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_bed3_4',
        name: 'Bedroom 3',
        type: RoomType.bedroom,
        x: 31.0,
        y: 27.0,
        width: 14.0,
        length: 13.5,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_bed3_door_4',
            roomId: 'r_bed3_4',
            wallSide: PlanWallSide.west,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_bed4_4',
        name: 'Bedroom 4',
        type: RoomType.bedroom,
        x: 16.5,
        y: 33.0,
        width: 14.0,
        length: 13.0,
        colorValue: RoomType.bedroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_bed4_door_4',
            roomId: 'r_bed4_4',
            wallSide: PlanWallSide.north,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.0,
          ),
        ],
      ),
      PlanRoom(
        id: 'r_cbath_4',
        name: 'Common Bath',
        type: RoomType.bathroom,
        x: 9.5,
        y: 36.5,
        width: 6.5,
        length: 8.0,
        colorValue: RoomType.bathroom.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_cbath_door_4',
            roomId: 'r_cbath_4',
            wallSide: PlanWallSide.east,
            type: OpeningType.door,
            offsetFeet: 1.5,
            widthFeet: 2.5,
          ),
        ],
      ),
    ];
  }

  // ================= CUSTOM DEFAULT ROOMS =================
  static List<PlanRoom> _buildCustomRooms() {
    return [
      PlanRoom(
        id: 'r_custom_main',
        name: 'Living Space',
        type: RoomType.living,
        x: 0,
        y: 0,
        width: 16.0,
        length: 16.0,
        colorValue: RoomType.living.defaultColor.toARGB32(),
        openings: const [
          PlanOpening(
            id: 'op_custom_entry',
            roomId: 'r_custom_main',
            wallSide: PlanWallSide.south,
            type: OpeningType.door,
            offsetFeet: 2.0,
            widthFeet: 3.5,
          ),
          PlanOpening(
            id: 'op_custom_win',
            roomId: 'r_custom_main',
            wallSide: PlanWallSide.north,
            type: OpeningType.window,
            offsetFeet: 4.0,
            widthFeet: 4.5,
          ),
        ],
      ),
    ];
  }

  /// Center and fit rooms within the user's defined plot dimensions
  static List<PlanRoom> _fitRoomsToPlot(
    List<PlanRoom> rooms,
    double plotWidth,
    double plotLength,
  ) {
    if (rooms.isEmpty) return rooms;

    // Calculate current bounding box of the layout
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final r in rooms) {
      minX = math.min(minX, r.x);
      minY = math.min(minY, r.y);
      maxX = math.max(maxX, r.x + r.width);
      maxY = math.max(maxY, r.y + r.length);
    }

    final layoutW = maxX - minX;
    final layoutL = maxY - minY;

    // Determine scale if layout is larger than target plot with 2ft setback buffer
    final availW = math.max(10.0, plotWidth - 4.0);
    final availL = math.max(10.0, plotLength - 4.0);

    double scale = 1.0;
    if (layoutW > availW || layoutL > availL) {
      scale = math.min(availW / layoutW, availL / layoutL);
    }

    final scaledLayoutW = layoutW * scale;
    final scaledLayoutL = layoutL * scale;

    // Center layout in plot
    final offsetX = math.max(2.0, (plotWidth - scaledLayoutW) / 2.0);
    final offsetY = math.max(2.0, (plotLength - scaledLayoutL) / 2.0);

    return rooms.map((r) {
      final relX = r.x - minX;
      final relY = r.y - minY;
      final newX = (offsetX + relX * scale);
      final newY = (offsetY + relY * scale);
      final newW = math.max(3.0, r.width * scale);
      final newL = math.max(3.0, r.length * scale);

      // Scale openings proportionally
      final scaledOpenings = r.openings.map((op) {
        final wallLen = op.wallSide.isHorizontal ? newW : newL;
        final maxOpW = math.max<double>(1.5, wallLen - 0.4);
        final opW = math.min<double>(op.widthFeet * scale, maxOpW);
        final opOffset = (op.offsetFeet * scale)
            .clamp(0.0, math.max<double>(0.0, wallLen - opW))
            .toDouble();
        return op.copyWith(offsetFeet: opOffset, widthFeet: opW);
      }).toList();

      return r.copyWith(
        x: double.parse(newX.toStringAsFixed(1)),
        y: double.parse(newY.toStringAsFixed(1)),
        width: double.parse(newW.toStringAsFixed(1)),
        length: double.parse(newL.toStringAsFixed(1)),
        openings: scaledOpenings,
      );
    }).toList();
  }
}
