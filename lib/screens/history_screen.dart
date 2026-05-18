import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calculation.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Calculation> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await StorageService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearHistory();
      _loadHistory();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No calculations yet',
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
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final calc = _history[index];
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
                          icon: const Icon(Icons.bookmark_border),
                          onPressed: () async {
                            await StorageService.saveCalculation(calc);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Saved to bookmarks'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
