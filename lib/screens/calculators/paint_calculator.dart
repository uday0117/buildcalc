import 'package:flutter/material.dart';

import '../../models/calculation.dart';
import '../../services/storage_service.dart';
import '../../widgets/input_field.dart';

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

  void _saveToHistory() {
    final calculation = Calculation(
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

    StorageService.saveToHistory(calculation);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paint Calculator',
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
                      Icons.format_paint,
                      size: 60,
                      color: Color(0xFF42A5F5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate paint quantity\nfor your walls',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            InputField(
              label: 'Room Length',
              hint: 'Enter length',
              controller: _lengthController,
              suffix: 'm',
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Wall Height',
              hint: 'Enter height',
              controller: _heightController,
              suffix: 'm',
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Door & Window Area',
              hint: 'Enter total area (optional)',
              controller: _doorWindowController,
              suffix: 'm²',
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Number of Coats',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _coats,
                          min: 1,
                          max: 3,
                          divisions: 2,
                          label: _coats.toInt().toString(),
                          activeColor: const Color(0xFFFF8C00),
                          onChanged: (value) {
                            setState(() {
                              _coats = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${_coats.toInt()} coats',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                        'Wall Area',
                        '${_wallArea.toStringAsFixed(2)} m²',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Paint Required',
                        '${_paintLiters.toStringAsFixed(2)} liters',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Number of Coats',
                        '${_coats.toInt()}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '(Includes 10% extra)',
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
    _heightController.dispose();
    _doorWindowController.dispose();
    super.dispose();
  }
}
