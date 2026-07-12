# 足跡マップ - 日本旅行の記録・塗りつぶし

行った都道府県を塗りつぶして、旅行・出張の思い出をメモと写真で残せる記録アプリ(Flutter製)。
Android アプリと Web(PWA)の両方で動く。

## 公開先

| 種類 | URL |
|---|---|
| Web版(PWA) | https://2015521027.github.io/ashiato-map/ |
| プライバシーポリシー | https://2015521027.github.io/ashiato-map/privacy.html |
| Google Play | 準備中(提出素材は `store_assets/` に一式あり) |

## 機能

- **日本地図**: ランク別に色分け。県をタップで詳細へ。ピンチズーム対応。離島(沖縄・奄美)は右下の枠内に表示
- **ランク**: 居住5 / 宿泊4 / 訪問3 / 接地2 / 通過1 / 未踏0。合計が「**足跡スコア**」(最大235点)
- **訪問記録**: 県ごとに日付・種別(旅行/出張/帰省/イベント/その他)・タイトル・メモ・写真(複数枚)を何件でも
- **バックアップ**: JSON をクリップボードにエクスポート/貼り付けで復元(写真は対象外)

## 開発

```powershell
$flutter = 'C:\Users\w5521\dev\tools\flutter\bin\flutter.bat'
& $flutter pub get       # 依存取得
& $flutter analyze       # 静的解析
& $flutter test          # テスト
```

## リリース手順

```powershell
$env:JAVA_HOME = 'C:\Users\w5521\dev\tools\jdk\jdk-17.0.19+10'
& $flutter build apk --release        # スマホ直接インストール用
& $flutter build appbundle --release  # Google Play 提出用(.aab)
& $flutter build web --release --base-href "/ashiato-map/"  # Web版
```

- 成果物: `build\app\outputs\flutter-apk\app-release.apk` / `build\app\outputs\bundle\release\app-release.aab`
- Web公開: `build\web` の中身を GitHub リポジトリ `2015521027/ashiato-map` の `gh-pages` ブランチに force push(`.nojekyll` を含めること)
- ⚠️ 署名鍵 `android/upload-keystore.jks` と `android/key.properties` は Git 管理外。**紛失するとアプリを更新できなくなる**ため必ずバックアップを保持する

## アイコン

- 生成スクリプト: `tool/gen_icons.js`(使い方はファイル冒頭のコメント参照)
- 本採用: 日本地図全面+中央の大足跡1つ+足跡上に暗オレンジの県境線
- 予備: 足跡2つ版(`store_assets/icon_backup_*.png`)

## 内部名について

歴史的経緯により、以下は旧プロジェクト名のままにしている(変更するとデータ互換や依存が壊れるため):

- Dart パッケージ名: `keiken_memo`(pubspec.yaml)
- 保存データのキー: `keiken_data_v1`(変更すると既存ユーザーのデータが読めなくなるため**変更禁止**)
- ローカルフォルダ名: `dev\keiken-memo`

## クレジット

- 日本地図 SVG: [geolonia/japanese-prefectures](https://github.com/geolonia/japanese-prefectures)(MIT License)
- 足跡アイコン: [Material Design Icons](https://pictogrammers.com/library/mdi/)(Apache License 2.0)
