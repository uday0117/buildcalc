import 'package:flutter/material.dart';

import '../../models/calculation.dart';
import '../../services/storage_service.dart';
import '../../widgets/input_field.dart';
import '../../widgets/result_card.dart';

class SandCalculator extends StatefulWidget {
  const SandCalculator({super.key});

  @override
  State<SandCalculator> createState() => _SandCalculatorState();
}

class _SandCalculatorState extends State<SandCalculator> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();

  double _sandCubicMeters = 0;
  double _sandTonnes = 0;
  double _sandCubicFeet = 0;
  bool _hasCalculated = false;

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final depth = double.tryParse(_depthController.text) ?? 0;

    if (length > 0 && width > 0 && depth > 0) {
      // Calculate volume in cubic meters
      _sandCubicMeters = length * width * depth;

      // Convert to cubic feet (1 m³ = 35.3147 ft³)
      _sandCubicFeet = _sandCubicMeters * 35.3147;

      // Convert to tonnes (1 m³ of sand ≈ 1.6 tonnes)
      _sandTonnes = _sandCubicMeters * 1.6;

      // Add 20% wastage
      _sandCubicMeters = _sandCubicMeters * 1.2;
      _sandTonnes = _sandTonnes * 1.2;
      _sandCubicFeet = _sandCubicFeet * 1.2;

      setState(() {
        _hasCalculated = true;
      });

      _saveToHistory();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter all values')));
    }
  }

  Calculation _createCalculationModel() {
    return Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'sand',
      title: 'Sand Calculator',
      inputs: {
        'length': _lengthController.text,
        'width': _widthController.text,
        'depth': _depthController.text,
      },
      results: {
        'sand_cubic_meters': _sandCubicMeters,
        'sand_tonnes': _sandTonnes,
        'sand_cubic_feet': _sandCubicFeet,
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
      _widthController.clear();
      _depthController.clear();
      _sandCubicMeters = 0;
      _sandTonnes = 0;
      _sandCubicFeet = 0;
      _hasCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sand Calculator',
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
                      Icons.terrain_rounded,
                      size: 54,
                      color: Color(0xFFFFA726),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate sand quantity\nrequired for construction',
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
              label: 'Length',
              hint: 'Enter length',
              controller: _lengthController,
              suffix: 'm',
              prefixIcon: Icons.straighten_rounded,
            ),
            const SizedBox(height: 14),

            InputField(
              label: 'Width',
              hint: 'Enter width',
              controller: _widthController,
              suffix: 'm',
              prefixIcon: Icons.square_foot_rounded,
            ),
            const SizedBox(height: 14),

            InputField(
              label: 'Depth',
              hint: 'Enter depth',
              controller: _depthController,
              suffix: 'm',
              prefixIcon: Icons.vertical_align_bottom_rounded,
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
                icon: Icons.terrain_rounded,
                onSave: _bookmark,
                note: 'Includes 20% allowance for compaction & transit loss',
                rows: [
                  ResultRowItem(
                    label: 'Sand Required (m³)',
                    value: '${_sandCubicMeters.toStringAsFixed(2)} m³',
                    isPrimary: true,
                  ),
                  ResultRowItem(
                    label: 'In Tonnes',
                    value: '${_sandTonnes.toStringAsFixed(2)} tonnes',
                  ),
                  ResultRowItem(
                    label: 'In Cubic Feet',
                    value: '${_sandCubicFeet.toStringAsFixed(2)} ft³',
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
    _widthController.dispose();
    _depthController.dispose();
    super.dispose();
  }
}
