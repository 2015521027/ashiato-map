# keiken-memo(経県メモ)

## 目的
経県値スタイルの都道府県訪問記録 Android アプリ(Flutter製)。
各都道府県に 0〜5 のランク(未踏/通過/接地/訪問/宿泊/居住)を設定し、
訪問記録(日付・種別・タイトル・メモ)を子レコードとして何件でも残せる。

## 技術構成
- Flutter(SDK: `C:\Users\w5521\dev\tools\flutter`)/ ターゲットは Android APK
- JDK 17: `C:\Users\w5521\dev\tools\jdk\jdk-17.0.19+10`(Gradle 用。ビルド時に JAVA_HOME 設定)
- Android SDK: `%LOCALAPPDATA%\Android\Sdk`
- データ保存: shared_preferences に JSON 文字列(キー `keiken_data_v1`)。バックアップはクリップボード経由の JSON エクスポート/インポート
- 日本地図: `assets/japan.svg`(geolonia/japanese-prefectures、MITライセンス)を実行時にパースし CustomPainter で描画+タップ判定

## 主要コマンド
- 依存取得: `flutter pub get`
- 静的解析: `flutter analyze`
- APKビルド: `flutter build apk --release`(flutter は上記SDKパスの `bin\flutter.bat`)

## ルール
- UI文言はすべて日本語
- 経県値ランク定義・色は `lib/models.dart` に集約(勝手に散らばらせない)
