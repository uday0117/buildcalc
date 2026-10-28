import 'package:flutter/material.dart';

import '../../models/plan/ready_made_template_models.dart';
import '../../services/plan_storage_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/plan/plan_thumbnail_painter.dart';
import '../../widgets/plan/template_preview_sheet.dart';
import 'plan_editor_screen.dart';

/// Screen allowing users to browse, filter, preview, duplicate and select ready-made house plan templates.
class PlanTemplatesScreen extends StatefulWidget {
  final bool selectOnly;

  const PlanTemplatesScreen({
    super.key,
    this.selectOnly = false,
  });

  @override
  State<PlanTemplatesScreen> createState() => _PlanTemplatesScreenState();
}

class _PlanTemplatesScreenState extends State<PlanTemplatesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedBhk = 'All';
  String _selectedDimension = 'All Sizes';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReadyMadePlanTemplate> get _filteredTemplates {
    return ReadyMadePlanCatalog.filter(
      bhk: _selectedBhk,
      dimension: _selectedDimension,
      query: _searchQuery,
    );
  }

  void _onTemplateSelected(ReadyMadePlanTemplate template) {
    if (widget.selectOnly) {
      Navigator.pop(context, template.createFreshPlan());
      return;
    }

    final freshPlan = template.createFreshPlan();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanEditorScreen(initialPlan: freshPlan),
      ),
    );
  }

  Future<void> _duplicateTemplate(ReadyMadePlanTemplate template) async {
    final freshPlan = template.createFreshPlan(
      name: '${template.title} (Copy)',
    );
    await PlanStorageService.savePlan(freshPlan);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template duplicated as "${freshPlan.name}" in Saved Plans!'),
        backgroundColor: const Color(0xFF1E3A5F),
        action: SnackBarAction(
          label: 'Open in Editor',
          textColor: const Color(0xFFFF8C00),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlanEditorScreen(initialPlan: freshPlan),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final templates = _filteredTemplates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready-Made House Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Disclaimer & Bylaws',
            onPressed: () => _showDisclaimerDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search templates, rooms, or plot sizes...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),

                // BHK Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ReadyMadePlanCatalog.bhkFilterOptions.map((bhk) {
                      final isSel = _selectedBhk == bhk;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(bhk),
                          selected: isSel,
                          selectedColor: const Color(0xFFFF8C00),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          onSelected: (_) => setState(() => _selectedBhk = bhk),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),

                // Plot Dimension Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ReadyMadePlanCatalog.plotDimensionFilterOptions.map((dim) {
                      final isSel = _selectedDimension == dim;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(dim),
                          selected: isSel,
                          selectedColor: const Color(0xFF0284C7),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          onSelected: (_) => setState(() => _selectedDimension = dim),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Compliance & Disclaimer Alert Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFDC2626).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFFDC2626),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Architectural & Municipal Compliance Notice',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Templates are conceptual starting layouts for planning and material estimates. They are not approved municipal sanction plans. Consult a licensed architect for local bylaws.',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Templates List
          Expanded(
            child: templates.isEmpty
                ? const EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No Matching Layouts',
                    message: 'Try adjusting your BHK category or plot dimension filters.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return _buildTemplateCard(
                        context: context,
                        template: template,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard({
    required BuildContext context,
    required ReadyMadePlanTemplate template,
    required bool isDark,
  }) {
    final previewPlan = template.createFreshPlan();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey[200]!,
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C00).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              template.bhkType,
                              style: const TextStyle(
                                color: Color(0xFFFF8C00),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              template.plotDimensionsLabel,
                              style: const TextStyle(
                                color: Color(0xFF0284C7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '🧭 ${template.orientation}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        template.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Duplicate Template',
                  onPressed: () => _duplicateTemplate(template),
                ),
              ],
            ),
          ),

          // 2D Blueprint Preview Area
          InkWell(
            onTap: () => TemplatePreviewSheet.show(context, template),
            child: Container(
              height: 180,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey[300]!,
                ),
              ),
              child: Stack(
                children: [
                  PlanThumbnail(
                    plan: previewPlan,
                    frontSetbackFeet: template.frontSetbackFeet,
                    rearSetbackFeet: template.rearSetbackFeet,
                    sideSetbackFeet: template.sideSetbackFeet,
                    orientation: template.orientation,
                    showLabels: true,
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Tap to Preview',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Metrics Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardMetric('Plot Area', '${template.plotAreaSqFt.toInt()} sq ft'),
                _buildCardMetric('Built-Up', '${template.totalBuiltUpAreaSqFt.toStringAsFixed(0)} sq ft'),
                _buildCardMetric('Usable Area', '${template.usablePlotAreaSqFt.toInt()} sq ft'),
                _buildCardMetric('Rooms', '${template.roomCount} Rooms'),
              ],
            ),
          ),

          // Setbacks & Orientation Bar
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.straighten_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Assumed Setbacks: ${template.setbacksDescription}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.white60 : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => TemplatePreviewSheet.show(context, template),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Preview & Specs'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _onTemplateSelected(template),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Edit in 2D'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text('Planning Disclaimer'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Important Legal & Architectural Notice:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                ReadyMadePlanCatalog.universalDisclaimer,
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                '• Setback and Ground Coverage requirements vary significantly between municipalities and zoning classifications.\n'
                '• Floor Area Ratio (FAR/FSI) determines the total permissible built-up area.\n'
                '• Soil conditions, earthquake zones, and structural load calculations require licensed engineering certification before commencing construction.',
                style: TextStyle(fontSize: 11.5, height: 1.4, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
