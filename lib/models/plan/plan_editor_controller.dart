import 'package:flutter/foundation.dart';

import 'plan_geometry.dart';
import 'plan_models.dart';
import 'plan_unit.dart';

class PlanEditorController extends ChangeNotifier {
  FloorPlan _plan;
  final List<FloorPlan> _undoStack = [];
  final List<FloorPlan> _redoStack = [];

  String? _selectedRoomId;
  String? _selectedOpeningId;
  ResizeHandle _activeHandle = ResizeHandle.none;

  bool _showGrid = true;
  bool _snapToGrid = true;
  PlanUnit _activeUnit = PlanUnit.feet;

  PlanEditorController({required FloorPlan initialPlan}) : _plan = initialPlan {
    _activeUnit = initialPlan.unit;
    _snapToGrid = initialPlan.gridSnap;
  }

  // Getters
  FloorPlan get plan => _plan;
  String? get selectedRoomId => _selectedRoomId;
  String? get selectedOpeningId => _selectedOpeningId;
  ResizeHandle get activeHandle => _activeHandle;
  bool get showGrid => _showGrid;
  bool get snapToGrid => _snapToGrid;
  PlanUnit get activeUnit => _activeUnit;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  PlanRoom? get selectedRoom {
    if (_selectedRoomId == null) return null;
    return _plan.findRoom(_selectedRoomId!);
  }

  PlanOpening? get selectedOpening {
    if (_selectedOpeningId == null) return null;
    return _plan.findOpening(_selectedOpeningId!);
  }

  // ---------------- Undo & Redo ----------------
  void _recordHistory() {
    _undoStack.add(_plan);
    if (_undoStack.length > 40) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_plan);
    _plan = _undoStack.removeLast();
    // Validate selection exists in restored plan
    if (_selectedRoomId != null && _plan.findRoom(_selectedRoomId!) == null) {
      _selectedRoomId = null;
    }
    if (_selectedOpeningId != null && _plan.findOpening(_selectedOpeningId!) == null) {
      _selectedOpeningId = null;
    }
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(_plan);
    _plan = _redoStack.removeLast();
    if (_selectedRoomId != null && _plan.findRoom(_selectedRoomId!) == null) {
      _selectedRoomId = null;
    }
    if (_selectedOpeningId != null && _plan.findOpening(_selectedOpeningId!) == null) {
      _selectedOpeningId = null;
    }
    notifyListeners();
  }

  // ---------------- Selection ----------------
  void selectRoom(String? roomId) {
    if (_selectedRoomId != roomId || _selectedOpeningId != null) {
      _selectedRoomId = roomId;
      _selectedOpeningId = null;
      _activeHandle = ResizeHandle.none;
      notifyListeners();
    }
  }

  void selectOpening(String? openingId) {
    if (_selectedOpeningId != openingId) {
      _selectedOpeningId = openingId;
      if (openingId != null) {
        final op = _plan.findOpening(openingId);
        _selectedRoomId = op?.roomId;
      }
      _activeHandle = ResizeHandle.none;
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedRoomId != null || _selectedOpeningId != null) {
      _selectedRoomId = null;
      _selectedOpeningId = null;
      _activeHandle = ResizeHandle.none;
      notifyListeners();
    }
  }

  void setActiveHandle(ResizeHandle handle) {
    if (_activeHandle != handle) {
      _activeHandle = handle;
      notifyListeners();
    }
  }

  // ---------------- Settings & Units ----------------
  void toggleGrid() {
    _showGrid = !_showGrid;
    notifyListeners();
  }

  void toggleSnap() {
    _snapToGrid = !_snapToGrid;
    _plan = _plan.copyWith(gridSnap: _snapToGrid);
    notifyListeners();
  }

  void setUnit(PlanUnit unit) {
    _activeUnit = unit;
    _plan = _plan.copyWith(unit: unit);
    notifyListeners();
  }

  void setPlotDimensions(double widthFeet, double lengthFeet) {
    if (widthFeet <= 0 || lengthFeet <= 0) return;
    _recordHistory();
    _plan = _plan.copyWith(
      plotWidthFeet: widthFeet,
      plotLengthFeet: lengthFeet,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void setPlanName(String name) {
    if (name.trim().isEmpty) return;
    _plan = _plan.copyWith(name: name.trim(), updatedAt: DateTime.now());
    notifyListeners();
  }

  // ---------------- Room Operations ----------------
  void addRoom(PlanRoom room) {
    _recordHistory();
    final clamped = PlanGeometry.clampRoomToPlot(
      room,
      _plan.plotWidthFeet,
      _plan.plotLengthFeet,
    );

    final updatedRooms = List<PlanRoom>.from(_plan.rooms)..add(clamped);
    _plan = _plan.copyWith(rooms: updatedRooms, updatedAt: DateTime.now());
    _selectedRoomId = clamped.id;
    _selectedOpeningId = null;
    notifyListeners();
  }

  void updateRoom(PlanRoom updatedRoom) {
    _recordHistory();
    final clamped = PlanGeometry.clampRoomToPlot(
      updatedRoom,
      _plan.plotWidthFeet,
      _plan.plotLengthFeet,
    );

    final updatedRooms = _plan.rooms.map((r) {
      return r.id == clamped.id ? clamped : r;
    }).toList();

    _plan = _plan.copyWith(rooms: updatedRooms, updatedAt: DateTime.now());
    notifyListeners();
  }

  void moveRoom(String roomId, double dxFeet, double dyFeet) {
    final room = _plan.findRoom(roomId);
    if (room == null) return;

    _recordHistory();

    double newX = room.x + dxFeet;
    double newY = room.y + dyFeet;

    if (_snapToGrid) {
      newX = PlanGeometry.snap(newX, _plan.snapStepFeet);
      newY = PlanGeometry.snap(newY, _plan.snapStepFeet);
    }

    final moved = room.copyWith(x: newX, y: newY);
    final clamped = PlanGeometry.clampRoomToPlot(
      moved,
      _plan.plotWidthFeet,
      _plan.plotLengthFeet,
    );

    final updatedRooms = _plan.rooms.map((r) => r.id == roomId ? clamped : r).toList();
    _plan = _plan.copyWith(rooms: updatedRooms, updatedAt: DateTime.now());
    notifyListeners();
  }

  void resizeRoom(String roomId, ResizeHandle handle, double dxFeet, double dyFeet) {
    final room = _plan.findRoom(roomId);
    if (room == null || handle == ResizeHandle.none) return;

    _recordHistory();

    final resized = PlanGeometry.applyResize(
      room,
      handle,
      dxFeet,
      dyFeet,
      minDim: PlanGeometry.minRoomDimensionFeet,
    );

    double rx = resized.x;
    double ry = resized.y;
    double rw = resized.width;
    double rl = resized.length;

    if (_snapToGrid) {
      rx = PlanGeometry.snap(rx, _plan.snapStepFeet);
      ry = PlanGeometry.snap(ry, _plan.snapStepFeet);
      rw = PlanGeometry.snap(rw, _plan.snapStepFeet);
      rl = PlanGeometry.snap(rl, _plan.snapStepFeet);
    }

    final clamped = PlanGeometry.clampRoomToPlot(
      resized.copyWith(x: rx, y: ry, width: rw, length: rl),
      _plan.plotWidthFeet,
      _plan.plotLengthFeet,
    );

    final updatedRooms = _plan.rooms.map((r) => r.id == roomId ? clamped : r).toList();
    _plan = _plan.copyWith(rooms: updatedRooms, updatedAt: DateTime.now());
    notifyListeners();
  }

  void deleteRoom(String roomId) {
    _recordHistory();
    final updatedRooms = _plan.rooms.where((r) => r.id != roomId).toList();
    _plan = _plan.copyWith(rooms: updatedRooms, updatedAt: DateTime.now());
    if (_selectedRoomId == roomId) {
      _selectedRoomId = null;
      _selectedOpeningId = null;
    }
    notifyListeners();
  }

  // ---------------- Opening Operations ----------------
  void addOpening(String roomId, PlanOpening opening) {
    final room = _plan.findRoom(roomId);
    if (room == null) return;

    _recordHistory();
    final clamped = PlanGeometry.clampOpening(opening, room);
    final updatedOpenings = List<PlanOpening>.from(room.openings)..add(clamped);
    final updatedRoom = room.copyWith(openings: updatedOpenings);

    final updatedRooms = _plan.rooms.map((r) => r.id == roomId ? updatedRoom : r).toList();
    _plan = _plan.copyWith(rooms: updatedRooms, updatedAt: DateTime.now());
    _selectedOpeningId = clamped.id;
    _selectedRoomId = roomId;
    notifyListeners();
  }

  void updateOpening(PlanOpening updatedOpening) {
    final room = _plan.findRoom(updatedOpening.roomId);
    if (room == null) return;

    _recordHistory();
    final clamped = PlanGeometry.clampOpening(updatedOpening, room);
    final updatedOpenings = room.openings.map((o) {
      return o.id == clamped.id ? clamped : o;
    }).toList();
    final updatedRoom = room.copyWith(openings: updatedOpenings);

    final updatedRooms = _plan.rooms.map((r) => r.id == room.id ? updatedRoom : r).toList();
    _plan = _plan.copyWith(rooms: updatedRooms, updatedAt: DateTime.now());
    notifyListeners();
  }

  void deleteOpening(String openingId) {
    _recordHistory();
    final updatedRooms = _plan.rooms.map((room) {
      final filtered = room.openings.where((o) => o.id != openingId).toList();
      return room.copyWith(openings: filtered);
    }).toList();

    _plan = _plan.copyWith(rooms: updatedRooms, updatedAt: DateTime.now());
    if (_selectedOpeningId == openingId) {
      _selectedOpeningId = null;
    }
    notifyListeners();
  }

  void deleteSelected() {
    if (_selectedOpeningId != null) {
      deleteOpening(_selectedOpeningId!);
    } else if (_selectedRoomId != null) {
      deleteRoom(_selectedRoomId!);
    }
  }

  // ---------------- Load / Reset ----------------
  void loadPlan(FloorPlan newPlan) {
    _undoStack.clear();
    _redoStack.clear();
    _plan = newPlan;
    _activeUnit = newPlan.unit;
    _snapToGrid = newPlan.gridSnap;
    _selectedRoomId = null;
    _selectedOpeningId = null;
    _activeHandle = ResizeHandle.none;
    notifyListeners();
  }
}

