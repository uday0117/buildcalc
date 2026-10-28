import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/plan/plan_3d_models.dart';
import '../../models/plan/plan_models.dart';
import '../../models/plan/plan_unit.dart';
import '../../services/plan_3d_builder.dart';
import '../../widgets/plan/material_selection_sheet.dart';
import '../../widgets/plan/plan_3d_interactive_canvas.dart';
import 'plan_elevation_screen.dart';

class Plan3DViewScreen extends StatefulWidget {
  final FloorPlan plan;

  const Plan3DViewScreen({super.key, required this.plan});

  @override
  State<Plan3DViewScreen> createState() => _Plan3DViewScreenState();
}

class _Plan3DViewScreenState extends State<Plan3DViewScreen> {
  late Camera3DState _camera;
  Scene3DMaterial _wallMaterial = Scene3DMaterial.plasterWhite;
  Scene3DMaterial _floorMaterial = Scene3DMaterial.oakHardwood;
  CutawayMode _cutawayMode = CutawayMode.full;
  bool _showRoomLabels = true;

  late Plan3DValidationResult _validation;
  late Mesh3D _mesh;
  bool _isWarningDismissed = false;

  @override
  void initState() {
    super.initState();
    _initScene();
  }

  void _initScene() {
    // Initial camera distance scaled by plot size
    final maxPlotDim = math.max(
      widget.plan.plotWidthFeet,
      widget.plan.plotLengthFeet,
    );
    final initialDistance = (maxPlotDim * 1.85).clamp(35.0, 180.0);

    _camera = Camera3DState(
      distance: initialDistance,
      projectionMode: ProjectionMode.perspective,
      cutawayMode: _cutawayMode,
    );

    _validateAndRebuildMesh();
  }

  void _validateAndRebuildMesh() {
    _validation = Plan3DBuilder.validatePlan(widget.plan);
    if (_validation.isValid) {
      _mesh = Plan3DBuilder.buildScene(
        plan: widget.plan,
        wallMaterial: _wallMaterial,
        floorMaterial: _floorMaterial,
        cutawayMode: _cutawayMode,
        showRoomLabels: _showRoomLabels,
        displayUnit: widget.plan.unit,
      );
    } else {
      _mesh = Mesh3D.empty();
    }
  }

  void _rebuildMesh() {
    setState(() {
      _validateAndRebuildMesh();
    });
  }

  void _resetCamera() {
    setState(() {
      final maxPlotDim = math.max(
        widget.plan.plotWidthFeet,
        widget.plan.plotLengthFeet,
      );
      _camera.distance = (maxPlotDim * 1.85).clamp(35.0, 180.0);
      _camera.reset();
    });
  }

  void _zoomIn() {
    setState(() {
      _camera.zoom(0.85);
    });
  }

  void _zoomOut() {
    setState(() {
      _camera.zoom(1.18);
    });
  }

  void _toggleProjectionMode() {
    setState(() {
      _camera.projectionMode =
          _camera.projectionMode == ProjectionMode.perspective
          ? ProjectionMode.isometric
          : ProjectionMode.perspective;
    });
  }

  void _openMaterialSheet() {
    MaterialSelectionSheet.show(
      context,
      activeWallMaterial: _wallMaterial,
      activeFloorMaterial: _floorMaterial,
      activeCutawayMode: _cutawayMode,
      showRoomLabels: _showRoomLabels,
      onWallMaterialChanged: (mat) {
        _wallMaterial = mat;
        _rebuildMesh();
      },
      onFloorMaterialChanged: (mat) {
        _floorMaterial = mat;
        _rebuildMesh();
      },
      onCutawayModeChanged: (mode) {
        _cutawayMode = mode;
        _camera.cutawayMode = mode;
        _rebuildMesh();
      },
      onToggleRoomLabels: (val) {
        _showRoomLabels = val;
        _rebuildMesh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = widget.plan;
    final unit = plan.unit;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Return to 2D Editor',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    plan.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '3D Scene',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${plan.rooms.length} Rooms • ${plan.allOpenings.length} Doors/Windows',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Projection Mode (Perspective / Isometric)
          IconButton(
            icon: Icon(
              _camera.projectionMode == ProjectionMode.perspective
                  ? Icons.view_in_ar_rounded
                  : Icons.grid_view_rounded,
            ),
            tooltip:
                'Switch to ${_camera.projectionMode == ProjectionMode.perspective ? 'Isometric' : 'Perspective'} Mode',
            onPressed: _toggleProjectionMode,
          ),
          // Materials & Colors
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Materials & Wall Colors',
            onPressed: _openMaterialSheet,
          ),
          // Front Elevation
          IconButton(
            icon: const Icon(Icons.villa_outlined, color: Color(0xFF0284C7)),
            tooltip: 'Front Elevation Generator',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanElevationScreen(plan: widget.plan),
                ),
              );
            },
          ),
          // Camera Reset
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset Camera View',
            onPressed: _resetCamera,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Warning Banner (e.g. room overlap or out-of-bounds)
            if (_validation.hasWarnings && !_isWarningDismissed)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validation.warnings.first,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          setState(() => _isWarningDismissed = true),
                    ),
                  ],
                ),
              ),

            // Main 3D Viewport
            Expanded(
              child: _validation.isValid
                  ? Stack(
                      children: [
                        // Interactive 3D Canvas
                        Plan3DInteractiveCanvas(
                          mesh: _mesh,
                          camera: _camera,
                          showLabels: _showRoomLabels,
                          onCameraChanged: () => setState(() {}),
                        ),

                        // View Presets Toolbar (Top-Right)
                        Positioned(
                          right: 14,
                          top: 14,
                          child: Column(
                            children: [
                              _buildFloatingActionButton(
                                icon: Icons.view_in_ar_rounded,
                                tooltip: 'Isometric SE',
                                onPressed: () {
                                  setState(() => _camera.presetIsometricSE());
                                },
                                isDark: isDark,
                              ),
                              const SizedBox(height: 6),
                              _buildFloatingActionButton(
                                icon: Icons.north_rounded,
                                tooltip: 'Front View (South)',
                                onPressed: () {
                                  setState(() => _camera.presetFrontSouth());
                                },
                                isDark: isDark,
                              ),
                              const SizedBox(height: 6),
                              _buildFloatingActionButton(
                                icon: Icons.east_rounded,
                                tooltip: 'Side View (East)',
                                onPressed: () {
                                  setState(() => _camera.presetRightEast());
                                },
                                isDark: isDark,
                              ),
                              const SizedBox(height: 6),
                              _buildFloatingActionButton(
                                icon: Icons.layers_outlined,
                                tooltip: 'Top-Down Plan View',
                                onPressed: () {
                                  setState(() => _camera.presetTopDown());
                                },
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),

                        // Floating Zoom Controls (Bottom-Right)
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Column(
                            children: [
                              _buildFloatingActionButton(
                                icon: Icons.add,
                                tooltip: 'Zoom In',
                                onPressed: _zoomIn,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 6),
                              _buildFloatingActionButton(
                                icon: Icons.remove,
                                tooltip: 'Zoom Out',
                                onPressed: _zoomOut,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 6),
                              _buildFloatingActionButton(
                                icon: Icons.center_focus_strong_rounded,
                                tooltip: 'Reset Camera',
                                onPressed: _resetCamera,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),

                        // Cutaway Mode Floating Quick Pill (Bottom-Left)
                        Positioned(
                          left: 14,
                          bottom: 14,
                          child: InkWell(
                            onTap: _openMaterialSheet,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white)
                                        .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.black12,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _cutawayMode.icon,
                                    size: 16,
                                    color: const Color(0xFFFF8C00),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _cutawayMode.label,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildInvalidLayoutState(isDark),
            ),

            // Bottom Navigation & Summary Bar
            _buildBottomBar(context, plan, unit, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInvalidLayoutState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.layers_clear_rounded,
                size: 48,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot Generate 3D Scene',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _validation.errors.isNotEmpty
                  ? _validation.errors.first
                  : 'Floor plan geometry is missing or unsupported for 3D reconstruction.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Return to 2D Editor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    FloorPlan plan,
    PlanUnit unit,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${unit.formatDimensions(plan.plotWidthFeet, plan.plotLengthFeet)} Plot',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Built-up: ${unit.formatArea(plan.totalBuiltUpAreaSqFt)} • 10 ft Ceiling',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.edit_road_rounded, size: 16),
            label: const Text(
              'Back to 2D Plan',
              style: TextStyle(fontSize: 12),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Material(
      color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(
        alpha: 0.9,
      ),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: const Color(0xFF1E3A5F)),
          ),
        ),
      ),
    );
  }
}
