# そなえあい

大島六丁目団地に住む人が、家の備えを整え、地域の危険箇所を伝え、災害時の安否確認を練習するアプリです。iOS・Android共通ソースとビルド済みWeb版があります。

## Web版

Macで `preview.command` を実行し、http://127.0.0.1:5187 を開きます。Python 3が必要です。ZIP版の `web_demo/` も同じコマンドで開きます。

## 主な操作

- ホームの上部に**機能一覧**、右下に**そなAI**があります。
- **自宅の防災診断**では、家具・出入口・棚上の写真を案内に沿って1か所ずつ撮影するか、写真を選びます。iOSではVisionが写っている物を分類し、関連する確認箇所を提示します。確認は写真ごとに行い、保留した箇所も写真付きの点検履歴から見直せます。Webでは写真を見て確認します。
- **備蓄品管理**では、品物、数量、任意の期限を登録し、期限が近い品物や切れた品物を見直せます。
- **防災共有**では、回覧板でお知らせを確認し、住民の投稿で団地や周辺の危険箇所を伝えられます。「危険箇所を投稿」から場所と状況を入力し、写真を添付できます。投稿後は編集、写真変更、共有メニューからの共有ができます。
- **ハザードマップ**は「地震」「洪水」を切り替えます。地震では拠点避難所を、洪水では浸水想定と水害時の一時避難施設を表示します。「現在地」は端末の許可後に取得します。各施設から江東区の案内を開けます。
- **そなAI**はホーム右下から開き、備えや災害時の行動を公的資料に基づく案内から調べられます。
- **安否確認と助け合い**は、設定の「非常時の訓練」でホームと安否タブから使えます。安否の記録、家族・近所の安否を見る流れ、支援の依頼・協力の手順を練習できます。

起動時は通常時のホームを表示します。点検履歴と写真、備蓄、投稿と写真、訓練の記録、表示設定は端末内に保存します。住民の投稿例や過去のAI点検例を収録しています。掲示板の「共有する」から、利用者が端末の共有先を選べます。地図と公的資料リンクには通信が必要です。

- [地理院地図・地理院タイル一覧](https://maps.gsi.go.jp/development/ichiran.html)
- [ハザードマップポータル・オープンデータ](https://disaportal.gsi.go.jp/hazardmapportal/hazardmap/copyright/opendata.html)
- [江東区防災ポータル](https://bosai.city.koto.lg.jp/)

## iPhone 18 Pro

このMacでは、端末を接続しロックを解除した状態で `iPhoneで起動.command` を実行します。署名付きReleaseビルド、インストール、起動まで実行します。ターミナルを閉じた後も、インストール済みアプリを利用できます。

Xcodeでは `ios/Runner.xcworkspace` を開き、Runnerと接続中のiPhoneを選びます。Bundle IDは `jp.ac.tid.neoJichikai` です。このMacの開発チームで自動署名を設定しています。

ZIP版ではFlutter SDKをPATHに設定してください。接続中のiPhone 18 Proを自動検出します。対象を明示する場合は `zsh './iPhoneで起動.command' <端末のUDID>` を使用します。別のMacでは、その環境の署名アカウント・証明書が必要です。

## 開発と検証

検証環境はFlutter 3.47.9 / Dart 3.13.7です。

```sh
flutter pub get
flutter run
flutter test

dart analyze --format=machine lib test
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
```

AndroidネイティブのビルドはAndroid SDKを用意した環境で `flutter build apk --debug` を実行します。

テストは完了までの一本道だけでなく、戻る・修正・取り消し・下書きの再開・二重タップ・記録リセット・キーボード表示・360/390幅・3言語・文字200%を確認します。実利用者によるユーザビリティ評価、VoiceOver/TalkBackの実機操作評価は別途必要です。

## アイコン

組み込みimage_genで、黄色・黒の盾と家の図形を生成しました。文字・仮称・ロゴタイプを含みません。

- 元画像：`assets/branding/app_icon_v3.png`
- 1024px版：`assets/branding/app_icon_1024.png`
- プロンプト：`assets/branding/PROMPT.txt`
- サイズ変換：`swift tools/generate_icons.swift "$PWD"`

iOSアイコンはアルファチャンネルのないPNGです。角丸はOSが適用します。変換後の画像が単色になっていないことも検査します。

## 構成

`lib/screens/` が画面と導線、`lib/widgets/` が共通の操作・表示、`lib/mock/` が状態と訓練シナリオ、`lib/theme/` が色・文字です。端末内の保存は `lib/local_records.dart`、カメラと写真選択は `lib/photo_picker.dart` にあります。`test/demo_flow_test.dart` が操作テストです。

`DESIGN.md` は提供された初期設計書と更新方針です。Noto Sans JPのOFLライセンスは `assets/fonts/OFL.txt`、FlutterとMaterial Iconsのライセンスはビルド成果物のNOTICESに含まれます。
