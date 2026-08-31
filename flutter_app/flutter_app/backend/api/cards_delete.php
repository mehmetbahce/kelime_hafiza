<?php
require_once __DIR__ . '/../config.php';
$pdo = getDB();

$id = $_GET['id'] ?? null;
if (!$id) jsonResponse(['error' => 'id zorunlu'], 400);

$stmt = $pdo->prepare("SELECT image_path FROM cards WHERE id = :id");
$stmt->execute([':id' => $id]);
$card = $stmt->fetch();

$stmt = $pdo->prepare("DELETE FROM cards WHERE id = :id");
$stmt->execute([':id' => $id]);

if ($card && $card['image_path']) {
    $file = UPLOAD_DIR . basename($card['image_path']);
    if (file_exists($file)) unlink($file);
}

jsonResponse(['success' => true]);
