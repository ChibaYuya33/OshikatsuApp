# 自動収集バックエンド (Xserver 共用レンタル / PHP + MySQL + cron)

推し情報を **YouTube / RSS / Web検索** から定期収集し、アプリへ REST API で配信するサーバー側です。
※ アプリ本体はこれなしでも動作します（手動登録）。本バックエンドは「次フェーズ」の自動収集用です。

## 構成
```
server/
  config.sample.php   設定サンプル → config.php にコピーして記入
  schema.sql          MySQL テーブル定義
  collect.php         収集バッチ (cron で実行)
  api/feed.php        配信API (GET)
  lib/db.php          DB接続・upsert・HTTP
  lib/collectors.php  YouTube / RSS / CSE 収集ロジック
  .htaccess           機密ファイル遮断
```

## セットアップ手順 (Xserver)

1. **MySQL作成**: サーバーパネル → MySQL設定 で DB とユーザーを作成。
2. **テーブル作成**: phpMyAdmin で `schema.sql` を実行。
3. **APIキー取得 (いずれも無料枠)**
   - YouTube Data API v3 のキー（Google Cloud Console）
   - Google Custom Search の APIキー と 検索エンジンID(cx)
4. **設定**: `config.sample.php` を `config.php` にコピーし、DB情報・APIキー・`targets`（アプリの推しIDと収集設定）・`api_token` を記入。
5. **アップロード**: `server/` 配下を公開ディレクトリ（例: `~/example.xsrv.jp/public_html/oshikatsu/`）へFTP/SFTPで設置。
6. **cron登録**: サーバーパネル → Cron設定 で 30分おきに実行。
   ```
   */30 * * * * /usr/bin/php /home/USER/example.xsrv.jp/public_html/oshikatsu/collect.php >> ~/oshikatsu_collect.log 2>&1
   ```
7. **動作確認**:
   ```
   curl "https://example.xsrv.jp/oshikatsu/api/feed.php?oshi=OSHI_ID&token=API_TOKEN"
   ```

## アプリ側の接続（自動収集の有効化）

`lib/main.dart` の `ProviderScope.overrides` に以下を追加すると、フィード画面の「更新」で自動取得されます。

```dart
import 'features/feed/feed_repository.dart';

// overrides: [...] に追加
feedRepositoryProvider.overrideWithValue(
  RemoteFeedRepository('https://example.xsrv.jp/oshikatsu/api'),
),
```

`RemoteFeedRepository` は `GET {baseUrl}/feed.php?oshi=...&since=...` を呼び、返却JSONをそのまま
`FeedItem` に変換します（キーは `id/oshiId/source/title/url/publishedAt/thumbnailUrl`）。
> 認証トークンを使う場合は `RemoteFeedRepository` に `X-Api-Token` ヘッダを追加してください。

## 規約・注意
- 公式RSS・YouTube公式API・Google検索APIを各利用規約の範囲で利用します。
- X(旧Twitter)・Instagram のスクレイピングは行いません（API有料・規約リスクのため）。
- `config.php`（DBパスワード・APIキー）は Git にコミットしないでください（`.gitignore` 済み）。
