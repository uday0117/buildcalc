import 'package:flutter/material.dart';

import '../../models/plan/material_estimation_models.dart';

class MaterialAssumptionsSheet extends StatefulWidget {
  final MaterialEstimationAssumptions currentAssumptions;
  final ValueChanged<MaterialEstimationAssumptions> onApply;

  const MaterialAssumptionsSheet({
    super.key,
    required this.currentAssumptions,
    required this.onApply,
  });

  @override
  State<MaterialAssumptionsSheet> createState() =>
      _MaterialAssumptionsSheetState();
}

class _MaterialAssumptionsSheetState extends State<MaterialAssumptionsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MaterialEstimationAssumptions _draft;

  // Controllers for text inputs
  late TextEditingController _wallHeightCtrl;
  late TextEditingController _extWallThickCtrl;
  late TextEditingController _intWallThickCtrl;

  late TextEditingController _customBrickLenCtrl;
  late TextEditingController _customBrickWidthCtrl;
  late TextEditingController _customBrickHeightCtrl;
  late TextEditingController _mortarJointCtrl;
  late TextEditingController _brickWastageCtrl;

  late TextEditingController _intPlasterThickCtrl;
  late TextEditingController _extPlasterThickCtrl;
  late TextEditingController _plasterWastageCtrl;

  late TextEditingController _intPaintCoverageCtrl;
  late TextEditingController _extPaintCoverageCtrl;
  late TextEditingController _primerCoverageCtrl;
  late TextEditingController _paintWastageCtrl;

  late TextEditingController _floorTileLenCtrl;
  late TextEditingController _floorTileWidthCtrl;
  late TextEditingController _tilesPerBoxCtrl;
  late TextEditingController _tileWastageCtrl;
  late TextEditingController _dadoHeightCtrl;
  late TextEditingController _kitchenBacksplashCtrl;

  late TextEditingController _roofSlabThickCtrl;
  late TextEditingController _roofSlabOverhangCtrl;
  late TextEditingController _lintelDepthCtrl;
  late TextEditingController _lintelBearingCtrl;
  late TextEditingController _plinthWidthCtrl;
  late TextEditingController _plinthDepthCtrl;
  late TextEditingController _concreteWastageCtrl;

  late TextEditingController _currencyCtrl;
  late TextEditingController _brickRateCtrl;
  late TextEditingController _cementRateCtrl;
  late TextEditingController _sandRateCtrl;
  late TextEditingController _aggRateCtrl;
  late TextEditingController _intPaintRateCtrl;
  late TextEditingController _extPaintRateCtrl;
  late TextEditingController _primerRateCtrl;
  late TextEditingController _floorTileRateCtrl;
  late TextEditingController _wallTileRateCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _draft = widget.currentAssumptions;
    _initControllers();
  }

  void _initControllers() {
    _wallHeightCtrl = TextEditingController(
      text: _draft.wallHeightFeet.toString(),
    );
    _extWallThickCtrl = TextEditingController(
      text: (_draft.exteriorWallThicknessFeet * 12.0).toStringAsFixed(1),
    );
    _intWallThickCtrl = TextEditingController(
      text: (_draft.interiorWallThicknessFeet * 12.0).toStringAsFixed(1),
    );

    _customBrickLenCtrl = TextEditingController(
      text: _draft.customBrickLengthInches.toString(),
    );
    _customBrickWidthCtrl = TextEditingController(
      text: _draft.customBrickWidthInches.toString(),
    );
    _customBrickHeightCtrl = TextEditingController(
      text: _draft.customBrickHeightInches.toString(),
    );
    _mortarJointCtrl = TextEditingController(
      text: _draft.mortarJointThicknessInches.toString(),
    );
    _brickWastageCtrl = TextEditingController(
      text: _draft.brickWastagePercent.toString(),
    );

    _intPlasterThickCtrl = TextEditingController(
      text: _draft.interiorPlasterThicknessInches.toString(),
    );
    _extPlasterThickCtrl = TextEditingController(
      text: _draft.exteriorPlasterThicknessInches.toString(),
    );
    _plasterWastageCtrl = TextEditingController(
      text: _draft.plasterWastagePercent.toString(),
    );

    _intPaintCoverageCtrl = TextEditingController(
      text: _draft.interiorPaintCoverageSqFtPerLiter.toString(),
    );
    _extPaintCoverageCtrl = TextEditingController(
      text: _draft.exteriorPaintCoverageSqFtPerLiter.toString(),
    );
    _primerCoverageCtrl = TextEditingController(
      text: _draft.primerCoverageSqFtPerLiter.toString(),
    );
    _paintWastageCtrl = TextEditingController(
      text: _draft.paintWastagePercent.toString(),
    );

    _floorTileLenCtrl = TextEditingController(
      text: _draft.floorTileLengthInches.toString(),
    );
    _floorTileWidthCtrl = TextEditingController(
      text: _draft.floorTileWidthInches.toString(),
    );
    _tilesPerBoxCtrl = TextEditingController(
      text: _draft.tilesPerBox.toString(),
    );
    _tileWastageCtrl = TextEditingController(
      text: _draft.tileWastagePercent.toString(),
    );
    _dadoHeightCtrl = TextEditingController(
      text: _draft.bathroomDadoHeightFeet.toString(),
    );
    _kitchenBacksplashCtrl = TextEditingController(
      text: _draft.kitchenBacksplashAreaSqFt.toString(),
    );

    _roofSlabThickCtrl = TextEditingController(
      text: _draft.roofSlabThicknessInches.toString(),
    );
    _roofSlabOverhangCtrl = TextEditingController(
      text: _draft.roofSlabOverhangFeet.toString(),
    );
    _lintelDepthCtrl = TextEditingController(
      text: _draft.lintelDepthInches.toString(),
    );
    _lintelBearingCtrl = TextEditingController(
      text: _draft.lintelBearingFeet.toString(),
    );
    _plinthWidthCtrl = TextEditingController(
      text: _draft.plinthBeamWidthInches.toString(),
    );
    _plinthDepthCtrl = TextEditingController(
      text: _draft.plinthBeamDepthInches.toString(),
    );
    _concreteWastageCtrl = TextEditingController(
      text: _draft.concreteWastagePercent.toString(),
    );

    _currencyCtrl = TextEditingController(text: _draft.currencySymbol);
    _brickRateCtrl = TextEditingController(
      text: _draft.brickRatePerUnit.toString(),
    );
    _cementRateCtrl = TextEditingController(
      text: _draft.cementRatePerBag.toString(),
    );
    _sandRateCtrl = TextEditingController(
      text: _draft.sandRatePerCuFt.toString(),
    );
    _aggRateCtrl = TextEditingController(
      text: _draft.aggregateRatePerCuFt.toString(),
    );
    _intPaintRateCtrl = TextEditingController(
      text: _draft.interiorPaintRatePerLiter.toString(),
    );
    _extPaintRateCtrl = TextEditingController(
      text: _draft.exteriorPaintRatePerLiter.toString(),
    );
    _primerRateCtrl = TextEditingController(
      text: _draft.primerRatePerLiter.toString(),
    );
    _floorTileRateCtrl = TextEditingController(
      text: _draft.floorTileRatePerSqFt.toString(),
    );
    _wallTileRateCtrl = TextEditingController(
      text: _draft.wallTileRatePerSqFt.toString(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wallHeightCtrl.dispose();
    _extWallThickCtrl.dispose();
    _intWallThickCtrl.dispose();
    _customBrickLenCtrl.dispose();
    _customBrickWidthCtrl.dispose();
    _customBrickHeightCtrl.dispose();
    _mortarJointCtrl.dispose();
    _brickWastageCtrl.dispose();
    _intPlasterThickCtrl.dispose();
    _extPlasterThickCtrl.dispose();
    _plasterWastageCtrl.dispose();
    _intPaintCoverageCtrl.dispose();
    _extPaintCoverageCtrl.dispose();
    _primerCoverageCtrl.dispose();
    _paintWastageCtrl.dispose();
    _floorTileLenCtrl.dispose();
    _floorTileWidthCtrl.dispose();
    _tilesPerBoxCtrl.dispose();
    _tileWastageCtrl.dispose();
    _dadoHeightCtrl.dispose();
    _kitchenBacksplashCtrl.dispose();
    _roofSlabThickCtrl.dispose();
    _roofSlabOverhangCtrl.dispose();
    _lintelDepthCtrl.dispose();
    _lintelBearingCtrl.dispose();
    _plinthWidthCtrl.dispose();
    _plinthDepthCtrl.dispose();
    _concreteWastageCtrl.dispose();
    _currencyCtrl.dispose();
    _brickRateCtrl.dispose();
    _cementRateCtrl.dispose();
    _sandRateCtrl.dispose();
    _aggRateCtrl.dispose();
    _intPaintRateCtrl.dispose();
    _extPaintRateCtrl.dispose();
    _primerRateCtrl.dispose();
    _floorTileRateCtrl.dispose();
    _wallTileRateCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final updated = _draft.copyWith(
      wallHeightFeet:
          double.tryParse(_wallHeightCtrl.text) ?? _draft.wallHeightFeet,
      exteriorWallThicknessFeet:
          (double.tryParse(_extWallThickCtrl.text) ?? 9.0) / 12.0,
      interiorWallThicknessFeet:
          (double.tryParse(_intWallThickCtrl.text) ?? 4.5) / 12.0,
      customBrickLengthInches:
          double.tryParse(_customBrickLenCtrl.text) ??
          _draft.customBrickLengthInches,
      customBrickWidthInches:
          double.tryParse(_customBrickWidthCtrl.text) ??
          _draft.customBrickWidthInches,
      customBrickHeightInches:
          double.tryParse(_customBrickHeightCtrl.text) ??
          _draft.customBrickHeightInches,
      mortarJointThicknessInches:
          double.tryParse(_mortarJointCtrl.text) ??
          _draft.mortarJointThicknessInches,
      brickWastagePercent:
          double.tryParse(_brickWastageCtrl.text) ?? _draft.brickWastagePercent,
      interiorPlasterThicknessInches:
          double.tryParse(_intPlasterThickCtrl.text) ??
          _draft.interiorPlasterThicknessInches,
      exteriorPlasterThicknessInches:
          double.tryParse(_extPlasterThickCtrl.text) ??
          _draft.exteriorPlasterThicknessInches,
      plasterWastagePercent:
          double.tryParse(_plasterWastageCtrl.text) ??
          _draft.plasterWastagePercent,
      interiorPaintCoverageSqFtPerLiter:
          double.tryParse(_intPaintCoverageCtrl.text) ??
          _draft.interiorPaintCoverageSqFtPerLiter,
      exteriorPaintCoverageSqFtPerLiter:
          double.tryParse(_extPaintCoverageCtrl.text) ??
          _draft.exteriorPaintCoverageSqFtPerLiter,
      primerCoverageSqFtPerLiter:
          double.tryParse(_primerCoverageCtrl.text) ??
          _draft.primerCoverageSqFtPerLiter,
      paintWastagePercent:
          double.tryParse(_paintWastageCtrl.text) ?? _draft.paintWastagePercent,
      floorTileLengthInches:
          double.tryParse(_floorTileLenCtrl.text) ??
          _draft.floorTileLengthInches,
      floorTileWidthInches:
          double.tryParse(_floorTileWidthCtrl.text) ??
          _draft.floorTileWidthInches,
      tilesPerBox: int.tryParse(_tilesPerBoxCtrl.text) ?? _draft.tilesPerBox,
      tileWastagePercent:
          double.tryParse(_tileWastageCtrl.text) ?? _draft.tileWastagePercent,
      bathroomDadoHeightFeet:
          double.tryParse(_dadoHeightCtrl.text) ??
          _draft.bathroomDadoHeightFeet,
      kitchenBacksplashAreaSqFt:
          double.tryParse(_kitchenBacksplashCtrl.text) ??
          _draft.kitchenBacksplashAreaSqFt,
      roofSlabThicknessInches:
          double.tryParse(_roofSlabThickCtrl.text) ??
          _draft.roofSlabThicknessInches,
      roofSlabOverhangFeet:
          double.tryParse(_roofSlabOverhangCtrl.text) ??
          _draft.roofSlabOverhangFeet,
      lintelDepthInches:
          double.tryParse(_lintelDepthCtrl.text) ?? _draft.lintelDepthInches,
      lintelBearingFeet:
          double.tryParse(_lintelBearingCtrl.text) ?? _draft.lintelBearingFeet,
      plinthBeamWidthInches:
          double.tryParse(_plinthWidthCtrl.text) ??
          _draft.plinthBeamWidthInches,
      plinthBeamDepthInches:
          double.tryParse(_plinthDepthCtrl.text) ??
          _draft.plinthBeamDepthInches,
      concreteWastagePercent:
          double.tryParse(_concreteWastageCtrl.text) ??
          _draft.concreteWastagePercent,
      currencySymbol: _currencyCtrl.text.isNotEmpty ? _currencyCtrl.text : '₹',
      brickRatePerUnit:
          double.tryParse(_brickRateCtrl.text) ?? _draft.brickRatePerUnit,
      cementRatePerBag:
          double.tryParse(_cementRateCtrl.text) ?? _draft.cementRatePerBag,
      sandRatePerCuFt:
          double.tryParse(_sandRateCtrl.text) ?? _draft.sandRatePerCuFt,
      aggregateRatePerCuFt:
          double.tryParse(_aggRateCtrl.text) ?? _draft.aggregateRatePerCuFt,
      interiorPaintRatePerLiter:
          double.tryParse(_intPaintRateCtrl.text) ??
          _draft.interiorPaintRatePerLiter,
      exteriorPaintRatePerLiter:
          double.tryParse(_extPaintRateCtrl.text) ??
          _draft.exteriorPaintRatePerLiter,
      primerRatePerLiter:
          double.tryParse(_primerRateCtrl.text) ?? _draft.primerRatePerLiter,
      floorTileRatePerSqFt:
          double.tryParse(_floorTileRateCtrl.text) ??
          _draft.floorTileRatePerSqFt,
      wallTileRatePerSqFt:
          double.tryParse(_wallTileRateCtrl.text) ?? _draft.wallTileRatePerSqFt,
    );

    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  void _resetDefaults() {
    setState(() {
      _draft = const MaterialEstimationAssumptions();
      _initControllers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, color: Color(0xFFFF8C00)),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Assumptions & Material Rates',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _resetDefaults,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text(
                        'Reset Defaults',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tab bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFFFF8C00),
            unselectedLabelColor: isDark
                ? Colors.white60
                : Colors.grey.shade700,
            indicatorColor: const Color(0xFFFF8C00),
            tabs: const [
              Tab(text: 'Walls & Masonry'),
              Tab(text: 'Plaster & Paint'),
              Tab(text: 'Tiles & Finishes'),
              Tab(text: 'Explicit Concrete'),
              Tab(text: 'Material Rates (Cost)'),
            ],
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMasonryTab(isDark),
                _buildPlasterPaintTab(isDark),
                _buildTilesTab(isDark),
                _buildConcreteTab(isDark),
                _buildRatesTab(isDark),
              ],
            ),
          ),
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                    ),
                    onPressed: _apply,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Apply Changes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasonryTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Dimensions & Heights'),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _wallHeightCtrl,
                label: 'Wall Height (ft)',
                hint: '10.0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _extWallThickCtrl,
                label: 'Exterior Wall (in)',
                hint: '9.0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _intWallThickCtrl,
                label: 'Interior Wall (in)',
                hint: '4.5',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Masonry Unit Type'),
        DropdownButtonFormField<MasonryUnitType>(
          initialValue: _draft.masonryType,
          isExpanded: true,
          decoration: _inputDecoration('Masonry Unit'),
          items: MasonryUnitType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.label, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _draft = _draft.copyWith(masonryType: val);
              });
            }
          },
        ),
        if (_draft.masonryType == MasonryUnitType.custom) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _customBrickLenCtrl,
                  label: 'Length (in)',
                  hint: '9.0',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _customBrickWidthCtrl,
                  label: 'Width (in)',
                  hint: '4.25',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _customBrickHeightCtrl,
                  label: 'Height (in)',
                  hint: '2.75',
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _buildSectionTitle('Mortar Joint & Mix'),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<MortarMixRatio>(
                initialValue: _draft.mortarMix,
                isExpanded: true,
                decoration: _inputDecoration('Mortar Mix Ratio'),
                items: MortarMixRatio.values.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m.label, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _draft = _draft.copyWith(mortarMix: val);
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _mortarJointCtrl,
                label: 'Joint Thickness (in)',
                hint: '0.39',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _brickWastageCtrl,
          label: 'Brick / Block Cutting Wastage (%)',
          hint: '7.0',
        ),
      ],
    );
  }

  Widget _buildPlasterPaintTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Wall & Ceiling Plastering'),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _intPlasterThickCtrl,
                label: 'Interior Thickness (in)',
                hint: '0.5',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _extPlasterThickCtrl,
                label: 'Exterior Thickness (in)',
                hint: '0.75',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<MortarMixRatio>(
                initialValue: _draft.plasterMix,
                isExpanded: true,
                decoration: _inputDecoration('Plaster Mortar Ratio'),
                items: MortarMixRatio.values.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m.label, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _draft = _draft.copyWith(plasterMix: val);
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _plasterWastageCtrl,
                label: 'Plaster Wastage (%)',
                hint: '8.0',
              ),
            ),
          ],
        ),
        SwitchListTile(
          title: const Text(
            'Include Ceiling Plaster',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const Text(
            'Applies plaster coating over interior room slab ceilings',
            style: TextStyle(fontSize: 12),
          ),
          value: _draft.includeCeilingPlaster,
          activeThumbColor: const Color(0xFFFF8C00),
          onChanged: (val) {
            setState(() {
              _draft = _draft.copyWith(includeCeilingPlaster: val);
            });
          },
        ),
        const Divider(height: 28),
        _buildSectionTitle('Paints & Primers'),
        SwitchListTile(
          title: const Text(
            'Include Interior Base Primer',
            style: TextStyle(fontSize: 14),
          ),
          value: _draft.includePrimer,
          activeThumbColor: const Color(0xFFFF8C00),
          onChanged: (val) {
            setState(() {
              _draft = _draft.copyWith(includePrimer: val);
            });
          },
        ),
        SwitchListTile(
          title: const Text(
            'Include Ceiling Painting',
            style: TextStyle(fontSize: 14),
          ),
          value: _draft.includeCeilingPaint,
          activeThumbColor: const Color(0xFFFF8C00),
          onChanged: (val) {
            setState(() {
              _draft = _draft.copyWith(includeCeilingPaint: val);
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _intPaintCoverageCtrl,
                label: 'Interior Coverage (sq ft/L)',
                hint: '110',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _extPaintCoverageCtrl,
                label: 'Exterior Coverage (sq ft/L)',
                hint: '90',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _primerCoverageCtrl,
                label: 'Primer Coverage (sq ft/L)',
                hint: '140',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _paintWastageCtrl,
                label: 'Paint Wastage (%)',
                hint: '5.0',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTilesTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Vitrified Floor Tiles'),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _floorTileLenCtrl,
                label: 'Tile Length (in)',
                hint: '24.0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _floorTileWidthCtrl,
                label: 'Tile Width (in)',
                hint: '24.0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _tilesPerBoxCtrl,
                label: 'Tiles / Box',
                hint: '4',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _tileWastageCtrl,
          label: 'Cutting & Breakage Wastage (%)',
          hint: '10.0',
        ),
        const Divider(height: 28),
        _buildSectionTitle('Wall Dado Tiles (Bathrooms & Kitchen)'),
        SwitchListTile(
          title: const Text(
            'Include Bathroom Wall Dado',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const Text(
            'Ceramic wall tiles up to specified height minus doors',
            style: TextStyle(fontSize: 12),
          ),
          value: _draft.includeBathroomWallTiles,
          activeThumbColor: const Color(0xFFFF8C00),
          onChanged: (val) {
            setState(() {
              _draft = _draft.copyWith(includeBathroomWallTiles: val);
            });
          },
        ),
        if (_draft.includeBathroomWallTiles)
          _buildTextField(
            controller: _dadoHeightCtrl,
            label: 'Bathroom Dado Height (ft)',
            hint: '7.0',
          ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text(
            'Include Kitchen Backsplash Tiles',
            style: TextStyle(fontSize: 14),
          ),
          value: _draft.includeKitchenBacksplash,
          activeThumbColor: const Color(0xFFFF8C00),
          onChanged: (val) {
            setState(() {
              _draft = _draft.copyWith(includeKitchenBacksplash: val);
            });
          },
        ),
        if (_draft.includeKitchenBacksplash)
          _buildTextField(
            controller: _kitchenBacksplashCtrl,
            label: 'Kitchen Backsplash Area (sq ft)',
            hint: '30.0',
          ),
      ],
    );
  }

  Widget _buildConcreteTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1E3A5F).withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF1E3A5F),
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Concrete quantities are calculated ONLY for explicitly defined structural elements below. Reinforcement (rebar) cannot be inferred from 2D architectural plans and requires structural drawings.',
                  style: TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Concrete Mix Grade'),
        DropdownButtonFormField<ConcreteGradeMix>(
          initialValue: _draft.concreteGrade,
          isExpanded: true,
          decoration: _inputDecoration('Design Mix Grade'),
          items: ConcreteGradeMix.values.map((g) {
            return DropdownMenuItem(
              value: g,
              child: Text(g.label, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _draft = _draft.copyWith(concreteGrade: val);
              });
            }
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _concreteWastageCtrl,
          label: 'Concrete Batching Wastage (%)',
          hint: '5.0',
        ),
        const Divider(height: 28),
        _buildSectionTitle('Explicit Concrete Elements'),
        SwitchListTile(
          title: const Text(
            '1. Roof Slab',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Continuous concrete ceiling slab over built-up area footprint',
            style: TextStyle(fontSize: 12),
          ),
          value: _draft.includeRoofSlab,
          activeThumbColor: const Color(0xFFFF8C00),
          onChanged: (val) {
            setState(() {
              _draft = _draft.copyWith(includeRoofSlab: val);
            });
          },
        ),
        if (_draft.includeRoofSlab) ...[
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _roofSlabThickCtrl,
                  label: 'Slab Thickness (in)',
                  hint: '5.0',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _roofSlabOverhangCtrl,
                  label: 'Eaves Overhang (ft)',
                  hint: '1.0',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SwitchListTile(
          title: const Text(
            '2. Lintel Beams over Openings',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Horizontal concrete lintels over doors & windows',
            style: TextStyle(fontSize: 12),
          ),
          value: _draft.includeLintelBeams,
          activeThumbColor: const Color(0xFFFF8C00),
          onChanged: (val) {
            setState(() {
              _draft = _draft.copyWith(includeLintelBeams: val);
            });
          },
        ),
        if (_draft.includeLintelBeams) ...[
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _lintelDepthCtrl,
                  label: 'Lintel Depth (in)',
                  hint: '6.0',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lintelBearingCtrl,
                  label: 'Bearing Each Side (ft)',
                  hint: '0.5',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SwitchListTile(
          title: const Text(
            '3. Plinth Beam / Foundation Tie Band',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Reinforced concrete band along total ground physical walls',
            style: TextStyle(fontSize: 12),
          ),
          value: _draft.includePlinthBeam,
          activeThumbColor: const Color(0xFFFF8C00),
          onChanged: (val) {
            setState(() {
              _draft = _draft.copyWith(includePlinthBeam: val);
            });
          },
        ),
        if (_draft.includePlinthBeam) ...[
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _plinthWidthCtrl,
                  label: 'Beam Width (in)',
                  hint: '9.0',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _plinthDepthCtrl,
                  label: 'Beam Depth (in)',
                  hint: '12.0',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRatesTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Currency & Market Rates'),
        _buildTextField(
          controller: _currencyCtrl,
          label: 'Currency Symbol (₹, \$, £, €)',
          hint: '₹',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Masonry & Mortar Rates'),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _brickRateCtrl,
                label: 'Brick Rate (per piece)',
                hint: '9.5',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _cementRateCtrl,
                label: 'Cement Rate (per 50kg bag)',
                hint: '380.0',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _sandRateCtrl,
                label: 'Sand Rate (per cu ft)',
                hint: '45.0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _aggRateCtrl,
                label: 'Stone Aggregate (per cu ft)',
                hint: '38.0',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Paints & Finishes Rates'),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _intPaintRateCtrl,
                label: 'Interior Paint (per L)',
                hint: '320.0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _extPaintRateCtrl,
                label: 'Exterior Paint (per L)',
                hint: '410.0',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _primerRateCtrl,
                label: 'Wall Primer (per L)',
                hint: '180.0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _floorTileRateCtrl,
                label: 'Floor Tile (per sq ft)',
                hint: '65.0',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _wallTileRateCtrl,
          label: 'Wall Dado Tile (per sq ft)',
          hint: '55.0',
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A5F),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputKeyData(signed: false, decimal: true),
      decoration: _inputDecoration(label, hintText: hint),
      style: const TextStyle(fontSize: 13),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
    );
  }
}

class TextInputKeyData extends TextInputType {
  const TextInputKeyData({super.signed, super.decimal})
    : super.numberWithOptions();
}
