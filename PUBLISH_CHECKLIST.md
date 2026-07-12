# 公開チェックリスト(足跡マップ)

## 完了済み ✅

- [x] Google Play Console 開発者登録($25)
- [x] 問い合わせ用メールアドレスの決定
- [x] リリース署名鍵の生成と署名設定(`android/upload-keystore.jks`)
- [x] AAB ビルド: `build\app\outputs\bundle\release\app-release.aab`
- [x] アプリアイコン(本採用: 1足+輪郭線版/予備: `store_assets/icon_backup_*.png`)
- [x] ストア用アイコン 512px: `store_assets/icon_512.png`
- [x] 宣伝画像 1024×500: `store_assets/feature_graphic.png`
- [x] ストア説明文: `store_assets/store_listing.md`(コピペ用)
- [x] スクリーンショット(スマホで撮影済みの3枚を使用)
- [x] GitHub 公開: https://github.com/2015521027/ashiato-map
- [x] Web版(PWA)公開: https://2015521027.github.io/ashiato-map/
- [x] プライバシーポリシー公開: https://2015521027.github.io/ashiato-map/privacy.html
- [x] 「経県値」表記の排除(アプリ名: 足跡マップ/スコア名: 足跡スコア)

## 残タスク

- [ ] Play Console でアプリ作成 → セットアップ項目の入力(`store_listing.md` からコピペ)
- [ ] AAB アップロード(製品版 → 新しいリリースを作成)
- [ ] 審査に送信
- [ ] (求められた場合)クローズドテスト要件への対応: 新規個人アカウントは
      「14日以上・テスター20人以上」のテスト実績が必要になることがある

## ⚠️ 最重要: 署名鍵のバックアップ

`android/upload-keystore.jks` と `android/key.properties` の2ファイルを
**USB メモリや個人のクラウドなど、PC 以外の場所に必ずバックアップすること。**
紛失すると、公開後のアプリを二度と更新できない(Git には含まれない)。

## Play Console 提出時の入力メモ

| 項目 | 値 |
|---|---|
| アプリ名 | 足跡マップ - 日本旅行の記録・塗りつぶし |
| カテゴリ | 旅行&地域 |
| 料金 | 無料/広告なし |
| プライバシーポリシーURL | https://2015521027.github.io/ashiato-map/privacy.html |
| データセーフティ | 収集なし・共有なし(全データ端末内保存) |
| コンテンツレーティング | 質問票すべて「なし」→ 全年齢想定 |
| 提出ファイル | `build\app\outputs\bundle\release\app-release.aab` |
