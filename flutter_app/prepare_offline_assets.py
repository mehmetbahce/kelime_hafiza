"""
KELİME HAFIZA - Sunucusuz (offline) APK için toplu veri hazırlama script'i
--------------------------------------------------------------------------
Ne yapar:
1) CSV'yi okur (kart_yukleme_sablonu.xlsx'ten "CSV UTF-8" olarak kaydedilmiş).
2) Her satırı flutter_app/assets/data/cards.json içine yazar.
3) image_filename sütununda belirtilen görseli bulur, 800px genişliğe indirip
   kaliteyi optimize ederek flutter_app/assets/images/ altına kopyalar
   (APK boyutu şişmesin diye).
4) Sonunda toplam tahmini APK boyutunu raporlar.

Kullanım:
    python3 prepare_offline_assets.py kartlar.csv gorseller_klasoru/

Gereksinim: pip install Pillow (bir kere)
--------------------------------------------------------------------------
"""

import csv
import json
import os
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow kurulu değil. Şunu çalıştır: pip install Pillow --break-system-packages")
    sys.exit(1)

SCRIPT_DIR = Path(__file__).parent
ASSETS_DATA = SCRIPT_DIR / "flutter_app" / "assets" / "data"
ASSETS_IMAGES = SCRIPT_DIR / "flutter_app" / "assets" / "images"
MAX_DIMENSION = 800   # px - kart görseli için yeterli, daha büyüğü boşuna yer kaplar
JPEG_QUALITY = 72     # 65-80 arası göz ile fark edilmez, boyutu ciddi düşürür


def compress_image(src_path: Path, dest_path: Path):
    img = Image.open(src_path).convert("RGB")
    img.thumbnail((MAX_DIMENSION, MAX_DIMENSION))
    img.save(dest_path, "JPEG", quality=JPEG_QUALITY, optimize=True)


def main():
    if len(sys.argv) < 2:
        print("Kullanım: python3 prepare_offline_assets.py <csv_dosyasi> [gorseller_klasoru]")
        sys.exit(1)

    csv_path = Path(sys.argv[1])
    images_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else None

    if not csv_path.exists():
        print(f"Hata: CSV bulunamadı: {csv_path}")
        sys.exit(1)

    ASSETS_DATA.mkdir(parents=True, exist_ok=True)
    ASSETS_IMAGES.mkdir(parents=True, exist_ok=True)

    # Eski görselleri temizle (yeniden derlerken karışıklık olmasın)
    for f in ASSETS_IMAGES.glob("*"):
        f.unlink()

    cards = []
    skipped = []
    missing_images = []

    with open(csv_path, "r", encoding="utf-8-sig") as f:
        reader = csv.reader(f)
        rows = list(reader)

    # Başlık satırlarını atla (1. satır İngilizce başlık, 2. satır Türkçe açıklama olabilir)
    start_idx = 1
    if len(rows) > 1 and "İngilizce" in (rows[1][0] if rows[1] else ""):
        start_idx = 2

    card_id = 1
    for row_num, row in enumerate(rows[start_idx:], start=start_idx + 1):
        if not any(cell.strip() for cell in row):
            continue
        row = (row + [""] * 7)[:7]
        english, turkish, assoc, sentence, category, difficulty, image_file = [c.strip() for c in row]

        if not (english and turkish and assoc and sentence):
            skipped.append(f"Satır {row_num}: zorunlu alan eksik")
            continue

        if difficulty not in ("easy", "medium", "hard"):
            difficulty = "medium"

        final_image_name = None
        if image_file and images_dir:
            src = images_dir / image_file
            if src.exists():
                ext = src.suffix.lower()
                final_image_name = f"card_{card_id}{ext if ext in ('.jpg', '.jpeg', '.png') else '.jpg'}"
                dest = ASSETS_IMAGES / final_image_name
                try:
                    compress_image(src, dest)
                except Exception as e:
                    missing_images.append(f"Satır {row_num}: {image_file} sıkıştırılamadı ({e})")
                    final_image_name = None
            else:
                missing_images.append(f"Satır {row_num}: görsel bulunamadı ({image_file})")

        cards.append({
            "id": card_id,
            "english_word": english,
            "turkish_meaning": turkish,
            "association_word": assoc,
            "mnemonic_sentence": sentence,
            "image_file": final_image_name,
            "category": category or "Genel",
            "difficulty": difficulty,
        })
        card_id += 1

    with open(ASSETS_DATA / "cards.json", "w", encoding="utf-8") as f:
        json.dump(cards, f, ensure_ascii=False, indent=2)

    total_size = sum(f.stat().st_size for f in ASSETS_IMAGES.glob("*"))

    print("=" * 50)
    print(f"✅ Eklenen kart: {len(cards)}")
    print(f"⚠️  Atlanan satır: {len(skipped)}")
    print(f"⚠️  Eksik/sorunlu görsel: {len(missing_images)}")
    print(f"📦 Toplam görsel boyutu: {total_size / 1024 / 1024:.1f} MB")
    print(f"📦 Tahmini APK boyutu: ~{total_size / 1024 / 1024 + 25:.0f} MB (Flutter motoru dahil)")
    print("=" * 50)
    if skipped:
        print("\nAtlanan satırlar:")
        for s in skipped[:20]:
            print(f"  - {s}")
    if missing_images:
        print("\nGörsel sorunları:")
        for m in missing_images[:20]:
            print(f"  - {m}")

    print(f"\n✅ Hazır: {ASSETS_DATA / 'cards.json'}")
    print(f"✅ Hazır: {ASSETS_IMAGES}/ ({len(list(ASSETS_IMAGES.glob('*')))} görsel)")
    print("\nŞimdi: cd flutter_app && flutter build apk --release")


if __name__ == "__main__":
    main()
