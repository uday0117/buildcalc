import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BuildCalcApp());
}

class BuildCalcApp extends StatelessWidget {
  const BuildCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildCalc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3A5F), // Dark Blue
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          primary: const Color(0xFF1E3A5F),
          secondary: const Color(0xFFFF8C00), // Orange
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1E3A5F)),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
