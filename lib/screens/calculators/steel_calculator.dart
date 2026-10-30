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
      AdService.showInterstitialAfterCalculation();
      ReviewService.checkAndPromptReview();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter length and diameter')),
      );
    }
  }

  Calculation _createCalculationModel() {
    return Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'steel',
      title: 'Steel Calculator',
      inputs: {
        'length': _lengthController.text,
        'diameter': _diameterController.text,
        'quantity': _quantityController.text,
      },
      results: {'weight_per_bar': _weightPerBar, 'total_weight': _totalWeight},
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
              icon: Icons.fence_rounded,
              iconColor: Color(0xFF607D8B),
              title: 'TMT Steel & Rebar Weight',
              description: 'Calculate unit weight per bar and total steel in kg & tonnes',
              formulaHint: 'Standard: D² × L / 162 (D in mm, L in m)',
            ),
            const SizedBox(height: 20),

            InputField(
              label: 'Bar Length',
              hint: 'Enter length',
              controller: _lengthController,
              suffix: 'm',
              prefixIcon: Icons.straighten_rounded,
            ),
            const SizedBox(height: 14),

            InputField(
              label: 'Bar Diameter',
              hint: 'Enter diameter (8/10/12/16/20/25)',
              controller: _diameterController,
              suffix: 'mm',
              prefixIcon: Icons.panorama_fish_eye_rounded,
              helperText:
                  'Common rebar: 8mm, 10mm, 12mm, 16mm, 20mm, 25mm, 32mm',
            ),
            const SizedBox(height: 14),

            InputField(
              label: 'Number of Bars',
              hint: 'Enter quantity',
              controller: _quantityController,
              suffix: 'bars',
              prefixIcon: Icons.format_list_numbered_rounded,
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
                icon: Icons.fence_rounded,
                onSave: _bookmark,
                onShare: () {
                  Share.share(
                    'Steel Rebar Calculation by BuildCalc:\n'
                    'Total Weight: ${_totalWeight.toStringAsFixed(2)} kg (${(_totalWeight / 1000).toStringAsFixed(3)} tonnes)\n'
                    'Weight per Bar: ${_weightPerBar.toStringAsFixed(2)} kg\n\n'
                    'Calculated with BuildCalc: https://play.google.com/store/apps/details?id=com.uksolutions.buildcalc',
                    subject: 'BuildCalc - Steel Rebar Calculation',
                  );
                },
                note:
                    'Standard formula: Weight = D² × L / 162 (D in mm, L in meters)',
                rows: [
                  ResultRowItem(
                    label: 'Total Weight',
                    value: '${_totalWeight.toStringAsFixed(2)} kg',
                    isPrimary: true,
                  ),
                  ResultRowItem(
                    label: 'In Tonnes',
                    value: '${(_totalWeight / 1000).toStringAsFixed(3)} tonnes',
                  ),
                  ResultRowItem(
                    label: 'Weight per Bar',
                    value: '${_weightPerBar.toStringAsFixed(2)} kg',
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
    _diameterController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
