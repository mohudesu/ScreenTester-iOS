#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p output
xcodebuild -version
xcodebuild -project ScreenTester.xcodeproj -list
plutil -lint ScreenTester/Info.plist
xcodebuild -project ScreenTester.xcodeproj -scheme ScreenTester -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath output/SimulatorBuild CODE_SIGNING_ALLOWED=NO build 2>&1 | tee output/simulator-build.log
echo "Simulator compilation passed. Follow DEVICE-CHECKLIST.md for visual and device validation."
