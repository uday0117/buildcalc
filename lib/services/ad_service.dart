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
  static const String testAndroidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testIOSRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  // Set to true only for local debug/development testing with Google test ads.
  // In release builds (Play Store), this is strictly ignored and real ads are always served.
  static bool useTestAds = false;

  /// Returns true only in debug/profile mode when test ads are explicitly enabled.
  /// Never returns true in release mode (Play Store builds).
  static bool get isTestMode => !kReleaseMode && useTestAds;

  static String get bannerAdUnitId {
    if (isTestMode) {
      if (!kIsWeb && Platform.isIOS) {
        return testIOSBannerId;
      }
      return testAndroidBannerId;
    }
    return prodBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (isTestMode) {
      if (!kIsWeb && Platform.isIOS) {
        return testIOSInterstitialId;
      }
      return testAndroidInterstitialId;
    }
    return prodInterstitialAdUnitId;
  }

  static String? get rewardedAdUnitId {
    if (isTestMode) {
      if (!kIsWeb && Platform.isIOS) {
        return testIOSRewardedId;
      }
      return testAndroidRewardedId;
    }
    return null; // No production rewarded ad unit ID configured
  }

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static DateTime? _lastInterstitialShownAt;
  static int _calculationCountSinceAd = 0;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    preloadInterstitial();
    if (rewardedAdUnitId != null) {
      preloadRewardedAd();
    }
  }

  static BannerAd createBannerAd({
    bool collapsible = false,
    VoidCallback? onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: collapsible
          ? const AdRequest(extras: {'collapsible': 'bottom'})
          : const AdRequest(),
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

  static void preloadRewardedAd() {
    final adUnitId = rewardedAdUnitId;
    if (adUnitId == null || _rewardedAd != null) return;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              preloadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: $error');
              ad.dispose();
              _rewardedAd = null;
              preloadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Shows a rewarded video ad if available and triggers onUserEarnedReward
  static Future<bool> showRewardedAd({
    required void Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onDismissed,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      preloadRewardedAd();
      return false;
    }

    await ad.show(
      onUserEarnedReward: (_, reward) {
        onUserEarnedReward(reward);
      },
    );
    onDismissed?.call();
    return true;
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

  /// Records a completed calculation event without displaying a full-screen ad.
  /// Full-screen ads are NEVER shown immediately upon calculation to prevent
  /// obstructing calculation results, complying with Google Play Better Ads Policy.
  static void recordCalculation() {
    _calculationCountSinceAd++;
  }

  /// Backward-compatible method: registers that a calculation was performed
  /// without immediately opening a full-screen ad screen over the results.
  static Future<void> showInterstitialAfterCalculation() async {
    recordCalculation();
  }

  /// Displays an interstitial ad during natural navigation transitions (e.g. when exiting
  /// a calculator screen back to home) provided adequate activity has occurred:
  /// - At least 4 calculations completed
  /// - Minimum 4 minutes cooldown between full-screen ads
  /// - Ad is preloaded and ready
  static Future<bool> maybeShowInterstitialOnExit({int minCalculations = 4}) async {
    if (_calculationCountSinceAd < minCalculations) {
      return false;
    }
    final shown = await maybeShowInterstitial(cooldownMinutes: 4);
    if (shown) {
      _calculationCountSinceAd = 0;
    }
    return shown;
  }

  /// Shows the interstitial ad respecting the cooldown period.
  /// Returns true if an ad was displayed.
  static Future<bool> maybeShowInterstitial({int cooldownMinutes = 4}) async {
    final now = DateTime.now();
    if (_lastInterstitialShownAt != null &&
        now.difference(_lastInterstitialShownAt!).inMinutes < cooldownMinutes) {
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
