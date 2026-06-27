# 推し活アプリ (OshikatsuApp)

推しの情報・グッズ・支出・イベントを一元管理する、個人向けの「推し活」スマホアプリです。
**Flutter** 製で iOS / Android の両方に対応。データはすべて端末内に保存され、外部に送信しません（サーバー不要・無料で動作）。

## 主な機能

| 機能 | 内容 |
|---|---|
| 💖 複数推し管理 | 推しごとに**推し色テーマ**・誕生日を設定。アプリ全体の色が推し色に変わります |
| 🎁 グッズ管理 | 写真・購入履歴・所持状況を記録。**同名グッズの重複を登録時に警告**（「あ、これ持ってた」を防止） |
| 💰 支出管理 | **月予算アラート（既定¥10,000）**、月別棒グラフ・カテゴリ別円グラフ、**推し活貯金目標** |
| 🎫 イベント / カレンダー | 手動登録＋カレンダー表示。**チケット販売日・イベント前日のローカル通知**。参戦記録（セトリ・座席・写真） |
| 📰 情報フィード | 公式情報や記事のURLをブックマーク保存・既読管理。**次フェーズで自動収集と統合**（下記） |
| 🎂 カウントダウン | 誕生日・次イベントまでの日数をホームに表示 |
| 🙏 お布施累計 | 推し別の支出総額を表示 |
| 🌙 ダークモード / バックアップ | テーマ切替、JSONエクスポート/インポート（機種変更時の引き継ぎ） |

## 技術スタック

- Flutter (stable) / Dart
- 状態管理: Riverpod
- ローカル保存: JSON ストア（`shared_preferences`）※iOS/Android/Web すべてで動作。将来 Isar/Drift へ差し替え可能な Repository 構成
- グラフ: fl_chart / カレンダー: table_calendar
- 通知: flutter_local_notifications + timezone（サーバー不要のローカル通知）

## セットアップ

```bash
flutter pub get
flutter run            # 実機 / エミュレータ
flutter run -d chrome  # Web プレビュー（通知は無効・写真は保存制限あり）
```

## 📱 iPhone で動作確認する（いちばん簡単：PWA）

Mac も Apple Developer 登録（$99/年）も Xcode も**不要**。Web版（PWA）を GitHub Pages に
自動公開し、iPhone の Safari で開いて「ホーム画面に追加」するだけでアプリのように使えます。

### 手順
1. **初回だけ**リポジトリ設定を1回行う（コードからは設定不可）
   - GitHub のリポジトリ → **Settings** → 左メニュー **Pages**
   - **Build and deployment** → **Source** を「**GitHub Actions**」に変更
2. `claude/fan-activity-app-6xo8tr` ブランチに push すると、GitHub Actions
   （`.github/workflows/deploy-web.yml`）が自動でビルド＆公開します
   （Actions タブで進捗を確認できます。数分で完了）
3. 公開後、iPhone の **Safari** で次のURLを開く
   - **https://chibayuya33.github.io/OshikatsuApp/**
4. 共有ボタン（□に↑）→ **「ホーム画面に追加」** をタップ
   → ホーム画面に「推し活アプリ」アイコンが追加され、全画面アプリのように起動します

### PWA でできること / 制約
- ✅ 推し・グッズ・支出・イベント・予算・貯金目標の登録/集計/グラフ/カレンダー、JSON バックアップ
  （データは端末内 = ブラウザのストレージに保存されます）
- ⚠️ **プッシュ通知**（チケット販売日リマインド等）は PWA では動きません → ネイティブ版のみ
- ⚠️ **写真**はブラウザの制約で永続保存が限定的です → ネイティブ版で完全対応
- ※ Safari のデータを消すと保存内容も消えます。機種変更・データ移行時は設定の **JSONエクスポート/インポート** をご利用ください

## ネイティブで iPhone 実機確認する（後日・任意）

「通知・写真も含めて本物のアプリとして」確認したくなったら、以下のどちらか。

- **TestFlight（Mac 不要）**: [Codemagic](https://codemagic.io/) などの CI 無料枠で iOS ビルド →
  App Store Connect → TestFlight で配信。**Apple Developer Program（$99/年）の登録が必要**。
- **Mac + Xcode（無料7日）**: Mac があれば Xcode で実機に直接インストール可能（無料アカウントで7日間有効・要再インストール）。

## 検証

```bash
flutter analyze        # Lint（0 issues）
flutter test           # 単体テスト（重複検知・予算判定・集計・誕生日・バックアップ）
flutter build web      # 実コンパイル検証
```

## 公開（リリース）手順

開発・アプリ動作は無料。ストア公開にかかるのは開発者アカウント費用のみです。

### Android（先行公開がおすすめ：低コスト）
1. アプリアイコン・署名鍵を用意（`flutter_launcher_icons` 等）
2. `flutter build appbundle`
3. Google Play Console（**$25 買い切り**）で内部テスト → 製品版

### iOS
1. Apple Developer Program（**$99/年**）に登録
2. `flutter build ipa` → App Store Connect → TestFlight → 審査

### 審査対策
- 本アプリはデータを端末内のみに保存し外部送信しないため、審査リスクは低めです
- 写真・通知の利用許諾説明文は設定済み（iOS `Info.plist` / Android `AndroidManifest.xml`）
- プライバシーポリシーは [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md) を参照

## 次フェーズ：推し情報の自動収集（サーバー側）

現在は情報フィードを手動登録する設計ですが、**取得元の Repository を抽象化**してあるため、
リモート実装に差し替えるだけで自動収集に対応できます（`lib/features/feed/feed_repository.dart`）。
構成・収集元・API 設計は [`docs/next-phase-backend.md`](docs/next-phase-backend.md) を参照してください。

## ディレクトリ構成

```
lib/
  core/        DB(JSONストア)/モデル/集計ロジック/テーマ/通知/状態管理
  features/    oshi, goods, expense, event, feed, home, settings, shell
  shared/      共通ウィジェット
test/          単体テスト
docs/          プライバシーポリシー・次フェーズ設計
```
