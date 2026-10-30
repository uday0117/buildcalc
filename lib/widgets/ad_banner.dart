import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

class AppBannerAd extends StatefulWidget {
  final bool reserveSpace;

  const AppBannerAd({
    super.key,
    this.reserveSpace = false,
  });

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
    if (_hasFailed || (_bannerAd == null && !widget.reserveSpace)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: _isLoaded && _bannerAd != null
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: 0.8),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 320,
                  height: 50,
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            )
          : widget.reserveSpace
              ? SizedBox(
                  height: 50,
                  child: Center(
                    child: Container(
                      width: 320,
                      height: 50,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
    );
  }
}
