import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = AdService.createBannerAd(
      onLoaded: () {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      },
      onFailed: (error) {
        if (mounted) {
          setState(() {
            _hasFailed = true;
            _bannerAd = null;
          });
        }
      },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasFailed || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      width: double.infinity,
      child: Center(
        child: SizedBox(
          width: 320,
          height: 50,
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
