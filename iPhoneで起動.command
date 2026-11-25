#!/bin/zsh
set -e
cd "${0:A:h}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export BYPASS_PERMISSION_LOCATION_ALWAYS=1
neo_flutter_binary="$(command -v flutter || true)"
if [[ -z "$neo_flutter_binary" && -f .flutter-sdk-path ]]; then
  neo_flutter_binary="$(cat .flutter-sdk-path)/bin/flutter"
fi
if [[ ! -x "$neo_flutter_binary" ]]; then
  print 'Flutter SDKが見つかりません。FlutterをPATHに設定してください。'
  exit 1
fi
neo_device_id="${1:-}"
if [[ -z "$neo_device_id" && -f .iphone-device-id ]]; then
  neo_device_id="$(cat .iphone-device-id)"
fi
if [[ -z "$neo_device_id" ]]; then
  mkdir -p build/device-run
  xcrun devicectl list devices --quiet --json-output build/device-run/devices.json
  neo_device_id="$(python3 - <<'DEVICE_PY'
import json
from pathlib import Path
candidates=[]
for device in json.loads(Path('build/device-run/devices.json').read_text()).get('result',{}).get('devices',[]):
    properties=device.get('properties',{})
    hardware=properties.get('hardware',device.get('hardwareProperties',{}))
    connection=properties.get('connection',device.get('connectionProperties',{}))
    if hardware.get('reality')=='physical' and hardware.get('marketingName')=='iPhone 18 Pro' and connection.get('pairingState')=='paired':
        candidates.append(hardware.get('udid',device['identifier']))
if len(candidates)==1: print(candidates[0])
DEVICE_PY
)"
fi
if [[ -z "$neo_device_id" ]]; then
  print 'iPhone 18 Proを特定できません。対象端末のUDIDを引数に指定してください。'
  "$neo_flutter_binary" devices
  exit 1
fi
"$neo_flutter_binary" build ios --release
xcrun devicectl device install app --device "$neo_device_id" build/ios/iphoneos/Runner.app --timeout 60
xcrun devicectl device process launch --device "$neo_device_id" --terminate-existing jp.ac.tid.neoJichikai --timeout 60
print 'そなえあいをiPhoneで起動しました。ターミナルを閉じてもアプリは利用できます。' 
