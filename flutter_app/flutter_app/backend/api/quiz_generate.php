<?php
// Çoktan seçmeli quiz sorusu üretir: 1 doğru + 3 yanlış şık (aynı kategoriden karışık)
require_once __DIR__ . '/../config.php';
$pdo = getDB();

$categoryId = $_GET['category_id'] ?? null;
$count = min((int)($_GET['count'] ?? 10), 50);

$sql = "SELECT id, english_word, turkish_meaning FROM cards";
$params = [];
if ($categoryId) {
    $sql .= " WHERE category_id = :cid";
    $params[':cid'] = $categoryId;
}
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$all = $stmt->fetchAll();

if (count($all) < 4) {
    jsonResponse(['error' => 'Quiz için en az 4 kart gerekli'], 400);
}

shuffle($all);
$questions = [];
$pool = $all;

foreach (array_slice($all, 0, $count) as $correct) {
    $distractors = array_filter($pool, fn($c) => $c['id'] !== $correct['id']);
    $distractors = array_values($distractors);
    shuffle($distractors);
    $wrong = array_slice($distractors, 0, 3);

    $options = array_map(fn($c) => $c['turkish_meaning'], array_merge([$correct], $wrong));
    shuffle($options);

    $questions[] = [
        'card_id' => $correct['id'],
        'question' => $correct['english_word'],
        'options' => $options,
        'correct_answer' => $correct['turkish_meaning'],
    ];
}

jsonResponse(['questions' => $questions]);
