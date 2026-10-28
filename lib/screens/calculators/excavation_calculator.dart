import 'package:flutter/material.dart';

import '../../models/calculation.dart';
import '../../models/calculators/excavation_calculation.dart';
import '../../services/calculators/excavation_calculator_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/input_field.dart';
import '../../widgets/result_card.dart';
import '../../widgets/unit_selector.dart';
import '../../widgets/calculators/excavation_sketch_painter.dart';

class ExcavationCalculator extends StatefulWidget {
  const ExcavationCalculator({super.key});

  @override
  State<ExcavationCalculator> createState() => _ExcavationCalculatorState();
}

class _ExcavationCalculatorState extends State<ExcavationCalculator> {
  final _lengthController = TextEditingController(text: '2.0');
  final _widthController = TextEditingController(text: '2.0');
  final _depthController = TextEditingController(text: '1.5');
  final _quantityController = TextEditingController(text: '4');
  final _workingSpaceController = TextEditingController(text: '0.3');
  final _structureVolController = TextEditingController(text: '3.2');
  final _bulkingController = TextEditingController(text: '20');
  final _compactionController = TextEditingController(text: '15');
  final _truckCapacityController = TextEditingController(text: '5.0');

  ExcavationType _selectedType = ExcavationType.isolatedFooting;
  ExcavationResult? _result;
  ExcavationInput? _lastInput;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final depth = double.tryParse(_depthController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final workingSpace = double.tryParse(_workingSpaceController.text) ?? 0.3;
    final structureVol = double.tryParse(_structureVolController.text) ?? 0;
    final bulking = double.tryParse(_bulkingController.text) ?? 20;
    final compaction = double.tryParse(_compactionController.text) ?? 15;
    final truckCap = double.tryParse(_truckCapacityController.text) ?? 5.0;

    final input = ExcavationInput(
      type: _selectedType,
      length: length,
      width: width,
      depth: depth,
      quantity: quantity,
      workingSpace: workingSpace,
      structureVolumeM3: structureVol,
      bulkingFactorPercent: bulking,
      compactionFactorPercent: compaction,
      truckCapacityM3: truckCap,
    );

    final res = ExcavationCalculatorService.calculate(input);

    setState(() {
      _lastInput = input;
      _result = res;
    });

    if (res.isValid) {
      _saveToHistory(res);
    } else if (res.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.errorMessage!)));
    }
  }

  Calculation _createCalculationModel(ExcavationResult res) {
    return Calculation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'excavation',
      title: 'Excavation & Backfilling',
      inputs: {
        'type': _selectedType.name,
        'length': _lengthController.text,
        'width': _widthController.text,
        'depth': _depthController.text,
        'quantity': _quantityController.text,
        'working_space': _workingSpaceController.text,
        'structure_volume_m3': _structureVolController.text,
        'bulking_percent': _bulkingController.text,
        'truck_capacity_m3': _truckCapacityController.text,
      },
      results: {
        'insitu_excavation_m3': res.inSituExcavationM3,
        'loose_soil_m3': res.looseSoilM3,
        'backfill_void_m3': res.inSituBackfillVoidM3,
        'required_backfill_m3': res.requiredCompactedBackfillM3,
        'surplus_soil_m3': res.surplusSoilM3,
        'truck_trips': res.truckTrips,
      },
      timestamp: DateTime.now(),
    );
  }

  void _saveToHistory(ExcavationResult res) {
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
      _lengthController.text = '2.0';
      _widthController.text = '2.0';
      _depthController.text = '1.5';
      _quantityController.text = '4';
      _workingSpaceController.text = '0.3';
      _structureVolController.text = '3.2';
      _bulkingController.text = '20';
      _compactionController.text = '15';
      _truckCapacityController.text = '5.0';
      _selectedType = ExcavationType.isolatedFooting;
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
          'Excavation & Backfilling',
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
                      Icons.agriculture_rounded,
                      size: 48,
                      color: Color(0xFF8D6E63),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Earthwork, Trenching & Backfilling',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calculate in-situ excavation, soil bulking volume, foundation backfill, surplus soil and truck trips.',
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

            // Excavation Type Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Excavation Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                UnitSelector<ExcavationType>(
                  values: ExcavationType.values,
                  selectedValue: _selectedType,
                  labelBuilder: (type) {
                    switch (type) {
                      case ExcavationType.isolatedFooting:
                        return 'Footing Pit';
                      case ExcavationType.trench:
                        return 'Trench';
                      case ExcavationType.basementRaft:
                        return 'Basement';
                    }
                  },
                  onSelected: (val) {
                    setState(() => _selectedType = val);
                    _calculate();
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Dimensions
            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'Net Length',
                    hint: 'e.g. 2.0',
                    controller: _lengthController,
                    suffix: 'm',
                    prefixIcon: Icons.straighten_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputField(
                    label: 'Net Width',
                    hint: 'e.g. 2.0',
                    controller: _widthController,
                    suffix: 'm',
                    prefixIcon: Icons.square_foot_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'Excavation Depth',
                    hint: 'e.g. 1.5',
                    controller: _depthController,
                    suffix: 'm',
                    prefixIcon: Icons.vertical_align_bottom_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputField(
                    label: 'Quantity (Pits/Trenches)',
                    hint: '1',
                    controller: _quantityController,
                    prefixIcon: Icons.numbers_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'Working Clearance',
                    hint: '0.3',
                    controller: _workingSpaceController,
                    suffix: 'm',
                    prefixIcon: Icons.space_bar_rounded,
                    helperText: 'Shuttering clearance on each side',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputField(
                    label: 'Structure Volume',
                    hint: 'e.g. 3.2',
                    controller: _structureVolController,
                    suffix: 'm³',
                    prefixIcon: Icons.view_in_ar_rounded,
                    helperText: 'Concrete footings/pedestals',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: InputField(
                    label: 'Soil Bulking Factor',
                    hint: '20',
                    controller: _bulkingController,
                    suffix: '%',
                    prefixIcon: Icons.expand_rounded,
                    helperText: 'Expansion when excavated',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputField(
                    label: 'Truck Capacity',
                    hint: '5.0',
                    controller: _truckCapacityController,
                    suffix: 'm³',
                    prefixIcon: Icons.local_shipping_rounded,
                    helperText: 'Dumper haul volume',
                  ),
                ),
              ],
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
                'Calculate Excavation & Backfill',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            if (res != null && res.isValid && _lastInput != null) ...[
              const SizedBox(height: 24),

              // Visual Dimensioned Trench Sketch
              const Text(
                'Trench & Footing Cross-Section',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ExcavationSketchWidget(input: _lastInput!, result: res),

              // Safety warning banner
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
                            Icons.shield_outlined,
                            size: 18,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Trench Safety & Geotechnical Advisory',
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

              // Excavation Volume Card
              ResultCard(
                title: 'Excavation Quantities',
                icon: Icons.layers_rounded,
                onSave: _bookmark,
                note:
                    'Effective pit: ${res.effectiveLengthMeters.toStringAsFixed(2)}m × ${res.effectiveWidthMeters.toStringAsFixed(2)}m (with +${_workingSpaceController.text}m working space)',
                rows: [
                  ResultRowItem(
                    label: 'In-Situ Excavation Volume',
                    value: '${res.inSituExcavationM3.toStringAsFixed(2)} m³',
                    isPrimary: true,
                  ),
                  ResultRowItem(
                    label: 'Loose / Bulked Soil Volume',
                    value:
                        '${res.looseSoilM3.toStringAsFixed(2)} m³ (+${_bulkingController.text}% swell)',
                  ),
                  ResultRowItem(
                    label: 'Total Footprint Area',
                    value:
                        '${(res.pitAreaM2 * (_lastInput?.quantity ?? 1)).toStringAsFixed(2)} m²',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Backfill & Cartage Card
              ResultCard(
                title: 'Backfilling & Cartage',
                icon: Icons.local_shipping_rounded,
                note:
                    'Compacted backfill void after erecting concrete structure',
                rows: [
                  ResultRowItem(
                    label: 'Backfill Void Volume',
                    value: '${res.inSituBackfillVoidM3.toStringAsFixed(2)} m³',
                    isPrimary: true,
                  ),
                  ResultRowItem(
                    label: 'Required Compacted Soil',
                    value:
                        '${res.requiredCompactedBackfillM3.toStringAsFixed(2)} m³ (with ${_compactionController.text}% compaction)',
                  ),
                  ResultRowItem(
                    label: 'Surplus Soil to Haul',
                    value: '${res.surplusSoilM3.toStringAsFixed(2)} m³',
                  ),
                  ResultRowItem(
                    label: 'Estimated Truck Trips',
                    value:
                        '${res.truckTrips} trips (${_truckCapacityController.text} m³ truck)',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Geotechnical Engineering Disclaimer
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
                        'Disclaimer: Soil expansion, bulk density, and safe excavation slopes depend on soil classification (clay, silt, gravel, rock) and site moisture content. For deep excavation, adhere to OSHA and local building authority shoring standards.',
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
    );
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _quantityController.dispose();
    _workingSpaceController.dispose();
    _structureVolController.dispose();
    _bulkingController.dispose();
    _compactionController.dispose();
    _truckCapacityController.dispose();
    super.dispose();
  }
}
