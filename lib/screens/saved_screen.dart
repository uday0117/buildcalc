import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calculation.dart';
import '../services/storage_service.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Calculation> _saved = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await StorageService.getSavedCalculations();
    setState(() {
      _saved = saved;
      _isLoading = false;
    });
  }

  Future<void> _removeSaved(String id) async {
    await StorageService.removeSavedCalculation(id);
    _loadSaved();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'cement':
        return Icons.architecture;
      case 'brick':
        return Icons.grid_4x4;
      case 'sand':
        return Icons.terrain;
      case 'paint':
        return Icons.format_paint;
      case 'steel':
        return Icons.settings_input_antenna;
      case 'tile':
        return Icons.dashboard;
      case 'area':
        return Icons.square_foot;
      default:
        return Icons.calculate;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'cement':
        return const Color(0xFF795548);
      case 'brick':
        return const Color(0xFFD32F2F);
      case 'sand':
        return const Color(0xFFFFA726);
      case 'paint':
        return const Color(0xFF42A5F5);
      case 'steel':
        return const Color(0xFF607D8B);
      case 'tile':
        return const Color(0xFF8D6E63);
      case 'area':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFFFF8C00);
    }
  }

  void _showCalculationDetails(Calculation calc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E3A5F),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForType(calc.type),
                  color: const Color(0xFFFF8C00),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    calc.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(calc.timestamp),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const Divider(color: Colors.white54, height: 24),
            const Text(
              'Inputs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...calc.inputs.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(color: Colors.white54, height: 24),
            const Text(
              'Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...calc.results.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        entry.value is double
                            ? (entry.value as double).toStringAsFixed(2)
                            : entry.value.toString(),
                        style: const TextStyle(
                          color: Color(0xFFFF8C00),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved',
          style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _saved.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved calculations',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _saved.length,
                  itemBuilder: (context, index) {
                    final calc = _saved[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getColorForType(calc.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForType(calc.type),
                            color: _getColorForType(calc.type),
                          ),
                        ),
                        title: Text(
                          calc.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy - hh:mm a')
                              .format(calc.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeSaved(calc.id),
                        ),
                        onTap: () => _showCalculationDetails(calc),
                      ),
                    );
                  },
                ),
    );
  }
}
