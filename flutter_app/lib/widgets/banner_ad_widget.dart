import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// ÖNEMLİ: Şu an Google'ın RESMİ TEST reklam birimi ID'si kullanılıyor.
/// Bu ID'ler gerçek para/tıklama üretmez, sadece geliştirme sırasında
/// reklam sisteminin çalıştığını görmek için Google tarafından sağlanır.
///
/// Gerçek (canlı) reklamlara geçmeden önce:
/// 1) AdMob hesabı aç, uygulamanı ekle.
/// 2) Kendi banner reklam birimi ID'ni al (ca-app-pub-XXXXXXXX/XXXXXXXX formatında).
/// 3) Aşağıdaki _testBannerAdUnitId sabitini kendi ID'inle değiştir.
/// 4) android/app/src/main/AndroidManifest.xml içindeki test APPLICATION_ID'yi
///    de kendi gerçek uygulama ID'inle değiştir (workflow dosyasında otomatik ekleniyor).
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  // Google'ın resmi test banner ID'si (Android). Gerçek reklam için değiştirilecek.
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _testBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner reklam yüklenemedi: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
