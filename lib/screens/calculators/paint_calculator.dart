import 'package:flutter/material.dart';

import '../../models/calculation.dart';
import '../../services/storage_service.dart';
import '../../widgets/input_field.dart';
import '../../widgets/result_card.dart';

class PaintCalculator extends StatefulWidget {
  const PaintCalculator({super.key});

  @override
  State<PaintCalculator> createState() => _PaintCalculatorState();
}

class _PaintCalculatorState extends State<PaintCalculator> {
  final _lengthController = TextEditingController();
  final _heightController = TextEditingController();
  final _doorWindowController = TextEditingController();

  double _paintLiters = 0;
  double _wallArea = 0;
  double _coats = 2;
  bool _hasCalculated = false;

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final doorWindow = double.tryParse(_doorWindowController.text) ?? 0;

    if (length > 0 && height > 0) {
      // Calculate total wall area (perimeter × height)
      _wallArea = (2 * (length + length)) * height;

      // Subtract door and window area
      _wallArea = _wallArea - doorWindow;

      // Paint coverage: 1 liter covers 10-12 m² (using 10 for better coverage)
      final coveragePerLiter = 10.0;

      // Calculate paint required for given coats
      _paintLiters = (_wallArea * _coats) / coveragePerLiter;

      // Add 10% extra
      _paintLiters = _paintLiters * 1.1;

      setState(() {
        _hasCalculated = true;
      });

      _saveToHistory();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter length and height')),
      );
    }
  }

  Calculation _createCalculationModel() {
    return Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'paint',
      title: 'Paint Calculator',
      inputs: {
        'length': _lengthController.text,
        'height': _heightController.text,
        'door_window_area': _doorWindowController.text,
        'coats': _coats,
      },
      results: {
        'paint_liters': _paintLiters,
        'wall_area': _wallArea,
      },
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
      _lengthController.clear();
      _heightController.clear();
      _doorWindowController.clear();
      _paintLiters = 0;
      _wallArea = 0;
      _coats = 2;
      _hasCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paint Calculator',
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
                      Icons.format_paint_rounded,
                      size: 54,
                      color: Color(0xFF42A5F5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate paint quantity\nfor your walls',
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

            InputField(
              label: 'Room Length',
              hint: 'Enter length',
              controller: _lengthController,
              suffix: 'm',
              prefixIcon: Icons.straighten_rounded,
            ),
            const SizedBox(height: 14),

            InputField(
              label: 'Wall Height',
              hint: 'Enter height',
              controller: _heightController,
              suffix: 'm',
              prefixIcon: Icons.height_rounded,
            ),
            const SizedBox(height: 14),

            InputField(
              label: 'Door & Window Area (optional)',
              hint: 'Enter total deducted area',
              controller: _doorWindowController,
              suffix: 'm²',
              prefixIcon: Icons.crop_square_rounded,
            ),
            const SizedBox(height: 14),

            // Number of coats selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Number of Coats',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _coats,
                          min: 1,
                          max: 3,
                          divisions: 2,
                          label: '${_coats.toInt()} coats',
                          activeColor: const Color(0xFFFF8C00),
                          onChanged: (value) {
                            setState(() {
                              _coats = value;
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_coats.toInt()} ${_coats.toInt() == 1 ? "coat" : "coats"}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8C00),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

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
                icon: Icons.format_paint_rounded,
                onSave: _bookmark,
                note: 'Includes 10% extra allowance. Assumes 10 m²/L standard coverage',
                rows: [
                  ResultRowItem(
                    label: 'Paint Required',
                    value: '${_paintLiters.toStringAsFixed(2)} liters',
                    isPrimary: true,
                  ),
                  ResultRowItem(
                    label: 'Net Wall Area',
                    value: '${_wallArea.toStringAsFixed(2)} m²',
                  ),
                  ResultRowItem(
                    label: 'Number of Coats',
                    value: '${_coats.toInt()}',
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
    _lengthController.dispose();
    _heightController.dispose();
    _doorWindowController.dispose();
    super.dispose();
  }
}
