import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/quotation.dart';
import '../../services/ad_service.dart';
import '../../services/quotation_pdf_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/empty_state.dart';
import 'quotation_editor_screen.dart';

class QuotationsListScreen extends StatefulWidget {
  const QuotationsListScreen({super.key});

  @override
  State<QuotationsListScreen> createState() => _QuotationsListScreenState();
}

class _QuotationsListScreenState extends State<QuotationsListScreen> {
  List<Quotation> _quotations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    final quotes = await StorageService.getQuotations();
    if (!mounted) return;
    setState(() {
      _quotations = quotes;
      _isLoading = false;
    });
  }

  List<Quotation> get _filteredQuotations {
    return _quotations.where((q) {
      if (_statusFilter != 'All' && q.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return q.clientName.toLowerCase().contains(query) ||
          q.projectName.toLowerCase().contains(query) ||
          q.quoteNumber.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteQuotation(Quotation quote) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quotation?'),
        content: Text(
          'Are you sure you want to delete quote #${quote.quoteNumber} for ${quote.clientName}?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteQuotation(quote.id);
      _loadQuotations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation deleted')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF16A34A);
      case 'Sent':
        return const Color(0xFF2563EB);
      case 'Completed':
        return const Color(0xFF9333EA);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quotes = _filteredQuotations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Quotations'),
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create New Quotation',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuotationEditorScreen(),
                ),
              );
              if (result == true) {
                _loadQuotations();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by client, project, or quote #...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                for (final st in ['All', 'Draft', 'Sent', 'Approved', 'Completed'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(st),
                      selected: _statusFilter == st,
                      onSelected: (sel) {
                        if (sel) setState(() => _statusFilter = st);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : quotes.isEmpty
                    ? Center(
                        child: EmptyStateView(
                          icon: Icons.receipt_long_rounded,
                          title: _searchQuery.isEmpty
                              ? 'No Quotations Yet'
                              : 'No matching quotations',
                          message: _searchQuery.isEmpty
                              ? 'Generate professional PDF quotations and share directly to WhatsApp with your clients!'
                              : 'Try adjusting your search filter.',
                          actionLabel: _searchQuery.isEmpty
                              ? 'Create First Quotation'
                              : null,
                          onAction: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const QuotationEditorScreen(),
                              ),
                            );
                            if (result == true) _loadQuotations();
                          },
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: quotes.length,
                        itemBuilder: (context, index) {
                          final quote = quotes[index];
                          final statusColor = _getStatusColor(quote.status);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                              onTap: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        QuotationEditorScreen(
                                      initialQuotation: quote,
                                    ),
                                  ),
                                );
                                if (res == true) _loadQuotations();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          quote.quoteNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Color(0xFFFF8C00),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            quote.status,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      quote.projectName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Client: ${quote.clientName}${quote.clientPhone.isNotEmpty ? ' • ${quote.clientPhone}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('MMM dd, yyyy')
                                              .format(quote.date),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '${quote.currencySymbol} ${NumberFormat('#,##0.00').format(quote.grandTotal)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF8C00),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${quote.items.length} line items',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.share_rounded,
                                                color: Color(0xFF25D366),
                                                size: 20,
                                              ),
                                              tooltip: 'WhatsApp / Share PDF',
                                              onPressed: () async {
                                                await QuotationPdfService
                                                    .shareQuotationPdf(quote);
                                                AdService
                                                    .showInterstitialAfterCalculation();
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.print_outlined,
                                                size: 20,
                                              ),
                                              tooltip: 'Print / Preview',
                                              onPressed: () =>
                                                  QuotationPdfService
                                                      .printQuotation(quote),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 20,
                                                color: Colors.redAccent,
                                              ),
                                              tooltip: 'Delete',
                                              onPressed: () =>
                                                  _deleteQuotation(quote),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const AppBannerAd(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF8C00),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Quote'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QuotationEditorScreen(),
            ),
          );
          if (result == true) _loadQuotations();
        },
      ),
    );
  }
}
