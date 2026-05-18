import 'package:flutter/material.dart';
import '../../widgets/input_field.dart';

class CostEstimator extends StatefulWidget {
  const CostEstimator({super.key});

  @override
  State<CostEstimator> createState() => _CostEstimatorState();
}

class _CostEstimatorState extends State<CostEstimator> {
  final _areaController = TextEditingController();
  String _constructionType = 'Basic';
  
  double _totalCost = 0;
  double _costPerSqFt = 0;
  bool _hasCalculated = false;

  final Map<String, double> _costRates = {
    'Basic': 1200,     // ₹1200 per sq ft
    'Standard': 1800,  // ₹1800 per sq ft
    'Premium': 2500,   // ₹2500 per sq ft
    'Luxury': 3500,    // ₹3500 per sq ft
  };

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 0;

    if (area > 0) {
      _costPerSqFt = _costRates[_constructionType] ?? 1200;
      _totalCost = area * _costPerSqFt;

      setState(() {
        _hasCalculated = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter area')),
      );
    }
  }

  void _reset() {
    setState(() {
      _areaController.clear();
      _constructionType = 'Basic';
      _totalCost = 0;
      _costPerSqFt = 0;
      _hasCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Construction Cost Estimator',
          style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.calculate,
                      size: 60,
                      color: Color(0xFFFF8C00),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estimate construction cost\nbased on area and type',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            InputField(
              label: 'Construction Area',
              hint: 'Enter total area',
              controller: _areaController,
              suffix: 'sq ft',
            ),
            const SizedBox(height: 24),

            // Construction Type Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Construction Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                ..._costRates.keys.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _constructionType = type;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _constructionType == type
                              ? const Color(0xFFFF8C00).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _constructionType == type
                                ? const Color(0xFFFF8C00)
                                : Colors.grey.shade300,
                            width: _constructionType == type ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _constructionType == type
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: _constructionType == type
                                  ? const Color(0xFFFF8C00)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _constructionType == type
                                          ? const Color(0xFF1E3A5F)
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    '₹${_costRates[type]} per sq ft',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Calculate Cost',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            if (_hasCalculated) ...[
              const SizedBox(height: 24),
              Card(
                color: const Color(0xFF1E3A5F),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Estimated Cost',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(color: Colors.white54, height: 24),
                      _buildResultRow(
                        'Construction Type',
                        _constructionType,
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Rate per sq ft',
                        '₹${_costPerSqFt.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Area',
                        '${_areaController.text} sq ft',
                      ),
                      const Divider(color: Colors.white54, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Cost',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${_totalCost.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF8C00),
                                ),
                              ),
                              Text(
                                '₹${(_totalCost / 100000).toStringAsFixed(2)} Lakhs',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Note: This is an approximate estimate. Actual costs may vary based on location, materials, and other factors.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }
}
