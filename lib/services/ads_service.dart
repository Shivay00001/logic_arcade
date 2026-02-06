import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  BannerAd? _bannerAd;
  BannerAd? _topLeftBannerAd;
  bool _isBannerAdReady = false;
  bool _isTopLeftBannerAdReady = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  Function? _onRewardedAdEarned;
  
  NativeAd? _nativeAd;
  bool _isNativeAdReady = false;

  AppOpenAd? _appOpenAd;
  bool _isAppOpenAdShowing = false;

  // Track which ID index we are on for rotation
  int _rewardedAdIndex = 0;
  int _appOpenAdIndex = 0;

  void initialize() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      MobileAds.instance.initialize();
      _loadAppOpenAd(); // Preload app open ad
    }
  }

  // --- Ad Unit IDs ---

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1334530399272066/3157069733';
    } else if (Platform.isIOS) {
       // Placeholder for iOS if needed, or use same/test
      return 'ca-app-pub-3940256099942544/2934735716'; 
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get topLeftBannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1334530399272066/3927225924';
    } else if (Platform.isIOS) {
       return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Rewarded IDs: ca-app-pub-1334530399272066/4311187540 then ca-app-pub-1334530399272066/9259443653
  List<String> get rewardedAdUnitIds {
    if (Platform.isAndroid) {
      return [
        'ca-app-pub-1334530399272066/4311187540',
        'ca-app-pub-1334530399272066/9259443653'
      ];
    } else {
       return ['ca-app-pub-3940256099942544/1712485313'];
    }
  }

  String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1334530399272066/5016946319';
    } else {
       return 'ca-app-pub-3940256099942544/3986624511';
    }
  }

  // App Open IDs: ca-app-pub-1334530399272066/5535821062 or ca-app-pub-1334530399272066/5180597842
  List<String> get appOpenAdUnitIds {
    if (Platform.isAndroid) {
      return [
        'ca-app-pub-1334530399272066/5535821062',
        'ca-app-pub-1334530399272066/5180597842'
      ];
    } else {
       return ['ca-app-pub-3940256099942544/5662855259'];
    }
  }

  // --- Banner Ads ---

  void loadBanner(Function(Ad) onLoaded) {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
          onLoaded(ad);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    )..load();
  }
  
  void loadTopLeftBanner(Function(Ad) onLoaded) {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    _topLeftBannerAd = BannerAd(
      adUnitId: topLeftBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isTopLeftBannerAdReady = true;
          onLoaded(ad);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load top left banner ad: ${err.message}');
          _isTopLeftBannerAdReady = false;
          ad.dispose();
        },
      ),
    )..load();
  }

  Widget getBannerAdWidget() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return const SizedBox.shrink();
    
    if (_isBannerAdReady && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
  
  Widget getTopLeftBannerAdWidget() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return const SizedBox.shrink();
    
    if (_isTopLeftBannerAdReady && _topLeftBannerAd != null) {
      return SizedBox(
        width: _topLeftBannerAd!.size.width.toDouble(),
        height: _topLeftBannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _topLeftBannerAd!),
      );
    }
    return const SizedBox.shrink();
  }

  // --- Rewarded Ads ---

  void loadRewardedAd(Function onEarnedReward) {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    _onRewardedAdEarned = onEarnedReward;
    
    // Rotate IDs
    String adUnitId = rewardedAdUnitIds[_rewardedAdIndex % rewardedAdUnitIds.length];
    _rewardedAdIndex++;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdReady = false;
              // Load next ad
              loadRewardedAd(onEarnedReward);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdReady = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load rewarded ad: $error');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  bool get isRewardedAdReady => _isRewardedAdReady;

  void showRewardedAd(BuildContext context) {
    if (_rewardedAd != null && _isRewardedAdReady) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          _onRewardedAdEarned?.call();
        },
      );
    }
  }

  // --- Native Ads ---
  
  // Note: Native ads require platform specific XML layout (Android) or XIB (iOS) if using NativeAd,
  // or use NativeAdTemplate (medium/small) if checking `google_mobile_ads` capabilities.
  // Converting to a simple interface to load and get the widget.
  
  void loadNativeAd(Function(Ad) onLoaded) {
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

      _nativeAd = NativeAd(
        adUnitId: nativeAdUnitId,
        factoryId: 'listTile', // Ensure this factory ID is registered on Native side if using CustomNativeAd, or use standard NativeAd
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            _isNativeAdReady = true;
            onLoaded(ad);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Native Ad failed to load: $error');
            ad.dispose();
            _isNativeAdReady = false;
          },
        ),
      )..load();
  }
  
  Widget getNativeAdWidget() {
     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return const SizedBox.shrink();

     if (_isNativeAdReady && _nativeAd != null) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 320, // minimum recommended width
            minHeight: 320, // minimum recommended height
            maxWidth: 400,
            maxHeight: 400,
          ),
          child: AdWidget(ad: _nativeAd!),
        );
     }
     return const SizedBox.shrink();
  }
  
  // --- App Open Ads ---

  void _loadAppOpenAd() {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    String adUnitId = appOpenAdUnitIds[_appOpenAdIndex % appOpenAdUnitIds.length];
    _appOpenAdIndex++;

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _showAppOpenAdIfAvailable();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }
  
  void _showAppOpenAdIfAvailable() {
    if (_appOpenAd == null) return;
    if (_isAppOpenAdShowing) return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isAppOpenAdShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isAppOpenAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd(); // Load the next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isAppOpenAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  void dispose() {
    _bannerAd?.dispose();
    _topLeftBannerAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
    _appOpenAd?.dispose();
  }
}
