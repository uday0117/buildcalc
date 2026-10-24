import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const String bannerAdUnitId = 'ca-app-pub-1451522103593938/3840200242';
  static const String interstitialAdUnitId =
      'ca-app-pub-1451522103593938/4850651700';

  static InterstitialAd? _interstitialAd;
  static DateTime? _lastInterstitialShownAt;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    preloadInterstitial();
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {},
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  static void preloadInterstitial() {
    if (_interstitialAd != null) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _lastInterstitialShownAt = DateTime.now();
              preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  static Future<void> maybeShowInterstitial() async {
    final now = DateTime.now();
    if (_lastInterstitialShownAt != null &&
        now.difference(_lastInterstitialShownAt!).inMinutes < 3) {
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      preloadInterstitial();
      return;
    }

    await ad.show();
  }
}
