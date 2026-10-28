import 'package:flutter/material.dart';

import '../../models/plan/plan_models.dart';
import '../../models/plan/plan_unit.dart';

class OpeningEditDialog extends StatefulWidget {
  final PlanRoom room;
  final PlanOpening? initialOpening;
  final PlanUnit unit;

  const OpeningEditDialog({
    super.key,
    required this.room,
    this.initialOpening,
    required this.unit,
  });

  @override
  State<OpeningEditDialog> createState() => _OpeningEditDialogState();
}

class _OpeningEditDialogState extends State<OpeningEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late OpeningType _selectedType;
  late PlanWallSide _selectedSide;
  late TextEditingController _widthController;
  late TextEditingController _offsetController;
  late bool _swingInward;

  @override
  void initState() {
    super.initState();
    final op = widget.initialOpening;
    _selectedType = op?.type ?? OpeningType.door;
    _selectedSide = op?.wallSide ?? PlanWallSide.south;
    _swingInward = op?.swingInward ?? true;

    final initialWFeet = op?.widthFeet ?? _selectedType.defaultWidthFeet;
    final initialOffsetFeet = op?.offsetFeet ?? 2.0;

    final dispW = widget.unit.fromFeet(initialWFeet);
    final dispOffset = widget.unit.fromFeet(initialOffsetFeet);

    _widthController = TextEditingController(text: dispW.toStringAsFixed(1));
    _offsetController = TextEditingController(text: dispOffset.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _widthController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  double get _currentWallLengthFeet => widget.room.wallLength(_selectedSide);

  void _onTypeChanged(OpeningType type) {
    setState(() {
      _selectedType = type;
      if (widget.initialOpening == null) {
        final dispW = widget.unit.fromFeet(type.defaultWidthFeet);
        _widthController.text = dispW.toStringAsFixed(1);
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final rawW = double.tryParse(_widthController.text.trim()) ?? 0.0;
    final rawOffset = double.tryParse(_offsetController.text.trim()) ?? 0.0;

    final widthFeet = widget.unit.toFeet(rawW);
    final offsetFeet = widget.unit.toFeet(rawOffset);

    final opening = PlanOpening(
      id: widget.initialOpening?.id ?? 'op_${DateTime.now().millisecondsSinceEpoch}',
      roomId: widget.room.id,
      wallSide: _selectedSide,
      type: _selectedType,
      offsetFeet: offsetFeet,
      widthFeet: widthFeet,
      swingInward: _swingInward,
    );

    Navigator.of(context).pop(opening);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialOpening != null;
    final wallLenUnit = widget.unit.formatLength(_currentWallLengthFeet);

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Opening' : 'Add Door / Window',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                              ),
                            ),
                            Text(
                              'On "${widget.room.name}"',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Opening Type
                  const Text(
                    'Opening Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: OpeningType.values.map((type) {
                        final isSel = type == _selectedType;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(type.label),
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

                  // Wall Side
                  const Text(
                    'Wall Placement',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: PlanWallSide.values.map((side) {
                      final isSel = side == _selectedSide;
                      return ChoiceChip(
                        label: Text(side.label),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E3A5F),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (_) => setState(() => _selectedSide = side),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wall length on this side: $wallLenUnit',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Width and Offset fields
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
                            if (num == null || num <= 0) return 'Enter width';
                            final ft = widget.unit.toFeet(num);
                            if (ft > _currentWallLengthFeet) {
                              return 'Exceeds wall length';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _offsetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Position Offset (${widget.unit.symbol})',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) {
                            final num = double.tryParse(val ?? '');
                            if (num == null || num < 0) return 'Invalid offset';
                            final offsetFt = widget.unit.toFeet(num);
                            final wFt = widget.unit.toFeet(double.tryParse(_widthController.text) ?? 0);
                            if (offsetFt + wFt > _currentWallLengthFeet + 0.05) {
                              return 'Past wall end';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Door Swing option
                  if (_selectedType.isDoor)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Swing Inward into room', style: TextStyle(fontSize: 13)),
                      value: _swingInward,
                      activeThumbColor: const Color(0xFFFF8C00),
                      onChanged: (val) => setState(() => _swingInward = val),
                    ),
                  const SizedBox(height: 16),

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
                        child: Text(isEditing ? 'Save Changes' : 'Add Opening'),
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
