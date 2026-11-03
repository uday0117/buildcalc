import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculation.dart';
import '../models/project.dart';
import '../models/quotation.dart';

class StorageService {
  static const String _historyKey = 'calculation_history';
  static const String _savedKey = 'saved_calculations';
  static const String _projectsKey = 'project_management';
  static const String _favoritesKey = 'favorite_calculators';
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _quotationsKey = 'contractor_quotations';
  static const String _contractorProfileKey = 'contractor_saved_profile';

  // Onboarding status
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setSeenOnboarding([bool seen = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, seen);
  }

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

  // Save a project and keep it in sorted order newest first
  static Future<void> saveProject(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await getProjects();
    final existingIndex = projects.indexWhere((item) => item.id == project.id);

    if (existingIndex >= 0) {
      projects[existingIndex] = project;
    } else {
      projects.insert(0, project);
    }

    final jsonList = projects.map((item) => item.toJson()).toList();
    await prefs.setString(_projectsKey, json.encode(jsonList));
  }

  static Future<List<Project>> getProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_projectsKey);

    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((json) => Project.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  static Future<void> deleteProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await getProjects();
    final filtered = projects.where((project) => project.id != id).toList();
    await prefs.setString(
      _projectsKey,
      json.encode(filtered.map((item) => item.toJson()).toList()),
    );
  }

  // Clear history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // Get recent calculations with limit
  static Future<List<Calculation>> getRecentCalculations({
    int limit = 5,
  }) async {
    final history = await getHistory();
    if (history.length <= limit) return history;
    return history.sublist(0, limit);
  }

  // Favorites management
  static Future<Set<String>> getFavoriteCalculatorIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesKey);
    if (list == null) return {};
    return list.toSet();
  }

  static Future<bool> toggleFavoriteCalculator(String calculatorId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_favoritesKey) ?? []).toSet();
    final isFavNow = !current.contains(calculatorId);
    if (isFavNow) {
      current.add(calculatorId);
    } else {
      current.remove(calculatorId);
    }
    await prefs.setStringList(_favoritesKey, current.toList());
    return isFavNow;
  }

  static Future<bool> isFavoriteCalculator(String calculatorId) async {
    final favorites = await getFavoriteCalculatorIds();
    return favorites.contains(calculatorId);
  }

  // --- Quotations Management ---
  static Future<void> saveQuotation(Quotation quotation) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getQuotations();
    final index = list.indexWhere((q) => q.id == quotation.id);
    if (index >= 0) {
      list[index] = quotation;
    } else {
      list.insert(0, quotation);
    }
    final jsonList = list.map((q) => q.toJson()).toList();
    await prefs.setString(_quotationsKey, json.encode(jsonList));
  }

  static Future<List<Quotation>> getQuotations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quotationsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(raw);
      return list
          .map((item) => Quotation.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteQuotation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getQuotations();
    list.removeWhere((q) => q.id == id);
    final jsonList = list.map((q) => q.toJson()).toList();
    await prefs.setString(_quotationsKey, json.encode(jsonList));
  }

  // --- Contractor Business Profile (remembered across quotations) ---
  static Future<Map<String, String>> getContractorProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_contractorProfileKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final Map<String, dynamic> decoded = json.decode(raw);
      return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveContractorProfile({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? currencySymbol,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'name': name,
      'phone': phone,
      'email': email ?? '',
      'address': address ?? '',
      'currencySymbol': currencySymbol ?? '\$',
    };
    await prefs.setString(_contractorProfileKey, json.encode(map));
  }
}
