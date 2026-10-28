import 'package:flutter/material.dart';

import '../../models/plan/plan_editor_controller.dart';
import '../../models/plan/plan_models.dart';
import 'opening_edit_dialog.dart';
import 'room_edit_dialog.dart';

class RoomListSheet extends StatelessWidget {
  final PlanEditorController controller;

  const RoomListSheet({super.key, required this.controller});

  static void show(BuildContext context, PlanEditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomListSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = controller.plan;
    final unit = controller.activeUnit;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rooms & Spaces',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${plan.rooms.length} room(s) in floor plan',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final newRoom = await showDialog<PlanRoom>(
                      context: context,
                      builder: (ctx) => RoomEditDialog(
                        unit: unit,
                        maxPlotWidthFeet: plan.plotWidthFeet,
                        maxPlotLengthFeet: plan.plotLengthFeet,
                      ),
                    );
                    if (newRoom != null) {
                      controller.addRoom(newRoom);
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Room'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: plan.rooms.isEmpty
                ? Center(
                    child: Text(
                      'No rooms yet. Tap "Add Room" to begin!',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: plan.rooms.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final room = plan.rooms[index];
                      final isSelected = room.id == controller.selectedRoomId;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFFF8C00)
                                : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        color: isSelected
                            ? const Color(0xFFFF8C00).withValues(alpha: 0.08)
                            : (isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC)),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(
                                room.colorValue,
                              ).withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              room.type.icon,
                              size: 18,
                              color: const Color(0xFF1E3A5F),
                            ),
                          ),
                          title: Text(
                            room.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${unit.formatDimensions(room.width, room.length)} • ${unit.formatArea(room.areaSqFt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () async {
                                  final updated = await showDialog<PlanRoom>(
                                    context: context,
                                    builder: (ctx) => RoomEditDialog(
                                      initialRoom: room,
                                      unit: unit,
                                      maxPlotWidthFeet: plan.plotWidthFeet,
                                      maxPlotLengthFeet: plan.plotLengthFeet,
                                    ),
                                  );
                                  if (updated != null) {
                                    controller.updateRoom(updated);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => controller.deleteRoom(room.id),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Openings (${room.openings.length}):',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          final newOp =
                                              await showDialog<PlanOpening>(
                                                context: context,
                                                builder: (ctx) =>
                                                    OpeningEditDialog(
                                                      room: room,
                                                      unit: unit,
                                                    ),
                                              );
                                          if (newOp != null) {
                                            controller.addOpening(
                                              room.id,
                                              newOp,
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text(
                                          'Add Door/Window',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (room.openings.isEmpty)
                                    const Text(
                                      'No doors or windows yet.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    )
                                  else
                                    ...room.openings.map((op) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              op.type.icon,
                                              size: 16,
                                              color: const Color(0xFFFF8C00),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${op.type.label} (${op.wallSide.name}) • ${unit.formatLength(op.widthFeet)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                              onPressed: () => controller
                                                  .deleteOpening(op.id),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
