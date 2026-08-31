import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// ÖNEMLİ: Şu an Google'ın RESMİ TEST reklam birimi ID'si kullanılıyor.
/// Gerçek para/tıklama üretmez, sadece geliştirme sırasında reklamın
/// gerçekten çalıştığını görmek için Google tarafından sağlanır.
///
/// Gerçek reklamlara geçmek için:
/// 1) AdMob hesabı aç, uygulamanı ekle, "Ödüllü Reklam" (Rewarded Ad) birimi oluştur.
/// 2) Aşağıdaki _testRewardedAdUnitId sabitini kendi ID'inle değiştir.
/// 3) android/app/src/main/AndroidManifest.xml içindeki test APPLICATION_ID'yi
///    de kendi gerçek uygulama ID'inle değiştir (workflow dosyasında otomatik ekleniyor).
class RewardedAdService {
  static final RewardedAdService _instance = RewardedAdService._internal();
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();

  // Google'ın resmi test ödüllü reklam ID'si (Android).
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

  /// Reklamı gösterir. Kullanıcı reklamı sonuna kadar izlerse [onReward] çağrılır.
  Future<void> show({required VoidCallback onReward, VoidCallback? onNotReady}) async {
    if (_rewardedAd == null) {
      onNotReady?.call();
      preload(); // bir dahaki sefere hazır olsun
      return;
    }
    final ad = _rewardedAd!;
    _rewardedAd = null; // bu reklam kullanıldı, referansı temizle
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload(); // bir sonraki gösterim için yeniden yükle
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
