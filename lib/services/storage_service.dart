import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculation.dart';

class StorageService {
  static const String _historyKey = 'calculation_history';
  static const String _savedKey = 'saved_calculations';

  // Save calculation to history
  static Future<void> saveToHistory(Calculation calculation) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, calculation);
    
    // Keep only last 50 calculations
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    
    final jsonList = history.map((c) => c.toJson()).toList();
    await prefs.setString(_historyKey, json.encode(jsonList));
  }

  // Get calculation history
  static Future<List<Calculation>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Calculation.fromJson(json)).toList();
  }

  // Save calculation to saved
  static Future<void> saveCalculation(Calculation calculation) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await getSavedCalculations();
    
    // Check if already saved
    if (!saved.any((c) => c.id == calculation.id)) {
      saved.insert(0, calculation);
      final jsonList = saved.map((c) => c.toJson()).toList();
      await prefs.setString(_savedKey, json.encode(jsonList));
    }
  }

  // Get saved calculations
  static Future<List<Calculation>> getSavedCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_savedKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Calculation.fromJson(json)).toList();
  }

  // Remove saved calculation
  static Future<void> removeSavedCalculation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await getSavedCalculations();
    saved.removeWhere((c) => c.id == id);
    
    final jsonList = saved.map((c) => c.toJson()).toList();
    await prefs.setString(_savedKey, json.encode(jsonList));
  }

  // Clear history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
