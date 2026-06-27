<?php
// 設定サンプル。`config.php` にコピーして値を埋めてください(config.php は公開しない)。
// Xserver の MySQL 情報・各APIキー・収集対象の推しを定義します。

return [
    // --- MySQL (Xserver のサーバーパネルで確認) ---
    'db' => [
        'host' => 'localhost',
        'name' => 'xxxxx_oshikatsu',
        'user' => 'xxxxx_oshi',
        'pass' => 'YOUR_DB_PASSWORD',
    ],

    // --- API キー(いずれも無料枠) ---
    // YouTube Data API v3: https://console.cloud.google.com/ で取得
    'youtube_api_key' => 'YOUR_YOUTUBE_API_KEY',
    // Google Custom Search: APIキー と 検索エンジンID(cx)
    'google_cse_key' => 'YOUR_CSE_API_KEY',
    'google_cse_cx'  => 'YOUR_CSE_ENGINE_ID',

    // API 認証(アプリからのアクセス用の簡易トークン)。任意だが推奨。
    'api_token' => 'CHANGE_ME_RANDOM_TOKEN',

    // --- 収集対象の推し ---
    // アプリの推しID(oshi.id)と収集設定を対応づける。
    'targets' => [
        [
            'oshi_id'            => 'PUT_APP_OSHI_ID',  // アプリの推しID
            'name'               => '推しの名前',         // Web/ニュース検索キーワード
            'youtube_channel_id' => 'UCxxxxxxxxxxxx',    // 任意
            'rss_urls'           => [                    // 任意(公式ブログ等)
                'https://example.com/feed',
            ],
        ],
    ],
];
