#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p output/ui-screenshots
xcrun simctl list devices available --json > output/simulators.json
device_id="$(python3 -c 'import json; d=json.load(open("output/simulators.json")); a=[x for v in d["devices"].values() for x in v if x.get("isAvailable") and x["name"].startswith("iPhone")]; a.sort(key=lambda x:x["name"] != "iPhone 17"); print(a[0]["udid"])')"
xcrun simctl boot "$device_id" || true
xcrun simctl bootstatus "$device_id" -b
xcrun simctl status_bar "$device_id" override --time '9:41' --batteryState charged --batteryLevel 100
test_status=0
xcodebuild -project ScreenTester.xcodeproj -scheme ScreenTester -configuration Debug \
  -destination "platform=iOS Simulator,id=$device_id" -parallel-testing-enabled NO \
  -derivedDataPath output/UITestBuild -resultBundlePath output/InterfaceTests.xcresult \
  CODE_SIGNING_ALLOWED=NO test 2>&1 | tee output/ui-test.log || test_status=$?
xcrun xcresulttool export attachments --path output/InterfaceTests.xcresult --output-path output/ui-screenshots
if [[ "$test_status" != 0 ]]; then exit "$test_status"; fi
xcrun simctl terminate "$device_id" com.local.screentester || true
xcrun simctl ui "$device_id" appearance dark
xcrun simctl launch "$device_id" com.local.screentester
sleep 2
xcrun simctl io "$device_id" screenshot output/ui-screenshots/04-Home-dark.png
xcrun simctl ui "$device_id" appearance light
