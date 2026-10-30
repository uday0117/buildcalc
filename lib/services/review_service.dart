import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewService {
  static const String packageId = 'com.uksolutions.buildcalc';
  static final InAppReview _inAppReview = InAppReview.instance;

  static const String _reviewPromptedKey = 'has_prompted_review';
  static const String _calculationCountKey = 'calculation_review_count';

  static Uri get playStoreReviewUri => Uri.parse(
    'https://play.google.com/store/apps/details?id=$packageId&showAllReviews=true',
  );

  /// Automatically requests an in-app review at a high-satisfaction milestone
  /// (e.g. after 4 successful calculations). Prompts once.
  static Future<void> checkAndPromptReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool(_reviewPromptedKey) ?? false;
      if (hasPrompted) return;

      final count = (prefs.getInt(_calculationCountKey) ?? 0) + 1;
      await prefs.setInt(_calculationCountKey, count);

      if (count >= 4) {
        await prefs.setBool(_reviewPromptedKey, true);
        await requestReview();
      }
    } catch (_) {
      // Ignore background rating trigger errors
    }
  }

  static Future<void> requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        return;
      }
    } catch (_) {
      // Fallback to the Play Store review page if the native in-app review flow is not supported.
    }

    final storeUrl = playStoreReviewUri;
    final marketUrl = Uri.parse('market://details?id=$packageId');

    if (await canLaunchUrl(marketUrl)) {
      await launchUrl(marketUrl, mode: LaunchMode.externalApplication);
      return;
    }

    if (await canLaunchUrl(storeUrl)) {
      await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
    }
  }
}
