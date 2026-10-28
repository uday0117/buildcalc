import 'package:flutter/material.dart';

import '../../models/plan/plan_3d_models.dart';

class MaterialSelectionSheet extends StatelessWidget {
  final Scene3DMaterial activeWallMaterial;
  final Scene3DMaterial activeFloorMaterial;
  final CutawayMode activeCutawayMode;
  final bool showRoomLabels;
  final ValueChanged<Scene3DMaterial> onWallMaterialChanged;
  final ValueChanged<Scene3DMaterial> onFloorMaterialChanged;
  final ValueChanged<CutawayMode> onCutawayModeChanged;
  final ValueChanged<bool> onToggleRoomLabels;

  const MaterialSelectionSheet({
    super.key,
    required this.activeWallMaterial,
    required this.activeFloorMaterial,
    required this.activeCutawayMode,
    required this.showRoomLabels,
    required this.onWallMaterialChanged,
    required this.onFloorMaterialChanged,
    required this.onCutawayModeChanged,
    required this.onToggleRoomLabels,
  });

  static Future<void> show(
    BuildContext context, {
    required Scene3DMaterial activeWallMaterial,
    required Scene3DMaterial activeFloorMaterial,
    required CutawayMode activeCutawayMode,
    required bool showRoomLabels,
    required ValueChanged<Scene3DMaterial> onWallMaterialChanged,
    required ValueChanged<Scene3DMaterial> onFloorMaterialChanged,
    required ValueChanged<CutawayMode> onCutawayModeChanged,
    required ValueChanged<bool> onToggleRoomLabels,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MaterialSelectionSheet(
        activeWallMaterial: activeWallMaterial,
        activeFloorMaterial: activeFloorMaterial,
        activeCutawayMode: activeCutawayMode,
        showRoomLabels: showRoomLabels,
        onWallMaterialChanged: onWallMaterialChanged,
        onFloorMaterialChanged: onFloorMaterialChanged,
        onCutawayModeChanged: onCutawayModeChanged,
        onToggleRoomLabels: onToggleRoomLabels,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_rounded, color: Color(0xFFFF8C00)),
                  SizedBox(width: 8),
                  Text(
                    '3D View & Materials',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Wall Height / Cutaway Mode
          const Text(
            'WALL CUTAWAY VIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<CutawayMode>(
            segments: CutawayMode.values.map((mode) {
              return ButtonSegment<CutawayMode>(
                value: mode,
                icon: Icon(mode.icon, size: 16),
                label: Text(
                  mode == CutawayMode.full
                      ? 'Full 10ft'
                      : mode == CutawayMode.dollhouse
                      ? 'Cutaway 4ft'
                      : 'Slab 0.5ft',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }).toList(),
            selected: {activeCutawayMode},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) onCutawayModeChanged(set.first);
            },
          ),
          const SizedBox(height: 18),

          // Wall Finishes & Colors
          const Text(
            'WALL FINISH & COLOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Scene3DMaterial.wallPresets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final mat = Scene3DMaterial.wallPresets[index];
                final isSelected = mat.id == activeWallMaterial.id;

                return InkWell(
                  onTap: () => onWallMaterialChanged(mat),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF8C00)
                            : isDark
                            ? Colors.white10
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: mat.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black26),
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Color(0xFFFF8C00),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Floor Finishes
          const Text(
            'FLOOR FINISH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Scene3DMaterial.floorPresets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final mat = Scene3DMaterial.floorPresets[index];
                final isSelected = mat.id == activeFloorMaterial.id;

                return InkWell(
                  onTap: () => onFloorMaterialChanged(mat),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF8C00)
                            : isDark
                            ? Colors.white10
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: mat.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black26),
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Color(0xFFFF8C00),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Toggles
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Show 3D Room Badges & Dimensions',
              style: TextStyle(fontSize: 13),
            ),
            value: showRoomLabels,
            activeTrackColor: const Color(0xFFFF8C00),
            onChanged: onToggleRoomLabels,
          ),
        ],
      ),
    );
  }
}
