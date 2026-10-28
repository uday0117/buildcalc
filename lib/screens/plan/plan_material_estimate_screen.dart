import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/plan/material_estimation_models.dart';
import '../../models/plan/plan_models.dart';
import '../../models/plan/plan_unit.dart';
import '../../services/plan_material_estimator.dart';
import '../../widgets/plan/material_assumptions_sheet.dart';
import '../../widgets/plan/plan_export_dialog.dart';

class PlanMaterialEstimateScreen extends StatefulWidget {
  final FloorPlan plan;
  final PlanUnit initialUnit;

  const PlanMaterialEstimateScreen({
    super.key,
    required this.plan,
    this.initialUnit = PlanUnit.feet,
  });

  @override
  State<PlanMaterialEstimateScreen> createState() =>
      _PlanMaterialEstimateScreenState();
}

class _PlanMaterialEstimateScreenState extends State<PlanMaterialEstimateScreen>
    with SingleTickerProviderStateMixin {
  late MaterialEstimationAssumptions _assumptions;
  late PlanUnit _displayUnit;
  late TabController _tabController;
  late PlanMaterialEstimateReport _report;

  @override
  void initState() {
    super.initState();
    _assumptions = const MaterialEstimationAssumptions();
    _displayUnit = widget.initialUnit;
    _tabController = TabController(length: 4, vsync: this);
    _recalculate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _recalculate() {
    _report = PlanMaterialEstimator.estimateMaterials(
      plan: widget.plan,
      assumptions: _assumptions,
    );
  }

  void _openAssumptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MaterialAssumptionsSheet(
        currentAssumptions: _assumptions,
        onApply: (updated) {
          setState(() {
            _assumptions = updated;
            _recalculate();
          });
        },
      ),
    );
  }

  void _openPdfExport() {
    PlanExportDialog.show(
      context,
      plan: widget.plan,
      activeUnit: _displayUnit,
      initialFormat: ExportFormat.materialEstimatePdf,
      assumptions: _assumptions,
    );
  }

  void _shareReport() {
    final currency = _assumptions.currencySymbol;
    final formatter = NumberFormat('#,##0.00');
    final numFormat = NumberFormat('#,##0.0');

    final buffer = StringBuffer();
    buffer.writeln('📋 BuildCalc - Automatic Material & Cost Estimate');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('Plan: ${widget.plan.name} (${widget.plan.layoutType})');
    buffer.writeln(
      'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(_report.generatedAt)}',
    );
    buffer.writeln(
      'Carpet Area: ${_displayUnit.formatArea(_report.totalCarpetAreaSqFt)}',
    );
    buffer.writeln(
      'Total Built-up Area: ${_displayUnit.formatArea(_report.totalBuiltUpAreaSqFt)}',
    );
    buffer.writeln(
      'Physical Walls Length: ${numFormat.format(_report.totalPhysicalWallLengthFeet)} ft (${numFormat.format(_report.exteriorWallLengthFeet)} ft Ext + ${numFormat.format(_report.interiorSharedWallLengthFeet)} ft Shared Int)',
    );
    buffer.writeln(
      'Net Masonry Volume: ${numFormat.format(_report.netMasonryVolumeCuFt)} cu ft (Gross: ${numFormat.format(_report.grossMasonryVolumeCuFt)} - Openings: ${numFormat.format(_report.openingsDeductionVolumeCuFt)})',
    );
    buffer.writeln(
      'Openings Deducted: ${_report.totalOpeningsCount} openings (${numFormat.format(_report.totalOpeningsAreaSqFt)} sq ft)',
    );
    buffer.writeln('');
    buffer.writeln(
      '💰 TOTAL ESTIMATED MATERIAL COST: $currency ${formatter.format(_report.totalEstimatedCost)}',
    );
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');

    buffer.writeln('📦 ITEMIZED MATERIAL QUANTITIES:');
    for (final item in _report.lineItems) {
      buffer.writeln('• ${item.name}');
      buffer.writeln(
        '  Qty: ${numFormat.format(item.totalQuantity)} ${item.unit} (Net: ${numFormat.format(item.netQuantity)} + ${item.wastagePercent}% wastage)',
      );
      buffer.writeln(
        '  Rate: $currency ${formatter.format(item.unitRate)} | Cost: $currency ${formatter.format(item.totalCost)}',
      );
      buffer.writeln('  Breakdown: ${item.formulaBreakdown}');
      buffer.writeln('');
    }

    buffer.writeln('🏢 ROOM-WISE SUMMARY:');
    for (final r in _report.roomBreakdowns) {
      buffer.writeln(
        '• ${r.roomName} (${r.roomType.displayName}): ${_displayUnit.formatDimensions(r.widthFeet, r.lengthFeet)} = ${_displayUnit.formatArea(r.carpetAreaSqFt)}',
      );
      buffer.writeln(
        '  Interior Wall Surface: ${numFormat.format(r.netWallSurfaceSqFt)} sq ft (Gross ${numFormat.format(r.grossWallSurfaceSqFt)} - ${r.openingsCount} Openings)',
      );
    }

    buffer.writeln('');
    buffer.writeln('⚖️ DISCLAIMER:');
    buffer.writeln(PlanMaterialEstimateReport.disclaimerText);

    Share.share(
      buffer.toString(),
      subject: '${widget.plan.name} - Material Estimation',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = _assumptions.currencySymbol;
    final costFormatter = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.plan.name} - Materials',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Phase 4 Material & Cost Estimation',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF Report',
            onPressed: _openPdfExport,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Review & Edit Assumptions',
            onPressed: _openAssumptionsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Estimate',
            onPressed: _shareReport,
          ),
          PopupMenuButton<PlanUnit>(
            icon: const Icon(Icons.straighten_rounded),
            tooltip: 'Display Units',
            onSelected: (unit) {
              setState(() {
                _displayUnit = unit;
              });
            },
            itemBuilder: (ctx) => PlanUnit.values.map((u) {
              return PopupMenuItem(
                value: u,
                child: Row(
                  children: [
                    if (_displayUnit == u)
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: Color(0xFFFF8C00),
                      )
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(u.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFFF8C00),
          unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade700,
          indicatorColor: const Color(0xFFFF8C00),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_rounded, size: 18),
              text: 'Summary & Cost',
            ),
            Tab(
              icon: Icon(Icons.inventory_2_rounded, size: 18),
              text: 'Itemized Breakdown',
            ),
            Tab(
              icon: Icon(Icons.meeting_room_rounded, size: 18),
              text: 'Room Breakdown',
            ),
            Tab(
              icon: Icon(Icons.view_week_rounded, size: 18),
              text: 'Physical Walls',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Total Estimated Cost Card & Quick Geometry Strip
          _buildHeroCostCard(isDark, currency, costFormatter),

          // Engineering Disclaimer Alert Banner
          _buildDisclaimerBanner(isDark),

          // Main Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(isDark, currency, costFormatter),
                _buildItemizedTab(isDark, currency, costFormatter),
                _buildRoomBreakdownTab(isDark),
                _buildPhysicalWallsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCostCard(
    bool isDark,
    String currency,
    NumberFormat costFormatter,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E3A5F), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFFF8C00),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ESTIMATED MATERIAL COST',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _openAssumptionsSheet,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        color: Color(0xFFFF8C00),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Edit Assumptions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currency ${costFormatter.format(_report.totalEstimatedCost)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          // Category budget mini pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MaterialCategory.values.map((cat) {
                final catCost = _report.costByCategory[cat] ?? 0.0;
                final percent = _report.totalEstimatedCost > 0
                    ? (catCost / _report.totalEstimatedCost * 100.0)
                    : 0.0;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cat.color.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 12, color: cat.color),
                      const SizedBox(width: 4),
                      Text(
                        '${cat.title.split(' ').first}: ${percent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Key Geometrical Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                'Carpet Area',
                _displayUnit.formatArea(_report.totalCarpetAreaSqFt),
              ),
              _buildMiniMetric(
                'Built-up',
                _displayUnit.formatArea(_report.totalBuiltUpAreaSqFt),
              ),
              _buildMiniMetric(
                'Walls Length',
                '${_report.totalPhysicalWallLengthFeet.toStringAsFixed(1)} ft',
              ),
              _buildMiniMetric(
                'Net Masonry',
                '${_report.netMasonryVolumeCuFt.toStringAsFixed(0)} cu ft',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimerBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFFC2410C), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Preliminary estimate for budgeting only. Not a certified BOQ or structural design. Reinforcement steel cannot be inferred from architectural plans and requires structural engineering drawings.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 10.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(
    bool isDark,
    String currency,
    NumberFormat costFormatter,
  ) {
    final numFormat = NumberFormat('#,##0.0');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: MaterialCategory.values.map((cat) {
        final items = _report.itemsByCategory[cat] ?? [];
        final totalCategoryCost = _report.costByCategory[cat] ?? 0.0;
        final costPercent = _report.totalEstimatedCost > 0
            ? (totalCategoryCost / _report.totalEstimatedCost * 100.0)
            : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: items.isNotEmpty,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat.icon, color: cat.color, size: 20),
              ),
              title: Text(
                cat.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${items.length} item(s) • ${costPercent.toStringAsFixed(1)}% of total',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              trailing: Text(
                '$currency ${costFormatter.format(totalCategoryCost)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cat.color,
                ),
              ),
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${numFormat.format(item.totalQuantity)} ${item.unit} (Net: ${numFormat.format(item.netQuantity)} + ${item.wastagePercent}% wastage)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$currency ${costFormatter.format(item.totalCost)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '@ $currency ${costFormatter.format(item.unitRate)} / unit',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemizedTab(
    bool isDark,
    String currency,
    NumberFormat costFormatter,
  ) {
    final numFormat = NumberFormat('#,##0.0');

    if (_report.lineItems.isEmpty) {
      return const Center(child: Text('No material line items calculated.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _report.lineItems.length,
      itemBuilder: (ctx, index) {
        final item = _report.lineItems[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge & Cost
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.category.icon,
                            size: 12,
                            color: item.category.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.category.title.split(' ').first,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.category.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$currency ${costFormatter.format(item.totalCost)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: item.category.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                // Quantities Strip
                Row(
                  children: [
                    _buildPill(
                      label: 'Net Quantity',
                      value:
                          '${numFormat.format(item.netQuantity)} ${item.unit}',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      label: 'Wastage',
                      value: '+${item.wastagePercent}%',
                      isDark: isDark,
                      highlight: true,
                    ),
                    const SizedBox(width: 8),
                    _buildPill(
                      label: 'Total Required',
                      value:
                          '${numFormat.format(item.totalQuantity)} ${item.unit}',
                      isDark: isDark,
                      bold: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Formula Breakdown Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.functions_rounded,
                            size: 14,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Calculation Breakdown & Formula:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.formulaBreakdown,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Assumptions: ${item.assumptionsSummary}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomBreakdownTab(bool isDark) {
    if (_report.roomBreakdowns.isEmpty) {
      return const Center(child: Text('No rooms in floor plan.'));
    }

    final numFormat = NumberFormat('#,##0.0');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _report.roomBreakdowns.length,
      itemBuilder: (ctx, index) {
        final r = _report.roomBreakdowns[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          r.roomType.icon,
                          color: const Color(0xFFFF8C00),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          r.roomName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.roomType.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Dimensions: ${_displayUnit.formatDimensions(r.widthFeet, r.lengthFeet)}  •  Perimeter: ${numFormat.format(r.perimeterFeet)} ft',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricBox(
                      'Carpet Floor Area',
                      _displayUnit.formatArea(r.carpetAreaSqFt),
                      isDark,
                    ),
                    _buildMetricBox(
                      'Gross Wall Surface',
                      '${numFormat.format(r.grossWallSurfaceSqFt)} sq ft',
                      isDark,
                    ),
                    _buildMetricBox(
                      'Openings Subtracted',
                      '-${numFormat.format(r.openingsAreaSqFt)} sq ft (${r.openingsCount})',
                      isDark,
                      color: Colors.red.shade700,
                    ),
                    _buildMetricBox(
                      'Net Wall Surface',
                      '${numFormat.format(r.netWallSurfaceSqFt)} sq ft',
                      isDark,
                      bold: true,
                    ),
                  ],
                ),
                if (r.wallTileAreaSqFt > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.grid_view_rounded,
                          size: 14,
                          color: Color(0xFF0D9488),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Wall Tile Dado Area: ${numFormat.format(r.wallTileAreaSqFt)} sq ft',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhysicalWallsTab(bool isDark) {
    if (_report.physicalWalls.isEmpty) {
      return const Center(child: Text('No physical walls extracted.'));
    }

    final numFormat = NumberFormat('#,##0.0');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF059669).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Physical walls deduplicated: ${_report.physicalWalls.length} non-overlapping wall segments. Shared partition walls are counted only once to avoid double-counting masonry!',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._report.physicalWalls.map((wall) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: wall.isExterior
                              ? const Color(0xFF1E3A5F).withValues(alpha: 0.12)
                              : const Color(0xFFFF8C00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          wall.isExterior
                              ? 'Exterior Perimeter Wall'
                              : 'Interior Shared Wall',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: wall.isExterior
                                ? const Color(0xFF1E3A5F)
                                : const Color(0xFFFF8C00),
                          ),
                        ),
                      ),
                      Text(
                        'Net Vol: ${numFormat.format(wall.netVolumeCuFt)} cu ft',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Length: ${numFormat.format(wall.lengthFeet)} ft  •  Height: ${numFormat.format(wall.heightFeet)} ft  •  Thickness: ${(wall.thicknessFeet * 12.0).toStringAsFixed(1)} in',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  if (wall.openings.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Openings on this wall: ${wall.openings.map((o) => '${o.type.label} (${o.widthFeet} ft)').join(', ')} (-${numFormat.format(wall.openingsAreaSqFt)} sq ft)',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPill({
    required String label,
    required String value,
    required bool isDark,
    bool highlight = false,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFF8C00).withValues(alpha: 0.12)
            : (isDark ? Colors.white10 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold || highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? const Color(0xFFFF8C00) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(
    String label,
    String value,
    bool isDark, {
    bool bold = false,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
