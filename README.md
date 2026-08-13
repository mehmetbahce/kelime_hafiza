# Kelime Hafıza - Kurulum

Melih Duyar tarzı çağrışım kartlarını (İngilizce kelime → Türkçe anlam → çağrışım → akılda kalıcı cümle → görsel) saklayıp, spaced repetition (SM-2) ile tekrar ettiren ve quiz'e çeviren Flutter uygulaması.

## 0) ÖNCE TEST SÜRÜMÜ (backend gerekmez)

Proje şu an sunucusuz çalışacak şekilde kurulu: kartlar `assets/data/cards.json` dosyasından okunuyor, görseller `assets/images/` altında. İnternet ya da backend gerekmeden GitHub Actions ile APK alıp doğrudan telefonunda deneyebilirsin — Galeri, Tekrar Modu ve Quiz hepsi bu kartlarla çalışır.

## 0) 500 KART, SUNUCUSUZ APK (senin şu anki hedefin)

Kartlar artık kod içine tek tek yazılmıyor — `assets/data/cards.json` dosyasından okunuyor. Bu sayede 6 kart da 500 kart da aynı şekilde çalışır, kod değişmez.

**Adımlar:**
1. `backend/kart_yukleme_sablonu.xlsx`'i 500 satır olacak şekilde doldur (İngilizce, Türkçe, çağrışım, cümle, kategori, zorluk, görsel dosya adı).
2. Excel'i "CSV UTF-8" olarak kaydet.
3. 500 görseli tek bir klasöre topla, dosya adları `image_filename` sütunuyla eşleşsin.
4. Şunu çalıştır:
   ```
   pip install Pillow --break-system-packages   # bir kereye mahsus
   python3 prepare_offline_assets.py kartlar.csv gorseller_klasoru/
   ```
   Bu script otomatik olarak:
   - Her görseli 800px genişliğe indirip sıkıştırır (kalite kaybı gözle fark edilmez, boyut ~%60 düşer).
   - `flutter_app/assets/data/cards.json` ve `flutter_app/assets/images/` içini 500 kartla doldurur.
   - Sonunda tahmini APK boyutunu yazar (500 kart için ~50-60 MB civarı beklenir).
5. `flutter_app` klasörünü GitHub'a push et → Actions otomatik APK'yı derler (bkz. adım 6).
6. APK tamamen offline çalışır — hiçbir sunucuya bağlanmaz, 500 kart telefonun içinde hazır gelir.

**Not:** Bu, kartları uygulama içinden ekleyip çıkarabildiğin canlı bir sistem değil — kartlar derleme anında gömülüyor. Yeni kart eklemek istediğinde CSV'yi güncelleyip script'i tekrar çalıştırıp APK'yı yeniden derlemen gerekir. Gerçek zamanlı ekleme/silme istersen (uygulama içinden), bir dahaki adım telefonun kendi içinde SQLite veritabanı kurmak olur — o zaman da hiç backend gerekmez ama kartları uygulamanın içinden ekleyip yönetebilirsin. İstersen onu da kurarım.

## 1) Backend'i XAMPP2'ye kur (opsiyonel — ileride online moda geçersen)

1. `backend/` klasörünü `C:\xampp2\htdocs\kelime_hafiza\` altına kopyala.
2. phpMyAdmin'den `backend/schema.sql` dosyasını çalıştır (örnek 6 kart + kategoriler otomatik gelir).
3. `backend/config.php` içindeki DB bilgilerini kontrol et (local'de genelde değişmez: root / şifre yok).
4. `backend/uploads/` klasörüne yazma izni ver.
5. Test et: `http://localhost/kelime_hafiza/backend/api/cards_list.php`

## 2) Flutter app'i çalıştır

```
cd flutter_app
flutter pub get
flutter run
```

`lib/services/api_service.dart` içinde `baseUrl`'i ortama göre değiştir:
- Android emülatör + local XAMPP: `http://10.0.2.2/kelime_hafiza/backend/api`
- Gerçek telefon + local XAMPP: `http://<bilgisayar-lokal-ip>/kelime_hafiza/backend/api`
- Canlı (güzelhosting): `https://guzel.net.tr/kelime_hafiza/backend/api` (şu an bu ayarlı)

## 3) Güzelhosting'e deploy

1. `backend/` klasörünü cPanel File Manager veya FTP ile `public_html/kelime_hafiza/` altına yükle.
2. cPanel MySQL'de veritabanı oluştur, `schema.sql`'i import et.
3. `config.php`'deki DB_HOST/DB_NAME/DB_USER/DB_PASS'i cPanel bilgileriyle güncelle.
4. `UPLOAD_URL_BASE`'i gerçek path'e göre ayarla.
5. Flutter tarafında `baseUrl` zaten güzel.net.tr'ye ayarlı; APK'yı GitHub Actions ile önceki projelerindeki gibi build edebilirsin.

## 5) Binlerce kartı toplu yüklemek (bana tek tek göndermene gerek yok)

İki yöntem var, ikisi de `backend/kart_yukleme_sablonu.xlsx` şablonunu kullanır:

**A) Tarayıcıdan (SSH gerekmez, önerilen):**
1. `kart_yukleme_sablonu.xlsx`'i doldur (her satır = 1 kart).
2. Excel'i "CSV UTF-8" olarak kaydet.
3. Tüm görselleri tek bir .zip'e topla (Excel'deki `image_filename` sütunuyla dosya adları birebir eşleşmeli).
4. `https://guzel.net.tr/kelime_hafiza/backend/admin_bulk_upload.php` sayfasını aç, CSV + zip'i yükle.
5. Saniyeler içinde binlerce kart veritabanına işlenir.

Not: `admin_bulk_upload.php` şifresiz — işin bitince sil ya da bana söyle, `.htaccess` ile şifre korumalı yaparım.

**B) Terminal/SSH varsa (daha hızlı, çok büyük dosyalarda tercih edilir):**
```
php bulk_import.php kart_yukleme_sablonu.csv gorseller_klasoru/
```

İkisi de aynı mantıkla çalışır: eksik zorunlu alanı olan satırları atlar, bulunamayan görselleri uyarı olarak listeler, kategori isimlerini otomatik oluşturur.

## 6) GitHub'a yükleyip APK almak

`flutter_app/.github/workflows/build-apk.yml` hazır — diğer projelerindeki akışın aynısı.

1. `flutter_app` klasörünü yeni bir GitHub reposuna yükle (repo kökü = `flutter_app` içeriği olmalı, yani `pubspec.yaml` repo kökünde dursun).
2. `main` branch'e push edince Actions otomatik tetiklenir; istersen Actions sekmesinden "Run workflow" ile manuel de başlatabilirsin.
3. Build bitince Actions çalıştırmasının sayfasında **Artifacts** bölümünden `kelime-hafiza-apk` zip'ini indir, içinden `app-release.apk` çıkar.
4. APK'yı telefona atıp kur (bilinmeyen kaynaklardan yükleme izni gerekebilir).

Not: `lib/services/api_service.dart` içindeki `baseUrl` güzel.net.tr'ye ayarlı olduğu için, backend'i oraya deploy etmeden APK canlı veriye ulaşamaz — önce adım 3'ü (güzelhosting deploy) yapman gerekir, yoksa "Bağlantı hatası" görürsün.

## Özellikler

- **Galeri**: Kategori filtreli, aranabilir kart listesi, her kartta başarı oranı çubuğu.
- **Kart Ekle**: Görsel + kelime + anlam + çağrışım + cümle, kategori/zorluk seçimi.
- **Tekrar Modu (Flashcard)**: Kart çevirme animasyonu, SM-2 algoritmasıyla "Tekrar / Zor / İyi / Kolay" butonları — her cevap kartın bir sonraki tekrar tarihini otomatik hesaplar.
- **Quiz Modu**: Kategori bazlı, 4 şıklı otomatik üretilen sorular.

## Ölçeklenebilirlik notu

Binlerce kart eklendikçe:
- Görseller sunucuda dosya olarak, metin verisi MySQL'de tutuluyor — performans sorunu yaşamazsın.
- `cards_list.php`'ye sayfalama (`LIMIT`/`OFFSET`) eklemek istersen haber ver, kolayca ekleriz.
- Flashcard modunda "sadece tekrar zamanı gelenler" için `due_only=1` parametresi zaten hazır — ana ekrana "Bugün tekrar edilecekler" filtresi eklemek istersen söyle.
