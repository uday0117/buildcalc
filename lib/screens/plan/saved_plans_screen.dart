import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/plan/plan_models.dart';
import '../../services/plan_backup_service.dart';
import '../../services/plan_storage_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/plan/plan_export_dialog.dart';
import '../../widgets/plan/plot_setup_dialog.dart';
import 'plan_3d_view_screen.dart';
import 'plan_editor_screen.dart';
import 'plan_elevation_screen.dart';
import 'plan_material_estimate_screen.dart';
import 'plan_templates_screen.dart';

class SavedPlansScreen extends StatefulWidget {
  const SavedPlansScreen({super.key});

  @override
  State<SavedPlansScreen> createState() => _SavedPlansScreenState();
}

class _SavedPlansScreenState extends State<SavedPlansScreen> {
  List<FloorPlan> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await PlanStorageService.getSavedPlans();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _isLoading = false;
    });
  }

  Future<void> _createNewPlan() async {
    final newPlan = await showDialog<FloorPlan>(
      context: context,
      builder: (ctx) => const PlotSetupDialog(),
    );
    if (newPlan != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlanEditorScreen(initialPlan: newPlan),
        ),
      );
      _loadPlans();
    }
  }

  Future<void> _duplicatePlan(String planId) async {
    await PlanStorageService.duplicatePlan(planId);
    _loadPlans();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan duplicated successfully!')),
    );
  }

  Future<void> _deletePlan(FloorPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Floor Plan'),
        content: Text(
          'Are you sure you want to delete "${plan.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PlanStorageService.deletePlan(plan.id);
      _loadPlans();
    }
  }

  Future<void> _backupAllPlans() async {
    try {
      final res = await PlanBackupService.shareBackupFile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.isSuccess ? const Color(0xFF059669) : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreBackup() async {
    final textController = TextEditingController();
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Plans from Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the JSON content from your exported BuildCalc backup file below. Existing plans with different IDs will be preserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON here...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore Plans'),
          ),
        ],
      ),
    );

    if (shouldRestore == true && textController.text.trim().isNotEmpty) {
      try {
        final count = await PlanBackupService.restoreBackupFromJson(
          textController.text.trim(),
          mergeWithExisting: true,
        );
        _loadPlans();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully restored $count plan(s) from backup!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCloudBackupStatusDialog() {
    final status = PlanBackupService.getCloudBackupStatus();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.cloud_done_rounded,
          color: Color(0xFF0284C7),
          size: 36,
        ),
        title: const Text('Local Offline Storage & Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '100% Offline Accessible',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              '• All floor plans, rooms, and calculations are saved completely offline in your device\'s local storage.\n\n'
              '• You can create and share complete JSON backups anytime without needing an internet connection.\n\n'
              '• No unapproved paid cloud subscriptions or mandatory sign-in required.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.statusDescription,
                style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1)),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Floor Plans'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.auto_awesome_mosaic_rounded,
              color: Color(0xFFFF8C00),
            ),
            tooltip: 'Ready-Made Templates',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlanTemplatesScreen()),
              );
              _loadPlans();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Plan',
            onPressed: _createNewPlan,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Backup & Storage',
            onSelected: (val) {
              switch (val) {
                case 'backup':
                  _backupAllPlans();
                  break;
                case 'restore':
                  _restoreBackup();
                  break;
                case 'status':
                  _showCloudBackupStatusDialog();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(
                      Icons.backup_rounded,
                      size: 20,
                      color: Color(0xFF1E3A5F),
                    ),
                    SizedBox(width: 10),
                    Text('Backup All Plans (JSON)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_backup_restore_rounded,
                      size: 20,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 10),
                    Text('Restore from Backup'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      size: 20,
                      color: Color(0xFF0284C7),
                    ),
                    SizedBox(width: 10),
                    Text('Offline / Cloud Status'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmptyStateView(
                      icon: Icons.architecture_rounded,
                      title: 'No saved floor plans yet',
                      message:
                          'Create editable 2D plans for 1 BHK, 2 BHK, 3 BHK, or 4 BHK homes with rooms, walls, doors and windows.',
                      actionLabel: 'Create New Floor Plan',
                      onAction: _createNewPlan,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PlanTemplatesScreen(),
                          ),
                        );
                        _loadPlans();
                      },
                      icon: const Icon(
                        Icons.auto_awesome_mosaic_rounded,
                        color: Color(0xFFFF8C00),
                      ),
                      label: const Text('Browse Ready-Made Templates'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: _plans.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlanTemplatesScreen(),
                            ),
                          );
                          _loadPlans();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(
                                0xFFFF8C00,
                              ).withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_mosaic_rounded,
                                color: Color(0xFFFF8C00),
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ready-Made House Templates',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '1 BHK, 2 BHK, 3 BHK, 4 BHK (20x30, 30x40, 40x60)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final plan = _plans[index - 1];
                final unit = plan.unit;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlanEditorScreen(initialPlan: plan),
                        ),
                      );
                      _loadPlans();
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF8C00,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.architecture_rounded,
                                  color: Color(0xFFFF8C00),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            plan.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF1E3A5F,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            plan.layoutType,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E3A5F),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Updated ${DateFormat('MMM dd, yyyy • hh:mm a').format(plan.updatedAt)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetric(
                                'Plot Size',
                                '${unit.formatLength(plan.plotWidthFeet)} × ${unit.formatLength(plan.plotLengthFeet)}',
                                isDark,
                              ),
                              _buildMetric(
                                'Plot Area',
                                unit.formatArea(plan.totalPlotAreaSqFt),
                                isDark,
                              ),
                              _buildMetric(
                                'Built-up',
                                unit.formatArea(plan.totalBuiltUpAreaSqFt),
                                isDark,
                              ),
                              _buildMetric(
                                'Rooms',
                                '${plan.rooms.length}',
                                isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _duplicatePlan(plan.id),
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Duplicate',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: () => _deletePlan(plan),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    PlanExportDialog.show(
                                      context,
                                      plan: plan,
                                      activeUnit: unit,
                                      initialFormat: ExportFormat.floorPlanPdf,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.ios_share_rounded,
                                    size: 16,
                                    color: Color(0xFF1E3A5F),
                                  ),
                                  label: const Text(
                                    'Export',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PlanMaterialEstimateScreen(
                                              plan: plan,
                                              initialUnit: unit,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.calculate_outlined,
                                    size: 16,
                                    color: Color(0xFF059669),
                                  ),
                                  label: const Text(
                                    'Materials',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            Plan3DViewScreen(plan: plan),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.view_in_ar_rounded,
                                    size: 16,
                                    color: Color(0xFFFF8C00),
                                  ),
                                  label: const Text(
                                    '3D View',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PlanElevationScreen(plan: plan),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.villa_outlined,
                                    size: 16,
                                    color: Color(0xFF0284C7),
                                  ),
                                  label: const Text(
                                    'Elevation',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                FilledButton.tonalIcon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PlanEditorScreen(initialPlan: plan),
                                      ),
                                    );
                                    _loadPlans();
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text(
                                    'Edit Plan',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewPlan,
        backgroundColor: const Color(0xFFFF8C00),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create New Plan'),
      ),
    );
  }

  Widget _buildMetric(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
