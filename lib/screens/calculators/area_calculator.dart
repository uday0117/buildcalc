import 'package:flutter/material.dart';
import '../../widgets/input_field.dart';
import '../../models/calculation.dart';
import '../../services/storage_service.dart';

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

  final List<String> _shapes = [
    'Rectangle',
    'Square',
    'Circle',
    'Triangle',
  ];

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter width')),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter height')),
          );
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

  void _saveToHistory() {
    final calculation = Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'area',
      title: 'Area Calculator',
      inputs: {
        'shape': _selectedShape,
        'dimension1': _dimension1Controller.text,
        'dimension2': _dimension2Controller.text,
        'dimension3': _dimension3Controller.text,
      },
      results: {
        'area': _area,
        'perimeter': _perimeter,
      },
      timestamp: DateTime.now(),
    );

    StorageService.saveToHistory(calculation);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Area Calculator',
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
                      Icons.square_foot,
                      size: 60,
                      color: Color(0xFF66BB6A),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate area and perimeter\nof different shapes',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Shape selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Shape',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedShape,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: _shapes.map((String shape) {
                        return DropdownMenuItem<String>(
                          value: shape,
                          child: Text(shape),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedShape = newValue!;
                          _reset();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Dimension 1
            InputField(
              label: _getDimension1Label(),
              hint: 'Enter ${_getDimension1Label().toLowerCase()}',
              controller: _dimension1Controller,
              suffix: 'm',
            ),
            const SizedBox(height: 16),

            // Dimension 2 (if needed)
            if (_selectedShape == 'Rectangle' || _selectedShape == 'Triangle')
              Column(
                children: [
                  InputField(
                    label: _getDimension2Label(),
                    hint: 'Enter ${_getDimension2Label().toLowerCase()}',
                    controller: _dimension2Controller,
                    suffix: 'm',
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Dimension 3 (for triangle perimeter)
            if (_selectedShape == 'Triangle')
              Column(
                children: [
                  InputField(
                    label: 'Third Side (optional)',
                    hint: 'For perimeter calculation',
                    controller: _dimension3Controller,
                    suffix: 'm',
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            const SizedBox(height: 8),

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
                        'Shape',
                        _selectedShape,
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Area',
                        '${_area.toStringAsFixed(2)} m²',
                      ),
                      if (_perimeter > 0) ...[
                        const SizedBox(height: 12),
                        _buildResultRow(
                          'Perimeter',
                          '${_perimeter.toStringAsFixed(2)} m',
                        ),
                      ],
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
    _dimension1Controller.dispose();
    _dimension2Controller.dispose();
    _dimension3Controller.dispose();
    super.dispose();
  }
}
