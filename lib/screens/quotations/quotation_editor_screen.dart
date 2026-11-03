import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/quotation.dart';
import '../../services/ad_service.dart';
import '../../services/quotation_pdf_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ad_banner.dart';

class QuotationEditorScreen extends StatefulWidget {
  final Quotation? initialQuotation;
  final List<QuotationItem>? initialItems;
  final String? initialProjectName;

  const QuotationEditorScreen({
    super.key,
    this.initialQuotation,
    this.initialItems,
    this.initialProjectName,
  });

  @override
  State<QuotationEditorScreen> createState() => _QuotationEditorScreenState();
}

class _QuotationEditorScreenState extends State<QuotationEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contractor Controllers
  final _contractorNameController = TextEditingController();
  final _contractorPhoneController = TextEditingController();
  final _contractorEmailController = TextEditingController();
  final _contractorAddressController = TextEditingController();

  // Client & Project Controllers
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _projectLocationController = TextEditingController();
  final _quoteNumberController = TextEditingController();

  // Financial Controllers
  final _taxPercentController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _notesController = TextEditingController(
    text:
        '1. 50% advance payment required upon agreement.\n2. Water, electricity, and site access to be provided by client.\n3. Quotation valid for 15 days from issue date.',
  );

  String _currencySymbol = '\$';
  DateTime _quoteDate = DateTime.now();
  DateTime? _validUntil = DateTime.now().add(const Duration(days: 15));
  String _status = 'Draft';

  List<QuotationItem> _items = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final existing = widget.initialQuotation;
    if (existing != null) {
      _quoteNumberController.text = existing.quoteNumber;
      _contractorNameController.text = existing.contractorName;
      _contractorPhoneController.text = existing.contractorPhone;
      _contractorEmailController.text = existing.contractorEmail;
      _contractorAddressController.text = existing.contractorAddress;

      _clientNameController.text = existing.clientName;
      _clientPhoneController.text = existing.clientPhone;
      _projectNameController.text = existing.projectName;
      _projectLocationController.text = existing.projectLocation;

      _taxPercentController.text = existing.taxPercent.toString();
      _discountController.text = existing.discountAmount.toString();
      _notesController.text = existing.notes;
      _currencySymbol = existing.currencySymbol;
      _quoteDate = existing.date;
      _validUntil = existing.validUntil;
      _status = existing.status;
      _items = List.from(existing.items);
    } else {
      // Auto-generate quote number: e.g. BC-2026-XXXX
      final randSuffix = (DateTime.now().millisecondsSinceEpoch % 10000)
          .toString()
          .padLeft(4, '0');
      _quoteNumberController.text = 'BC-${DateTime.now().year}-$randSuffix';

      // Load remembered contractor profile
      final profile = await StorageService.getContractorProfile();
      if (profile.isNotEmpty) {
        _contractorNameController.text = profile['name'] ?? '';
        _contractorPhoneController.text = profile['phone'] ?? '';
        _contractorEmailController.text = profile['email'] ?? '';
        _contractorAddressController.text = profile['address'] ?? '';
        if (profile['currencySymbol'] != null &&
            profile['currencySymbol']!.isNotEmpty) {
          _currencySymbol = profile['currencySymbol']!;
        }
      }

      if (widget.initialProjectName != null) {
        _projectNameController.text = widget.initialProjectName!;
      }

      if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
        _items = List.from(widget.initialItems!);
      } else {
        // Start with one sample item
        _items = [
          const QuotationItem(
            id: 'item_1',
            description: 'Civil Construction & Masonry Work',
            quantity: 1,
            unit: 'lumpsum',
            unitPrice: 0,
          ),
        ];
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _contractorNameController.dispose();
    _contractorPhoneController.dispose();
    _contractorEmailController.dispose();
    _contractorAddressController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _projectNameController.dispose();
    _projectLocationController.dispose();
    _quoteNumberController.dispose();
    _taxPercentController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Quotation _buildCurrentQuotation() {
    final tax = double.tryParse(_taxPercentController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    return Quotation(
      id: widget.initialQuotation?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      quoteNumber: _quoteNumberController.text.trim().isNotEmpty
          ? _quoteNumberController.text.trim()
          : 'BC-${DateTime.now().year}-001',
      date: _quoteDate,
      validUntil: _validUntil,
      contractorName: _contractorNameController.text.trim(),
      contractorPhone: _contractorPhoneController.text.trim(),
      contractorEmail: _contractorEmailController.text.trim(),
      contractorAddress: _contractorAddressController.text.trim(),
      clientName: _clientNameController.text.trim(),
      clientPhone: _clientPhoneController.text.trim(),
      projectName: _projectNameController.text.trim().isNotEmpty
          ? _projectNameController.text.trim()
          : 'Construction Project',
      projectLocation: _projectLocationController.text.trim(),
      items: _items,
      taxPercent: tax,
      discountAmount: discount,
      currencySymbol: _currencySymbol,
      notes: _notesController.text.trim(),
      status: _status,
    );
  }

  Future<void> _saveQuotation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to quotation')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final quote = _buildCurrentQuotation();

    // Auto-save contractor profile so it's remembered next time
    if (quote.contractorName.isNotEmpty) {
      await StorageService.saveContractorProfile(
        name: quote.contractorName,
        phone: quote.contractorPhone,
        email: quote.contractorEmail,
        address: quote.contractorAddress,
        currencySymbol: quote.currencySymbol,
      );
    }

    await StorageService.saveQuotation(quote);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Quotation saved successfully!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  void _addItemDialog([QuotationItem? editItem, int? editIndex]) {
    final descController =
        TextEditingController(text: editItem?.description ?? '');
    final qtyController =
        TextEditingController(text: editItem != null ? editItem.quantity.toString() : '1');
    final unitController =
        TextEditingController(text: editItem?.unit ?? 'pcs');
    final rateController =
        TextEditingController(text: editItem != null ? editItem.unitPrice.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    editItem != null ? 'Edit Line Item' : 'Add Line Item',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick Construction Presets
              if (editItem == null) ...[
                const Text(
                  'Quick Presets:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _presetChip('Cement Bags', 'bags', descController, unitController),
                      _presetChip('Bricks (Standard)', 'pcs', descController, unitController),
                      _presetChip('River / M-Sand', 'brass', descController, unitController),
                      _presetChip('TMT Steel', 'tonnes', descController, unitController),
                      _presetChip('Floor Tiles', 'sq ft', descController, unitController),
                      _presetChip('Wall Paint', 'liters', descController, unitController),
                      _presetChip('Masonry Labor', 'days', descController, unitController),
                      _presetChip('Excavation', 'cu ft', descController, unitController),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Item Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit (bags, pcs, sqft)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Rate per unit ($_currencySymbol) *',
                  border: const OutlineInputBorder(),
                  prefixText: '$_currencySymbol ',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(editItem != null ? 'Update Item' : 'Add to Quote'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final desc = descController.text.trim();
                    final qty = double.tryParse(qtyController.text) ?? 1.0;
                    final unit = unitController.text.trim().isNotEmpty
                        ? unitController.text.trim()
                        : 'unit';
                    final rate = double.tryParse(rateController.text) ?? 0.0;

                    if (desc.isEmpty) return;

                    final newItem = QuotationItem(
                      id: editItem?.id ??
                          'item_${DateTime.now().millisecondsSinceEpoch}',
                      description: desc,
                      quantity: qty,
                      unit: unit,
                      unitPrice: rate,
                    );

                    setState(() {
                      if (editIndex != null) {
                        _items[editIndex] = newItem;
                      } else {
                        _items.add(newItem);
                      }
                    });

                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _presetChip(
    String label,
    String unit,
    TextEditingController desc,
    TextEditingController unitCtrl,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        backgroundColor: const Color(0xFFFF8C00).withValues(alpha: 0.1),
        side: BorderSide(color: const Color(0xFFFF8C00).withValues(alpha: 0.3)),
        onPressed: () {
          desc.text = label;
          unitCtrl.text = unit;
        },
      ),
    );
  }

  Future<void> _shareQuote() async {
    final quote = _buildCurrentQuotation();
    if (quote.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to quote before sharing')),
      );
      return;
    }

    try {
      await QuotationPdfService.shareQuotationPdf(quote);
      AdService.showInterstitialAfterCalculation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _printOrPreviewQuote() async {
    final quote = _buildCurrentQuotation();
    if (quote.items.isEmpty) return;
    try {
      await QuotationPdfService.printQuotation(quote);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rendering print preview: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuote = _buildCurrentQuotation();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialQuotation != null
            ? 'Edit Quotation'
            : 'New Client Quotation'),
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print / Preview',
            onPressed: _printOrPreviewQuote,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share via WhatsApp / PDF',
            onPressed: _shareQuote,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Viral/Professional Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFFFF8C00), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contractor Quotation Generator',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '100% Free • Export WhatsApp PDF with your business name',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 1: Contractor / Business Details
            _buildSectionCard(
              title: 'Your Business / Contractor Profile',
              icon: Icons.business_center_rounded,
              isDark: isDark,
              child: Column(
                children: [
                  TextFormField(
                    controller: _contractorNameController,
                    decoration: const InputDecoration(
                      labelText: 'Contractor / Company Name *',
                      hintText: 'e.g. Apex Civil Contractors',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Business name is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _contractorPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone / WhatsApp *',
                            hintText: '+1 555-0199',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Phone number is required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Currency Selector
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<String>(
                          initialValue: _currencySymbol,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '\$',
                              child: Text('\$ USD', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: '₹',
                              child: Text('₹ INR', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: '£',
                              child: Text('£ GBP', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: '€',
                              child: Text('€ EUR', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'AED',
                              child: Text('AED', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: '₱',
                              child: Text('₱ PHP', overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _currencySymbol = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _contractorAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Office Address / City (Optional)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Client & Project Details
            _buildSectionCard(
              title: 'Client & Site Details',
              icon: Icons.person_rounded,
              isDark: isDark,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quoteNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Quote Number',
                            prefixIcon: Icon(Icons.tag_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Draft',
                              child: Text('Draft', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Sent',
                              child: Text('Sent', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Approved',
                              child: Text('Approved', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'Completed',
                              child: Text('Completed', overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Client Name *',
                      hintText: 'e.g. John Doe',
                      prefixIcon: Icon(Icons.account_circle_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Client name is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _projectNameController,
                          decoration: const InputDecoration(
                            labelText: 'Project Name *',
                            hintText: 'e.g. 2-Storey Villa / Bathroom Reno',
                            prefixIcon: Icon(Icons.home_work_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Project name is required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _projectLocationController,
                          decoration: const InputDecoration(
                            labelText: 'Site Location',
                            hintText: 'Plot 42, Green Avenue',
                            prefixIcon: Icon(Icons.pin_drop_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 3: Itemized Works & Materials
            _buildSectionCard(
              title: 'Items & Estimated Costs (${_items.length})',
              icon: Icons.list_alt_rounded,
              isDark: isDark,
              trailing: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF8C00), size: 16),
                label: const Text(
                  'Add Item',
                  style: TextStyle(
                    color: Color(0xFFFF8C00),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                onPressed: () => _addItemDialog(),
              ),
              child: Column(
                children: [
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No items added yet. Tap "+ Add Item" above.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF8C00),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity} ${item.unit} × $_currencySymbol${item.unitPrice.toStringAsFixed(2)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_currencySymbol${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFFF8C00),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              onPressed: () => _addItemDialog(item, idx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              onPressed: () {
                                setState(() => _items.removeAt(idx));
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 4: Taxes, Discounts & Summary
            _buildSectionCard(
              title: 'Totals & Financial Summary',
              icon: Icons.account_balance_wallet_rounded,
              isDark: isDark,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Discount ($_currencySymbol)',
                            prefixIcon: const Icon(Icons.discount_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _taxPercentController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Tax / GST %',
                            prefixIcon: Icon(Icons.percent_rounded),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _summaryLine('Subtotal',
                            '$_currencySymbol ${currentQuote.subtotal.toStringAsFixed(2)}'),
                        if (currentQuote.discountAmount > 0)
                          _summaryLine(
                            'Discount',
                            '- $_currencySymbol ${currentQuote.discountAmount.toStringAsFixed(2)}',
                            color: Colors.redAccent,
                          ),
                        if (currentQuote.taxPercent > 0)
                          _summaryLine(
                            'Tax (${currentQuote.taxPercent}%)',
                            '+ $_currencySymbol ${currentQuote.taxAmount.toStringAsFixed(2)}',
                          ),
                        const Divider(thickness: 1.2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '$_currencySymbol ${NumberFormat('#,##0.00').format(currentQuote.grandTotal)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFFFF8C00),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 5: Terms and Notes
            _buildSectionCard(
              title: 'Terms & Conditions / Site Notes',
              icon: Icons.notes_rounded,
              isDark: isDark,
              child: TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter payment milestones, validity, and site terms...',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366)),
                    label: const Text('Share WhatsApp / PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                    ),
                    onPressed: _shareQuote,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('Save Quote'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSaving ? null : _saveQuotation,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const AppBannerAd(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: const Color(0xFFFF8C00), size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
