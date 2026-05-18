import 'package:flutter/material.dart';
import '../../widgets/input_field.dart';
import '../../models/calculation.dart';
import '../../services/storage_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all values')),
      );
    }
  }

  void _saveToHistory() {
    final calculation = Calculation(
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

    StorageService.saveToHistory(calculation);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sand Calculator',
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
                      Icons.terrain,
                      size: 60,
                      color: Color(0xFFFFA726),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate sand quantity\nrequired for construction',
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
              label: 'Depth',
              hint: 'Enter depth',
              controller: _depthController,
              suffix: 'm',
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
                        'Sand Required',
                        '${_sandCubicMeters.toStringAsFixed(2)} m³',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'In Cubic Feet',
                        '${_sandCubicFeet.toStringAsFixed(2)} ft³',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'In Tonnes',
                        '${_sandTonnes.toStringAsFixed(2)} tonnes',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '(Includes 20% wastage)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
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
    _depthController.dispose();
    super.dispose();
  }
}
