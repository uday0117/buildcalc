import 'package:flutter/material.dart';

import '../../models/calculation.dart';
import '../../services/storage_service.dart';
import '../../widgets/input_field.dart';
import '../../widgets/result_card.dart';

class AreaCalculator extends StatefulWidget {
  const AreaCalculator({super.key});

  @override
  State<AreaCalculator> createState() => _AreaCalculatorState();
}

class _AreaCalculatorState extends State<AreaCalculator> {
  String _selectedShape = 'Rectangle';
  final _dimension1Controller = TextEditingController();
  final _dimension2Controller = TextEditingController();
  final _dimension3Controller = TextEditingController();

  double _area = 0;
  double _perimeter = 0;
  bool _hasCalculated = false;

  final List<String> _shapes = ['Rectangle', 'Square', 'Circle', 'Triangle'];

  void _calculate() {
    final dim1 = double.tryParse(_dimension1Controller.text) ?? 0;
    final dim2 = double.tryParse(_dimension2Controller.text) ?? 0;
    final dim3 = double.tryParse(_dimension3Controller.text) ?? 0;

    if (dim1 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid dimensions')),
      );
      return;
    }

    switch (_selectedShape) {
      case 'Rectangle':
        if (dim2 <= 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please enter width')));
          return;
        }
        _area = dim1 * dim2;
        _perimeter = 2 * (dim1 + dim2);
        break;

      case 'Square':
        _area = dim1 * dim1;
        _perimeter = 4 * dim1;
        break;

      case 'Circle':
        _area = 3.14159 * dim1 * dim1;
        _perimeter = 2 * 3.14159 * dim1;
        break;

      case 'Triangle':
        if (dim2 <= 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please enter height')));
          return;
        }
        _area = 0.5 * dim1 * dim2;
        // For perimeter, need all three sides
        if (dim3 > 0) {
          _perimeter = dim1 + dim2 + dim3;
        } else {
          _perimeter = 0;
        }
        break;
    }

    setState(() {
      _hasCalculated = true;
    });

    _saveToHistory();
  }

  Calculation _createCalculationModel() {
    return Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'area',
      title: 'Area Calculator',
      inputs: {
        'shape': _selectedShape,
        'dimension1': _dimension1Controller.text,
        'dimension2': _dimension2Controller.text,
        'dimension3': _dimension3Controller.text,
      },
      results: {'area': _area, 'perimeter': _perimeter},
      timestamp: DateTime.now(),
    );
  }

  void _saveToHistory() {
    StorageService.saveToHistory(_createCalculationModel());
  }

  Future<void> _bookmark() async {
    await StorageService.saveCalculation(_createCalculationModel());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to Bookmarks'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _reset() {
    setState(() {
      _dimension1Controller.clear();
      _dimension2Controller.clear();
      _dimension3Controller.clear();
      _area = 0;
      _perimeter = 0;
      _hasCalculated = false;
    });
  }

  String _getDimension1Label() {
    switch (_selectedShape) {
      case 'Circle':
        return 'Radius';
      case 'Triangle':
        return 'Base';
      case 'Square':
        return 'Side';
      default:
        return 'Length';
    }
  }

  String _getDimension2Label() {
    switch (_selectedShape) {
      case 'Rectangle':
        return 'Width';
      case 'Triangle':
        return 'Height';
      default:
        return '';
    }
  }

  IconData _getShapeIcon(String shape) {
    switch (shape) {
      case 'Rectangle':
        return Icons.crop_landscape_rounded;
      case 'Square':
        return Icons.crop_square_rounded;
      case 'Circle':
        return Icons.circle_outlined;
      case 'Triangle':
        return Icons.change_history_rounded;
      default:
        return Icons.square_foot_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Area Calculator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset',
            onPressed: _reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.square_foot_rounded,
                      size: 54,
                      color: Color(0xFF66BB6A),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate area and perimeter\nof different geometric shapes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Shape Selector Chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Shape',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _shapes.map((shape) {
                    final isSelected = _selectedShape == shape;
                    return ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(
                        _getShapeIcon(shape),
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF1E3A5F)),
                      ),
                      label: Text(shape),
                      labelStyle: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF1E3A5F)),
                      ),
                      selectedColor: const Color(0xFFFF8C00),
                      backgroundColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedShape = shape;
                            _reset();
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dimension 1
            InputField(
              label: _getDimension1Label(),
              hint: 'Enter ${_getDimension1Label().toLowerCase()}',
              controller: _dimension1Controller,
              suffix: 'm',
              prefixIcon: Icons.straighten_rounded,
            ),
            const SizedBox(height: 14),

            // Dimension 2 (if needed)
            if (_selectedShape == 'Rectangle' || _selectedShape == 'Triangle') ...[
              InputField(
                label: _getDimension2Label(),
                hint: 'Enter ${_getDimension2Label().toLowerCase()}',
                controller: _dimension2Controller,
                suffix: 'm',
                prefixIcon: Icons.height_rounded,
              ),
              const SizedBox(height: 14),
            ],

            // Dimension 3 (for triangle perimeter)
            if (_selectedShape == 'Triangle') ...[
              InputField(
                label: 'Third Side (optional)',
                hint: 'For perimeter calculation',
                controller: _dimension3Controller,
                suffix: 'm',
                prefixIcon: Icons.architecture_rounded,
                helperText: 'Optional: only needed if calculating perimeter',
              ),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Calculate',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),

            if (_hasCalculated) ...[
              const SizedBox(height: 24),
              ResultCard(
                title: 'Results',
                icon: Icons.square_foot_rounded,
                onSave: _bookmark,
                note: 'Shape: $_selectedShape',
                rows: [
                  ResultRowItem(
                    label: 'Total Area',
                    value: '${_area.toStringAsFixed(2)} m²',
                    isPrimary: true,
                  ),
                  if (_perimeter > 0)
                    ResultRowItem(
                      label: 'Perimeter',
                      value: '${_perimeter.toStringAsFixed(2)} m',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dimension1Controller.dispose();
    _dimension2Controller.dispose();
    _dimension3Controller.dispose();
    super.dispose();
  }
}
