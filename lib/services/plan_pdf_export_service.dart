import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/plan/export_metadata.dart';
import '../models/plan/material_estimation_models.dart';
import '../models/plan/plan_models.dart';
import '../models/plan/plan_unit.dart';
import 'plan_image_export_service.dart';

/// Professional PDF Generation Service for 2D Floor Plans and Material Quantity & Cost Reports.
class PlanPdfExportService {
  /// Generates a comprehensive 2D Floor Plan PDF document with high-res plan drawing,
  /// dimensioned room schedules, project specifications, and client details.
  static Future<Uint8List> generateFloorPlanPdf({
    required FloorPlan plan,
    required ReportMetadata metadata,
    Uint8List? planImageBytes,
    PlanUnit? displayUnit,
  }) async {
    final pdf = pw.Document(
      title: metadata.title.isNotEmpty
          ? metadata.title
          : '${plan.name} - 2D Floor Plan',
      author: metadata.companyName.isNotEmpty
          ? metadata.companyName
          : 'BuildCalc Architectural',
    );

    final unit = displayUnit ?? plan.unit;
    final imageBytes =
        planImageBytes ??
        await PlanImageExportService.renderPlanToPng(plan: plan);
    final pdfImage = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildPdfHeader(metadata, plan, '2D ARCHITECTURAL FLOOR PLAN'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),

          // Client & Company Details block if provided
          if (metadata.hasClientDetails || metadata.hasCompanyDetails) ...[
            _buildMetadataDetailsCard(metadata),
            pw.SizedBox(height: 14),
          ],

          // High Resolution 2D Floor Plan Image Container
          pw.Container(
            height: 280,
            width: double.infinity,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey200, width: 1.0),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 6,
              verticalRadius: 6,
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            ),
          ),
          pw.SizedBox(height: 16),

          // Plot & Layout Specifications Grid
          pw.Text(
            'PROJECT SPECIFICATIONS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1E3A5F'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tableCell('Plot Dimensions', isHeader: true),
                  _tableCell(
                    '${unit.formatLength(plan.plotWidthFeet)} × ${unit.formatLength(plan.plotLengthFeet)}',
                  ),
                  _tableCell('Total Plot Area', isHeader: true),
                  _tableCell(unit.formatArea(plan.totalPlotAreaSqFt)),
                ],
              ),
              pw.TableRow(
                children: [
                  _tableCell('Built-up Area', isHeader: true),
                  _tableCell(unit.formatArea(plan.totalBuiltUpAreaSqFt)),
                  _tableCell('Ground Coverage', isHeader: true),
                  _tableCell(
                    '${plan.groundCoveragePercent.toStringAsFixed(1)}%',
                  ),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey50),
                children: [
                  _tableCell('Layout Configuration', isHeader: true),
                  _tableCell(plan.layoutType),
                  _tableCell('Total Rooms / Openings', isHeader: true),
                  _tableCell(
                    '${plan.rooms.length} rooms / ${plan.rooms.fold<int>(0, (s, r) => s + r.openings.length)} openings',
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Dimensioned Room Schedule Table (Auto-wrapping across pages if long)
          pw.Text(
            'DIMENSIONED ROOM SCHEDULE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1E3A5F'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1E3A5F),
            ),
            headerHeight: 24,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            headers: [
              '#',
              'Room Name',
              'Room Type',
              'Dimensions (W × L)',
              'Carpet Area',
              'Wall Openings',
              'Wall Perimeter',
            ],
            data: plan.rooms.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final r = entry.value;
              final doorsCount = r.openings
                  .where(
                    (o) =>
                        o.type == OpeningType.door ||
                        o.type == OpeningType.doubleDoor ||
                        o.type == OpeningType.slidingDoor,
                  )
                  .length;
              final windowsCount = r.openings
                  .where(
                    (o) =>
                        o.type == OpeningType.window ||
                        o.type == OpeningType.ventilation,
                  )
                  .length;
              final openingsStr =
                  '${r.openings.length} ($doorsCount D, $windowsCount W)';
              final perimeterFeet = (r.width + r.length) * 2;

              return [
                '$idx',
                r.name,
                r.type.displayName,
                unit.formatDimensions(r.width, r.length),
                unit.formatArea(r.areaSqFt),
                openingsStr,
                unit.formatLength(perimeterFeet),
              ];
            }).toList(),
          ),

          if (metadata.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: PdfColors.amber300, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PROJECT NOTES & REMARKS:',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown900,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    metadata.notes,
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.brown800,
                    ),
                  ),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 16),
          _buildStatutoryDisclaimer(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates a comprehensive Material Quantity and Cost Estimation PDF report with
  /// exact mathematical breakdowns, itemized bill of quantities, rates, and structural assumptions.
  static Future<Uint8List> generateMaterialEstimatePdf({
    required FloorPlan plan,
    required PlanMaterialEstimateReport report,
    required MaterialEstimationAssumptions assumptions,
    required ReportMetadata metadata,
    PlanUnit displayUnit = PlanUnit.feet,
  }) async {
    final pdf = pw.Document(
      title: metadata.title.isNotEmpty
          ? metadata.title
          : '${plan.name} - Material & Cost Estimate',
      author: metadata.companyName.isNotEmpty
          ? metadata.companyName
          : 'BuildCalc Estimator',
    );

    final currency = _safeCurrency(assumptions.currencySymbol);
    final costFormat = NumberFormat('#,##0.00');
    final numFormat = NumberFormat('#,##0.0');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(
          metadata,
          plan,
          'BILL OF QUANTITIES & COST ESTIMATE',
        ),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 10),

          // Client & Company Details block if provided
          if (metadata.hasClientDetails || metadata.hasCompanyDetails) ...[
            _buildMetadataDetailsCard(metadata),
            pw.SizedBox(height: 12),
          ],

          // Hero Executive Summary Banner
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1E3A5F),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TOTAL ESTIMATED MATERIAL COST',
                      style: pw.TextStyle(
                        color: const PdfColor.fromInt(0xFFFF8C00),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      metadata.includeRatesAndCosts
                          ? '$currency ${costFormat.format(report.totalEstimatedCost)}'
                          : 'QUANTITIES ONLY (RATES HIDDEN)',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Built-up Area: ${displayUnit.formatArea(report.totalBuiltUpAreaSqFt)}',
                      style: const pw.TextStyle(
                        color: PdfColors.grey200,
                        fontSize: 9.5,
                      ),
                    ),
                    pw.Text(
                      'Carpet Area: ${displayUnit.formatArea(report.totalCarpetAreaSqFt)}',
                      style: const pw.TextStyle(
                        color: PdfColors.grey200,
                        fontSize: 9.5,
                      ),
                    ),
                    pw.Text(
                      'Net Masonry: ${numFormat.format(report.netMasonryVolumeCuFt)} cu.ft',
                      style: const pw.TextStyle(
                        color: PdfColors.grey200,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Quantitative Engineering Highlights
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tableCell('Physical Wall Length', isHeader: true),
                  _tableCell(
                    '${numFormat.format(report.totalPhysicalWallLengthFeet)} ft (${numFormat.format(report.exteriorWallLengthFeet)} ft Ext + ${numFormat.format(report.interiorSharedWallLengthFeet)} ft Shared Int)',
                  ),
                  _tableCell('Masonry Volume', isHeader: true),
                  _tableCell(
                    '${numFormat.format(report.netMasonryVolumeCuFt)} cu.ft (Gross: ${numFormat.format(report.grossMasonryVolumeCuFt)} cu.ft)',
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  _tableCell('Deducted Openings', isHeader: true),
                  _tableCell(
                    '${report.totalOpeningsCount} openings (${numFormat.format(report.totalOpeningsAreaSqFt)} sq.ft deducted)',
                  ),
                  _tableCell('Openings Volume Deduction', isHeader: true),
                  _tableCell(
                    '${numFormat.format(report.openingsDeductionVolumeCuFt)} cu.ft',
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Itemized Bill of Quantities & Material Costs Table (Auto-page breaking)
          pw.Text(
            'ITEMIZED MATERIAL QUANTITIES & ESTIMATED RATES',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1E3A5F'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1E3A5F),
            ),
            headerHeight: 22,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headers: metadata.includeRatesAndCosts
                ? [
                    'Material Item',
                    'Net Qty',
                    'Wastage',
                    'Total Qty',
                    'Unit',
                    'Rate ($currency)',
                    'Total Cost ($currency)',
                    'Engineering Basis / Formula',
                  ]
                : [
                    'Material Item',
                    'Net Qty',
                    'Wastage',
                    'Total Qty',
                    'Unit',
                    'Engineering Basis / Formula',
                  ],
            data: report.lineItems.map((item) {
              if (metadata.includeRatesAndCosts) {
                return [
                  item.name,
                  numFormat.format(item.netQuantity),
                  '${item.wastagePercent}%',
                  numFormat.format(item.totalQuantity),
                  item.unit,
                  costFormat.format(item.unitRate),
                  costFormat.format(item.totalCost),
                  item.formulaBreakdown,
                ];
              } else {
                return [
                  item.name,
                  numFormat.format(item.netQuantity),
                  '${item.wastagePercent}%',
                  numFormat.format(item.totalQuantity),
                  item.unit,
                  item.formulaBreakdown,
                ];
              }
            }).toList(),
          ),
          pw.SizedBox(height: 16),

          // Structural Assumptions and Rates Used section
          pw.Text(
            'ENGINEERING ASSUMPTIONS & DESIGN SPECIFICATIONS',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1E3A5F'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _specRow(
                            'Masonry Unit:',
                            '${assumptions.masonryType.label} (joint ${assumptions.mortarJointThicknessInches}")',
                          ),
                          _specRow(
                            'Wall Heights:',
                            'Ceiling ${assumptions.wallHeightFeet} ft (Ext ${assumptions.exteriorWallThicknessFeet} ft, Int ${assumptions.interiorWallThicknessFeet} ft)',
                          ),
                          _specRow('Mortar Mix:', assumptions.mortarMix.label),
                          _specRow(
                            'Plaster Details:',
                            '${assumptions.plasterMix.label} (Int ${assumptions.interiorPlasterThicknessInches}", Ext ${assumptions.exteriorPlasterThicknessInches}")',
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _specRow(
                            'RCC Elements:',
                            assumptions.includeRoofSlab
                                ? '${assumptions.roofSlabThicknessInches}" slab (${assumptions.concreteGrade.label})'
                                : 'Masonry superstructure',
                          ),
                          _specRow(
                            'Paint Coverage:',
                            '${assumptions.interiorPaintCoverageSqFtPerLiter} sq.ft/L (${assumptions.interiorPaintCoats} coats)',
                          ),
                          _specRow(
                            'Wastage Factors:',
                            'Bricks ${assumptions.brickWastagePercent}%, Plaster ${assumptions.plasterWastagePercent}%, Tiles ${assumptions.tileWastagePercent}%',
                          ),
                          _specRow(
                            'Rates Applied:',
                            'Brk: $currency${assumptions.brickRatePerUnit} | Cmt: $currency${assumptions.cementRatePerBag} | Sand: $currency${assumptions.sandRatePerCuFt}/cu.ft',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Room-by-room masonry schedule breakdown
          if (report.roomBreakdowns.isNotEmpty) ...[
            pw.Text(
              'ROOM-WISE MASONRY & OPENINGS BREAKDOWN',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1E3A5F'),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF334155),
              ),
              headerHeight: 20,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              headers: [
                'Room Name',
                'Carpet Area',
                'Perimeter',
                'Gross Wall Surface',
                'Deducted Openings',
                'Net Wall Surface',
              ],
              data: report.roomBreakdowns.map((room) {
                return [
                  room.roomName,
                  displayUnit.formatArea(room.carpetAreaSqFt),
                  '${numFormat.format(room.perimeterFeet)} ft',
                  '${numFormat.format(room.grossWallSurfaceSqFt)} sq.ft',
                  '${room.openingsCount} (${numFormat.format(room.openingsAreaSqFt)} sq.ft)',
                  '${numFormat.format(room.netWallSurfaceSqFt)} sq.ft',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 14),
          ],

          if (metadata.notes.trim().isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: PdfColors.amber300, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ESTIMATE REMARKS & SITE CONDITIONS:',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown900,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    metadata.notes,
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.brown800,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
          ],

          _buildStatutoryDisclaimer(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Saves PDF bytes to application documents or cache directory.
  static Future<File> savePdfToFile({
    required Uint8List pdfBytes,
    required String fileName,
    bool useTemporaryDir = false,
  }) async {
    Directory directory;
    try {
      directory = useTemporaryDir
          ? await getTemporaryDirectory()
          : await getApplicationDocumentsDirectory();
    } catch (_) {
      directory = Directory.systemTemp;
    }

    final safeName = fileName
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/${safeName}_$timestamp.pdf');

    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  // --- Internal PDF Layout Helpers ---

  static pw.Widget _buildPdfHeader(
    ReportMetadata metadata,
    FloorPlan plan,
    String reportTypeTitle,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromInt(0xFF1E3A5F),
            width: 1.5,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Text(
                    'BUILDCALC',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF1E3A5F),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFF8C00),
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      'PRO',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                reportTypeTitle,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                metadata.projectName.isNotEmpty
                    ? metadata.projectName
                    : plan.name,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF0F172A),
                ),
              ),
              pw.Text(
                'Date: ${dateFormat.format(metadata.createdAt)}',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'BuildCalc | Professional Civil & Architectural Solutions | Confidential',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetadataDetailsCard(ReportMetadata metadata) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (metadata.hasClientDetails)
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CLIENT / CUSTOMER DETAILS:',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF1E3A5F),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  if (metadata.clientName.isNotEmpty)
                    pw.Text(
                      metadata.clientName,
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  if (metadata.clientPhone.isNotEmpty)
                    pw.Text(
                      'Phone: ${metadata.clientPhone}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  if (metadata.clientEmail.isNotEmpty)
                    pw.Text(
                      'Email: ${metadata.clientEmail}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  if (metadata.projectLocation.isNotEmpty)
                    pw.Text(
                      'Site: ${metadata.projectLocation}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
            ),
          if (metadata.hasClientDetails && metadata.hasCompanyDetails)
            pw.SizedBox(width: 14),
          if (metadata.hasCompanyDetails)
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PREPARED BY / ARCHITECT / CONTRACTOR:',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF1E3A5F),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  if (metadata.companyName.isNotEmpty)
                    pw.Text(
                      metadata.companyName,
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  if (metadata.preparedBy.isNotEmpty)
                    pw.Text(
                      'Engineer/Designer: ${metadata.preparedBy}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  if (metadata.companyPhone.isNotEmpty)
                    pw.Text(
                      'Contact: ${metadata.companyPhone}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  if (metadata.companyAddress.isNotEmpty)
                    pw.Text(
                      metadata.companyAddress,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatutoryDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'STATUTORY NOTICE & ENGINEERING DISCLAIMER:',
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'This drawing and material estimation report is generated based on geometric mathematical parameters, nominal masonry deductions, and user-configured unit rates. Actual site conditions, soil bearing capacities, seismic structural codes, concrete mix designs, local labor logistics, and contractor margins must be independently verified by a licensed civil engineer or registered architect prior to execution.',
            style: const pw.TextStyle(
              fontSize: 6.8,
              color: PdfColors.grey700,
              lineSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader
              ? const PdfColor.fromInt(0xFF1E3A5F)
              : PdfColors.black,
        ),
      ),
    );
  }

  static String _safeCurrency(String symbol) {
    if (symbol == '₹') return 'Rs.';
    if (symbol == '€') return 'EUR';
    if (symbol == '£') return 'GBP';
    return symbol;
  }

  static pw.Widget _specRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 7.8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 7.8,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
