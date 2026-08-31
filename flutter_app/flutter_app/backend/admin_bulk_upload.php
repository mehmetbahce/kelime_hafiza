<?php
require_once __DIR__ . '/config.php';
$pdo = getDB();

$message = '';
$errors = [];
$inserted = 0;
$skipped = 0;

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['csv_file'])) {
    $csvTmp = $_FILES['csv_file']['tmp_name'];

    // Görsel zip'i varsa uploads/ altına aç
    $imagesExtractDir = null;
    if (isset($_FILES['images_zip']) && $_FILES['images_zip']['error'] === UPLOAD_ERR_OK) {
        $imagesExtractDir = sys_get_temp_dir() . '/kh_import_' . uniqid();
        mkdir($imagesExtractDir, 0755, true);
        $zip = new ZipArchive();
        if ($zip->open($_FILES['images_zip']['tmp_name']) === true) {
            $zip->extractTo($imagesExtractDir);
            $zip->close();
        }
    }

    $catCache = [];
    foreach ($pdo->query("SELECT id, name FROM categories") as $row) {
        $catCache[mb_strtolower($row['name'])] = $row['id'];
    }
    function getOrCreateCategory($pdo, &$catCache, $name) {
        if (!$name || trim($name) === '') return null;
        $key = mb_strtolower(trim($name));
        if (isset($catCache[$key])) return $catCache[$key];
        $stmt = $pdo->prepare("INSERT INTO categories (name) VALUES (:n)");
        $stmt->execute([':n' => trim($name)]);
        $id = $pdo->lastInsertId();
        $catCache[$key] = $id;
        return $id;
    }

    // Görseli extract edilen klasörde (alt klasörler dahil) ada göre bul
    function findImageFile($dir, $filename) {
        if (!$dir || !$filename) return null;
        $rii = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir));
        foreach ($rii as $file) {
            if ($file->getFilename() === $filename) return $file->getPathname();
        }
        return null;
    }

    $handle = fopen($csvTmp, 'r');
    fgets($handle); // başlık satırı
    $pos = ftell($handle);
    $maybeDesc = fgetcsv($handle);
    if (!$maybeDesc || stripos($maybeDesc[0] ?? '', 'İngilizce') === false) {
        fseek($handle, $pos);
    }

    $insertStmt = $pdo->prepare("INSERT INTO cards
        (english_word, turkish_meaning, association_word, mnemonic_sentence, image_path, category_id, difficulty, next_review_date)
        VALUES (:e, :t, :a, :s, :img, :cat, :diff, CURDATE())");

    if (!is_dir(UPLOAD_DIR)) mkdir(UPLOAD_DIR, 0755, true);

    $rowNum = 2;
    while (($row = fgetcsv($handle)) !== false) {
        $rowNum++;
        if (count(array_filter($row)) === 0) continue;
        [$english, $turkish, $assoc, $sentence, $category, $difficulty, $imageFile] =
            array_pad(array_map('trim', $row), 7, '');

        if (!$english || !$turkish || !$assoc || !$sentence) {
            $errors[] = "Satır $rowNum: zorunlu alan eksik, atlandı.";
            $skipped++;
            continue;
        }
        if (!in_array($difficulty, ['easy', 'medium', 'hard'])) $difficulty = 'medium';

        $imagePath = null;
        if ($imageFile && $imagesExtractDir) {
            $found = findImageFile($imagesExtractDir, $imageFile);
            if ($found) {
                $ext = strtolower(pathinfo($imageFile, PATHINFO_EXTENSION));
                $newName = uniqid('card_') . '.' . $ext;
                copy($found, UPLOAD_DIR . $newName);
                $imagePath = $newName;
            } else {
                $errors[] = "Satır $rowNum: görsel bulunamadı ($imageFile).";
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
    $message = "İşlem tamamlandı.";
}
?>
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<title>Kelime Hafıza - Toplu Kart Yükleme</title>
<style>
  body{font-family:Arial,sans-serif;background:#FAF7F0;max-width:640px;margin:40px auto;padding:0 20px;color:#2A2A2A;}
  h1{font-size:22px;} .box{background:#fff;border-radius:14px;padding:24px;box-shadow:0 4px 14px rgba(0,0,0,.08);margin-bottom:20px;}
  label{display:block;font-weight:bold;margin:14px 0 6px;font-size:13px;}
  input[type=file]{width:100%;padding:8px;border:1px solid #ddd;border-radius:8px;}
  button{background:#1A1A1A;color:#F5C518;border:none;padding:12px 22px;border-radius:10px;font-weight:bold;margin-top:18px;cursor:pointer;}
  .result{background:#FFF6D9;border-radius:10px;padding:14px;font-size:13px;}
  .ok{color:#2e8b4f;font-weight:bold;} .warn{color:#c2447a;font-weight:bold;}
  ul{font-size:12.5px;color:#8A6D00;}
</style>
</head>
<body>
<h1>📥 Kelime Hafıza — Toplu Kart Yükleme</h1>

<?php if ($message): ?>
<div class="box result">
  <p class="ok">✅ Eklenen kart: <?= $inserted ?></p>
  <p class="warn">⚠️ Atlanan/uyarı: <?= $skipped ?></p>
  <?php if ($errors): ?><ul><?php foreach (array_slice($errors,0,30) as $e) echo "<li>".htmlspecialchars($e)."</li>"; ?></ul><?php endif; ?>
</div>
<?php endif; ?>

<div class="box">
  <form method="POST" enctype="multipart/form-data">
    <label>1) CSV dosyası (kart_yukleme_sablonu.xlsx'ten "CSV UTF-8" olarak kaydet)</label>
    <input type="file" name="csv_file" accept=".csv" required>

    <label>2) Görseller (isteğe bağlı) — hepsini tek bir .zip yapıp yükle</label>
    <input type="file" name="images_zip" accept=".zip">

    <button type="submit">Yükle ve İşle</button>
  </form>
</div>

<p style="font-size:12px;color:#8A8272;">
Bu sayfayı sadece sen kullan — herkese açık bırakma. İşin bitince dosyayı sunucudan silebilir
ya da bir .htaccess ile şifre koruması ekleyebiliriz, istersen söyle.
</p>
</body>
</html>
