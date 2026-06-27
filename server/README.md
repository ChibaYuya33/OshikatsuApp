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

## アプリ側の接続（コード変更は不要・設定画面から）

アプリの **設定 → 自動収集サーバー → 収集サーバーの設定** で、次を入力して保存するだけです。

- **API URL**: `https://example.xsrv.jp/oshikatsu/api`（`feed.php` の1つ上のディレクトリ）
- **APIトークン**: `config.php` の `api_token` と同じ値（空なら認証なし）

設定すると、情報タブ右上の「更新」ボタンで収集サーバーから新着を取得します（URL重複は自動除外）。
URL を空に戻すと未設定（手動登録のみ）に戻ります。

### 推しID（targets 設定用）の調べ方
`config.php` の `targets[].oshi_id` には**アプリ内の推しID**を入れます。
アプリの **設定 → 自動収集サーバー → 推しID (サーバー設定用)** で各推しのIDをコピーできます。

### 通信仕様
`RemoteFeedRepository` は `GET {baseUrl}/feed.php?oshi=...&since=...&token=...` を呼び、返却JSONを
`FeedItem` に変換します（キーは `id/oshiId/source/title/url/publishedAt/thumbnailUrl`）。
トークンはクエリ `token` で送ります（Web のクロスオリジンで preflight を避けるため。サーバーは
`X-Api-Token` ヘッダにも対応）。

### CORS（PWA / 別ドメインから呼ぶ場合・重要）
アプリを GitHub Pages 等の別ドメインで動かす場合、ブラウザのCORS制限で `feed.php` を呼べません。
`api/feed.php` には `Access-Control-Allow-Origin: *` 等のヘッダと OPTIONS 応答を実装済みです。
セキュリティを上げたい場合は `*` を自分の公開URL（例 `https://chibayuya33.github.io`）に絞ってください。

## 規約・注意
- 公式RSS・YouTube公式API・Google検索APIを各利用規約の範囲で利用します。
- X(旧Twitter)・Instagram のスクレイピングは行いません（API有料・規約リスクのため）。
- `config.php`（DBパスワード・APIキー）は Git にコミットしないでください（`.gitignore` 済み）。
