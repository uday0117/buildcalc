import 'package:flutter/material.dart';

import '../../models/calculation.dart';
import '../../services/storage_service.dart';
import '../../widgets/input_field.dart';
import '../../widgets/result_card.dart';

class CementCalculator extends StatefulWidget {
  const CementCalculator({super.key});

  @override
  State<CementCalculator> createState() => _CementCalculatorState();
}

class _CementCalculatorState extends State<CementCalculator> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _thicknessController = TextEditingController();

  double _cementBags = 0;
  double _sandCubicMeters = 0;
  double _volume = 0;
  bool _hasCalculated = false;

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final thickness = double.tryParse(_thicknessController.text) ?? 0;

    if (length > 0 && width > 0 && thickness > 0) {
      // Convert thickness from mm to m
      final thicknessInMeters = thickness / 1000;

      // Calculate volume in cubic meters
      _volume = length * width * thicknessInMeters;

      // Cement calculation (1:6 ratio)
      // Dry volume = Wet volume * 1.54
      final dryVolume = _volume * 1.54;

      // Cement = (dry volume * cement ratio) / sum of ratios
      final cementVolume = (dryVolume * 1) / 7;

      // 1 bag of cement = 0.0347 cubic meters
      _cementBags = cementVolume / 0.0347;

      // Sand calculation
      _sandCubicMeters = (dryVolume * 6) / 7;

      setState(() {
        _hasCalculated = true;
      });

      // Save to history
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
      type: 'cement',
      title: 'Cement Calculator',
      inputs: {
        'length': _lengthController.text,
        'width': _widthController.text,
        'thickness': _thicknessController.text,
      },
      results: {
        'cement_bags': _cementBags,
        'sand_cubic_meters': _sandCubicMeters,
        'volume': _volume,
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
      _thicknessController.clear();
      _cementBags = 0;
      _sandCubicMeters = 0;
      _volume = 0;
      _hasCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cement Calculator',
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
                      Icons.architecture_rounded,
                      size: 54,
                      color: Color(0xFF795548),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate cement and sand\nrequired for construction',
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
              label: 'Thickness',
              hint: 'Enter thickness',
              controller: _thicknessController,
              suffix: 'mm',
              prefixIcon: Icons.layers_rounded,
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
                icon: Icons.architecture_rounded,
                onSave: _bookmark,
                note: 'Based on standard 1:6 mix ratio with dry volume factor 1.54',
                rows: [
                  ResultRowItem(
                    label: 'Cement Required',
                    value: '${_cementBags.toStringAsFixed(2)} bags',
                    isPrimary: true,
                  ),
                  ResultRowItem(
                    label: 'Sand Required',
                    value: '${_sandCubicMeters.toStringAsFixed(2)} m³',
                  ),
                  ResultRowItem(
                    label: 'Volume',
                    value: '${_volume.toStringAsFixed(2)} m³',
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
    _thicknessController.dispose();
    super.dispose();
  }
}
