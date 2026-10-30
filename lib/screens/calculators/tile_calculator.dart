import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/calculation.dart';
import '../../services/ad_service.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/calculator_header.dart';
import '../../widgets/input_field.dart';
import '../../widgets/result_card.dart';

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
      AdService.showInterstitialAfterCalculation();
      ReviewService.checkAndPromptReview();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter all values')));
    }
  }

  Calculation _createCalculationModel() {
    return Calculation(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionHeaderColor = isDark
        ? const Color(0xFFFFA726)
        : const Color(0xFF1E3A5F);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tile Calculator',
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
            const CalculatorHeader(
              icon: Icons.dashboard_rounded,
              iconColor: Color(0xFF8D6E63),
              title: 'Floor & Wall Tile Estimator',
              description: 'Calculate tile counts and packaging boxes with wastage',
              formulaHint: 'Standard: 10% cutting wastage • 10 tiles/box',
            ),
            const SizedBox(height: 20),

            Text(
              'Floor Dimensions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: sectionHeaderColor,
              ),
            ),
            const SizedBox(height: 12),

            InputField(
              label: 'Floor Length',
              hint: 'Enter length',
              controller: _lengthController,
              suffix: 'm',
              prefixIcon: Icons.straighten_rounded,
            ),
            const SizedBox(height: 14),

            InputField(
              label: 'Floor Width',
              hint: 'Enter width',
              controller: _widthController,
              suffix: 'm',
              prefixIcon: Icons.square_foot_rounded,
            ),
            const SizedBox(height: 20),

            Text(
              'Tile Dimensions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: sectionHeaderColor,
              ),
            ),
            const SizedBox(height: 12),

            InputField(
              label: 'Tile Length',
              hint: 'Enter tile length (e.g. 600)',
              controller: _tileLengthController,
              suffix: 'mm',
              prefixIcon: Icons.crop_portrait_rounded,
            ),
            const SizedBox(height: 14),

            InputField(
              label: 'Tile Width',
              hint: 'Enter tile width (e.g. 600)',
              controller: _tileWidthController,
              suffix: 'mm',
              prefixIcon: Icons.crop_landscape_rounded,
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
                icon: Icons.dashboard_rounded,
                onSave: _bookmark,
                onShare: () {
                  Share.share(
                    'Tile Calculation by BuildCalc:\n'
                    'Tiles Required: ${_tilesRequired.toStringAsFixed(0)} tiles (incl. 10% wastage)\n'
                    'Boxes Required: ${_boxes.toStringAsFixed(1)} boxes\n'
                    'Total Floor Area: ${_areaToTile.toStringAsFixed(2)} m²\n\n'
                    'Calculated with BuildCalc: https://play.google.com/store/apps/details?id=com.uksolutions.buildcalc',
                    subject: 'BuildCalc - Tile Calculation',
                  );
                },
                note:
                    'Includes 10% wastage for cutting. Box count assumes 10 tiles/box.',
                rows: [
                  ResultRowItem(
                    label: 'Tiles Required',
                    value: '${_tilesRequired.toStringAsFixed(0)} tiles',
                    isPrimary: true,
                  ),
                  ResultRowItem(
                    label: 'Boxes Required',
                    value: '${_boxes.toStringAsFixed(1)} boxes',
                  ),
                  ResultRowItem(
                    label: 'Total Floor Area',
                    value: '${_areaToTile.toStringAsFixed(2)} m²',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: AppBannerAd(),
      ),
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
