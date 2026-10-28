import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan/elevation_models.dart';

class ElevationStorageService {
  static const String _storageKey = 'saved_front_elevations';

  /// Save or update an elevation configuration
  static Future<void> saveElevation(ElevationConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllElevations();

    final index = list.indexWhere((e) => e.id == config.id);
    final updated = config.copyWith(updatedAt: DateTime.now());

    if (index >= 0) {
      list[index] = updated;
    } else {
      list.insert(0, updated);
    }

    // Sort newest updated first
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  /// Get all saved elevations
  static Future<List<ElevationConfig>> getAllElevations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> raw = json.decode(jsonStr);
      return raw
          .map(
            (item) => ElevationConfig.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get saved elevations linked to a specific FloorPlan
  static Future<List<ElevationConfig>> getElevationsForPlan(
    String planId,
  ) async {
    final all = await getAllElevations();
    if (planId.isEmpty) return all;
    return all.where((e) => e.planId == planId).toList();
  }

  /// Get a single elevation by ID
  static Future<ElevationConfig?> getElevationById(String id) async {
    final all = await getAllElevations();
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Delete a saved elevation
  static Future<void> deleteElevation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllElevations();
    list.removeWhere((e) => e.id == id);

    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  /// Duplicate an elevation
  static Future<ElevationConfig?> duplicateElevation(String id) async {
    final original = await getElevationById(id);
    if (original == null) return null;

    final now = DateTime.now();
    final copy = original.copyWith(
      id: 'elev_${original.planId}_${now.millisecondsSinceEpoch}',
      name: '${original.name} (Copy)',
      createdAt: now,
      updatedAt: now,
    );

    await saveElevation(copy);
    return copy;
  }

  /// Toggle favorite status
  static Future<void> toggleFavorite(String id) async {
    final item = await getElevationById(id);
    if (item != null) {
      await saveElevation(item.copyWith(isFavorite: !item.isFavorite));
    }
  }
}
