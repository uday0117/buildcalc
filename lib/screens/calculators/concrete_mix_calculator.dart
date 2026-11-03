import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/calculation.dart';
import '../../models/quotation.dart';
import '../../services/ad_service.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/calculator_header.dart';
import '../../widgets/input_field.dart';
import '../../widgets/result_card.dart';
import '../quotations/quotation_editor_screen.dart';

class ConcreteMixCalculator extends StatefulWidget {
  const ConcreteMixCalculator({super.key});

  @override
  State<ConcreteMixCalculator> createState() => _ConcreteMixCalculatorState();
}

class _ConcreteMixCalculatorState extends State<ConcreteMixCalculator> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _thicknessController = TextEditingController();
  final _directVolumeController = TextEditingController();

  String _inputMode = 'Dimensions'; // 'Dimensions' or 'Volume'
  String _unit = 'Meters'; // 'Meters' or 'Feet'
  String _selectedGrade = 'M20 (1 : 1.5 : 3)';
  String _structuralMember = 'Slab';

  // Standard mix ratios (Cement : Sand : Coarse Aggregate)
  final Map<String, List<double>> _mixRatios = {
    'M10 (1 : 3 : 6)': [1.0, 3.0, 6.0],
    'M15 (1 : 2 : 4)': [1.0, 2.0, 4.0],
    'M20 (1 : 1.5 : 3)': [1.0, 1.5, 3.0],
    'M25 (1 : 1 : 2)': [1.0, 1.0, 2.0],
    'M30 (1 : 0.75 : 1.5)': [1.0, 0.75, 1.5],
  };

  // Dry volume factor in civil engineering (wet concrete shrinks ~54%)
  static const double dryVolumeFactor = 1.54;
  // 5% allowance for site wastage
  static const double wastageFactor = 1.05;

  double _wetVolumeM3 = 0;
  double _wetVolumeCuFt = 0;
  double _dryVolumeM3 = 0;

  double _cementBags = 0;
  double _cementKg = 0;

  double _sandCuFt = 0;
  double _sandM3 = 0;
  double _sandTonnes = 0;
  double _sandBrass = 0;

  double _aggregateCuFt = 0;
  double _aggregateM3 = 0;
  double _aggregateTonnes = 0;
  double _aggregateBrass = 0;

  double _waterLiters = 0;
  bool _hasCalculated = false;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _thicknessController.dispose();
    _directVolumeController.dispose();
    super.dispose();
  }

  void _calculate() {
    double wetM3 = 0;

    if (_inputMode == 'Dimensions') {
      final length = double.tryParse(_lengthController.text) ?? 0;
      final width = double.tryParse(_widthController.text) ?? 0;
      final thickness = double.tryParse(_thicknessController.text) ?? 0;

      if (length <= 0 || width <= 0 || thickness <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid length, width, and thickness')),
        );
        return;
      }

      if (_unit == 'Meters') {
        wetM3 = length * width * thickness;
      } else {
        // Feet to m3 (1 m3 = 35.3147 ft3)
        final cuFt = length * width * thickness;
        wetM3 = cuFt / 35.3147;
      }
    } else {
      final directVol = double.tryParse(_directVolumeController.text) ?? 0;
      if (directVol <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid volume')),
        );
        return;
      }

      if (_unit == 'Meters') {
        wetM3 = directVol;
      } else {
        wetM3 = directVol / 35.3147;
      }
    }

    _wetVolumeM3 = wetM3;
    _wetVolumeCuFt = wetM3 * 35.3147;

    // Dry volume with 5% wastage
    _dryVolumeM3 = wetM3 * dryVolumeFactor * wastageFactor;

    final ratio = _mixRatios[_selectedGrade] ?? [1.0, 1.5, 3.0];
    final ratioSum = ratio[0] + ratio[1] + ratio[2];

    // Cement
    final cementVolumeM3 = (ratio[0] / ratioSum) * _dryVolumeM3;
    // 1 bag cement (50kg) = 0.035 m3
    _cementBags = cementVolumeM3 / 0.035;
    _cementKg = _cementBags * 50;

    // Sand (Fine Aggregate)
    _sandM3 = (ratio[1] / ratioSum) * _dryVolumeM3;
    _sandCuFt = _sandM3 * 35.3147;
    // Sand density ≈ 1600 kg/m3 (1.6 tonnes/m3)
    _sandTonnes = _sandM3 * 1.6;
    // 1 Brass = 100 cu ft
    _sandBrass = _sandCuFt / 100.0;

    // Coarse Aggregate (Gravel / Stone chips)
    _aggregateM3 = (ratio[2] / ratioSum) * _dryVolumeM3;
    _aggregateCuFt = _aggregateM3 * 35.3147;
    // Aggregate density ≈ 1500 kg/m3 (1.5 tonnes/m3)
    _aggregateTonnes = _aggregateM3 * 1.5;
    _aggregateBrass = _aggregateCuFt / 100.0;

    // Water (Water-cement ratio ≈ 0.50)
    _waterLiters = _cementKg * 0.50;

    setState(() {
      _hasCalculated = true;
    });

    _saveToHistory();
    AdService.showInterstitialAfterCalculation();
    ReviewService.checkAndPromptReview();
  }

  void _saveToHistory() {
    final calc = Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'concrete_mix',
      title: 'Concrete Mix ($_selectedGrade)',
      inputs: {
        'grade': _selectedGrade,
        'member': _structuralMember,
        'unit': _unit,
        'wet_volume_m3': _wetVolumeM3.toStringAsFixed(3),
      },
      results: {
        'cement_bags': _cementBags.toStringAsFixed(1),
        'sand_cuft': _sandCuFt.toStringAsFixed(1),
        'sand_brass': _sandBrass.toStringAsFixed(2),
        'aggregate_cuft': _aggregateCuFt.toStringAsFixed(1),
        'aggregate_brass': _aggregateBrass.toStringAsFixed(2),
        'water_liters': _waterLiters.toStringAsFixed(0),
      },
      timestamp: DateTime.now(),
    );
    StorageService.saveToHistory(calc);
  }

  void _shareResults() {
    final text = '''
🏗️ Concrete Mix Design - $_selectedGrade
Structural Element: $_structuralMember
Wet Volume: ${_wetVolumeM3.toStringAsFixed(2)} m³ (${_wetVolumeCuFt.toStringAsFixed(1)} cu ft)
─────────────────────────────
📦 Cement: ${_cementBags.ceil()} bags (50kg) / ${_cementKg.toStringAsFixed(0)} kg
🏖️ Sand: ${_sandCuFt.toStringAsFixed(1)} cu ft (${_sandBrass.toStringAsFixed(2)} Brass / ${_sandTonnes.toStringAsFixed(2)} Tonnes)
🪨 Aggregate: ${_aggregateCuFt.toStringAsFixed(1)} cu ft (${_aggregateBrass.toStringAsFixed(2)} Brass / ${_aggregateTonnes.toStringAsFixed(2)} Tonnes)
💧 Water: ${_waterLiters.toStringAsFixed(0)} Liters (w/c = 0.50)

Calculated via BuildCalc (Free Construction App)
''';
    Share.share(text);
  }

  void _createClientQuotation() {
    final items = [
      QuotationItem(
        id: 'quote_cem_${DateTime.now().millisecondsSinceEpoch}',
        description: 'Cement (Grade 53 OPC/PPC)',
        quantity: _cementBags.ceilToDouble(),
        unit: 'bags',
        unitPrice: 0,
      ),
      QuotationItem(
        id: 'quote_sand_${DateTime.now().millisecondsSinceEpoch}',
        description: 'River Sand / M-Sand',
        quantity: double.parse(_sandBrass.toStringAsFixed(2)),
        unit: 'brass',
        unitPrice: 0,
      ),
      QuotationItem(
        id: 'quote_agg_${DateTime.now().millisecondsSinceEpoch}',
        description: 'Coarse Aggregate (20mm)',
        quantity: double.parse(_aggregateBrass.toStringAsFixed(2)),
        unit: 'brass',
        unitPrice: 0,
      ),
      QuotationItem(
        id: 'quote_lab_${DateTime.now().millisecondsSinceEpoch}',
        description: 'RCC Concrete Casting Labor ($_structuralMember)',
        quantity: double.parse(_wetVolumeCuFt.toStringAsFixed(1)),
        unit: 'cu ft',
        unitPrice: 0,
      ),
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuotationEditorScreen(
          initialItems: items,
          initialProjectName: '$_structuralMember Concrete Casting',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Concrete Mix Design'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            tooltip: 'Save to Saved Calculations',
            onPressed: _hasCalculated
                ? () {
                    final calc = Calculation(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      type: 'concrete_mix',
                      title: 'Concrete Mix ($_selectedGrade)',
                      inputs: {'grade': _selectedGrade, 'member': _structuralMember},
                      results: {
                        'cement_bags': _cementBags.toStringAsFixed(1),
                        'sand_cuft': _sandCuFt.toStringAsFixed(1),
                        'aggregate_cuft': _aggregateCuFt.toStringAsFixed(1),
                      },
                      timestamp: DateTime.now(),
                    );
                    StorageService.saveCalculation(calc);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to Saved Calculations!')),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CalculatorHeader(
              icon: Icons.foundation_rounded,
              iconColor: Color(0xFF607D8B),
              title: 'Concrete Mix Design',
              description:
                  'Calculate exact bags of cement, sand volume (cu ft & brass), coarse aggregate & water required by concrete grade.',
              formulaHint: 'Wet to Dry Factor: 1.54 • IS 456 / ACI Standards',
            ),
            const SizedBox(height: 16),

            // Grade & Structural Member Selector
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white12
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGrade,
                            decoration: const InputDecoration(
                              labelText: 'Concrete Grade',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: _mixRatios.keys.map((grade) {
                              return DropdownMenuItem(
                                value: grade,
                                child: Text(grade, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedGrade = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _structuralMember,
                            decoration: const InputDecoration(
                              labelText: 'Structural Member',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Slab', child: Text('Slab')),
                              DropdownMenuItem(value: 'Beam', child: Text('Beam')),
                              DropdownMenuItem(value: 'Column', child: Text('Column')),
                              DropdownMenuItem(value: 'Footing', child: Text('Footing')),
                              DropdownMenuItem(value: 'PCC Bed', child: Text('PCC Bed')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _structuralMember = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'Dimensions', label: Text('Dimensions')),
                              ButtonSegment(value: 'Volume', label: Text('Total Volume')),
                            ],
                            selected: {_inputMode},
                            onSelectionChanged: (sel) {
                              setState(() => _inputMode = sel.first);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: _unit,
                          items: const [
                            DropdownMenuItem(value: 'Meters', child: Text('Meters (m)')),
                            DropdownMenuItem(value: 'Feet', child: Text('Feet (ft)')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _unit = v);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_inputMode == 'Dimensions') ...[
              InputField(
                controller: _lengthController,
                label: 'Length (${_unit == 'Meters' ? 'm' : 'ft'})',
                hint: 'e.g. 5.0',
                prefixIcon: Icons.straighten_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              InputField(
                controller: _widthController,
                label: 'Width (${_unit == 'Meters' ? 'm' : 'ft'})',
                hint: 'e.g. 4.0',
                prefixIcon: Icons.square_foot_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              InputField(
                controller: _thicknessController,
                label: 'Thickness / Depth (${_unit == 'Meters' ? 'm' : 'ft'})',
                hint: 'e.g. 0.15 (150mm)',
                prefixIcon: Icons.height_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ] else ...[
              InputField(
                controller: _directVolumeController,
                label: 'Total Concrete Volume (${_unit == 'Meters' ? 'm³' : 'cu ft'})',
                hint: 'e.g. 3.0',
                prefixIcon: Icons.view_in_ar_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Calculate Concrete Mix'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_hasCalculated) ...[
              ResultCard(
                title: 'Concrete Materials Breakdown',
                icon: Icons.inventory_2_rounded,
                rows: [
                  ResultRowItem(
                    label: 'Wet Volume',
                    value: '${_wetVolumeM3.toStringAsFixed(2)} m³ (${_wetVolumeCuFt.toStringAsFixed(1)} ft³)',
                  ),
                  ResultRowItem(
                    label: 'Dry Volume (incl. 5% waste)',
                    value: '${_dryVolumeM3.toStringAsFixed(2)} m³',
                  ),
                  ResultRowItem(
                    label: 'Cement Required',
                    value: '${_cementBags.ceil()} Bags (50kg)',
                    isPrimary: true,
                    subtitle: '≈ ${_cementKg.toStringAsFixed(0)} kg of cement',
                  ),
                  ResultRowItem(
                    label: 'Sand (Fine Aggregate)',
                    value: '${_sandBrass.toStringAsFixed(2)} Brass',
                    isPrimary: true,
                    subtitle:
                        '${_sandCuFt.toStringAsFixed(1)} cu ft • ${_sandTonnes.toStringAsFixed(2)} Tonnes • ${_sandM3.toStringAsFixed(2)} m³',
                  ),
                  ResultRowItem(
                    label: 'Coarse Aggregate (Gravel)',
                    value: '${_aggregateBrass.toStringAsFixed(2)} Brass',
                    isPrimary: true,
                    subtitle:
                        '${_aggregateCuFt.toStringAsFixed(1)} cu ft • ${_aggregateTonnes.toStringAsFixed(2)} Tonnes • ${_aggregateM3.toStringAsFixed(2)} m³',
                  ),
                  ResultRowItem(
                    label: 'Water (W/C = 0.50)',
                    value: '${_waterLiters.toStringAsFixed(0)} Liters',
                  ),
                ],
                note:
                    '1 Brass = 100 cubic feet (standard truck billing unit). Ensure proper vibration and curing for 14-28 days.',
                onShare: _shareResults,
              ),
              const SizedBox(height: 14),
              // Direct Quotation Generator Action
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF8C00)),
                label: const Text(
                  'Create Client Quotation from this Mix',
                  style: TextStyle(
                    color: Color(0xFFFF8C00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _createClientQuotation,
              ),
            ],
            const SizedBox(height: 24),
            const AppBannerAd(),
          ],
        ),
      ),
    );
  }
}
