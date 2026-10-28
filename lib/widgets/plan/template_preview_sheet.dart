import 'package:flutter/material.dart';

import '../../models/plan/material_estimation_models.dart';
import '../../models/plan/ready_made_template_models.dart';
import '../../services/plan_material_estimator.dart';
import '../../services/plan_storage_service.dart';
import '../../screens/plan/plan_editor_screen.dart';
import 'plan_thumbnail_painter.dart';

/// Modal bottom sheet or dialog providing in-depth inspection of a ready-made template.
class TemplatePreviewSheet extends StatelessWidget {
  final ReadyMadePlanTemplate template;

  const TemplatePreviewSheet({super.key, required this.template});

  static Future<void> show(BuildContext context, ReadyMadePlanTemplate template) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TemplatePreviewSheet(template: template),
    );
  }

  Future<void> _duplicateAndSave(BuildContext context) async {
    final freshPlan = template.createFreshPlan(
      name: '${template.title} (My Plan)',
    );
    await PlanStorageService.savePlan(freshPlan);

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plan "${freshPlan.name}" saved to your Saved Plans!'),
        backgroundColor: const Color(0xFF1E3A5F),
        action: SnackBarAction(
          label: 'Open Editor',
          textColor: const Color(0xFFFF8C00),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlanEditorScreen(initialPlan: freshPlan),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openInEditor(BuildContext context) {
    final freshPlan = template.createFreshPlan();
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanEditorScreen(initialPlan: freshPlan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final freshPlan = template.createFreshPlan();
    final estimateReport = PlanMaterialEstimator.estimateMaterials(plan: freshPlan);

    double totalCementBags = 0.0;
    double totalSandCuFt = 0.0;
    double totalBricks = 0.0;
    double totalTileSqFt = 0.0;

    for (final item in estimateReport.lineItems) {
      if (item.name.toLowerCase().contains('cement')) {
        totalCementBags += item.totalQuantity;
      } else if (item.name.toLowerCase().contains('sand')) {
        totalSandCuFt += item.totalQuantity;
      } else if (item.category == MaterialCategory.masonry) {
        totalBricks += item.totalQuantity;
      } else if (item.category == MaterialCategory.tile) {
        totalTileSqFt += item.totalQuantity;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),

              // Title and Badges Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  template.bhkType,
                                  style: const TextStyle(
                                    color: Color(0xFFFF8C00),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  template.plotDimensionsLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF0284C7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white12 : Colors.grey[200]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🧭 ${template.orientation}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey[800],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            template.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 20),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // Blueprint 2D Visual Preview
                    SizedBox(
                      height: 220,
                      child: PlanThumbnail(
                        plan: freshPlan,
                        frontSetbackFeet: template.frontSetbackFeet,
                        rearSetbackFeet: template.rearSetbackFeet,
                        sideSetbackFeet: template.sideSetbackFeet,
                        orientation: template.orientation,
                        showLabels: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Key Specs Metrics Row
                    Row(
                      children: [
                        _buildSpecCard(
                          isDark: isDark,
                          label: 'Plot Area',
                          value: '${template.plotAreaSqFt.toInt()} sq ft',
                          subtitle: template.plotDimensionsLabel,
                          icon: Icons.aspect_ratio_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 10),
                        _buildSpecCard(
                          isDark: isDark,
                          label: 'Built-Up Area',
                          value: '${template.totalBuiltUpAreaSqFt.toStringAsFixed(0)} sq ft',
                          subtitle: '${template.groundCoveragePercent.toStringAsFixed(1)}% Coverage',
                          icon: Icons.home_work_outlined,
                          color: const Color(0xFFFF8C00),
                        ),
                        const SizedBox(width: 10),
                        _buildSpecCard(
                          isDark: isDark,
                          label: 'Usable Area',
                          value: '${template.usablePlotAreaSqFt.toInt()} sq ft',
                          subtitle: 'Within Setbacks',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 10),
                        _buildSpecCard(
                          isDark: isDark,
                          label: 'Rooms',
                          value: '${template.roomCount}',
                          subtitle: '${freshPlan.allOpenings.length} Doors/Win',
                          icon: Icons.meeting_room_outlined,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Setbacks & Usable Area Assumptions Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.straighten_rounded,
                                size: 18,
                                color: Color(0xFF0284C7),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Planning Assumptions & Setbacks',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildAssumpRow('Front Setback', '${template.frontSetbackFeet.toStringAsFixed(1)} ft'),
                              _buildAssumpRow('Rear Setback', '${template.rearSetbackFeet.toStringAsFixed(1)} ft'),
                              _buildAssumpRow('Side Setbacks', '${template.sideSetbackFeet.toStringAsFixed(1)} ft each'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildAssumpRow('Usable Plot W × L', '${template.usablePlotWidthFeet.toStringAsFixed(1)} × ${template.usablePlotLengthFeet.toStringAsFixed(1)} ft'),
                              _buildAssumpRow('Main Orientation', template.orientation),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rooms Breakdown List
                    const Text(
                      'Rooms & Dimensions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey[200]!,
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: freshPlan.rooms.length,
                        separatorBuilder: (ctx, index) => Divider(
                          height: 1,
                          color: isDark ? Colors.white10 : Colors.grey[200],
                        ),
                        itemBuilder: (ctx, i) {
                          final room = freshPlan.rooms[i];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Color(room.colorValue).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(room.type.icon, size: 18, color: const Color(0xFF1E3A5F)),
                            ),
                            title: Text(
                              room.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${freshPlan.unit.formatDimensions(room.width, room.length)}  •  ${freshPlan.unit.formatArea(room.areaSqFt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                            trailing: Text(
                              '${room.openings.length} opening(s)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Instant Material Estimate Summary
                    const Text(
                      'Estimated Material Requirements',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF059669).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildEstimateChip('Cement', '${totalCementBags.toInt()} bags'),
                              _buildEstimateChip('Sand', '${totalSandCuFt.toInt()} cu ft'),
                              _buildEstimateChip('Bricks / AAC', '${totalBricks.toInt()} pcs'),
                              _buildEstimateChip('Tiles', '${totalTileSqFt.toInt()} sq ft'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Estimated based on ${template.totalBuiltUpAreaSqFt.toStringAsFixed(0)} sq ft built-up area. Dynamically recalculates as you modify rooms in the 2D editor.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Regulatory & Compliance Disclaimer (Mandatory)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.gavel_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Regulatory & Compliance Notice',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  template.disclaimer,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.35,
                                    color: isDark ? Colors.white70 : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Actions Bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _duplicateAndSave(context),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Duplicate & Save'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _openInEditor(context),
                          icon: const Icon(Icons.edit_road_rounded, size: 18),
                          label: const Text('Open in 2D Editor'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8C00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildSpecCard({
    required bool isDark,
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : Colors.grey[700],
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8.5,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildAssumpRow(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  static Widget _buildEstimateChip(String material, String qty) {
    return Column(
      children: [
        Text(
          qty,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF059669),
          ),
        ),
        Text(
          material,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
