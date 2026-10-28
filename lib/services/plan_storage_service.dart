import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan/plan_models.dart';

class PlanStorageService {
  static const String _savedPlansKey = 'saved_floor_plans';

  /// Save or update a floor plan locally
  static Future<void> savePlan(FloorPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final plans = await getSavedPlans();

    final index = plans.indexWhere((p) => p.id == plan.id);
    final updatedPlan = plan.copyWith(updatedAt: DateTime.now());

    if (index >= 0) {
      plans[index] = updatedPlan;
    } else {
      plans.insert(0, updatedPlan);
    }

    // Keep sorted by updated date newest first
    plans.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final jsonList = plans.map((p) => p.toJson()).toList();
    await prefs.setString(_savedPlansKey, json.encode(jsonList));
  }

  /// Retrieve all locally saved floor plans
  static Future<List<FloorPlan>> getSavedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_savedPlansKey);

    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => FloorPlan.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get single plan by ID
  static Future<FloorPlan?> getPlanById(String id) async {
    final plans = await getSavedPlans();
    try {
      return plans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Delete a saved plan
  static Future<void> deletePlan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final plans = await getSavedPlans();
    plans.removeWhere((p) => p.id == id);

    final jsonList = plans.map((p) => p.toJson()).toList();
    await prefs.setString(_savedPlansKey, json.encode(jsonList));
  }

  /// Duplicate an existing plan
  static Future<FloorPlan?> duplicatePlan(String id) async {
    final original = await getPlanById(id);
    if (original == null) return null;

    final now = DateTime.now();
    final copy = original.copyWith(
      id: 'plan_${now.microsecondsSinceEpoch}_copy',
      name: '${original.name} (Copy)',
      createdAt: now,
      updatedAt: now,
    );

    await savePlan(copy);
    return copy;
  }
}
