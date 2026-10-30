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

class CostEstimator extends StatefulWidget {
  const CostEstimator({super.key});

  @override
  State<CostEstimator> createState() => _CostEstimatorState();
}

class _CostEstimatorState extends State<CostEstimator> {
  final _areaController = TextEditingController();
  String _constructionType = 'Basic';

  double _totalCost = 0;
  double _costPerSqFt = 0;
  bool _hasCalculated = false;

  final Map<String, double> _costRates = {
    'Basic': 1200, // ₹1200 per sq ft
    'Standard': 1800, // ₹1800 per sq ft
    'Premium': 2500, // ₹2500 per sq ft
    'Luxury': 3500, // ₹3500 per sq ft
  };

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 0;

    if (area > 0) {
      _costPerSqFt = _costRates[_constructionType] ?? 1200;
      _totalCost = area * _costPerSqFt;

      setState(() {
        _hasCalculated = true;
      });

      _saveToHistory();
      AdService.showInterstitialAfterCalculation();
      ReviewService.checkAndPromptReview();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter area')));
    }
  }

  Calculation _createCalculationModel() {
    return Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'cost_estimator',
      title: 'Construction Cost Estimator',
      inputs: {
        'area': _areaController.text,
        'construction_type': _constructionType,
      },
      results: {'total_cost': _totalCost, 'rate_per_sqft': _costPerSqFt},
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
      _areaController.clear();
      _constructionType = 'Basic';
      _totalCost = 0;
      _costPerSqFt = 0;
      _hasCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Construction Cost Estimator',
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
              icon: Icons.calculate_rounded,
              iconColor: Color(0xFFFF8C00),
              title: 'Construction Cost Budget',
              description: 'Estimate construction budget based on area and quality grade',
              formulaHint: 'Basic • Standard • Premium • Luxury tiers',
            ),
            const SizedBox(height: 20),

            InputField(
              label: 'Construction Area',
              hint: 'Enter total area',
              controller: _areaController,
              suffix: 'sq ft',
              prefixIcon: Icons.aspect_ratio_rounded,
            ),
            const SizedBox(height: 20),

            // Construction Type Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Construction Grade',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                ..._costRates.keys.map((type) {
                  final isSelected = _constructionType == type;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _constructionType = type;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(
                                    0xFFFF8C00,
                                  ).withValues(alpha: isDark ? 0.2 : 0.1)
                                : cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF8C00)
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade300),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? const Color(0xFFFF8C00)
                                    : (isDark ? Colors.white38 : Colors.grey),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? const Color(0xFFFF8C00)
                                            : (isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1E3A5F)),
                                      ),
                                    ),
                                    Text(
                                      '₹${_costRates[type]?.toStringAsFixed(0)} per sq ft',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
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
                'Calculate Cost',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),

            if (_hasCalculated) ...[
              const SizedBox(height: 24),
              ResultCard(
                title: 'Estimated Cost',
                icon: Icons.calculate_rounded,
                onSave: _bookmark,
                onShare: () {
                  Share.share(
                    'Construction Cost Estimate by BuildCalc:\n'
                    'Total Cost: ₹${_totalCost.toStringAsFixed(0)} (≈ ₹${(_totalCost / 100000).toStringAsFixed(2)} Lakhs)\n'
                    'Area: ${_areaController.text} sq ft\n'
                    'Grade: $_constructionType @ ₹${_costPerSqFt.toStringAsFixed(0)}/sq ft\n\n'
                    'Calculated with BuildCalc: https://play.google.com/store/apps/details?id=com.uksolutions.buildcalc',
                    subject: 'BuildCalc - Cost Estimate',
                  );
                },
                note:
                    'Approximate estimate. Actual costs may vary based on location, materials, and contractor rates.',
                rows: [
                  ResultRowItem(
                    label: 'Total Cost',
                    value: '₹${_totalCost.toStringAsFixed(0)}',
                    isPrimary: true,
                    subtitle:
                        '≈ ₹${(_totalCost / 100000).toStringAsFixed(2)} Lakhs',
                  ),
                  ResultRowItem(
                    label: 'Construction Grade',
                    value: _constructionType,
                  ),
                  ResultRowItem(
                    label: 'Rate per sq ft',
                    value: '₹${_costPerSqFt.toStringAsFixed(0)}',
                  ),
                  ResultRowItem(
                    label: 'Area',
                    value: '${_areaController.text} sq ft',
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
    _areaController.dispose();
    super.dispose();
  }
}
