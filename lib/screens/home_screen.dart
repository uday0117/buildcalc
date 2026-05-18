import 'package:flutter/material.dart';

import '../widgets/calculator_card.dart';
import 'calculators/area_calculator.dart';
import 'calculators/brick_calculator.dart';
import 'calculators/cement_calculator.dart';
import 'calculators/cost_estimator.dart';
import 'calculators/paint_calculator.dart';
import 'calculators/sand_calculator.dart';
import 'calculators/steel_calculator.dart';
import 'calculators/tile_calculator.dart';
import 'history_screen.dart';
import 'saved_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeContent(),
    HistoryScreen(),
    SavedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFFFF8C00),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, size: 28),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Logo and Tagline
              Center(
                child: Column(
                  children: [
                    // Logo placeholder (user can add custom logo later)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business,
                            size: 60,
                            color: Color(0xFFFF8C00),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'BuildCalc',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Build Smart, Calculate Right',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Calculator Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  CalculatorCard(
                    icon: Icons.architecture,
                    title: 'Cement\nCalculator',
                    iconColor: const Color(0xFF795548),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CementCalculator(),
                        ),
                      );
                    },
                  ),
                  CalculatorCard(
                    icon: Icons.grid_4x4,
                    title: 'Brick\nCalculator',
                    iconColor: const Color(0xFFD32F2F),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrickCalculator(),
                        ),
                      );
                    },
                  ),
                  CalculatorCard(
                    icon: Icons.terrain,
                    title: 'Sand\nCalculator',
                    iconColor: const Color(0xFFFFA726),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SandCalculator(),
                        ),
                      );
                    },
                  ),
                  CalculatorCard(
                    icon: Icons.format_paint,
                    title: 'Paint\nCalculator',
                    iconColor: const Color(0xFF42A5F5),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaintCalculator(),
                        ),
                      );
                    },
                  ),
                  CalculatorCard(
                    icon: Icons.settings_input_antenna,
                    title: 'Steel\nCalculator',
                    iconColor: const Color(0xFF607D8B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SteelCalculator(),
                        ),
                      );
                    },
                  ),
                  CalculatorCard(
                    icon: Icons.dashboard,
                    title: 'Tile\nCalculator',
                    iconColor: const Color(0xFF8D6E63),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TileCalculator(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Area Calculator Card
              CalculatorCard(
                icon: Icons.square_foot,
                title: 'Area Calculator',
                iconColor: const Color(0xFF66BB6A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AreaCalculator(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Construction Cost Estimator
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CostEstimator(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calculate,
                            size: 32,
                            color: Color(0xFFFF8C00),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Construction Cost\nEstimator',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF2C3E50),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
