#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mkdir -p build

encore_simulator_id="${ENCORE_SIMULATOR_ID:-$(xcrun simctl list devices available -j | python3 -c 'import json,sys; devices=json.load(sys.stdin)["devices"]; candidates=[d for runtime,group in devices.items() if "iOS-27" in runtime for d in group if d["name"]=="iPhone 18 Pro"]; print(candidates[0]["udid"] if candidates else "")')}"
if [[ -z "$encore_simulator_id" ]]; then
  print -u2 'Install an iOS 27 simulator in Xcode, or set ENCORE_SIMULATOR_ID.'
  exit 1
fi
xcrun simctl boot "$encore_simulator_id" 2>/dev/null || true
xcrun simctl bootstatus "$encore_simulator_id" -b
xcrun simctl terminate "$encore_simulator_id" com.neelsharma.encore 2>/dev/null || true
if ! xcodebuild -project Wordle.xcodeproj -scheme Wordle -configuration Debug \
  -destination "platform=iOS Simulator,id=$encore_simulator_id" \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build > build/last-build.log 2>&1; then
  tail -60 build/last-build.log
  exit 1
fi
xcrun simctl install "$encore_simulator_id" build/DerivedData/Build/Products/Debug-iphonesimulator/Wordle.app
xcrun simctl launch "$encore_simulator_id" com.neelsharma.encore
print 'Encore is running in the iOS simulator.'
