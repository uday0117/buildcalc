import 'package:flutter/material.dart';

import '../../models/plan/plan_editor_controller.dart';
import '../../models/plan/plan_models.dart';
import '../../models/plan/plan_templates.dart';
import '../../models/plan/plan_unit.dart';
import '../../services/plan_storage_service.dart';
import '../../widgets/plan/opening_edit_dialog.dart';
import '../../widgets/plan/plan_export_dialog.dart';
import '../../widgets/plan/plan_interactive_canvas.dart';
import '../../widgets/plan/plan_summary_bar.dart';
import '../../widgets/plan/plot_setup_dialog.dart';
import '../../widgets/plan/room_edit_dialog.dart';
import '../../widgets/plan/room_list_sheet.dart';
import 'plan_3d_view_screen.dart';
import 'plan_elevation_screen.dart';
import 'plan_material_estimate_screen.dart';
import 'plan_templates_screen.dart';
import 'saved_plans_screen.dart';

class PlanEditorScreen extends StatefulWidget {
  final FloorPlan? initialPlan;

  const PlanEditorScreen({super.key, this.initialPlan});

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  late PlanEditorController _controller;
  final TransformationController _transformationController =
      TransformationController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final plan =
        widget.initialPlan ??
        PlanTemplates.createPlan(
          name: '2 BHK House Plan',
          layoutType: PlanTemplates.layout2BHK,
          plotWidthFeet: 36.0,
          plotLengthFeet: 48.0,
          unit: PlanUnit.feet,
        );

    _controller = PlanEditorController(initialPlan: plan);
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _zoomIn() {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    if (currentScale < 3.0) {
      _transformationController.value = currentMatrix.clone()
        ..scaleByDouble(1.25, 1.25, 1.0, 1.0);
    }
  }

  void _zoomOut() {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    if (currentScale > 0.3) {
      _transformationController.value = currentMatrix.clone()
        ..scaleByDouble(0.8, 0.8, 1.0, 1.0);
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Future<void> _savePlan() async {
    setState(() => _isSaving = true);
    await PlanStorageService.savePlan(_controller.plan);
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Floor plan "${_controller.plan.name}" saved successfully!',
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Saved Plans',
          textColor: const Color(0xFFFF8C00),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedPlansScreen()),
            );
          },
        ),
      ),
    );
  }

  void _exportPlanSummary() {
    PlanExportDialog.show(
      context,
      plan: _controller.plan,
      activeUnit: _controller.activeUnit,
    );
  }

  void _open3DView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Plan3DViewScreen(plan: _controller.plan),
      ),
    );
  }

  void _openElevation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanElevationScreen(plan: _controller.plan),
      ),
    );
  }

  void _openMaterialEstimate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanMaterialEstimateScreen(
          plan: _controller.plan,
          initialUnit: _controller.activeUnit,
        ),
      ),
    );
  }

  Future<void> _openTemplatesPicker() async {
    final selectedPlan = await Navigator.push<FloorPlan>(
      context,
      MaterialPageRoute(
        builder: (_) => const PlanTemplatesScreen(selectOnly: true),
      ),
    );
    if (!mounted || selectedPlan == null) return;
    _controller.loadPlan(selectedPlan);
    _resetZoom();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded template "${selectedPlan.name}"')),
    );
  }

  Future<void> _openPlotSetup() async {
    final updatedPlan = await showDialog<FloorPlan>(
      context: context,
      builder: (ctx) => PlotSetupDialog(currentPlan: _controller.plan),
    );
    if (updatedPlan != null) {
      _controller.loadPlan(updatedPlan);
      _resetZoom();
    }
  }

  Future<void> _addNewRoom() async {
    final newRoom = await showDialog<PlanRoom>(
      context: context,
      builder: (ctx) => RoomEditDialog(
        unit: _controller.activeUnit,
        maxPlotWidthFeet: _controller.plan.plotWidthFeet,
        maxPlotLengthFeet: _controller.plan.plotLengthFeet,
      ),
    );
    if (newRoom != null) {
      _controller.addRoom(newRoom);
    }
  }

  Future<void> _editSelectedRoom() async {
    final room = _controller.selectedRoom;
    if (room == null) return;

    final updated = await showDialog<PlanRoom>(
      context: context,
      builder: (ctx) => RoomEditDialog(
        initialRoom: room,
        unit: _controller.activeUnit,
        maxPlotWidthFeet: _controller.plan.plotWidthFeet,
        maxPlotLengthFeet: _controller.plan.plotLengthFeet,
      ),
    );
    if (updated != null) {
      _controller.updateRoom(updated);
    }
  }

  Future<void> _addOpeningToSelectedRoom() async {
    final room = _controller.selectedRoom;
    if (room == null) return;

    final opening = await showDialog<PlanOpening>(
      context: context,
      builder: (ctx) =>
          OpeningEditDialog(room: room, unit: _controller.activeUnit),
    );
    if (opening != null) {
      _controller.addOpening(room.id, opening);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = _controller.plan;
    final unit = _controller.activeUnit;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _openPlotSetup,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    plan.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
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
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plan.layoutType,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
        actions: [
          // Materials Estimate
          IconButton(
            icon: const Icon(
              Icons.calculate_outlined,
              color: Color(0xFF059669),
            ),
            tooltip: 'Material & Cost Estimate',
            onPressed: _openMaterialEstimate,
          ),
          // 3D View
          IconButton(
            icon: const Icon(
              Icons.view_in_ar_rounded,
              color: Color(0xFFFF8C00),
            ),
            tooltip: '3D House View',
            onPressed: _open3DView,
          ),
          // Front Elevation
          IconButton(
            icon: const Icon(Icons.villa_outlined, color: Color(0xFF0284C7)),
            tooltip: 'Front Elevation Generator',
            onPressed: _openElevation,
          ),
          // Undo
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Undo',
            onPressed: _controller.canUndo ? () => _controller.undo() : null,
          ),
          // Redo
          IconButton(
            icon: const Icon(Icons.redo_rounded),
            tooltip: 'Redo',
            onPressed: _controller.canRedo ? () => _controller.redo() : null,
          ),
          // Unit & Settings Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              switch (value) {
                case 'materials':
                  _openMaterialEstimate();
                  break;
                case '3d_view':
                  _open3DView();
                  break;
                case 'elevation':
                  _openElevation();
                  break;
                case 'templates':
                  _openTemplatesPicker();
                  break;
                case 'save':
                  _savePlan();
                  break;
                case 'export':
                  _exportPlanSummary();
                  break;
                case 'saved_plans':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedPlansScreen()),
                  );
                  break;
                case 'toggle_grid':
                  _controller.toggleGrid();
                  break;
                case 'toggle_snap':
                  _controller.toggleSnap();
                  break;
                case 'unit_ft':
                  _controller.setUnit(PlanUnit.feet);
                  break;
                case 'unit_m':
                  _controller.setUnit(PlanUnit.meters);
                  break;
                case 'unit_in':
                  _controller.setUnit(PlanUnit.inches);
                  break;
                case 'unit_yd':
                  _controller.setUnit(PlanUnit.yards);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'materials',
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 20,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 10),
                    Text('Automatic Material Estimate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: '3d_view',
                child: Row(
                  children: [
                    Icon(
                      Icons.view_in_ar_rounded,
                      size: 20,
                      color: Color(0xFFFF8C00),
                    ),
                    SizedBox(width: 10),
                    Text('3D House View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'elevation',
                child: Row(
                  children: [
                    Icon(
                      Icons.villa_outlined,
                      size: 20,
                      color: Color(0xFF0284C7),
                    ),
                    SizedBox(width: 10),
                    Text('Front Elevation Generator'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'templates',
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_mosaic_rounded,
                      size: 20,
                      color: Color(0xFFFF8C00),
                    ),
                    SizedBox(width: 10),
                    Text('Browse Ready-Made Templates'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(
                      Icons.save_rounded,
                      size: 20,
                      color: Color(0xFFFF8C00),
                    ),
                    SizedBox(width: 10),
                    Text('Save Plan Locally'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'saved_plans',
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 20,
                      color: Color(0xFF1E3A5F),
                    ),
                    SizedBox(width: 10),
                    Text('Open Saved Plans'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Share / Export Summary'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                value: 'toggle_grid',
                checked: _controller.showGrid,
                child: const Text('Show Grid'),
              ),
              CheckedPopupMenuItem(
                value: 'toggle_snap',
                checked: _controller.snapToGrid,
                child: const Text('Snap to Grid (0.5 ft)'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                enabled: false,
                child: Text(
                  'UNITS (${unit.symbol.toUpperCase()})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CheckedPopupMenuItem(
                value: 'unit_ft',
                checked: unit == PlanUnit.feet,
                child: const Text('Feet (ft)'),
              ),
              CheckedPopupMenuItem(
                value: 'unit_m',
                checked: unit == PlanUnit.meters,
                child: const Text('Meters (m)'),
              ),
              CheckedPopupMenuItem(
                value: 'unit_in',
                checked: unit == PlanUnit.inches,
                child: const Text('Inches (in)'),
              ),
              CheckedPopupMenuItem(
                value: 'unit_yd',
                checked: unit == PlanUnit.yards,
                child: const Text('Yards (yd)'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Bar
            PlanSummaryBar(
              plan: plan,
              unit: unit,
              onEstimateMaterials: _openMaterialEstimate,
            ),

            // Canvas & Floating Controls
            Expanded(
              child: Stack(
                children: [
                  PlanInteractiveCanvas(
                    controller: _controller,
                    transformationController: _transformationController,
                  ),

                  // Floating Zoom Controls (Top-Right)
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Column(
                      children: [
                        _buildFloatingCircleButton(
                          icon: Icons.add,
                          tooltip: 'Zoom In',
                          onPressed: _zoomIn,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildFloatingCircleButton(
                          icon: Icons.remove,
                          tooltip: 'Zoom Out',
                          onPressed: _zoomOut,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildFloatingCircleButton(
                          icon: Icons.filter_center_focus_rounded,
                          tooltip: 'Fit to View',
                          onPressed: _resetZoom,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  // Floating Fast-Save Button (Bottom-Right)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FloatingActionButton.small(
                      heroTag: 'plan_quick_save',
                      onPressed: _isSaving ? null : _savePlan,
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      tooltip: 'Save Floor Plan',
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Contextual Toolbar
            _buildBottomToolbar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: const Color(0xFF1E3A5F)),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomToolbar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedRoom = _controller.selectedRoom;
    final selectedOpening = _controller.selectedOpening;
    final unit = _controller.activeUnit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selectedOpening != null
            ? _buildOpeningToolbar(context, selectedOpening, unit)
            : selectedRoom != null
            ? _buildRoomToolbar(context, selectedRoom, unit)
            : _buildGeneralToolbar(context),
      ),
    );
  }

  Widget _buildGeneralToolbar(BuildContext context) {
    return Row(
      key: const ValueKey('general_toolbar'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildToolbarAction(
          icon: Icons.add_box_rounded,
          label: 'Add Room',
          onTap: _addNewRoom,
          color: const Color(0xFFFF8C00),
        ),
        _buildToolbarAction(
          icon: Icons.view_quilt_rounded,
          label: 'Templates',
          onTap: _openPlotSetup,
          color: const Color(0xFF1E3A5F),
        ),
        _buildToolbarAction(
          icon: Icons.meeting_room_outlined,
          label: 'Room List (${_controller.plan.rooms.length})',
          onTap: () => RoomListSheet.show(context, _controller),
          color: const Color(0xFF0288D1),
        ),
        _buildToolbarAction(
          icon: Icons.view_in_ar_rounded,
          label: '3D View',
          onTap: _open3DView,
          color: const Color(0xFF0D9488),
        ),
      ],
    );
  }

  Widget _buildRoomToolbar(BuildContext context, PlanRoom room, PlanUnit unit) {
    return Row(
      key: ValueKey('room_toolbar_${room.id}'),
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                room.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${unit.formatDimensions(room.width, room.length)} • ${unit.formatArea(room.areaSqFt)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.sensor_door_outlined, size: 18),
          tooltip: 'Add Door or Window',
          onPressed: _addOpeningToSelectedRoom,
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Edit Dimensions & Color',
          onPressed: _editSelectedRoom,
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: Colors.red,
          ),
          tooltip: 'Delete Room',
          onPressed: () => _controller.deleteRoom(room.id),
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          tooltip: 'Deselect',
          onPressed: () => _controller.clearSelection(),
        ),
      ],
    );
  }

  Widget _buildOpeningToolbar(
    BuildContext context,
    PlanOpening op,
    PlanUnit unit,
  ) {
    return Row(
      key: ValueKey('op_toolbar_${op.id}'),
      children: [
        Icon(op.type.icon, color: const Color(0xFFFF8C00)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${op.type.label} (${op.wallSide.name})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Width: ${unit.formatLength(op.widthFeet)} • Offset: ${unit.formatLength(op.offsetFeet)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (op.type.isDoor)
          IconButton.filledTonal(
            icon: const Icon(Icons.flip_rounded, size: 18),
            tooltip: 'Flip Inward / Outward',
            onPressed: () {
              _controller.updateOpening(
                op.copyWith(swingInward: !op.swingInward),
              );
            },
          ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: Colors.red,
          ),
          tooltip: 'Delete Opening',
          onPressed: () => _controller.deleteOpening(op.id),
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          tooltip: 'Deselect',
          onPressed: () => _controller.clearSelection(),
        ),
      ],
    );
  }

  Widget _buildToolbarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
