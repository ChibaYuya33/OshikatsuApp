<?php
// 収集バッチ。cron から定期実行する(例: 30分おき)。
//   */30 * * * * /usr/bin/php /home/USER/oshikatsu/collect.php >> /home/USER/oshikatsu/collect.log 2>&1
// CLI 専用(ブラウザからの実行は禁止)。

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("CLI only\n");
}

require_once __DIR__ . '/lib/db.php';
require_once __DIR__ . '/lib/collectors.php';

$config = require __DIR__ . '/config.php';
$pdo = db_connect($config['db']);

$totalInserted = 0;
foreach ($config['targets'] as $target) {
    $oshiId = $target['oshi_id'];

    $batches = [
        'youtube' => collect_youtube($target, $config['youtube_api_key'] ?? ''),
        'rss'     => collect_rss($target),
        'web'     => collect_web(
            $target,
            $config['google_cse_key'] ?? '',
            $config['google_cse_cx'] ?? ''
        ),
    ];

    foreach ($batches as $source => $items) {
        $inserted = 0;
        foreach ($items as $item) {
            try {
                if (feed_upsert($pdo, $item)) {
                    $inserted++;
                }
            } catch (Throwable $e) {
                // 1件の失敗で全体を止めない。
                error_log("upsert failed: {$e->getMessage()}");
            }
        }
        $totalInserted += $inserted;
        log_collect($pdo, $source, $oshiId, $inserted);
        printf("[%s] %s/%s : %d new\n", date('H:i'), $oshiId, $source, $inserted);
    }
}

printf("done. total new = %d\n", $totalInserted);
