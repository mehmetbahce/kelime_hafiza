import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// ÖNEMLİ: Şu an Google'ın RESMİ TEST reklam birimi ID'si kullanılıyor.
/// Gerçek para/tıklama üretmez, sadece geliştirme sırasında reklamın
/// gerçekten çalıştığını görmek için Google tarafından sağlanır.
class RewardedAdService {
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  void preload() {
    if (_rewardedAd != null || _isLoading) return;
    _isLoading = true;
    RewardedAd.load(
      adUnitId: _testRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  bool get isReady => _rewardedAd != null;

  Future<void> show({required VoidCallback onReward, VoidCallback? onNotReady}) async {
    if (_rewardedAd == null) {
      onNotReady?.call();
      preload();
      return;
    }
    final ad = _rewardedAd!;
    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
      },
    );
    await ad.show(onUserEarnedReward: (ad, reward) {
      onReward();
    });
  }
}
