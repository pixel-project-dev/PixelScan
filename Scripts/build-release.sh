#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

DERIVED="build/DerivedDataRelease"
xcodebuild \
  -project SamsungScan.xcodeproj \
  -scheme SamsungScan \
  -destination 'platform=macOS' \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  build

APP="$DERIVED/Build/Products/Release/Samsung Scan.app"
mkdir -p dist
rm -rf "dist/Samsung Scan.app"
cp -R "$APP" "dist/Samsung Scan.app"

IDENTITY="Developer ID Application: Norman Hennige (Z9U2P89679)"
if security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
  codesign --force --deep --options runtime --timestamp \
    --sign "$IDENTITY" \
    "dist/Samsung Scan.app"
  codesign --verify --verbose=2 "dist/Samsung Scan.app"
else
  echo "Developer ID Zertifikat nicht gefunden. Die App bleibt ad-hoc signiert."
fi

bash Scripts/make-dmg.sh
echo "Fertig: dist/Samsung Scan.app und dist/SamsungScan-1.1.0-unnotarized.dmg"
