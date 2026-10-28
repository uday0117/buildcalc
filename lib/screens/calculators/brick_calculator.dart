import 'package:flutter/material.dart';

import '../../models/calculation.dart';
import '../../services/storage_service.dart';
import '../../widgets/input_field.dart';
import '../../widgets/result_card.dart';

class BrickCalculator extends StatefulWidget {
  const BrickCalculator({super.key});

  @override
  State<BrickCalculator> createState() => _BrickCalculatorState();
}

class _BrickCalculatorState extends State<BrickCalculator> {
  final _lengthController = TextEditingController();
  final _heightController = TextEditingController();
  final _thicknessController = TextEditingController();

  double _bricksRequired = 0;
  double _wallArea = 0;
  bool _hasCalculated = false;

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final thickness = double.tryParse(_thicknessController.text) ?? 0;

    if (length > 0 && height > 0 && thickness > 0) {
      // Calculate wall area
      _wallArea = length * height;

      // Standard brick size: 190mm x 90mm x 90mm
      // Bricks per square meter varies by wall thickness
      double bricksPerSqm;
      if (thickness <= 115) {
        bricksPerSqm = 50; // Single brick wall
      } else if (thickness <= 230) {
        bricksPerSqm = 100; // Double brick wall
      } else {
        bricksPerSqm = 150; // Triple brick wall
      }

      _bricksRequired = _wallArea * bricksPerSqm;

      // Add 10% wastage
      _bricksRequired = _bricksRequired * 1.1;

      setState(() {
        _hasCalculated = true;
      });

      _saveToHistory();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all values')),
      );
    }
  }

  Calculation _createCalculationModel() {
    return Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'brick',
      title: 'Brick Calculator',
      inputs: {
        'length': _lengthController.text,
        'height': _heightController.text,
        'thickness': _thicknessController.text,
      },
      results: {
        'bricks_required': _bricksRequired,
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
      _thicknessController.clear();
      _bricksRequired = 0;
      _wallArea = 0;
      _hasCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Brick Calculator',
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
                      Icons.grid_4x4_rounded,
                      size: 54,
                      color: Color(0xFFD32F2F),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate number of bricks\nrequired for wall construction',
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
              label: 'Wall Length',
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
              label: 'Wall Thickness',
              hint: 'Enter thickness (115/230/345)',
              controller: _thicknessController,
              suffix: 'mm',
              prefixIcon: Icons.line_weight_rounded,
              helperText: 'Standard: 115mm (single) or 230mm (double)',
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
                icon: Icons.grid_4x4_rounded,
                onSave: _bookmark,
                note: 'Includes 10% wastage factor for cuts and transport breakage',
                rows: [
                  ResultRowItem(
                    label: 'Bricks Required',
                    value: '${_bricksRequired.toStringAsFixed(0)} bricks',
                    isPrimary: true,
                  ),
                  ResultRowItem(
                    label: 'Wall Area',
                    value: '${_wallArea.toStringAsFixed(2)} m²',
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
    _thicknessController.dispose();
    super.dispose();
  }
}
