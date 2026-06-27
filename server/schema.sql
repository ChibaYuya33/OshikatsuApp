-- 推し活アプリ 自動収集バックエンド スキーマ (MySQL / Xserver 共用)
-- 文字コードは絵文字対応のため utf8mb4。

CREATE TABLE IF NOT EXISTS feed_items (
  id            VARCHAR(64)  NOT NULL,            -- ソース由来ID or URLのSHA1
  oshi_id       VARCHAR(64)  NOT NULL,            -- アプリ側の推しID
  source        VARCHAR(16)  NOT NULL,            -- youtube / rss / web
  title         TEXT         NOT NULL,
  url           TEXT         NOT NULL,
  published_at  DATETIME     NOT NULL,
  thumbnail_url TEXT         NULL,
  created_at    DATETIME     NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uniq_url (url(255)),
  KEY idx_oshi_pub (oshi_id, published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 収集バッチの実行ログ(任意・監視用)
CREATE TABLE IF NOT EXISTS collect_log (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  ran_at     DATETIME NOT NULL,
  source     VARCHAR(16) NOT NULL,
  oshi_id    VARCHAR(64) NOT NULL,
  inserted   INT NOT NULL DEFAULT 0,
  message    TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
