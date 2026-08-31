<?php
require_once __DIR__ . '/../config.php';
$pdo = getDB();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['error' => 'Sadece POST kabul edilir'], 405);
}

$english = trim($_POST['english_word'] ?? '');
$turkish = trim($_POST['turkish_meaning'] ?? '');
$assoc   = trim($_POST['association_word'] ?? '');
$sentence = trim($_POST['mnemonic_sentence'] ?? '');
$categoryId = $_POST['category_id'] ?? null;
$difficulty = $_POST['difficulty'] ?? 'medium';

if (!$english || !$turkish || !$assoc || !$sentence) {
    jsonResponse(['error' => 'english_word, turkish_meaning, association_word, mnemonic_sentence zorunlu'], 400);
}

$imagePath = null;
if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
    if (!is_dir(UPLOAD_DIR)) mkdir(UPLOAD_DIR, 0755, true);
    $ext = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
    $allowed = ['jpg', 'jpeg', 'png', 'webp'];
    if (!in_array($ext, $allowed)) {
        jsonResponse(['error' => 'Sadece jpg/png/webp kabul edilir'], 400);
    }
    $filename = uniqid('card_') . '.' . $ext;
    $target = UPLOAD_DIR . $filename;
    if (move_uploaded_file($_FILES['image']['tmp_name'], $target)) {
        $imagePath = $filename;
    }
}

$stmt = $pdo->prepare("INSERT INTO cards
    (english_word, turkish_meaning, association_word, mnemonic_sentence, image_path, category_id, difficulty, next_review_date)
    VALUES (:e, :t, :a, :s, :img, :cat, :diff, CURDATE())");
$stmt->execute([
    ':e' => $english, ':t' => $turkish, ':a' => $assoc, ':s' => $sentence,
    ':img' => $imagePath, ':cat' => $categoryId ?: null, ':diff' => $difficulty
]);

jsonResponse(['success' => true, 'id' => $pdo->lastInsertId(), 'image_path' => $imagePath], 201);
