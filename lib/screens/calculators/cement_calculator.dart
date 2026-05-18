import 'package:flutter/material.dart';

import '../../models/calculation.dart';
import '../../services/storage_service.dart';
import '../../widgets/input_field.dart';

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

  void _saveToHistory() {
    final calculation = Calculation(
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

    StorageService.saveToHistory(calculation);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cement Calculator',
          style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                      Icons.architecture,
                      size: 60,
                      color: Color(0xFF795548),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate cement and sand\nrequired for construction',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            InputField(
              label: 'Length',
              hint: 'Enter length',
              controller: _lengthController,
              suffix: 'm',
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Width',
              hint: 'Enter width',
              controller: _widthController,
              suffix: 'm',
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Thickness',
              hint: 'Enter thickness',
              controller: _thicknessController,
              suffix: 'mm',
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Calculate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            if (_hasCalculated) ...[
              const SizedBox(height: 24),
              Card(
                color: const Color(0xFF1E3A5F),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Results',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(color: Colors.white54, height: 24),
                      _buildResultRow(
                        'Volume',
                        '${_volume.toStringAsFixed(2)} m³',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Cement Required',
                        '${_cementBags.toStringAsFixed(2)} bags',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Sand Required',
                        '${_sandCubicMeters.toStringAsFixed(2)} m³',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8C00),
          ),
        ),
      ],
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
