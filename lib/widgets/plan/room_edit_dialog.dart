import 'package:flutter/material.dart';

import '../../models/plan/plan_models.dart';
import '../../models/plan/plan_unit.dart';

class RoomEditDialog extends StatefulWidget {
  final PlanRoom? initialRoom;
  final PlanUnit unit;
  final double maxPlotWidthFeet;
  final double maxPlotLengthFeet;

  const RoomEditDialog({
    super.key,
    this.initialRoom,
    required this.unit,
    required this.maxPlotWidthFeet,
    required this.maxPlotLengthFeet,
  });

  @override
  State<RoomEditDialog> createState() => _RoomEditDialogState();
}

class _RoomEditDialogState extends State<RoomEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _widthController;
  late TextEditingController _lengthController;

  late RoomType _selectedType;
  late Color _selectedColor;

  final List<Color> _availableColors = [
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFEDE7F6), // Soft Purple
    const Color(0xFFE8EAF6), // Soft Indigo
    const Color(0xFFFFF3E0), // Warm Orange
    const Color(0xFFFFFDE7), // Soft Yellow
    const Color(0xFFE0F7FA), // Soft Cyan
    const Color(0xFFE8F5E9), // Light Green
    const Color(0xFFF3E5F5), // Light Violet
    const Color(0xFFFFF8E1), // Amber
    const Color(0xFFECEFF1), // Blue Grey
    const Color(0xFFFFEBEE), // Soft Red/Pink
    const Color(0xFFFAFAFA), // Off White
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.initialRoom;
    _selectedType = r?.type ?? RoomType.bedroom;
    _selectedColor = r != null ? Color(r.colorValue) : _selectedType.defaultColor;

    _nameController = TextEditingController(text: r?.name ?? _selectedType.displayName);

    final initialW = r != null ? widget.unit.fromFeet(r.width) : widget.unit.fromFeet(12.0);
    final initialL = r != null ? widget.unit.fromFeet(r.length) : widget.unit.fromFeet(13.0);

    _widthController = TextEditingController(text: initialW.toStringAsFixed(1));
    _lengthController = TextEditingController(text: initialL.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  void _onTypeChanged(RoomType type) {
    setState(() {
      _selectedType = type;
      if (widget.initialRoom == null) {
        _nameController.text = type.displayName;
        _selectedColor = type.defaultColor;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final rawW = double.tryParse(_widthController.text.trim()) ?? 0.0;
    final rawL = double.tryParse(_lengthController.text.trim()) ?? 0.0;

    final widthFeet = widget.unit.toFeet(rawW);
    final lengthFeet = widget.unit.toFeet(rawL);

    final room = PlanRoom(
      id: widget.initialRoom?.id ?? 'r_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _selectedType,
      x: widget.initialRoom?.x ?? 4.0,
      y: widget.initialRoom?.y ?? 4.0,
      width: widthFeet,
      length: lengthFeet,
      colorValue: _selectedColor.toARGB32(),
      openings: widget.initialRoom?.openings ?? const [],
    );

    Navigator.of(context).pop(room);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialRoom != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _selectedType.icon,
                          color: const Color(0xFFFF8C00),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Room' : 'Add New Room',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Room Type selector
                  const Text(
                    'Room Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: RoomType.values.map((type) {
                        final isSel = type == _selectedType;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(type.displayName),
                            selected: isSel,
                            selectedColor: const Color(0xFFFF8C00),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            onSelected: (_) => _onTypeChanged(type),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Room Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Room Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Room name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Width and Length
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _widthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Width (${widget.unit.symbol})',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) {
                            final num = double.tryParse(val ?? '');
                            if (num == null || num <= 0) {
                              return 'Enter valid width';
                            }
                            if (widget.unit.toFeet(num) < 3.0) {
                              return 'Min 3 ft';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lengthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Length (${widget.unit.symbol})',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) {
                            final num = double.tryParse(val ?? '');
                            if (num == null || num <= 0) {
                              return 'Enter valid length';
                            }
                            if (widget.unit.toFeet(num) < 3.0) {
                              return 'Min 3 ft';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Color Picker
                  const Text(
                    'Color Tag',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableColors.map((color) {
                      final isSel = color.toARGB32() == _selectedColor.toARGB32();
                      return InkWell(
                        onTap: () => setState(() => _selectedColor = color),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? const Color(0xFFFF8C00) : Colors.black26,
                              width: isSel ? 2.5 : 1.0,
                            ),
                          ),
                          child: isSel
                              ? const Icon(Icons.check, size: 16, color: Color(0xFFFF8C00))
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isEditing ? 'Save Changes' : 'Add Room'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

