import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../models/plan/plan_3d_models.dart';
import 'scene_3d_painter.dart';

class Plan3DInteractiveCanvas extends StatefulWidget {
  final Mesh3D mesh;
  final Camera3DState camera;
  final bool showLabels;
  final VoidCallback onCameraChanged;

  const Plan3DInteractiveCanvas({
    super.key,
    required this.mesh,
    required this.camera,
    this.showLabels = true,
    required this.onCameraChanged,
  });

  @override
  State<Plan3DInteractiveCanvas> createState() =>
      _Plan3DInteractiveCanvasState();
}

class _Plan3DInteractiveCanvasState extends State<Plan3DInteractiveCanvas> {
  // Gesture tracking
  Offset? _lastPanFocalPoint;
  double _lastScale = 1.0;

  void _onScaleStart(ScaleStartDetails details) {
    _lastPanFocalPoint = details.focalPoint;
    _lastScale = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_lastPanFocalPoint == null) return;

    final focalDelta = details.focalPoint - _lastPanFocalPoint!;
    _lastPanFocalPoint = details.focalPoint;

    bool changed = false;

    // Zoom Pinch
    if (details.scale != 1.0 && (_lastScale - details.scale).abs() > 0.005) {
      final zoomFactor = _lastScale / details.scale;
      widget.camera.zoom(zoomFactor);
      _lastScale = details.scale;
      changed = true;
    }

    // Two-finger drag => Pan, Single-finger drag => Orbit Rotation
    if (details.pointerCount >= 2) {
      widget.camera.panBy(focalDelta);
      changed = true;
    } else if (details.pointerCount == 1 && details.scale == 1.0) {
      const rotateSensitivity = 0.0075;
      final deltaAzimuth = -focalDelta.dx * rotateSensitivity;
      final deltaElevation = focalDelta.dy * rotateSensitivity;
      widget.camera.rotate(deltaAzimuth, deltaElevation);
      changed = true;
    }

    if (changed) {
      widget.onCameraChanged();
      setState(() {});
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastPanFocalPoint = null;
    _lastScale = 1.0;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final zoomDelta = event.scrollDelta.dy > 0 ? 1.08 : 0.92;
      widget.camera.zoom(zoomDelta);
      widget.onCameraChanged();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Canvas
            CustomPaint(
              painter: Scene3DPainter(
                mesh: widget.mesh,
                camera: widget.camera,
                showLabels: widget.showLabels,
              ),
              size: Size.infinite,
            ),

            // Top-Left 3D Orientation Compass
            Positioned(left: 14, top: 14, child: _buildCompassWidget(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassWidget(bool isDark) {
    final azimuthDeg = ((widget.camera.azimuth * 180 / math.pi) % 360).round();
    final elevationDeg = (widget.camera.elevation * 180 / math.pi).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(
          alpha: 0.88,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: -widget.camera.azimuth,
            child: const Icon(
              Icons.navigation_rounded,
              size: 16,
              color: Color(0xFFFF8C00),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Rot $azimuthDeg° • Tilt $elevationDeg°',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF1E3A5F),
            ),
          ),
        ],
      ),
    );
  }
}
