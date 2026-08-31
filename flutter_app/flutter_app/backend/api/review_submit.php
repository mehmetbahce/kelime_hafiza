<?php
// SM-2 (SuperMemo 2) spaced repetition algoritması
// quality: 0-5 arası (0=hiç hatırlamadım, 5=çok kolay hatırladım)
// Flutter tarafında basitçe 4 buton önerilir: Tekrar(1) / Zor(3) / İyi(4) / Kolay(5)

require_once __DIR__ . '/../config.php';
$pdo = getDB();

$data = json_decode(file_get_contents('php://input'), true);
$id = $data['id'] ?? null;
$quality = isset($data['quality']) ? (int)$data['quality'] : null;

if (!$id || $quality === null || $quality < 0 || $quality > 5) {
    jsonResponse(['error' => 'id ve quality (0-5) zorunlu'], 400);
}

$stmt = $pdo->prepare("SELECT ease_factor, interval_days, repetitions, times_seen, times_correct FROM cards WHERE id = :id");
$stmt->execute([':id' => $id]);
$card = $stmt->fetch();
if (!$card) jsonResponse(['error' => 'Kart bulunamadı'], 404);

$ef = (float)$card['ease_factor'];
$interval = (int)$card['interval_days'];
$reps = (int)$card['repetitions'];

if ($quality < 3) {
    // Yanlış / hatırlamadı -> baştan başla
    $reps = 0;
    $interval = 1;
} else {
    $reps++;
    if ($reps === 1) {
        $interval = 1;
    } elseif ($reps === 2) {
        $interval = 6;
    } else {
        $interval = (int)round($interval * $ef);
    }
}

$ef = $ef + (0.1 - (5 - $quality) * (0.08 + (5 - $quality) * 0.02));
if ($ef < 1.3) $ef = 1.3;

$timesSeen = (int)$card['times_seen'] + 1;
$timesCorrect = (int)$card['times_correct'] + ($quality >= 3 ? 1 : 0);

$stmt = $pdo->prepare("UPDATE cards SET
    ease_factor = :ef, interval_days = :interval, repetitions = :reps,
    next_review_date = DATE_ADD(CURDATE(), INTERVAL :interval DAY),
    last_reviewed_at = NOW(), times_seen = :seen, times_correct = :correct
    WHERE id = :id");
$stmt->execute([
    ':ef' => $ef, ':interval' => $interval, ':reps' => $reps,
    ':seen' => $timesSeen, ':correct' => $timesCorrect, ':id' => $id
]);

jsonResponse(['success' => true, 'next_interval_days' => $interval, 'ease_factor' => round($ef, 2)]);
