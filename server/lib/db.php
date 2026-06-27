<?php
// PDO 接続と feed_items への upsert ヘルパー。

function db_connect(array $cfg): PDO
{
    $dsn = sprintf(
        'mysql:host=%s;dbname=%s;charset=utf8mb4',
        $cfg['host'],
        $cfg['name']
    );
    return new PDO($dsn, $cfg['user'], $cfg['pass'], [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
}

/**
 * フィードを1件 upsert する。URL重複は無視(既存を維持)。
 * @return bool 新規挿入なら true。
 */
function feed_upsert(PDO $pdo, array $item): bool
{
    $sql = 'INSERT INTO feed_items
              (id, oshi_id, source, title, url, published_at, thumbnail_url, created_at)
            VALUES
              (:id, :oshi_id, :source, :title, :url, :published_at, :thumbnail_url, NOW())
            ON DUPLICATE KEY UPDATE id = id'; // 既存はそのまま
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':id'            => $item['id'],
        ':oshi_id'       => $item['oshi_id'],
        ':source'        => $item['source'],
        ':title'         => $item['title'],
        ':url'           => $item['url'],
        ':published_at'  => $item['published_at'],
        ':thumbnail_url' => $item['thumbnail_url'] ?? null,
    ]);
    return $stmt->rowCount() === 1; // 1=挿入, 0/2=重複
}

function log_collect(PDO $pdo, string $source, string $oshiId, int $inserted, ?string $msg = null): void
{
    $stmt = $pdo->prepare(
        'INSERT INTO collect_log (ran_at, source, oshi_id, inserted, message)
         VALUES (NOW(), :s, :o, :i, :m)'
    );
    $stmt->execute([':s' => $source, ':o' => $oshiId, ':i' => $inserted, ':m' => $msg]);
}

/** 簡易HTTP GET(JSON想定)。 */
function http_get(string $url): ?string
{
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 20,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_USERAGENT      => 'OshikatsuApp-Collector/1.0',
    ]);
    $body = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($body === false || $code >= 400) {
        return null;
    }
    return $body;
}
