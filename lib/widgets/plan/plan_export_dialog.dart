import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../models/plan/export_metadata.dart';
import '../../models/plan/material_estimation_models.dart';
import '../../models/plan/plan_models.dart';
import '../../models/plan/plan_unit.dart';
import '../../services/plan_image_export_service.dart';
import '../../services/plan_material_estimator.dart';
import '../../services/plan_pdf_export_service.dart';
import '../../services/plan_share_service.dart';

enum ExportFormat { floorPlanPng, floorPlanPdf, materialEstimatePdf }

/// Dialog / Sheet allowing users to customize export options, customer/company metadata,
/// and share or save 2D floor plans and material calculation reports.
class PlanExportDialog extends StatefulWidget {
  final FloorPlan plan;
  final PlanUnit activeUnit;
  final ExportFormat initialFormat;
  final MaterialEstimationAssumptions? assumptions;
  final GlobalKey? repaintBoundaryKey;

  const PlanExportDialog({
    super.key,
    required this.plan,
    this.activeUnit = PlanUnit.feet,
    this.initialFormat = ExportFormat.floorPlanPdf,
    this.assumptions,
    this.repaintBoundaryKey,
  });

  /// Static helper to display the sheet easily
  static Future<void> show(
    BuildContext context, {
    required FloorPlan plan,
    PlanUnit activeUnit = PlanUnit.feet,
    ExportFormat initialFormat = ExportFormat.floorPlanPdf,
    MaterialEstimationAssumptions? assumptions,
    GlobalKey? repaintBoundaryKey,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlanExportDialog(
        plan: plan,
        activeUnit: activeUnit,
        initialFormat: initialFormat,
        assumptions: assumptions,
        repaintBoundaryKey: repaintBoundaryKey,
      ),
    );
  }

  @override
  State<PlanExportDialog> createState() => _PlanExportDialogState();
}

class _PlanExportDialogState extends State<PlanExportDialog> {
  late ExportFormat _selectedFormat;
  late TextEditingController _titleController;
  late TextEditingController _projectNameController;
  late TextEditingController _clientNameController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _clientEmailController;
  late TextEditingController _companyNameController;
  late TextEditingController _companyAddressController;
  late TextEditingController _companyPhoneController;
  late TextEditingController _companyEmailController;
  late TextEditingController _preparedByController;
  late TextEditingController _projectLocationController;
  late TextEditingController _notesController;

  bool _rememberCompany = false;
  bool _includeRatesAndCosts = true;
  bool _showCompanyFields = false;
  bool _isExporting = false;
  String _exportStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;

    final defaultTitle = _selectedFormat == ExportFormat.materialEstimatePdf
        ? '${widget.plan.name} - Bill of Quantities & Material Estimate'
        : '${widget.plan.name} - 2D Architectural Floor Plan';

    _titleController = TextEditingController(text: defaultTitle);
    _projectNameController = TextEditingController(text: widget.plan.name);
    _clientNameController = TextEditingController();
    _clientPhoneController = TextEditingController();
    _clientEmailController = TextEditingController();
    _companyNameController = TextEditingController();
    _companyAddressController = TextEditingController();
    _companyPhoneController = TextEditingController();
    _companyEmailController = TextEditingController();
    _preparedByController = TextEditingController();
    _projectLocationController = TextEditingController();
    _notesController = TextEditingController();

    _loadSavedCompanyProfile();
  }

  Future<void> _loadSavedCompanyProfile() async {
    final profile = await ReportMetadata.loadDefaultCompanyDetails();
    if (profile.isNotEmpty && mounted) {
      setState(() {
        _companyNameController.text = profile['companyName'] ?? '';
        _companyAddressController.text = profile['companyAddress'] ?? '';
        _companyPhoneController.text = profile['companyPhone'] ?? '';
        _companyEmailController.text = profile['companyEmail'] ?? '';
        _preparedByController.text = profile['preparedBy'] ?? '';
        _rememberCompany = true;
        if (_companyNameController.text.isNotEmpty) {
          _showCompanyFields = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _projectNameController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _preparedByController.dispose();
    _projectLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ReportMetadata _buildMetadata() {
    return ReportMetadata(
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : widget.plan.name,
      projectName: _projectNameController.text.trim().isNotEmpty
          ? _projectNameController.text.trim()
          : widget.plan.name,
      clientName: _clientNameController.text.trim(),
      clientPhone: _clientPhoneController.text.trim(),
      clientEmail: _clientEmailController.text.trim(),
      companyName: _companyNameController.text.trim(),
      companyAddress: _companyAddressController.text.trim(),
      companyPhone: _companyPhoneController.text.trim(),
      companyEmail: _companyEmailController.text.trim(),
      preparedBy: _preparedByController.text.trim(),
      projectLocation: _projectLocationController.text.trim(),
      notes: _notesController.text.trim(),
      includeRatesAndCosts: _includeRatesAndCosts,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _handleExport({required bool isShareAction}) async {
    setState(() {
      _isExporting = true;
      _exportStatusMessage = isShareAction
          ? 'Preparing share file...'
          : 'Generating document...';
    });

    try {
      if (_rememberCompany) {
        await ReportMetadata.saveDefaultCompanyDetails(
          companyName: _companyNameController.text.trim(),
          companyAddress: _companyAddressController.text.trim(),
          companyPhone: _companyPhoneController.text.trim(),
          companyEmail: _companyEmailController.text.trim(),
          preparedBy: _preparedByController.text.trim(),
        );
      }

      final metadata = _buildMetadata();
      Uint8List fileBytes;
      String fileName;
      String mimeType;

      switch (_selectedFormat) {
        case ExportFormat.floorPlanPng:
          _updateStatus('Rendering crisp 2D plan image...');
          fileBytes = await PlanImageExportService.captureBoundaryOrRender(
            boundaryKey: widget.repaintBoundaryKey,
            plan: widget.plan,
          );
          fileName = '${widget.plan.name}_2D_Plan.png';
          mimeType = 'image/png';
          break;

        case ExportFormat.floorPlanPdf:
          _updateStatus('Rendering 2D plan and building PDF...');
          final pngBytes = await PlanImageExportService.captureBoundaryOrRender(
            boundaryKey: widget.repaintBoundaryKey,
            plan: widget.plan,
          );
          fileBytes = await PlanPdfExportService.generateFloorPlanPdf(
            plan: widget.plan,
            metadata: metadata,
            planImageBytes: pngBytes,
            displayUnit: widget.activeUnit,
          );
          fileName = '${widget.plan.name}_2D_Plan.pdf';
          mimeType = 'application/pdf';
          break;

        case ExportFormat.materialEstimatePdf:
          _updateStatus('Computing engineering quantities and building PDF...');
          final assumptions =
              widget.assumptions ?? const MaterialEstimationAssumptions();
          final report = PlanMaterialEstimator.estimateMaterials(
            plan: widget.plan,
            assumptions: assumptions,
          );
          fileBytes = await PlanPdfExportService.generateMaterialEstimatePdf(
            plan: widget.plan,
            report: report,
            assumptions: assumptions,
            metadata: metadata,
            displayUnit: widget.activeUnit,
          );
          fileName = '${widget.plan.name}_Material_Estimate.pdf';
          mimeType = 'application/pdf';
          break;
      }

      if (!mounted) return;

      ExportActionResult result;
      if (isShareAction) {
        result = await PlanShareService.shareBytes(
          bytes: fileBytes,
          fileName: fileName,
          mimeType: mimeType,
          subject: metadata.title,
          text: '${metadata.title} - Generated by BuildCalc',
        );
      } else {
        if (_selectedFormat == ExportFormat.floorPlanPng) {
          result = await PlanShareService.saveBytesToDevice(
            bytes: fileBytes,
            fileName: fileName,
          );
        } else {
          // Native Print / Save as PDF
          result = await PlanShareService.printOrSavePdfNative(
            pdfBytes: fileBytes,
            fileName: fileName,
          );
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess
              ? const Color(0xFF059669)
              : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => _exportStatusMessage = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.ios_share_rounded,
                    color: Color(0xFF1E3A5F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export & Share Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Generate architectural PNG/PDF & cost reports',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 24),

            // Format Selection Chips
            const Text(
              'EXPORT FORMAT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFormatChip(
                    format: ExportFormat.floorPlanPdf,
                    label: '2D Plan (PDF)',
                    icon: Icons.picture_as_pdf_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildFormatChip(
                    format: ExportFormat.materialEstimatePdf,
                    label: 'Materials & Cost (PDF)',
                    icon: Icons.receipt_long_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildFormatChip(
                    format: ExportFormat.floorPlanPng,
                    label: '2D Plan (PNG Image)',
                    icon: Icons.image_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Report Title & Project Name
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Document Title',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.title_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 10),

            // Client / Customer Details (Optional)
            ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Customer / Client Details (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Include client name and contact on the report header',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              children: [
                const SizedBox(height: 6),
                TextField(
                  controller: _clientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Client / Customer Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _clientPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Client Phone',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _clientEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Client Email',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _projectLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Project Site / Location',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                ),
              ],
            ),

            // Company / Contractor Details (Optional)
            ExpansionTile(
              initiallyExpanded: _showCompanyFields,
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Company / Contractor / Architect Details (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Add professional branding to exports',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              children: [
                const SizedBox(height: 6),
                TextField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company / Firm Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.business_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _preparedByController,
                  decoration: const InputDecoration(
                    labelText: 'Prepared By (Architect / Engineer)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _companyPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Company Phone',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _companyEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Company Email',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _companyAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Office Address',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Remember company details for future exports',
                  ),
                  value: _rememberCompany,
                  onChanged: (val) {
                    setState(() => _rememberCompany = val ?? false);
                  },
                ),
              ],
            ),

            // Additional Options (Notes & Pricing toggle)
            if (_selectedFormat == ExportFormat.materialEstimatePdf)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Include material rates and estimated total cost',
                ),
                subtitle: const Text(
                  'Uncheck to export quantities and engineering formulas only',
                ),
                value: _includeRatesAndCosts,
                onChanged: (val) {
                  setState(() => _includeRatesAndCosts = val ?? true);
                },
              ),

            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Project Notes & Site Remarks (Optional)',
                border: OutlineInputBorder(),
                isDense: true,
                hintText:
                    'e.g. Ground floor only; excludes municipal approval fees',
              ),
            ),
            const SizedBox(height: 20),

            // Loading indicator or Action Buttons
            if (_isExporting)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      Text(
                        _exportStatusMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleExport(isShareAction: false),
                      icon: Icon(
                        _selectedFormat == ExportFormat.floorPlanPng
                            ? Icons.save_alt_rounded
                            : Icons.print_rounded,
                        size: 20,
                      ),
                      label: Text(
                        _selectedFormat == ExportFormat.floorPlanPng
                            ? 'Save Image'
                            : 'Save / Print PDF',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _handleExport(isShareAction: true),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('Share File'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip({
    required ExportFormat format,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFormat == format;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFormat = format;
            if (format == ExportFormat.materialEstimatePdf) {
              _titleController.text =
                  '${widget.plan.name} - Bill of Quantities & Material Estimate';
            } else if (format == ExportFormat.floorPlanPdf) {
              _titleController.text =
                  '${widget.plan.name} - 2D Architectural Floor Plan';
            } else {
              _titleController.text = '${widget.plan.name} - 2D Plan Image';
            }
          });
        }
      },
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : const Color(0xFF1E3A5F),
      ),
      label: Text(label),
      selectedColor: const Color(0xFF1E3A5F),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : null,
      ),
    );
  }
}
