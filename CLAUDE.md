# keiken-memo(足跡マップ)

## 目的
「足跡マップ - 日本旅行の記録・塗りつぶし」— 都道府県の訪問記録アプリ(Flutter製)。
各都道府県に 0〜5 のランク(未踏/通過/接地/訪問/宿泊/居住)を設定し、
訪問記録(日付・種別・タイトル・メモ・写真)を子レコードとして何件でも残せる。
Android(APK/AAB)と Web(GitHub Pages の PWA)の両対応。

## 技術構成
- Flutter(SDK: `C:\Users\w5521\dev\tools\flutter`)
- JDK 17: `C:\Users\w5521\dev\tools\jdk\jdk-17.0.19+10`(Gradleビルド時に JAVA_HOME 設定が必要)
- Android SDK: `%LOCALAPPDATA%\Android\Sdk`
- リリース署名: `android/upload-keystore.jks` + `android/key.properties`(Git管理外・紛失厳禁)
- データ保存: shared_preferences に JSON 文字列。バックアップはクリップボード経由
- 日本地図: `assets/japan.svg`(geolonia製・小島除去加工済み・沖縄と奄美は右下枠)を実行時パースして CustomPainter で描画+タップ判定
- アイコン生成: `tool/gen_icons.js`(SVG出力→headless ChromeでPNG化→flutter_launcher_icons)

## 主要コマンド
- 解析/テスト: `flutter analyze` / `flutter test`
- APK: `flutter build apk --release`
- Play提出用: `flutter build appbundle --release`
- Web: `flutter build web --release --base-href "/ashiato-map/"` → `build\web` を GitHub `2015521027/ashiato-map` の gh-pages ブランチへ force push

## ルール
- UI文言はすべて日本語
- ランク定義・色は `lib/models.dart` に集約(勝手に散らばらせない)
- **「経県値」「経県」という表記をアプリ・ストア文言に使わない**(商標回避。スコア名は「足跡スコア」)
- 保存キー `keiken_data_v1` と Dartパッケージ名 `keiken_memo` は互換性のため**変更禁止**
- Play 公開後は `applicationId` を変更しない(変更すると別アプリ扱いになる)
