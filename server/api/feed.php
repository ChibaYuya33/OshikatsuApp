<?php
// 配信API: GET /api/feed.php?oshi={oshiId}&since={ISO8601}
// レスポンスはアプリの FeedItem.fromJson と一致する camelCase の JSON 配列。
// 認証: ヘッダ `X-Api-Token` か クエリ `token` が config の api_token と一致すること。

header('Content-Type: application/json; charset=utf-8');

// --- CORS ---
// アプリ(PWA / GitHub Pages 等)からクロスオリジンで叩けるよう許可する。
// 必要なら '*' を自分の公開URL(例: https://chibayuya33.github.io)に絞ってよい。
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: X-Api-Token, Content-Type');
header('Access-Control-Max-Age: 86400');
// プリフライト(OPTIONS)はここで終了。
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/../lib/db.php';
$config = require __DIR__ . '/../config.php';

// --- 認証 ---
$expected = $config['api_token'] ?? '';
$given = $_SERVER['HTTP_X_API_TOKEN'] ?? ($_GET['token'] ?? '');
if ($expected !== '' && !hash_equals($expected, (string) $given)) {
    http_response_code(401);
    echo json_encode(['error' => 'unauthorized']);
    exit;
}

$oshi = $_GET['oshi'] ?? '';
$since = $_GET['since'] ?? null;

try {
    $pdo = db_connect($config['db']);

    $sql = 'SELECT id, oshi_id, source, title, url, published_at, thumbnail_url
            FROM feed_items WHERE 1=1';
    $params = [];
    if ($oshi !== '') {
        $sql .= ' AND oshi_id = :oshi';
        $params[':oshi'] = $oshi;
    }
    if ($since) {
        $ts = strtotime($since);
        if ($ts !== false) {
            $sql .= ' AND published_at > :since';
            $params[':since'] = date('Y-m-d H:i:s', $ts);
        }
    }
    $sql .= ' ORDER BY published_at DESC LIMIT 200';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    $out = [];
    foreach ($stmt as $row) {
        $out[] = [
            'id'           => $row['id'],
            'oshiId'       => $row['oshi_id'],
            'source'       => $row['source'],          // youtube/rss/web
            'title'        => $row['title'],
            'url'          => $row['url'],
            'publishedAt'  => date('c', strtotime($row['published_at'])),
            'thumbnailUrl' => $row['thumbnail_url'],
            'isRead'       => false,
            'isBookmarked' => false,
        ];
    }
    echo json_encode($out, JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => 'server_error']);
}
