import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quotation.dart';

class QuotationPdfService {
  static const PdfColor primaryNavy = PdfColor.fromInt(0xFF1E3A5F);
  static const PdfColor accentOrange = PdfColor.fromInt(0xFFFF8C00);
  static const PdfColor darkSlate = PdfColor.fromInt(0xFF334155);
  static const PdfColor lightBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor borderLight = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor successGreen = PdfColor.fromInt(0xFF16A34A);

  /// Generates the PDF document as bytes
  static Future<Uint8List> generatePdf(Quotation quote) async {
    final pdf = pw.Document(
      title: 'Quotation_${quote.quoteNumber}',
      author: quote.contractorName.isNotEmpty
          ? quote.contractorName
          : 'BuildCalc Contractor',
    );

    pw.Font fontRegular = pw.Font.helvetica();
    pw.Font fontBold = pw.Font.helveticaBold();
    pw.Font fontSemiBold = pw.Font.helveticaBold();
    try {
      fontRegular = await PdfGoogleFonts.interRegular();
      fontBold = await PdfGoogleFonts.interBold();
      fontSemiBold = await PdfGoogleFonts.interSemiBold();
    } catch (_) {
      // Offline fallback: use built-in standard fonts
    }

    final dateFormat = DateFormat('MMM dd, yyyy');
    final currency = quote.currencySymbol;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [fontRegular],
        ),
        header: (context) => _buildHeader(quote, dateFormat, fontBold),
        footer: (context) => _buildFooter(context, fontRegular),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildInfoCards(quote, dateFormat, fontSemiBold),
          pw.SizedBox(height: 18),
          _buildItemsTable(quote, currency, fontBold, fontSemiBold),
          pw.SizedBox(height: 14),
          _buildFinancialSummary(quote, currency, fontBold),
          if (quote.notes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildNotesSection(quote.notes, fontBold),
          ],
          pw.SizedBox(height: 28),
          _buildSignatures(quote, fontSemiBold),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    Quotation quote,
    DateFormat dateFormat,
    pw.Font fontBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: accentOrange, width: 2.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  quote.contractorName.isNotEmpty
                      ? quote.contractorName
                      : 'CONTRACTOR QUOTATION',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 20,
                    color: primaryNavy,
                  ),
                ),
                if (quote.contractorPhone.isNotEmpty)
                  pw.Text(
                    'Phone: ${quote.contractorPhone}',
                    style: const pw.TextStyle(fontSize: 10, color: darkSlate),
                  ),
                if (quote.contractorEmail.isNotEmpty)
                  pw.Text(
                    'Email: ${quote.contractorEmail}',
                    style: const pw.TextStyle(fontSize: 10, color: darkSlate),
                  ),
                if (quote.contractorAddress.isNotEmpty)
                  pw.Text(
                    quote.contractorAddress,
                    style: const pw.TextStyle(fontSize: 9, color: darkSlate),
                  ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: primaryNavy,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'ESTIMATE / QUOTE',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Quote #: ${quote.quoteNumber}',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 11,
                  color: primaryNavy,
                ),
              ),
              pw.Text(
                'Date: ${dateFormat.format(quote.date)}',
                style: const pw.TextStyle(fontSize: 9, color: darkSlate),
              ),
              if (quote.validUntil != null)
                pw.Text(
                  'Valid Until: ${dateFormat.format(quote.validUntil!)}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.red700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoCards(
    Quotation quote,
    DateFormat dateFormat,
    pw.Font fontSemiBold,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Client Info
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: borderLight),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'QUOTATION FOR (CLIENT)',
                  style: pw.TextStyle(
                    font: fontSemiBold,
                    fontSize: 9,
                    color: accentOrange,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  quote.clientName.isNotEmpty ? quote.clientName : 'Valued Client',
                  style: pw.TextStyle(
                    font: fontSemiBold,
                    fontSize: 12,
                    color: primaryNavy,
                  ),
                ),
                if (quote.clientPhone.isNotEmpty)
                  pw.Text(
                    'Phone: ${quote.clientPhone}',
                    style: const pw.TextStyle(fontSize: 9, color: darkSlate),
                  ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        // Project Info
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: borderLight),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PROJECT / SITE DETAILS',
                  style: pw.TextStyle(
                    font: fontSemiBold,
                    fontSize: 9,
                    color: accentOrange,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  quote.projectName.isNotEmpty
                      ? quote.projectName
                      : 'Construction Project',
                  style: pw.TextStyle(
                    font: fontSemiBold,
                    fontSize: 12,
                    color: primaryNavy,
                  ),
                ),
                if (quote.projectLocation.isNotEmpty)
                  pw.Text(
                    'Site: ${quote.projectLocation}',
                    style: const pw.TextStyle(fontSize: 9, color: darkSlate),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(
    Quotation quote,
    String currency,
    pw.Font fontBold,
    pw.Font fontSemiBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderLight, width: 0.8),
      columnWidths: const {
        0: pw.FixedColumnWidth(28),
        1: pw.FlexColumnWidth(4.5),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FlexColumnWidth(2.0),
        5: pw.FlexColumnWidth(2.2),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: primaryNavy),
          children: [
            _buildTableHeaderCell('#', fontBold, align: pw.TextAlign.center),
            _buildTableHeaderCell('Item Description', fontBold),
            _buildTableHeaderCell('Qty', fontBold, align: pw.TextAlign.right),
            _buildTableHeaderCell('Unit', fontBold, align: pw.TextAlign.center),
            _buildTableHeaderCell('Rate ($currency)', fontBold,
                align: pw.TextAlign.right),
            _buildTableHeaderCell('Amount ($currency)', fontBold,
                align: pw.TextAlign.right),
          ],
        ),
        // Item Rows
        ...quote.items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          final isEven = index % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? lightBg : PdfColors.white,
            ),
            children: [
              _buildTableCell('$index', align: pw.TextAlign.center),
              _buildTableCell(item.description, isBold: true),
              _buildTableCell(_formatNumber(item.quantity),
                  align: pw.TextAlign.right),
              _buildTableCell(item.unit, align: pw.TextAlign.center),
              _buildTableCell(_formatCurrency(item.unitPrice),
                  align: pw.TextAlign.right),
              _buildTableCell(_formatCurrency(item.total),
                  align: pw.TextAlign.right, isBold: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(
    String text,
    pw.Font font, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          color: darkSlate,
        ),
      ),
    );
  }

  static pw.Widget _buildFinancialSummary(
    Quotation quote,
    String currency,
    pw.Font fontBold,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 240,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: lightBg,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: borderLight),
          ),
          child: pw.Column(
            children: [
              _buildSummaryRow(
                'Subtotal:',
                '$currency ${_formatCurrency(quote.subtotal)}',
              ),
              if (quote.discountAmount > 0) ...[
                pw.SizedBox(height: 3),
                _buildSummaryRow(
                  'Discount:',
                  '- $currency ${_formatCurrency(quote.discountAmount)}',
                  textColor: PdfColors.red700,
                ),
              ],
              if (quote.taxPercent > 0) ...[
                pw.SizedBox(height: 3),
                _buildSummaryRow(
                  'Tax / GST (${quote.taxPercent}%):',
                  '+ $currency ${_formatCurrency(quote.taxAmount)}',
                ),
              ],
              pw.Divider(color: accentOrange, thickness: 1.2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'GRAND TOTAL:',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 11,
                      color: primaryNavy,
                    ),
                  ),
                  pw.Text(
                    '$currency ${_formatCurrency(quote.grandTotal)}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                      color: accentOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    PdfColor? textColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: darkSlate),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            color: textColor ?? darkSlate,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildNotesSection(String notes, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderLight),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TERMS & CONDITIONS / NOTES',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 9,
              color: primaryNavy,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            notes,
            style: const pw.TextStyle(fontSize: 8.5, color: darkSlate),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatures(Quotation quote, pw.Font fontSemiBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 160,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: darkSlate, width: 1),
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Authorized Signature (Contractor)',
              style: pw.TextStyle(font: fontSemiBold, fontSize: 8.5, color: darkSlate),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 160,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: darkSlate, width: 1),
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Client Acceptance & Approval',
              style: pw.TextStyle(font: fontSemiBold, fontSize: 8.5, color: darkSlate),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font fontRegular) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: borderLight, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'Prepared with ',
                style: const pw.TextStyle(fontSize: 8, color: darkSlate),
              ),
              pw.Text(
                'BuildCalc',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: accentOrange,
                ),
              ),
              pw.Text(
                ' — Free Civil & Construction App (Play Store & App Store)',
                style: const pw.TextStyle(fontSize: 8, color: darkSlate),
              ),
            ],
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: darkSlate),
          ),
        ],
      ),
    );
  }

  /// Exports and shares the PDF with direct WhatsApp & System Share
  static Future<void> shareQuotationPdf(Quotation quote) async {
    final pdfBytes = await generatePdf(quote);
    final tempDir = await getTemporaryDirectory();
    final sanitizedNumber = quote.quoteNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
    final file = File('${tempDir.path}/Quotation_$sanitizedNumber.pdf');
    await file.writeAsBytes(pdfBytes);

    final clientName = quote.clientName.isNotEmpty ? quote.clientName : 'Client';
    final contractor = quote.contractorName.isNotEmpty ? quote.contractorName : 'BuildCalc Contractor';
    final projectName = quote.projectName.isNotEmpty ? quote.projectName : 'Construction Work';

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Quotation #$sanitizedNumber - $projectName',
      text: 'Hello $clientName,\n\nPlease find attached the official quotation for $projectName from $contractor.\n\nGenerated with BuildCalc — The Free Construction Calculator & 3D Plan App.',
    );
  }

  /// Print or preview layout using Printing
  static Future<void> printQuotation(Quotation quote) async {
    final pdfBytes = await generatePdf(quote);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Quotation_${quote.quoteNumber}.pdf',
    );
  }

  static String _formatCurrency(double amount) {
    final f = NumberFormat('#,##0.00');
    return f.format(amount);
  }

  static String _formatNumber(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return NumberFormat('#,##0.##').format(amount);
  }
}

