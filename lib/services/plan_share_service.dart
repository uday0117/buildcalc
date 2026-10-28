import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Result status of a file export, share, or save operation.
class ExportActionResult {
  final bool isSuccess;
  final String? filePath;
  final String message;
  final Object? error;

  const ExportActionResult({
    required this.isSuccess,
    this.filePath,
    required this.message,
    this.error,
  });

  factory ExportActionResult.success({String? filePath, required String message}) =>
      ExportActionResult(
        isSuccess: true,
        filePath: filePath,
        message: message,
      );

  factory ExportActionResult.failure({required String message, Object? error}) =>
      ExportActionResult(
        isSuccess: false,
        message: message,
        error: error,
      );
}

/// Service providing cross-platform file sharing and saving capabilities.
/// Supports native sharing to WhatsApp, Email, Drive, and system print / Save-as-PDF.
class PlanShareService {
  /// Shares bytes natively with WhatsApp, Gmail, Messages, Drive, AirDrop, etc.
  static Future<ExportActionResult> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? subject,
    String? text,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final safeName = _sanitizeFileName(fileName);
      final tempFile = File('${tempDir.path}/$safeName');
      await tempFile.writeAsBytes(bytes, flush: true);

      final shareResult = await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: mimeType, name: safeName)],
        subject: subject,
        text: text,
      );

      return ExportActionResult.success(
        filePath: tempFile.path,
        message: 'Shared successfully (${shareResult.status.name})',
      );
    } catch (e) {
      return ExportActionResult.failure(
        message: 'Failed to share file: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Saves bytes locally to the device's application documents directory.
  static Future<ExportActionResult> saveBytesToDevice({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      Directory docDir;
      try {
        docDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        try {
          docDir = await getTemporaryDirectory();
        } catch (_) {
          docDir = Directory.systemTemp;
        }
      }
      final safeName = _sanitizeFileName(fileName);
      final targetFile = File('${docDir.path}/$safeName');

      await targetFile.writeAsBytes(bytes, flush: true);

      return ExportActionResult.success(
        filePath: targetFile.path,
        message: 'Saved to device storage at ${targetFile.path}',
      );
    } catch (e) {
      return ExportActionResult.failure(
        message: 'Permission or storage error saving file: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Opens the native OS print and "Save as PDF" dialogue.
  static Future<ExportActionResult> printOrSavePdfNative({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      final safeName = _sanitizeFileName(fileName);
      final completed = await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: safeName,
      );

      return ExportActionResult.success(
        message: completed ? 'Print / PDF export completed.' : 'PDF dialogue closed.',
      );
    } catch (e) {
      return ExportActionResult.failure(
        message: 'Failed to launch print or PDF save: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Removes illegal characters for filesystem filenames across platforms
  static String _sanitizeFileName(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
