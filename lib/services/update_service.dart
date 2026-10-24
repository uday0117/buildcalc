import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _latestVersion = '1.1.0';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.uksolutions.buildcalc';

  static Future<bool> hasUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return _compareVersions(info.version, _latestVersion) < 0;
    } catch (_) {
      return false;
    }
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    final shouldUpdate = await hasUpdate();
    if (!context.mounted || !shouldUpdate) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update available'),
        content: const Text(
          'A newer version of BuildCalc is ready to install with improved features and fixes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              final url = Uri.parse(playStoreUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Install update'),
          ),
        ],
      ),
    );
  }

  static int _compareVersions(String current, String latest) {
    final currentParts = current.split('+').first.split('.');
    final latestParts = latest.split('+').first.split('.');
    final max = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;

    for (var i = 0; i < max; i++) {
      final currentValue = i < currentParts.length
          ? int.tryParse(currentParts[i]) ?? 0
          : 0;
      final latestValue = i < latestParts.length
          ? int.tryParse(latestParts[i]) ?? 0
          : 0;
      if (currentValue < latestValue) return -1;
      if (currentValue > latestValue) return 1;
    }

    return 0;
  }
}
