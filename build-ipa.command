#!/bin/bash
# Builds a device binary and packages it as an IPA. Run on macOS with Xcode.
set -euo pipefail
cd "$(dirname "$0")"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script requires macOS and Xcode." >&2
  exit 1
fi
if ! xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1; then
  echo "Open Xcode, install the iOS platform, and select Xcode in Settings > Locations > Command Line Tools." >&2
  exit 1
fi
mkdir -p output
stamp="$(date +%Y%m%d-%H%M%S)-$$"
build_dir="$PWD/output/build-$stamp"
stage_dir="$PWD/output/package-$stamp"
ipa_name="ScreenTester-unsigned-$stamp.ipa"
xcodebuild -project ScreenTester.xcodeproj -scheme ScreenTester -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath "$build_dir" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build 2>&1 | tee "output/build-$stamp.log"
app="$build_dir/Build/Products/Release-iphoneos/ScreenTester.app"
test -f "$app/ScreenTester"
xcrun lipo "$app/ScreenTester" -verify_arch arm64
plutil -lint "$app/Info.plist"
mkdir -p "$stage_dir/Payload"
ditto "$app" "$stage_dir/Payload/ScreenTester.app"
ditto -c -k --keepParent "$stage_dir/Payload" "$PWD/output/$ipa_name"
unzip -t "output/$ipa_name"
(cd output && shasum -a 256 "$ipa_name" > "$ipa_name.sha256")
echo "Created: $PWD/output/$ipa_name"
echo "UNSIGNED: sign this IPA yourself before installing."
if [[ "${CI:-false}" != "true" ]]; then
  open "$PWD/output"
fi
