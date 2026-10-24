import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewService {
  static const String packageId = 'com.uksolutions.buildcalc';
  static final InAppReview _inAppReview = InAppReview.instance;

  static Uri get playStoreReviewUri => Uri.parse(
    'https://play.google.com/store/apps/details?id=$packageId&showAllReviews=true',
  );

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
