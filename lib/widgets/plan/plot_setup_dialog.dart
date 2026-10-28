import 'package:flutter/material.dart';

import '../../models/plan/plan_models.dart';
import '../../models/plan/plan_templates.dart';
import '../../models/plan/plan_unit.dart';
import '../../screens/plan/plan_templates_screen.dart';

class PlotSetupDialog extends StatefulWidget {
  final FloorPlan? currentPlan;

  const PlotSetupDialog({
    super.key,
    this.currentPlan,
  });

  @override
  State<PlotSetupDialog> createState() => _PlotSetupDialogState();
}

class _PlotSetupDialogState extends State<PlotSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _widthController;
  late TextEditingController _lengthController;

  late PlanUnit _selectedUnit;
  late String _selectedTemplate;

  @override
  void initState() {
    super.initState();
    final p = widget.currentPlan;
    _selectedUnit = p?.unit ?? PlanUnit.feet;
    _selectedTemplate = p?.layoutType ?? PlanTemplates.layout2BHK;

    _nameController = TextEditingController(text: p?.name ?? 'My House Plan');

    final defaultSizeFeet = PlanTemplates.getDefaultPlotSize(_selectedTemplate);
    final wFeet = p?.plotWidthFeet ?? defaultSizeFeet.width;
    final lFeet = p?.plotLengthFeet ?? defaultSizeFeet.height;

    _widthController = TextEditingController(
      text: _selectedUnit.fromFeet(wFeet).toStringAsFixed(1),
    );
    _lengthController = TextEditingController(
      text: _selectedUnit.fromFeet(lFeet).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  void _onUnitChanged(PlanUnit newUnit) {
    if (newUnit == _selectedUnit) return;
    // Convert current displayed numbers to new unit
    final currentW = double.tryParse(_widthController.text.trim()) ?? 0.0;
    final currentL = double.tryParse(_lengthController.text.trim()) ?? 0.0;

    final feetW = _selectedUnit.toFeet(currentW);
    final feetL = _selectedUnit.toFeet(currentL);

    setState(() {
      _selectedUnit = newUnit;
      _widthController.text = newUnit.fromFeet(feetW).toStringAsFixed(1);
      _lengthController.text = newUnit.fromFeet(feetL).toStringAsFixed(1);
    });
  }

  void _onTemplateSelected(String template) {
    setState(() {
      _selectedTemplate = template;
      if (widget.currentPlan == null) {
        final defSizeFeet = PlanTemplates.getDefaultPlotSize(template);
        _widthController.text = _selectedUnit.fromFeet(defSizeFeet.width).toStringAsFixed(1);
        _lengthController.text = _selectedUnit.fromFeet(defSizeFeet.height).toStringAsFixed(1);
        _nameController.text = '$template House Plan';
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final rawW = double.tryParse(_widthController.text.trim()) ?? 0.0;
    final rawL = double.tryParse(_lengthController.text.trim()) ?? 0.0;

    final widthFeet = _selectedUnit.toFeet(rawW);
    final lengthFeet = _selectedUnit.toFeet(rawL);

    final newPlan = PlanTemplates.createPlan(
      name: _nameController.text.trim(),
      layoutType: _selectedTemplate,
      plotWidthFeet: widthFeet,
      plotLengthFeet: lengthFeet,
      unit: _selectedUnit,
    );

    Navigator.of(context).pop(newPlan);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.currentPlan != null;

    final curW = double.tryParse(_widthController.text.trim()) ?? 0.0;
    final curL = double.tryParse(_lengthController.text.trim()) ?? 0.0;
    final plotAreaSqFt = _selectedUnit.toFeet(curW) * _selectedUnit.toFeet(curL);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
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
                        child: const Icon(
                          Icons.architecture_rounded,
                          color: Color(0xFFFF8C00),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Plot & Layout Setup' : 'Create 2D House Plan',
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

                  // Plan Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Plan Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 14),

                  // Unit Selection
                  const Text(
                    'Measurement Unit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: PlanUnit.values.map((unit) {
                      final isSel = unit == _selectedUnit;
                      return ChoiceChip(
                        label: Text(unit.label),
                        selected: isSel,
                        selectedColor: const Color(0xFFFF8C00),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (_) => _onUnitChanged(unit),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Starting Template (1 BHK, 2 BHK, 3 BHK, 4 BHK)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Starting Layout',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final selected = await Navigator.push<FloorPlan>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlanTemplatesScreen(selectOnly: true),
                            ),
                          );
                          if (selected != null && context.mounted) {
                            Navigator.of(context).pop(selected);
                          }
                        },
                        icon: const Icon(Icons.auto_awesome_mosaic_rounded, size: 14, color: Color(0xFFFF8C00)),
                        label: const Text(
                          'Ready-Made Templates',
                          style: TextStyle(fontSize: 11, color: Color(0xFFFF8C00)),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: PlanTemplates.availableTemplates.map((template) {
                      final isSel = template == _selectedTemplate;
                      return ChoiceChip(
                        label: Text(template),
                        selected: isSel,
                        selectedColor: const Color(0xFF1E3A5F),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (_) => _onTemplateSelected(template),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Plot Width and Length
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _widthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Plot Width (${_selectedUnit.symbol})',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            final num = double.tryParse(val ?? '');
                            if (num == null || num <= 0) return 'Enter width';
                            if (_selectedUnit.toFeet(num) < 15.0) return 'Min 15 ft';
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
                            labelText: 'Plot Length (${_selectedUnit.symbol})',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            final num = double.tryParse(val ?? '');
                            if (num == null || num <= 0) return 'Enter length';
                            if (_selectedUnit.toFeet(num) < 15.0) return 'Min 15 ft';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Calculated Plot Area Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calculated Plot Area:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _selectedUnit.formatArea(plotAreaSqFt),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8C00),
                          ),
                        ),
                      ],
                    ),
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
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isEditing ? 'Apply Layout' : 'Generate Plan'),
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

