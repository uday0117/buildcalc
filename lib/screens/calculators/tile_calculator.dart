import 'package:flutter/material.dart';

import '../../models/calculation.dart';
import '../../services/storage_service.dart';
import '../../widgets/input_field.dart';

class TileCalculator extends StatefulWidget {
  const TileCalculator({super.key});

  @override
  State<TileCalculator> createState() => _TileCalculatorState();
}

class _TileCalculatorState extends State<TileCalculator> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _tileLengthController = TextEditingController();
  final _tileWidthController = TextEditingController();

  double _tilesRequired = 0;
  double _areaToTile = 0;
  double _boxes = 0;
  bool _hasCalculated = false;

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final tileLength = double.tryParse(_tileLengthController.text) ?? 0;
    final tileWidth = double.tryParse(_tileWidthController.text) ?? 0;

    if (length > 0 && width > 0 && tileLength > 0 && tileWidth > 0) {
      // Calculate area to tile
      _areaToTile = length * width;

      // Convert tile size from mm to meters
      final tileLengthM = tileLength / 1000;
      final tileWidthM = tileWidth / 1000;

      // Calculate area of one tile
      final tileArea = tileLengthM * tileWidthM;

      // Calculate number of tiles
      _tilesRequired = _areaToTile / tileArea;

      // Add 10% wastage
      _tilesRequired = _tilesRequired * 1.1;

      // Calculate boxes (assuming 10 tiles per box)
      _boxes = _tilesRequired / 10;

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

  void _saveToHistory() {
    final calculation = Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'tile',
      title: 'Tile Calculator',
      inputs: {
        'length': _lengthController.text,
        'width': _widthController.text,
        'tile_length': _tileLengthController.text,
        'tile_width': _tileWidthController.text,
      },
      results: {
        'tiles_required': _tilesRequired,
        'area_to_tile': _areaToTile,
        'boxes': _boxes,
      },
      timestamp: DateTime.now(),
    );

    StorageService.saveToHistory(calculation);
  }

  void _reset() {
    setState(() {
      _lengthController.clear();
      _widthController.clear();
      _tileLengthController.clear();
      _tileWidthController.clear();
      _tilesRequired = 0;
      _areaToTile = 0;
      _boxes = 0;
      _hasCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tile Calculator',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
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
                      Icons.dashboard,
                      size: 60,
                      color: Color(0xFF8D6E63),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate tiles required\nfor flooring',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Floor Dimensions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 12),

            InputField(
              label: 'Floor Length',
              hint: 'Enter length',
              controller: _lengthController,
              suffix: 'm',
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Floor Width',
              hint: 'Enter width',
              controller: _widthController,
              suffix: 'm',
            ),
            const SizedBox(height: 24),

            const Text(
              'Tile Dimensions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 12),

            InputField(
              label: 'Tile Length',
              hint: 'Enter tile length (e.g., 600)',
              controller: _tileLengthController,
              suffix: 'mm',
            ),
            const SizedBox(height: 16),

            InputField(
              label: 'Tile Width',
              hint: 'Enter tile width (e.g., 600)',
              controller: _tileWidthController,
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
                        'Floor Area',
                        '${_areaToTile.toStringAsFixed(2)} m²',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Tiles Required',
                        '${_tilesRequired.toStringAsFixed(0)} tiles',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Boxes Required',
                        '${_boxes.toStringAsFixed(1)} boxes',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '(Includes 10% wastage)',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
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
          style: const TextStyle(fontSize: 16, color: Colors.white70),
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
    _tileLengthController.dispose();
    _tileWidthController.dispose();
    super.dispose();
  }
}
