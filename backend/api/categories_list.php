<?php
require_once __DIR__ . '/../config.php';
$pdo = getDB();

$stmt = $pdo->query("SELECT cat.*, COUNT(c.id) AS card_count
    FROM categories cat LEFT JOIN cards c ON c.category_id = cat.id
    GROUP BY cat.id ORDER BY cat.name");
jsonResponse(['categories' => $stmt->fetchAll()]);
