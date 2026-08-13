<?php
/**
 * TOPLU KART YÜKLEME
 * ------------------------------------------------------------
 * Kullanım (sunucuda terminal/SSH veya cPanel'in "Terminal" özelliğinden):
 *   php bulk_import.php kart_yukleme_sablonu.csv gorseller_klasoru/
 *
 * - Excel dosyasını ÖNCE CSV olarak kaydet (Dosya > Farklı Kaydet > CSV UTF-8).
 * - gorseller_klasoru/ : Excel'deki image_filename sütunundaki dosyaların bulunduğu klasör.
 *   Bu script o klasördeki görselleri otomatik olarak backend/uploads/ altına kopyalar.
 * - Binlerce satırı saniyeler içinde işler, tek tek eklemene gerek kalmaz.
 * ------------------------------------------------------------
 */

require_once __DIR__ . '/config.php';

if ($argc < 2) {
    die("Kullanım: php bulk_import.php <csv_dosyasi> [gorseller_klasoru]\n");
}

$csvPath = $argv[1];
$imagesDir = $argv[2] ?? null;

if (!file_exists($csvPath)) {
    die("Hata: CSV dosyası bulunamadı: $csvPath\n");
}

$pdo = getDB();

// Kategorileri önceden çekip cache'liyoruz (her satırda tekrar sorgu atmamak için)
$catCache = [];
foreach ($pdo->query("SELECT id, name FROM categories") as $row) {
    $catCache[mb_strtolower($row['name'])] = $row['id'];
}

function getOrCreateCategory(PDO $pdo, array &$catCache, ?string $name): ?int {
    if (!$name || trim($name) === '') return null;
    $key = mb_strtolower(trim($name));
    if (isset($catCache[$key])) return $catCache[$key];
    $stmt = $pdo->prepare("INSERT INTO categories (name) VALUES (:n)");
    $stmt->execute([':n' => trim($name)]);
    $id = $pdo->lastInsertId();
    $catCache[$key] = $id;
    return $id;
}

$handle = fopen($csvPath, 'r');
if (!$handle) die("CSV açılamadı.\n");

// BOM temizliği (Excel'den UTF-8 kaydedince başa BOM ekler)
$firstLine = fgets($handle);
$firstLine = preg_replace('/^\xEF\xBB\xBF/', '', $firstLine);
rewind($handle);
fgets($handle); // header satırını atla (english_word,turkish_meaning,...)

// 2. satır Türkçe açıklama satırıysa onu da atla
$pos = ftell($handle);
$maybeDescRow = fgetcsv($handle);
if ($maybeDescRow && stripos($maybeDescRow[0] ?? '', 'İngilizce') !== false) {
    // açıklama satırıydı, atlandı, devam
} else {
    fseek($handle, $pos); // açıklama satırı değildi, geri sar
}

$insertStmt = $pdo->prepare("INSERT INTO cards
    (english_word, turkish_meaning, association_word, mnemonic_sentence, image_path, category_id, difficulty, next_review_date)
    VALUES (:e, :t, :a, :s, :img, :cat, :diff, CURDATE())");

if (!is_dir(UPLOAD_DIR)) mkdir(UPLOAD_DIR, 0755, true);

$inserted = 0;
$skipped = 0;
$errors = [];
$rowNum = 2;

while (($row = fgetcsv($handle)) !== false) {
    $rowNum++;
    if (count(array_filter($row)) === 0) continue; // tamamen boş satır

    [$english, $turkish, $assoc, $sentence, $category, $difficulty, $imageFile] =
        array_pad(array_map('trim', $row), 7, '');

    if (!$english || !$turkish || !$assoc || !$sentence) {
        $errors[] = "Satır $rowNum: zorunlu alan eksik, atlandı.";
        $skipped++;
        continue;
    }

    if (!in_array($difficulty, ['easy', 'medium', 'hard'])) $difficulty = 'medium';

    $imagePath = null;
    if ($imageFile && $imagesDir) {
        $srcFile = rtrim($imagesDir, '/') . '/' . $imageFile;
        if (file_exists($srcFile)) {
            $ext = strtolower(pathinfo($imageFile, PATHINFO_EXTENSION));
            $newName = uniqid('card_') . '.' . $ext;
            copy($srcFile, UPLOAD_DIR . $newName);
            $imagePath = $newName;
        } else {
            $errors[] = "Satır $rowNum: görsel bulunamadı ($imageFile), görselsiz eklendi.";
        }
    }

    $catId = getOrCreateCategory($pdo, $catCache, $category);

    $insertStmt->execute([
        ':e' => $english, ':t' => $turkish, ':a' => $assoc, ':s' => $sentence,
        ':img' => $imagePath, ':cat' => $catId, ':diff' => $difficulty
    ]);
    $inserted++;
}

fclose($handle);

echo "=====================================\n";
echo "✅ Eklenen kart sayısı: $inserted\n";
echo "⚠️  Atlanan satır sayısı: $skipped\n";
if ($errors) {
    echo "\nUyarılar (ilk 20):\n";
    foreach (array_slice($errors, 0, 20) as $e) echo " - $e\n";
}
echo "=====================================\n";
