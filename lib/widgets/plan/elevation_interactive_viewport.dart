import 'package:flutter/material.dart';

import '../../models/plan/elevation_models.dart';
import 'elevation_canvas_painter.dart';

class ElevationInteractiveViewport extends StatefulWidget {
  final ElevationConfig config;
  final ElevationViewMode mode;
  final ValueChanged<ElevationViewMode>? onModeChanged;

  const ElevationInteractiveViewport({
    super.key,
    required this.config,
    this.mode = ElevationViewMode.illustrative,
    this.onModeChanged,
  });

  @override
  State<ElevationInteractiveViewport> createState() =>
      _ElevationInteractiveViewportState();
}

class _ElevationInteractiveViewportState
    extends State<ElevationInteractiveViewport> {
  final TransformationController _transformationController =
      TransformationController();

  void _zoomIn() {
    final matrix = _transformationController.value;
    if (matrix.getMaxScaleOnAxis() < 4.0) {
      _transformationController.value = matrix.clone()
        ..scaleByDouble(1.25, 1.25, 1.0, 1.0);
    }
  }

  void _zoomOut() {
    final matrix = _transformationController.value;
    if (matrix.getMaxScaleOnAxis() > 0.4) {
      _transformationController.value = matrix.clone()
        ..scaleByDouble(0.8, 0.8, 1.0, 1.0);
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Interactive Canvas
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: ElevationCanvasPainter(
                  config: widget.config,
                  mode: widget.mode,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),

        // Mode Switcher Pill (Top Center)
        Positioned(
          top: 14,
          left: 14,
          right: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      mode: ElevationViewMode.illustrative,
                      label: 'Illustrative Concept',
                      icon: Icons.palette_outlined,
                      isSelected: widget.mode == ElevationViewMode.illustrative,
                    ),
                    const SizedBox(width: 4),
                    _buildModeButton(
                      mode: ElevationViewMode.dimensioned,
                      label: 'CAD Elevation Draft',
                      icon: Icons.straighten_rounded,
                      isSelected: widget.mode == ElevationViewMode.dimensioned,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Floating Zoom / Reset buttons (Bottom Right)
        Positioned(
          right: 14,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFloatingBtn(
                icon: Icons.add,
                tooltip: 'Zoom In',
                onPressed: _zoomIn,
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildFloatingBtn(
                icon: Icons.remove,
                tooltip: 'Zoom Out',
                onPressed: _zoomOut,
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildFloatingBtn(
                icon: Icons.restart_alt_rounded,
                tooltip: 'Reset View',
                onPressed: _resetZoom,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required ElevationViewMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected ? const Color(0xFFFF8C00) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => widget.onModeChanged?.call(mode),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: const Color(0xFFFF8C00)),
        ),
      ),
    );
  }
}
