import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/project.dart';
import '../services/storage_service.dart';
import '../widgets/ad_banner.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() =>
      _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await StorageService.getProjects();
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _createProject() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final budgetController = TextEditingController();
    final notesController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create project'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Project name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Project name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: budgetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Budget'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Budget is required';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Enter a valid number';
                    }
                    if (parsed < 0) {
                      return 'Budget cannot be negative';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save project'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      location: locationController.text.trim(),
      budget: double.parse(budgetController.text.trim()),
      createdAt: DateTime.now(),
      notes: notesController.text.trim(),
      history: [
        ProjectHistoryEntry(
          id: 'init-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Project created',
          timestamp: DateTime.now(),
          note: 'Initial project setup complete.',
        ),
      ],
    );

    await StorageService.saveProject(project);
    await _loadProjects();
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailScreen(projectId: project.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New project'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 72,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No projects yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first project and start tracking materials.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProjectDetailScreen(projectId: project.id),
                        ),
                      );
                      _loadProjects();
                    },
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    title: Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          project.location.isEmpty
                              ? 'No location set'
                              : project.location,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${project.materials.length} materials • ${NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0).format(project.totalMaterialCost)} total',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(
                            symbol: 'SAR ',
                            decimalDigits: 0,
                          ).format(project.budget),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.statusLabel,
                          style: TextStyle(
                            color: project.budgetRemaining >= 0
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: AppBannerAd(),
      ),
    );
  }
}

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final projects = await StorageService.getProjects();
    final project = projects.firstWhere(
      (item) => item.id == widget.projectId,
      orElse: () => Project(
        id: '',
        name: 'Project not found',
        location: '',
        budget: 0,
        createdAt: DateTime.now(),
        notes: '',
      ),
    );
    if (!mounted) return;
    setState(() {
      _project = project.id.isEmpty ? null : project;
      _isLoading = false;
    });
  }

  Future<void> _saveProject(Project project) async {
    await StorageService.saveProject(project);
    await _loadProject();
  }

  Future<void> _addMaterialEstimate() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final unitController = TextEditingController(text: 'bag');
    final quantityController = TextEditingController();
    final unitPriceController = TextEditingController();
    final wastageController = TextEditingController(text: '5');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add material estimate'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Material name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Material name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Quantity is required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: unitPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Unit price'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unit price is required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: wastageController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Wastage %'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok != true || _project == null) return;

    final material = ProjectMaterial(
      id: 'material-${DateTime.now().millisecondsSinceEpoch}',
      name: nameController.text.trim(),
      unit: unitController.text.trim().isEmpty
          ? 'unit'
          : unitController.text.trim(),
      quantity: double.parse(quantityController.text.trim()),
      unitPrice: double.parse(unitPriceController.text.trim()),
      wastagePercent: double.tryParse(wastageController.text.trim()) ?? 0,
    );

    final updatedProject = Project(
      id: _project!.id,
      name: _project!.name,
      location: _project!.location,
      budget: _project!.budget,
      createdAt: _project!.createdAt,
      notes: _project!.notes,
      materials: [..._project!.materials, material],
      history: [
        ..._project!.history,
        ProjectHistoryEntry(
          id: 'history-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Added material: ${material.name}',
          timestamp: DateTime.now(),
          note:
              '${material.quantity} ${material.unit} at ${NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0).format(material.lineTotal)}',
        ),
      ],
    );

    await _saveProject(updatedProject);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${material.name} estimate added')),
      );
    }
  }

  Future<void> _deleteMaterial(String materialId) async {
    if (_project == null) return;

    final item = _project!.materials.firstWhere(
      (element) => element.id == materialId,
      orElse: () => const ProjectMaterial(
        id: '',
        name: '',
        unit: 'unit',
        quantity: 0,
        unitPrice: 0,
        wastagePercent: 0,
      ),
    );
    if (item.id.isEmpty) return;

    final updatedProject = Project(
      id: _project!.id,
      name: _project!.name,
      location: _project!.location,
      budget: _project!.budget,
      createdAt: _project!.createdAt,
      notes: _project!.notes,
      materials: _project!.materials
          .where((element) => element.id != materialId)
          .toList(),
      history: [
        ..._project!.history,
        ProjectHistoryEntry(
          id: 'history-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Removed material: ${item.name}',
          timestamp: DateTime.now(),
        ),
      ],
    );

    await _saveProject(updatedProject);
  }

  Future<void> _shareReport() async {
    if (_project == null) return;

    final text = [
      'Project report: ${_project!.name}',
      'Location: ${_project!.location.isEmpty ? 'Not set' : _project!.location}',
      'Budget: ${NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0).format(_project!.budget)}',
      'Material cost: ${NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0).format(_project!.totalMaterialCost)}',
      'Remaining budget: ${NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0).format(_project!.budgetRemaining)}',
      '',
      'Materials:',
      ..._project!.materials.map(
        (material) =>
            '- ${material.name}: ${material.quantity} ${material.unit} @ ${NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0).format(material.unitPrice)} = ${NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0).format(material.lineTotal)}',
      ),
      '',
      'History:',
      ..._project!.history.map(
        (entry) =>
            '- ${DateFormat.yMMMd().add_jm().format(entry.timestamp)}: ${entry.title}',
      ),
    ].join('\n');

    await Share.share(text, subject: 'Project report: ${_project!.name}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: const Center(child: Text('Project not found.')),
      );
    }

    final totalCost = _project!.totalMaterialCost;
    final budgetRemaining = _project!.budgetRemaining;
    final materialCount = _project!.materials.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_project!.name),
        actions: [
          IconButton(
            onPressed: _shareReport,
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share project report',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMaterialEstimate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add estimate'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _project!.location.isEmpty
                          ? 'Location: not set'
                          : _project!.location,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _project!.notes.isEmpty
                          ? 'No notes yet.'
                          : _project!.notes,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Created ${DateFormat.yMMMd().format(_project!.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _AnalyticsCard(
                  title: 'Estimated cost',
                  value: NumberFormat.currency(
                    symbol: 'SAR ',
                    decimalDigits: 0,
                  ).format(totalCost),
                  color: const Color(0xFF1E3A5F),
                  icon: Icons.calculate_rounded,
                ),
                _AnalyticsCard(
                  title: 'Budget left',
                  value: NumberFormat.currency(
                    symbol: 'SAR ',
                    decimalDigits: 0,
                  ).format(budgetRemaining),
                  color: budgetRemaining >= 0 ? Colors.green : Colors.red,
                  icon: Icons.account_balance_wallet_rounded,
                ),
                _AnalyticsCard(
                  title: 'Materials',
                  value: materialCount.toString(),
                  color: const Color(0xFFFFA726),
                  icon: Icons.layers_rounded,
                ),
                _AnalyticsCard(
                  title: 'Coverage',
                  value: '${_project!.coveragePercent.toStringAsFixed(0)}%',
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.pie_chart_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Material estimate',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_project!.materials.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No material estimates added yet.'),
                ),
              )
            else
              ..._project!.materials.map((material) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.format_paint_rounded),
                    title: Text(material.name),
                    subtitle: Text(
                      '${material.quantity} ${material.unit} • ${material.wastagePercent}% waste',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(
                            symbol: 'SAR ',
                            decimalDigits: 0,
                          ).format(material.lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () => _deleteMaterial(material.id),
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: 'Remove material',
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.history_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Project history',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_project!.history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No history yet.'),
                ),
              )
            else
              ..._project!.history.reversed.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.event_note_rounded),
                    title: Text(entry.title),
                    subtitle: Text(
                      '${DateFormat.yMMMd().add_jm().format(entry.timestamp)}${entry.note == null || entry.note!.isEmpty ? '' : ' • ${entry.note}'}',
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
