import 'package:flutter/material.dart';

import '../../models/plan/plan_editor_controller.dart';
import '../../models/plan/plan_geometry.dart';
import '../../models/plan/plan_models.dart';
import '../../models/plan/plan_unit.dart';
import 'plan_canvas_painter.dart';

class PlanInteractiveCanvas extends StatefulWidget {
  final PlanEditorController controller;
  final TransformationController transformationController;

  const PlanInteractiveCanvas({
    super.key,
    required this.controller,
    required this.transformationController,
  });

  @override
  State<PlanInteractiveCanvas> createState() => _PlanInteractiveCanvasState();
}

class _PlanInteractiveCanvasState extends State<PlanInteractiveCanvas> {
  // Fixed drawing scale: 12.0 screen pixels per foot
  static const double _canvasScale = 12.0;
  static const double _padding = 80.0;

  // Interaction drag states
  bool _isDraggingRoom = false;
  bool _isResizingHandle = false;
  ResizeHandle _activeHandle = ResizeHandle.none;
  Offset? _lastDragFeet;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  /// Convert screen local offset (relative to painter origin) to floor plan feet
  Offset _localToFeet(Offset localPosition) {
    final plotLocal = localPosition - const Offset(_padding, _padding);
    return Offset(plotLocal.dx / _canvasScale, plotLocal.dy / _canvasScale);
  }

  void _onPointerDown(PointerDownEvent event) {
    final feetPos = _localToFeet(event.localPosition);
    final plan = widget.controller.plan;
    final selectedRoom = widget.controller.selectedRoom;

    // 1. Check if user tapped a resize handle on the selected room
    if (selectedRoom != null) {
      final handle = PlanGeometry.hitTestHandle(feetPos, selectedRoom, radiusFeet: 1.5);
      if (handle != ResizeHandle.none) {
        setState(() {
          _isResizingHandle = true;
          _activeHandle = handle;
          _lastDragFeet = feetPos;
        });
        widget.controller.setActiveHandle(handle);
        return;
      }
    }

    // 2. Check if user tapped an opening (door / window)
    final tappedOpening = PlanGeometry.hitTestOpening(feetPos, plan.rooms, hitRadiusFeet: 1.2);
    if (tappedOpening != null) {
      widget.controller.selectOpening(tappedOpening.id);
      return;
    }

    // 3. Check if user tapped a room
    final tappedRoom = PlanGeometry.findRoomAtPoint(feetPos, plan.rooms);
    if (tappedRoom != null) {
      widget.controller.selectRoom(tappedRoom.id);
      setState(() {
        _isDraggingRoom = true;
        _lastDragFeet = feetPos;
      });
      return;
    }

    // 4. Tapped outside on background
    widget.controller.clearSelection();
  }

  void _onPointerMove(PointerMoveEvent event) {
    final feetPos = _localToFeet(event.localPosition);

    if (_isResizingHandle && _lastDragFeet != null && widget.controller.selectedRoomId != null) {
      final dx = feetPos.dx - _lastDragFeet!.dx;
      final dy = feetPos.dy - _lastDragFeet!.dy;

      if (dx.abs() > 0.05 || dy.abs() > 0.05) {
        widget.controller.resizeRoom(
          widget.controller.selectedRoomId!,
          _activeHandle,
          dx,
          dy,
        );
        _lastDragFeet = feetPos;
      }
      return;
    }

    if (_isDraggingRoom && _lastDragFeet != null && widget.controller.selectedRoomId != null) {
      final dx = feetPos.dx - _lastDragFeet!.dx;
      final dy = feetPos.dy - _lastDragFeet!.dy;

      if (dx.abs() > 0.1 || dy.abs() > 0.1) {
        widget.controller.moveRoom(widget.controller.selectedRoomId!, dx, dy);
        _lastDragFeet = feetPos;
      }
      return;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isResizingHandle || _isDraggingRoom) {
      setState(() {
        _isResizingHandle = false;
        _isDraggingRoom = false;
        _activeHandle = ResizeHandle.none;
        _lastDragFeet = null;
      });
      widget.controller.setActiveHandle(ResizeHandle.none);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _onPointerUp(const PointerUpEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = widget.controller.plan;

    final plotWidthPx = plan.plotWidthFeet * _canvasScale;
    final plotLengthPx = plan.plotLengthFeet * _canvasScale;

    final canvasWidth = plotWidthPx + _padding * 2;
    final canvasHeight = plotLengthPx + _padding * 2;

    final isInteractingWithRoom = _isDraggingRoom || _isResizingHandle;

    return Container(
      color: isDark ? const Color(0xFF090D16) : const Color(0xFFE2E8F0),
      child: InteractiveViewer(
        transformationController: widget.transformationController,
        boundaryMargin: const EdgeInsets.all(300),
        minScale: 0.25,
        maxScale: 3.5,
        panEnabled: !isInteractingWithRoom,
        scaleEnabled: !isInteractingWithRoom,
        child: Center(
          child: SizedBox(
            width: canvasWidth,
            height: canvasHeight,
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: CustomPaint(
                size: Size(canvasWidth, canvasHeight),
                painter: _PlanCanvasWrapper(
                  plan: plan,
                  selectedRoomId: widget.controller.selectedRoomId,
                  selectedOpeningId: widget.controller.selectedOpeningId,
                  activeHandle: _activeHandle,
                  showGrid: widget.controller.showGrid,
                  unit: widget.controller.activeUnit,
                  isDark: isDark,
                  scale: _canvasScale,
                  padding: _padding,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCanvasWrapper extends CustomPainter {
  final FloorPlan plan;
  final String? selectedRoomId;
  final String? selectedOpeningId;
  final ResizeHandle activeHandle;
  final bool showGrid;
  final PlanUnit unit;
  final bool isDark;
  final double scale;
  final double padding;

  _PlanCanvasWrapper({
    required this.plan,
    required this.selectedRoomId,
    required this.selectedOpeningId,
    required this.activeHandle,
    required this.showGrid,
    required this.unit,
    required this.isDark,
    required this.scale,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(padding, padding);

    final painter = PlanCanvasPainter(
      plan: plan,
      selectedRoomId: selectedRoomId,
      selectedOpeningId: selectedOpeningId,
      activeHandle: activeHandle,
      showGrid: showGrid,
      unit: unit,
      isDark: isDark,
      scale: scale,
    );
    painter.paint(canvas, size);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlanCanvasWrapper oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.selectedRoomId != selectedRoomId ||
        oldDelegate.selectedOpeningId != selectedOpeningId ||
        oldDelegate.activeHandle != activeHandle ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.unit != unit ||
        oldDelegate.isDark != isDark;
  }
}
