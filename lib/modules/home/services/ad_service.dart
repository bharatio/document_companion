import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service to manage interstitial and rewarded ads
/// Provides a clean interface for showing ads after user actions
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  
  // Counter to limit ad frequency
  int _operationCount = 0;
  static const int _adFrequency = 3; // Show ad every 3 operations

  // Ad Unit IDs
  static const String _interstitialAdUnitId = 'ca-app-pub-3672075156086851/3071491590'; // Interstitial Ad
  static const String _rewardedAdUnitId = 'ca-app-pub-3672075156086851/4328732948'; // Rewarded Ad

  /// Loads an interstitial ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _setInterstitialListeners(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialReady = false;
        },
      ),
    );
  }

  /// Sets up listeners for interstitial ad
  void _setInterstitialListeners(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialReady = false;
        // Load next ad
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _isInterstitialReady = false;
        loadInterstitialAd();
      },
    );
  }

  /// Shows interstitial ad after operation completion
  /// Returns true if ad was shown, false otherwise
  bool showInterstitialAdIfReady() {
    // Increment operation counter
    _operationCount++;
    
    // Only show ad every N operations
    if (_operationCount < _adFrequency) {
      return false;
    }

    // Reset counter
    _operationCount = 0;

    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
      return true;
    } else {
      // Load ad for next time
      loadInterstitialAd();
      return false;
    }
  }

  /// Loads a rewarded ad
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          _setRewardedListeners(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _isRewardedReady = false;
        },
      ),
    );
  }

  /// Sets up listeners for rewarded ad
  void _setRewardedListeners(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        // Call dismissed callback if set
        if (_rewardedAdDismissedCallback != null) {
          _rewardedAdDismissedCallback!();
        }
        ad.dispose();
        _isRewardedReady = false;
        // Clear callbacks
        _rewardedAdDismissedCallback = null;
        _rewardedAdFailedCallback = null;
        // Load next ad
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        // Call failed callback if set
        if (_rewardedAdFailedCallback != null) {
          _rewardedAdFailedCallback!(error.toString());
        }
        ad.dispose();
        _isRewardedReady = false;
        // Clear callbacks
        _rewardedAdDismissedCallback = null;
        _rewardedAdFailedCallback = null;
        loadRewardedAd();
      },
    );
  }

  /// Shows rewarded ad with callback for reward handling
  /// Returns true if ad was shown, false if not ready
  bool showRewardedAd({
    required Function() onRewarded,
    Function()? onAdDismissed,
    Function(String)? onAdFailedToShow,
  }) {
    if (_isRewardedReady && _rewardedAd != null) {
      // Store callbacks for use in listeners
      _rewardedAdDismissedCallback = onAdDismissed;
      _rewardedAdFailedCallback = onAdFailedToShow;
      
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          // Call the reward callback
          onRewarded();
        },
      );
      return true;
    } else {
      // Load ad for next time
      loadRewardedAd();
      if (onAdFailedToShow != null) {
        onAdFailedToShow('Ad not ready. Please try again in a moment.');
      }
      return false;
    }
  }

  // Callback storage for rewarded ad listeners
  Function()? _rewardedAdDismissedCallback;
  Function(String)? _rewardedAdFailedCallback;

  /// Preloads both ad types (call this on app startup)
  void preloadAds() {
    loadInterstitialAd();
    loadRewardedAd();
  }

  /// Disposes all ads
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _isInterstitialReady = false;
    _isRewardedReady = false;
  }

  /// Check if rewarded ad is ready
  bool get isRewardedAdReady => _isRewardedReady;
}

final adService = AdService();

