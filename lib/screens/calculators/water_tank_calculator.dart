import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/calculation.dart';
import '../../services/ad_service.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/calculator_header.dart';
import '../../widgets/input_field.dart';
import '../../widgets/result_card.dart';

class WaterTankCalculator extends StatefulWidget {
  const WaterTankCalculator({super.key});

  @override
  State<WaterTankCalculator> createState() => _WaterTankCalculatorState();
}

class _WaterTankCalculatorState extends State<WaterTankCalculator> {
  // Mode: 'By Dimensions' or 'By Occupants'
  String _calcMode = 'By Dimensions';
  String _tankShape = 'Rectangular'; // 'Rectangular' or 'Cylindrical'
  String _unit = 'Meters'; // 'Meters' or 'Feet'

  // Dimensions controllers
  final _lengthController = TextEditingController(text: '2.5');
  final _widthController = TextEditingController(text: '2.0');
  final _depthController = TextEditingController(text: '1.8');
  final _diameterController = TextEditingController(text: '2.0');

  // Occupancy controllers
  final _occupantsController = TextEditingController(text: '5');
  final _dailyPerHeadController = TextEditingController(text: '135'); // 135 L/person/day
  final _reserveDaysController = TextEditingController(text: '2');

  // Results
  double _capacityLiters = 0;
  double _capacityGallonsUS = 0;
  double _capacityCuFt = 0;
  double _capacityM3 = 0;

  double _excavationVolumeCuM = 0;
  double _plasterAreaSqM = 0;
  int _estimatedBricks = 0;
  double _cementBagsForPlaster = 0;
  bool _hasCalculated = false;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _diameterController.dispose();
    _occupantsController.dispose();
    _dailyPerHeadController.dispose();
    _reserveDaysController.dispose();
    super.dispose();
  }

  void _calculate() {
    double volM3 = 0;

    if (_calcMode == 'By Occupants') {
      final people = double.tryParse(_occupantsController.text) ?? 0;
      final dailyPerHead = double.tryParse(_dailyPerHeadController.text) ?? 135;
      final days = double.tryParse(_reserveDaysController.text) ?? 1;

      if (people <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter number of occupants')),
        );
        return;
      }

      final totalLiters = people * dailyPerHead * days;
      volM3 = totalLiters / 1000.0;

      // Suggest dimensions: assume depth of 1.8m and aspect ratio 1.3
      final area = volM3 / 1.8;
      final width = math.sqrt(area / 1.3);
      final length = width * 1.3;

      _lengthController.text = length.toStringAsFixed(2);
      _widthController.text = width.toStringAsFixed(2);
      _depthController.text = '1.80';
    } else {
      if (_tankShape == 'Rectangular') {
        final length = double.tryParse(_lengthController.text) ?? 0;
        final width = double.tryParse(_widthController.text) ?? 0;
        final depth = double.tryParse(_depthController.text) ?? 0;

        if (length <= 0 || width <= 0 || depth <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter valid dimensions')),
          );
          return;
        }

        if (_unit == 'Meters') {
          volM3 = length * width * depth;
        } else {
          final cuFt = length * width * depth;
          volM3 = cuFt / 35.3147;
        }
      } else {
        final dia = double.tryParse(_diameterController.text) ?? 0;
        final depth = double.tryParse(_depthController.text) ?? 0;

        if (dia <= 0 || depth <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter valid diameter and depth')),
          );
          return;
        }

        final radius = dia / 2.0;
        if (_unit == 'Meters') {
          volM3 = math.pi * radius * radius * depth;
        } else {
          final cuFt = math.pi * radius * radius * depth;
          volM3 = cuFt / 35.3147;
        }
      }
    }

    _capacityM3 = volM3;
    _capacityLiters = volM3 * 1000.0;
    _capacityGallonsUS = _capacityLiters * 0.264172;
    _capacityCuFt = volM3 * 35.3147;

    // Construction estimations (assuming 9-inch / 0.23m brick wall or 150mm RCC)
    final l = double.tryParse(_lengthController.text) ?? 2.0;
    final w = double.tryParse(_widthController.text) ?? 1.5;
    final d = double.tryParse(_depthController.text) ?? 1.5;

    // Plaster area (Floor + 4 vertical walls)
    _plasterAreaSqM = (l * w) + (2 * (l + w) * d);
    // Estimated bricks for 9-inch wall around tank perimeter
    final wallPerimeter = 2 * (l + w);
    final wallVolumeM3 = wallPerimeter * d * 0.23;
    _estimatedBricks = (wallVolumeM3 * 500).round(); // ~500 bricks per m3

    // Excavation: tank dimensions + 0.3m offset on each side
    _excavationVolumeCuM = (l + 0.6) * (w + 0.6) * (d + 0.3);

    // Waterproof plaster cement (1:3 mix, 12mm thickness): ~0.25 bags per sq m
    _cementBagsForPlaster = _plasterAreaSqM * 0.25;

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
      type: 'water_tank',
      title: 'Water Tank Capacity',
      inputs: {
        'shape': _tankShape,
        'unit': _unit,
        'liters': _capacityLiters.toStringAsFixed(0),
      },
      results: {
        'liters': _capacityLiters.toStringAsFixed(0),
        'gallons': _capacityGallonsUS.toStringAsFixed(0),
        'volume_m3': _capacityM3.toStringAsFixed(2),
        'cuft': _capacityCuFt.toStringAsFixed(1),
      },
      timestamp: DateTime.now(),
    );
    StorageService.saveToHistory(calc);
  }

  void _shareResults() {
    final text = '''
💧 Water Tank & Sump Sizing
Capacity: ${NumberFormat('#,##0').format(_capacityLiters)} Liters (${NumberFormat('#,##0').format(_capacityGallonsUS)} US Gal)
Volume: ${_capacityM3.toStringAsFixed(2)} m³ (${_capacityCuFt.toStringAsFixed(1)} cu ft)
─────────────────────────────
⛏️ Estimated Excavation: ${_excavationVolumeCuM.toStringAsFixed(2)} m³
🧱 Brick Count (9" wall): $_estimatedBricks bricks
🎨 Waterproof Plaster Area: ${_plasterAreaSqM.toStringAsFixed(1)} m² (~${_cementBagsForPlaster.ceil()} bags cement)

Calculated via BuildCalc (Free Construction App)
''';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tank / Sump Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CalculatorHeader(
              icon: Icons.water_drop_rounded,
              iconColor: Color(0xFF0288D1),
              title: 'Water Tank & Sump Calculator',
              description:
                  'Calculate water storage capacity in Liters & Gallons, plus required brickwork, plaster area & excavation volume.',
              formulaHint: '1 m³ = 1,000 Liters = 264.17 US Gallons',
            ),
            const SizedBox(height: 16),

            // Mode Toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'By Dimensions',
                  label: Text('By Dimensions'),
                  icon: Icon(Icons.straighten_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 'By Occupants',
                  label: Text('By Family Size'),
                  icon: Icon(Icons.group_rounded, size: 16),
                ),
              ],
              selected: {_calcMode},
              onSelectionChanged: (sel) {
                setState(() => _calcMode = sel.first);
              },
            ),
            const SizedBox(height: 16),

            if (_calcMode == 'By Occupants') ...[
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
                      InputField(
                        controller: _occupantsController,
                        label: 'Number of Residents / Occupants',
                        hint: 'e.g. 5',
                        prefixIcon: Icons.people_outline_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      InputField(
                        controller: _dailyPerHeadController,
                        label: 'Daily Usage per Person (Liters)',
                        hint: 'Standard: 135 L',
                        prefixIcon: Icons.water_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      InputField(
                        controller: _reserveDaysController,
                        label: 'Reserve Days (e.g. 1 to 3 days)',
                        hint: 'e.g. 2',
                        prefixIcon: Icons.calendar_today_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
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
                              initialValue: _tankShape,
                              decoration: const InputDecoration(labelText: 'Tank Shape'),
                              items: const [
                                DropdownMenuItem(value: 'Rectangular', child: Text('Rectangular Sump')),
                                DropdownMenuItem(value: 'Cylindrical', child: Text('Cylindrical Tank')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _tankShape = v);
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
                      const SizedBox(height: 12),
                      if (_tankShape == 'Rectangular') ...[
                        InputField(
                          controller: _lengthController,
                          label: 'Length (${_unit == 'Meters' ? 'm' : 'ft'})',
                          hint: 'e.g. 2.5',
                          prefixIcon: Icons.straighten_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 10),
                        InputField(
                          controller: _widthController,
                          label: 'Width (${_unit == 'Meters' ? 'm' : 'ft'})',
                          hint: 'e.g. 2.0',
                          prefixIcon: Icons.square_foot_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 10),
                        InputField(
                          controller: _depthController,
                          label: 'Water Depth (${_unit == 'Meters' ? 'm' : 'ft'})',
                          hint: 'e.g. 1.8',
                          prefixIcon: Icons.height_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ] else ...[
                        InputField(
                          controller: _diameterController,
                          label: 'Diameter (${_unit == 'Meters' ? 'm' : 'ft'})',
                          hint: 'e.g. 2.0',
                          prefixIcon: Icons.circle_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 10),
                        InputField(
                          controller: _depthController,
                          label: 'Water Depth (${_unit == 'Meters' ? 'm' : 'ft'})',
                          hint: 'e.g. 1.8',
                          prefixIcon: Icons.height_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Calculate Capacity & Materials'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1),
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
                title: 'Tank Capacity & Sizing',
                icon: Icons.water_drop_rounded,
                rows: [
                  ResultRowItem(
                    label: 'Water Capacity (Liters)',
                    value: '${NumberFormat('#,##0').format(_capacityLiters)} Liters',
                    isPrimary: true,
                    subtitle: '≈ ${NumberFormat('#,##0').format(_capacityGallonsUS)} US Gallons',
                  ),
                  ResultRowItem(
                    label: 'Storage Volume',
                    value: '${_capacityM3.toStringAsFixed(2)} m³ (${_capacityCuFt.toStringAsFixed(1)} ft³)',
                  ),
                  ResultRowItem(
                    label: 'Suggested Dimensions (m)',
                    value:
                        '${_lengthController.text}m (L) × ${_widthController.text}m (W) × ${_depthController.text}m (D)',
                  ),
                  ResultRowItem(
                    label: 'Estimated Excavation Volume',
                    value: '${_excavationVolumeCuM.toStringAsFixed(2)} m³',
                    subtitle: 'Includes 0.3m offset on all sides for mason work',
                  ),
                  ResultRowItem(
                    label: 'Brickwork Requirement',
                    value: '$_estimatedBricks Red Bricks',
                    subtitle: 'Based on 9" (230mm) perimeter brick wall',
                  ),
                  ResultRowItem(
                    label: 'Waterproof Plaster Area',
                    value: '${_plasterAreaSqM.toStringAsFixed(1)} m²',
                    subtitle: '≈ ${_cementBagsForPlaster.ceil()} bags cement + waterproofing compound',
                  ),
                ],
                note:
                    'Ensure 1:3 waterproof plaster with Dr. Fixit or crystalline water-proofing compound on both internal walls and base slab.',
                onShare: _shareResults,
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
