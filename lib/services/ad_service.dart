import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const String prodBannerAdUnitId =
      'ca-app-pub-1451522103593938/3840200242';
  static const String prodInterstitialAdUnitId =
      'ca-app-pub-1451522103593938/4850651700';

  // Official Google AdMob test ad unit IDs
  static const String testAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testIOSBannerId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String testAndroidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testIOSInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  static String get bannerAdUnitId {
    if (kDebugMode) {
      if (!kIsWeb && Platform.isIOS) {
        return testIOSBannerId;
      }
      return testAndroidBannerId;
    }
    return prodBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      if (!kIsWeb && Platform.isIOS) {
        return testIOSInterstitialId;
      }
      return testAndroidInterstitialId;
    }
    return prodInterstitialAdUnitId;
  }

  static InterstitialAd? _interstitialAd;
  static DateTime? _lastInterstitialShownAt;
  static int _calculationCountSinceAd = 0;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    preloadInterstitial();
  }

  static BannerAd createBannerAd({
    VoidCallback? onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          onFailed?.call(error);
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

  /// Displays an interstitial ad if conditions are met:
  /// - At least 2 calculations completed since last ad
  /// - Minimum 3 minutes cooldown between full-screen ads
  /// - Ad is preloaded and ready
  static Future<void> showInterstitialAfterCalculation() async {
    _calculationCountSinceAd++;
    if (_calculationCountSinceAd < 2) {
      return;
    }

    final shown = await maybeShowInterstitial();
    if (shown) {
      _calculationCountSinceAd = 0;
    }
  }

  /// Shows the interstitial ad respecting the 3-minute cooldown period.
  /// Returns true if an ad was displayed.
  static Future<bool> maybeShowInterstitial() async {
    final now = DateTime.now();
    if (_lastInterstitialShownAt != null &&
        now.difference(_lastInterstitialShownAt!).inMinutes < 3) {
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      preloadInterstitial();
      return false;
    }

    await ad.show();
    return true;
  }
}
