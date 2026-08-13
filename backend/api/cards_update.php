<?php
require_once __DIR__ . '/../config.php';
$pdo = getDB();

$data = json_decode(file_get_contents('php://input'), true);
$id = $data['id'] ?? null;
if (!$id) jsonResponse(['error' => 'id zorunlu'], 400);

$fields = ['english_word', 'turkish_meaning', 'association_word', 'mnemonic_sentence', 'category_id', 'difficulty'];
$set = [];
$params = [':id' => $id];
foreach ($fields as $f) {
    if (isset($data[$f])) {
        $set[] = "$f = :$f";
        $params[":$f"] = $data[$f];
    }
}
if (empty($set)) jsonResponse(['error' => 'Güncellenecek alan yok'], 400);

$sql = "UPDATE cards SET " . implode(', ', $set) . " WHERE id = :id";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);

jsonResponse(['success' => true]);
