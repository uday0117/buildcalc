import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/calculation.dart';
import '../../models/calculators/staircase_calculation.dart';
import '../../services/ad_service.dart';
import '../../services/calculators/staircase_calculator_service.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/calculators/staircase_sketch_painter.dart';
import '../../widgets/input_field.dart';
import '../../widgets/result_card.dart';
import '../../widgets/unit_selector.dart';

class StaircaseCalculator extends StatefulWidget {
  const StaircaseCalculator({super.key});

  @override
  State<StaircaseCalculator> createState() => _StaircaseCalculatorState();
}

class _StaircaseCalculatorState extends State<StaircaseCalculator> {
  final _heightController = TextEditingController(text: '3.0');
  final _riserController = TextEditingController(text: '160');
  final _treadController = TextEditingController(text: '280');
  final _widthController = TextEditingController(text: '1.0');
  final _waistController = TextEditingController(text: '150');
  final _landingController = TextEditingController(text: '1.0');

  ConcreteGrade _selectedGrade = ConcreteGrade.m20;
  int _flightCount = 1;
  StaircaseResult? _result;
  StaircaseInput? _lastInput;
  bool _isFirstInit = true;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final height = double.tryParse(_heightController.text) ?? 0;
    final riser = double.tryParse(_riserController.text) ?? 0;
    final tread = double.tryParse(_treadController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final waist = double.tryParse(_waistController.text) ?? 0;
    final landing = double.tryParse(_landingController.text) ?? 0;

    final input = StaircaseInput(
      totalHeight: height,
      targetRiser: riser,
      targetTread: tread,
      flightWidth: width,
      waistThickness: waist,
      landingLength: landing,
      flightCount: _flightCount,
      concreteGrade: _selectedGrade,
    );

    final res = StaircaseCalculatorService.calculate(input);

    setState(() {
      _lastInput = input;
      _result = res;
    });

    if (res.isValid) {
      _saveToHistory(res);
      if (!_isFirstInit) {
        AdService.showInterstitialAfterCalculation();
        ReviewService.checkAndPromptReview();
      }
      _isFirstInit = false;
    } else if (res.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.errorMessage!)));
    }
  }

  Calculation _createCalculationModel(StaircaseResult res) {
    return Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'staircase',
      title: 'Staircase Calculator',
      inputs: {
        'total_height': _heightController.text,
        'target_riser': _riserController.text,
        'target_tread': _treadController.text,
        'flight_width': _widthController.text,
        'waist_thickness': _waistController.text,
        'landing_length': _landingController.text,
        'flight_type': _flightCount == 1 ? 'Straight' : 'Dog-legged',
        'concrete_grade': _selectedGrade.name,
      },
      results: {
        'total_risers': res.totalRisers,
        'total_treads': res.totalTreads,
        'actual_riser_mm': res.actualRiserMm,
        'actual_tread_mm': res.actualTreadMm,
        'pitch_angle_deg': res.pitchAngleDegrees,
        'total_concrete_m3': res.totalWetVolumeM3,
        'cement_bags': res.cementBags,
        'sand_m3': res.sandM3,
        'aggregate_m3': res.aggregateM3,
        'estimated_steel_kg': res.estimatedSteelKg,
      },
      timestamp: DateTime.now(),
    );
  }

  void _saveToHistory(StaircaseResult res) {
    StorageService.saveToHistory(_createCalculationModel(res));
  }

  Future<void> _bookmark() async {
    if (_result == null || !_result!.isValid) return;
    await StorageService.saveCalculation(_createCalculationModel(_result!));
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
      _heightController.text = '3.0';
      _riserController.text = '160';
      _treadController.text = '280';
      _widthController.text = '1.0';
      _waistController.text = '150';
      _landingController.text = '1.0';
      _flightCount = 1;
      _selectedGrade = ConcreteGrade.m20;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Staircase Calculator',
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
            Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.stairs_rounded,
                      size: 48,
                      color: Color(0xFFFF8C00),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Staircase Dimensions & RCC Estimation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calculate risers, treads, flight slope, and concrete/steel quantities with visual architectural cross-section.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Flight Configuration Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Staircase Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                UnitSelector<int>(
                  values: const [1, 2],
                  selectedValue: _flightCount,
                  labelBuilder: (val) =>
                      val == 1 ? 'Single Flight' : 'Dog-legged (2 Flights)',
                  onSelected: (val) {
                    setState(() => _flightCount = val);
                    _calculate();
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Concrete Grade Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Concrete Mix',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                UnitSelector<ConcreteGrade>(
                  values: ConcreteGrade.values,
                  selectedValue: _selectedGrade,
                  labelBuilder: (val) => val.name,
                  onSelected: (val) {
                    setState(() => _selectedGrade = val);
                    _calculate();
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Inputs
            InputField(
              label: 'Total Vertical Rise / Floor Height',
              hint: 'e.g. 3.0',
              controller: _heightController,
              suffix: 'm',
              prefixIcon: Icons.height_rounded,
              helperText: 'Finished floor to finished floor vertical rise',
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'Target Riser',
                    hint: '150-180',
                    controller: _riserController,
                    suffix: 'mm',
                    prefixIcon: Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputField(
                    label: 'Target Tread',
                    hint: '250-300',
                    controller: _treadController,
                    suffix: 'mm',
                    prefixIcon: Icons.arrow_forward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'Flight Width',
                    hint: 'e.g. 1.0',
                    controller: _widthController,
                    suffix: 'm',
                    prefixIcon: Icons.straighten_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputField(
                    label: 'Waist Slab Thickness',
                    hint: 'e.g. 150',
                    controller: _waistController,
                    suffix: 'mm',
                    prefixIcon: Icons.layers_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            InputField(
              label: 'Landing Length',
              hint: 'e.g. 1.0',
              controller: _landingController,
              suffix: 'm',
              prefixIcon: Icons.space_bar_rounded,
              helperText: 'Intermediate or top landing slab length',
            ),
            const SizedBox(height: 20),

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
                'Calculate Staircase',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            if (res != null && res.isValid && _lastInput != null) ...[
              const SizedBox(height: 24),

              // Visual Dimensioned Sketch
              const Text(
                'Dimensioned Architectural Cross-Section',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              StaircaseSketchWidget(input: _lastInput!, result: res),

              // Warnings banner if any
              if (res.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Design Comfort & Code Considerations',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.amber[200]
                                  : Colors.amber[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...res.warnings.map(
                        (w) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• $w',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Geometric Results
              ResultCard(
                title: 'Staircase Dimensions',
                icon: Icons.square_foot_rounded,
                onSave: _bookmark,
                onShare: () {
                  Share.share(
                    'Staircase Sizing by BuildCalc:\n'
                    'Total Height: ${_heightController.text} m\n'
                    'Risers: ${res.totalRisers} (${res.actualRiserMm.toStringAsFixed(1)} mm)\n'
                    'Treads: ${res.totalTreads} (${res.actualTreadMm.toStringAsFixed(0)} mm)\n'
                    'Going Run: ${res.totalGoingMeters.toStringAsFixed(2)} m\n'
                    'Concrete: ${res.totalWetVolumeM3.toStringAsFixed(2)} m³\n\n'
                    'Calculated with BuildCalc: https://play.google.com/store/apps/details?id=com.uksolutions.buildcalc',
                    subject: 'BuildCalc - Staircase Calculation',
                  );
                },
                note:
                    'Step formula: Blondel rule (2R + T = ${res.blondelComfortIndexMm.toStringAsFixed(0)} mm)',
                rows: [
                  ResultRowItem(
                    label: 'Number of Risers',
                    value:
                        '${res.totalRisers} risers (${res.actualRiserMm.toStringAsFixed(1)} mm each)',
                    isPrimary: true,
                  ),
                  ResultRowItem(
                    label: 'Number of Treads',
                    value:
                        '${res.totalTreads} treads (${res.actualTreadMm.toStringAsFixed(0)} mm run)',
                  ),
                  ResultRowItem(
                    label: 'Total Flight Going (Run)',
                    value: '${res.totalGoingMeters.toStringAsFixed(2)} m',
                  ),
                  ResultRowItem(
                    label: 'Waist Slab Incline Length',
                    value: '${res.inclineLengthMeters.toStringAsFixed(2)} m',
                  ),
                  ResultRowItem(
                    label: 'Pitch / Slope Angle',
                    value: '${res.pitchAngleDegrees.toStringAsFixed(1)}°',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Materials Estimation Card
              ResultCard(
                title: 'Concrete & Materials Estimate',
                icon: Icons.layers_rounded,
                note:
                    'Quantities include 54% dry volume factor for ${_selectedGrade.name}',
                rows: [
                  ResultRowItem(
                    label: 'Total Wet Concrete',
                    value: '${res.totalWetVolumeM3.toStringAsFixed(2)} m³',
                    isPrimary: true,
                  ),
                  ResultRowItem(
                    label: 'Cement (50 kg bags)',
                    value: '${res.cementBags.toStringAsFixed(1)} bags',
                  ),
                  ResultRowItem(
                    label: 'Sand',
                    value:
                        '${res.sandM3.toStringAsFixed(2)} m³ (${res.sandTonnes.toStringAsFixed(2)} tonnes)',
                  ),
                  ResultRowItem(
                    label: 'Coarse Aggregate',
                    value:
                        '${res.aggregateM3.toStringAsFixed(2)} m³ (${res.aggregateTonnes.toStringAsFixed(2)} tonnes)',
                  ),
                  ResultRowItem(
                    label: 'Estimated Steel Rebar',
                    value:
                        '~${res.estimatedSteelKg.toStringAsFixed(0)} kg (rule of thumb ~85 kg/m³)',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Professional Engineering Disclaimer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Disclaimer: This calculator is intended for material estimation and preliminary dimensional planning only. It is not a certified structural design. Sizing, steel reinforcement diameter, and bar bending schedule must be engineered and approved in accordance with local structural building codes.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
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
    _heightController.dispose();
    _riserController.dispose();
    _treadController.dispose();
    _widthController.dispose();
    _waistController.dispose();
    _landingController.dispose();
    super.dispose();
  }
}
