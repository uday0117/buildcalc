import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import '../models/plan/plan_models.dart';
import 'plan_share_service.dart';
import 'plan_storage_service.dart';

/// Status descriptor for Cloud and Local backup readiness.
class CloudBackupStatus {
  final bool isConfigured;
  final bool isApproved;
  final String statusDescription;

  const CloudBackupStatus({
    required this.isConfigured,
    required this.isApproved,
    required this.statusDescription,
  });

  factory CloudBackupStatus.offlineDefault() => const CloudBackupStatus(
        isConfigured: false,
        isApproved: false,
        statusDescription:
            'Offline Local Storage Active (100% private & accessible offline). '
            'Cloud backup requires approved cloud service architecture and sign-in configuration.',
      );
}

/// Backup and restore service ensuring local saved plans remain fully accessible offline.
/// Allows exporting and restoring complete JSON backups without requiring paid backend services or sign-in.
class PlanBackupService {
  static const int currentBackupSchemaVersion = 1;

  /// Retrieves the current cloud backup status.
  /// Follows the architecture constraint: no paid backend services or unapproved sign-in.
  static CloudBackupStatus getCloudBackupStatus() {
    return CloudBackupStatus.offlineDefault();
  }

  /// Exports all locally saved floor plans into a versioned JSON backup payload.
  static Future<String> createBackupJson() async {
    final plans = await PlanStorageService.getSavedPlans();
    final backupData = {
      'app': 'BuildCalc',
      'schemaVersion': currentBackupSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'planCount': plans.length,
      'plans': plans.map((p) => p.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Exports backup JSON to a local file in application documents.
  static Future<File> exportBackupToFile() async {
    final jsonStr = await createBackupJson();
    Directory docDir;
    try {
      docDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      docDir = Directory.systemTemp;
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${docDir.path}/buildcalc_backup_$timestamp.json');

    await file.writeAsString(jsonStr, flush: true);
    return file;
  }

  /// Shares the JSON backup file natively using system share action (WhatsApp, Drive, Email, etc.).
  static Future<ExportActionResult> shareBackupFile() async {
    final jsonStr = await createBackupJson();
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return PlanShareService.shareBytes(
      bytes: bytes,
      fileName: 'buildcalc_plans_backup_$timestamp.json',
      mimeType: 'application/json',
      subject: 'BuildCalc Saved Floor Plans Backup',
      text: 'Backup file containing saved BuildCalc floor plans. Can be restored offline on any device.',
    );
  }

  /// Validates and restores floor plans from a JSON backup payload.
  /// If [mergeWithExisting] is true, plans with existing IDs are updated and new ones appended.
  /// If [mergeWithExisting] is false, local storage is completely replaced with backup plans.
  static Future<int> restoreBackupFromJson(
    String jsonString, {
    bool mergeWithExisting = true,
  }) async {
    if (jsonString.trim().isEmpty) {
      throw const FormatException('Backup file is empty.');
    }

    final dynamic decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup file format: Root must be a JSON object.');
    }

    final rawPlans = decoded['plans'];
    if (rawPlans is! List<dynamic>) {
      throw const FormatException('Invalid backup file format: Missing "plans" list.');
    }

    final List<FloorPlan> parsedPlans = [];
    for (int i = 0; i < rawPlans.length; i++) {
      final item = rawPlans[i];
      if (item is Map<String, dynamic>) {
        try {
          parsedPlans.add(FloorPlan.fromJson(item));
        } catch (e) {
          throw FormatException('Failed to parse plan at index $i: $e');
        }
      }
    }

    if (mergeWithExisting) {
      final currentPlans = await PlanStorageService.getSavedPlans();
      final Map<String, FloorPlan> planMap = {
        for (final p in currentPlans) p.id: p,
      };

      for (final p in parsedPlans) {
        planMap[p.id] = p;
      }

      for (final plan in planMap.values) {
        await PlanStorageService.savePlan(plan);
      }
    } else {
      // Clear and re-save
      final currentPlans = await PlanStorageService.getSavedPlans();
      for (final p in currentPlans) {
        await PlanStorageService.deletePlan(p.id);
      }
      for (final plan in parsedPlans) {
        await PlanStorageService.savePlan(plan);
      }
    }

    return parsedPlans.length;
  }
}
