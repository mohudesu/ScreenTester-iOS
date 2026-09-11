#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "UI tests require macOS, Xcode and an installed iPhone simulator." >&2
  exit 1
fi
command -v python3 >/dev/null || { echo "Install Python 3 to select an available simulator." >&2; exit 1; }
stamp="$(date +%Y%m%d-%H%M%S)-$$"
result_bundle="$PWD/output/InterfaceTests-$stamp.xcresult"
screenshots="$PWD/output/ui-screenshots/$stamp"
mkdir -p "$screenshots"
xcrun simctl list devices available --json > output/simulators.json
device_id="$(python3 -c 'import json,sys; d=json.load(open("output/simulators.json")); a=[x for v in d["devices"].values() for x in v if x.get("isAvailable") and x["name"].startswith("iPhone")]; a.sort(key=lambda x:x["name"] != "iPhone 17"); sys.exit("Install an iPhone simulator in Xcode Settings > Components.") if not a else print(a[0]["udid"])')"
xcrun simctl boot "$device_id" || true
xcrun simctl bootstatus "$device_id" -b
xcrun simctl status_bar "$device_id" override --time '9:41' --batteryState charged --batteryLevel 100
test_status=0
xcodebuild -project ScreenTester.xcodeproj -scheme ScreenTester -configuration Debug \
  -destination "platform=iOS Simulator,id=$device_id" -parallel-testing-enabled NO \
  -derivedDataPath output/UITestBuild -resultBundlePath "$result_bundle" \
  CODE_SIGNING_ALLOWED=NO test 2>&1 | tee "output/ui-test-$stamp.log" || test_status=$?
if [[ -d "$result_bundle" ]]; then
  xcrun xcresulttool export attachments --path "$result_bundle" --output-path "$screenshots"
fi
if [[ "$test_status" != 0 ]]; then exit "$test_status"; fi
# Capture dark mode through XCTest so the screenshot waits for the real home UI.
# A fixed delay after simctl launch can capture only the launch screen on a busy runner.
xcrun simctl ui "$device_id" appearance dark
trap 'xcrun simctl ui "$device_id" appearance light' EXIT
dark_bundle="$PWD/output/InterfaceTests-Dark-$stamp.xcresult"
dark_status=0
xcodebuild -project ScreenTester.xcodeproj -scheme ScreenTester -configuration Debug \
  -destination "platform=iOS Simulator,id=$device_id" -parallel-testing-enabled NO \
  -derivedDataPath output/UITestBuild -resultBundlePath "$dark_bundle" \
  -only-testing:ScreenTesterUITests/InterfaceTests/testHomeSettingsAndFullscreenReturn \
  CODE_SIGNING_ALLOWED=NO test-without-building 2>&1 | tee "output/ui-dark-$stamp.log" || dark_status=$?
if [[ -d "$dark_bundle" ]]; then
  xcrun xcresulttool export attachments --path "$dark_bundle" --output-path "$screenshots/dark"
fi
if [[ "$dark_status" != 0 ]]; then exit "$dark_status"; fi
xcrun simctl ui "$device_id" appearance light
trap - EXIT
echo "UI tests passed. Screenshots: $screenshots"
