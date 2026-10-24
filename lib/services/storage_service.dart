import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculation.dart';
import '../models/project.dart';

class StorageService {
  static const String _historyKey = 'calculation_history';
  static const String _savedKey = 'saved_calculations';
  static const String _projectsKey = 'project_management';

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
}
