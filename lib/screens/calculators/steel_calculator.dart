import 'package:flutter/material.dart';

import '../../models/calculation.dart';
import '../../services/storage_service.dart';
import '../../widgets/input_field.dart';

class SteelCalculator extends StatefulWidget {
  const SteelCalculator({super.key});

  @override
  State<SteelCalculator> createState() => _SteelCalculatorState();
}

class _SteelCalculatorState extends State<SteelCalculator> {
  final _lengthController = TextEditingController();
  final _diameterController = TextEditingController();
  final _quantityController = TextEditingController();
  
  double _totalWeight = 0;
  double _weightPerBar = 0;
  bool _hasCalculated = false;

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final diameter = double.tryParse(_diameterController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 1;

    if (length > 0 && diameter > 0) {
      // Formula: Weight = D² × L / 162
      // Where D = diameter in mm, L = length in meters
      _weightPerBar = (diameter * diameter * length) / 162;
      
      _totalWeight = _weightPerBar * quantity;

      setState(() {
        _hasCalculated = true;
      });

      _saveToHistory();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter length and diameter')),
      );
    }
  }

  void _saveToHistory() {
    final calculation = Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'steel',
      title: 'Steel Calculator',
      inputs: {
        'length': _lengthController.text,
        'diameter': _diameterController.text,
        'quantity': _quantityController.text,
      },
      results: {
        'weight_per_bar': _weightPerBar,
        'total_weight': _totalWeight,
      },
      timestamp: DateTime.now(),
    );

    StorageService.saveToHistory(calculation);
  }

  void _reset() {
    setState(() {
      _lengthController.clear();
      _diameterController.clear();
      _quantityController.clear();
      _totalWeight = 0;
      _weightPerBar = 0;
      _hasCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Steel Calculator',
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
                      Icons.settings_input_antenna,
                      size: 60,
                      color: Color(0xFF607D8B),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate steel bar weight\nfor construction',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            InputField(
              label: 'Bar Length',
              hint: 'Enter length',
              controller: _lengthController,
              suffix: 'm',
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Bar Diameter',
              hint: 'Enter diameter (8/10/12/16/20/25)',
              controller: _diameterController,
              suffix: 'mm',
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Number of Bars',
              hint: 'Enter quantity',
              controller: _quantityController,
              suffix: 'bars',
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
                        'Weight per Bar',
                        '${_weightPerBar.toStringAsFixed(2)} kg',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Total Weight',
                        '${_totalWeight.toStringAsFixed(2)} kg',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'In Tonnes',
                        '${(_totalWeight / 1000).toStringAsFixed(3)} tonnes',
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
    _diameterController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
