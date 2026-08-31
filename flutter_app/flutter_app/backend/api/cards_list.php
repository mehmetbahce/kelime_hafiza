<?php
require_once __DIR__ . '/../config.php';
$pdo = getDB();

$categoryId = $_GET['category_id'] ?? null;
$search = $_GET['search'] ?? null;
$dueOnly = isset($_GET['due_only']) && $_GET['due_only'] === '1'; // sadece tekrar zamanı gelenler

$sql = "SELECT c.*, cat.name AS category_name, cat.color AS category_color
        FROM cards c LEFT JOIN categories cat ON c.category_id = cat.id WHERE 1=1";
$params = [];

if ($categoryId) {
    $sql .= " AND c.category_id = :cid";
    $params[':cid'] = $categoryId;
}
if ($search) {
    $sql .= " AND (c.english_word LIKE :s OR c.turkish_meaning LIKE :s OR c.association_word LIKE :s)";
    $params[':s'] = "%$search%";
}
if ($dueOnly) {
    $sql .= " AND (c.next_review_date IS NULL OR c.next_review_date <= CURDATE())";
}

$sql .= " ORDER BY c.created_at DESC";

$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$cards = $stmt->fetchAll();

foreach ($cards as &$card) {
    if ($card['image_path']) {
        $card['image_url'] = UPLOAD_URL_BASE . basename($card['image_path']);
    }
}

jsonResponse(['cards' => $cards, 'count' => count($cards)]);
