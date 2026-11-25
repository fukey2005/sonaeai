#!/bin/zsh
set -e
cd "${0:A:h}"
if [[ -f build/web/index.html ]]; then
  demo_directory=build/web
elif [[ -f web_demo/index.html ]]; then
  demo_directory=web_demo
else
  flutter_binary="$(command -v flutter || true)"
  if [[ -z "$flutter_binary" && -f .flutter-sdk-path ]]; then
    flutter_binary="$(cat .flutter-sdk-path)/bin/flutter"
  fi
  if [[ ! -x "$flutter_binary" ]]; then
    print 'Flutterが見つかりません。Flutterを用意し、flutter build web --release --no-web-resources-cdn を実行してください。'
    exit 1
  fi
  "$flutter_binary" build web --release --no-web-resources-cdn --no-wasm-dry-run
  demo_directory=build/web
fi
print ''
print 'そなえあい Web版'
print 'ブラウザーで http://127.0.0.1:5187 を開いてください。'
print '終了するときは、このウィンドウで Control + C を押してください。'
print ''
python3 -m http.server 5187 --bind 127.0.0.1 --directory "$demo_directory"
