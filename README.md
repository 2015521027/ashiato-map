# 経県メモ(keiken-memo)

経県値スタイルの都道府県訪問記録 Android アプリ。
各都道府県に 6 段階の経県ランクを付け、「いつ・何の旅行/出張で行ったか」を
訪問記録(子レコード)として何件でも残せる。

## 機能

- **日本地図**: ランク別に色分け。タップで都道府県詳細へ。ピンチズームで小さい県も選択可能
- **経県ランク**: 居住5 / 宿泊4 / 訪問3 / 接地2 / 通過1 / 未踏0(合計が「経県値」、最大235点)
- **訪問記録**: 日付・種別(旅行/出張/帰省/イベント/その他)・タイトル・メモを都道府県ごとに記録
- **バックアップ**: JSON をクリップボードにエクスポート/貼り付けで復元

## 開発

```powershell
$flutter = 'C:\Users\w5521\dev\tools\flutter\bin\flutter.bat'
& $flutter pub get          # 依存取得
& $flutter analyze          # 静的解析
& $flutter test             # テスト
& $flutter build apk --release   # APKビルド
```

ビルド成果物: `build\app\outputs\flutter-apk\app-release.apk`
スマホへは APK を転送し、「提供元不明のアプリ」を許可してインストールする。

## クレジット

- 日本地図 SVG: [geolonia/japanese-prefectures](https://github.com/geolonia/japanese-prefectures)(MIT License)
- 経県値の考え方: [経県値](https://uub.jp/kkn/)に着想
