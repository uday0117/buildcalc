import 'package:flutter/material.dart';
import '../../widgets/input_field.dart';
import '../../models/calculation.dart';
import '../../services/storage_service.dart';

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

  void _saveToHistory() {
    final calculation = Calculation(
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

    StorageService.saveToHistory(calculation);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Brick Calculator',
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
                      Icons.grid_4x4,
                      size: 60,
                      color: Color(0xFFD32F2F),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate number of bricks\nrequired for wall construction',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            InputField(
              label: 'Wall Length',
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
              label: 'Wall Thickness',
              hint: 'Enter thickness (115/230/345)',
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
                        'Wall Area',
                        '${_wallArea.toStringAsFixed(2)} m²',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Bricks Required',
                        '${_bricksRequired.toStringAsFixed(0)} bricks',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '(Includes 10% wastage)',
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
    _thicknessController.dispose();
    super.dispose();
  }
}
