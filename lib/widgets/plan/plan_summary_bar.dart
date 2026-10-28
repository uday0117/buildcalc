import 'package:flutter/material.dart';

import '../../models/plan/plan_geometry.dart';
import '../../models/plan/plan_models.dart';
import '../../models/plan/plan_unit.dart';

class PlanSummaryBar extends StatelessWidget {
  final FloorPlan plan;
  final PlanUnit unit;
  final VoidCallback? onEstimateMaterials;

  const PlanSummaryBar({
    super.key,
    required this.plan,
    required this.unit,
    this.onEstimateMaterials,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlapping = PlanGeometry.findOverlappingPairs(plan.rooms);
    final hasOverlaps = overlapping.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatItem(
              context,
              label: 'Plot Area',
              value: unit.formatArea(plan.totalPlotAreaSqFt),
              icon: Icons.aspect_ratio_rounded,
              color: const Color(0xFF1E3A5F),
            ),
            _buildDivider(),
            _buildStatItem(
              context,
              label: 'Built-up Area',
              value: unit.formatArea(plan.totalBuiltUpAreaSqFt),
              icon: Icons.foundation_rounded,
              color: const Color(0xFFFF8C00),
            ),
            _buildDivider(),
            _buildStatItem(
              context,
              label: 'Coverage',
              value: '${plan.groundCoveragePercent.toStringAsFixed(1)}%',
              icon: Icons.pie_chart_outline_rounded,
              color: const Color(0xFF43A047),
            ),
            _buildDivider(),
            _buildStatItem(
              context,
              label: 'Rooms',
              value: '${plan.rooms.length}',
              icon: Icons.meeting_room_outlined,
              color: const Color(0xFF8E24AA),
            ),
            if (onEstimateMaterials != null) ...[
              const SizedBox(width: 10),
              InkWell(
                onTap: onEstimateMaterials,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calculate_outlined,
                        size: 15,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Materials Estimate',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (hasOverlaps) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${overlapping.length} room overlap(s)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 22,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
