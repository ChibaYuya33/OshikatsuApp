# 次フェーズ設計：推し情報の自動収集バックエンド

MVP（現行アプリ）は情報フィードを手動登録する構成です。本ドキュメントは、次フェーズで
**Xserver（共用レンタル：PHP + MySQL + cron）** 上に構築する自動収集バックエンドの設計を記録します。

## 方針
- アプリ側の `FeedRepository`（`lib/features/feed/feed_repository.dart`）を `RemoteFeedRepository` に差し替えるだけで自動収集に対応。
- 収集元は **YouTube（公式API）・公式サイト/RSS・Web/ニュース検索** の3つ。X / Instagram は API有料・規約リスクのため対象外。
- 個人利用想定。費用は契約済み Xserver の範囲内＋各APIの無料枠で完結。

## 構成図（概念）

```
[cron(定期実行)] --> [PHP収集バッチ] --> [MySQL: feed_items] <-- [PHP REST API] <-- [Flutterアプリ(dio)]
                          |
            +-------------+-------------+
            |             |             |
     YouTube Data API   RSS/ブログ   Google Custom Search
```

## 収集元と無料枠
| 収集元 | 手段 | 無料枠 |
|---|---|---|
| YouTube 新着/配信 | YouTube Data API v3（`search.list` / `playlistItems`） | 1万ユニット/日 |
| 公式サイト/ブログ | RSS を `SimplePie` 等でパース | 無料 |
| Web/ニュース | Google Custom Search JSON API（推し名で検索） | 100クエリ/日 |

## MySQL スキーマ（案）
```sql
CREATE TABLE feed_items (
  id            VARCHAR(64) PRIMARY KEY,   -- ソース由来の安定ID or URLハッシュ
  oshi_id       VARCHAR(64) NOT NULL,
  source        VARCHAR(16) NOT NULL,      -- youtube / rss / web
  title         TEXT NOT NULL,
  url           TEXT NOT NULL,
  published_at  DATETIME NOT NULL,
  thumbnail_url TEXT,
  created_at    DATETIME NOT NULL,
  UNIQUE KEY uniq_url (url(255))           -- 重複除外
);
```

## 収集バッチ（cron）
- 例: `*/30 * * * * php /home/xxx/batch/collect.php`
- 各推しの登録情報（`youtubeChannelId`・公式URL・推し名）をもとに収集し、`feed_items` に upsert。
- 重複は `url` の一意制約で除外。

## 配信 API（PHP REST）
- `GET /api/feed?oshi={oshiId}&since={ISO8601}`
- レスポンス: `FeedItem` の JSON 配列（`source/title/url/publishedAt/thumbnailUrl`）。
- アプリ側 `RemoteFeedRepository.fetchNew()` がこの形を想定済み。

## プッシュ通知（任意）
- 新着を端末へ通知したい場合は **Firebase Cloud Messaging（無料）** を追加。
- MVP はローカル通知のみで、サーバープッシュは未使用。

## アプリ側の切替手順
`feedRepositoryProvider` を override するだけ:
```dart
// main.dart の ProviderScope.overrides に追加
feedRepositoryProvider.overrideWithValue(
  RemoteFeedRepository('https://example.xsrv.jp/api'),
),
```

## 法務 / 規約
- 公式RSS・YouTube公式API・検索APIは各利用規約の範囲で利用する。
- X / Instagram のスクレイピングは行わない。
- 自動収集を有効化する際はプライバシーポリシーに外部通信の内容を追記する。
