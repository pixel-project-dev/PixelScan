#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

DERIVED="build/DerivedDataRelease"
xcodebuild \
  -project PixelScan.xcodeproj \
  -scheme PixelScan \
  -destination 'platform=macOS' \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  build

APP="$DERIVED/Build/Products/Release/PixelScan.app"
mkdir -p dist
rm -rf "dist/PixelScan.app"
cp -R "$APP" "dist/PixelScan.app"

IDENTITY="Developer ID Application: Norman Hennige (Z9U2P89679)"
if security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
  codesign --force --deep --options runtime --timestamp \
    --entitlements Config/SamsungScan.entitlements \
    --sign "$IDENTITY" \
    "dist/PixelScan.app"
  codesign --verify --deep --strict "dist/PixelScan.app"
else
  echo "Developer ID Zertifikat nicht gefunden. Die App bleibt ad-hoc signiert."
  exit 1
fi

bash Scripts/make-dmg.sh
echo "Fertig: dist/PixelScan.app und dist/PixelScan-1.3.1-unnotarized.dmg"
echo "Die notarisierte Datei dist/PixelScan-1.3.0.dmg wird nicht ersetzt."
echo "Öffentliche Veröffentlichung ist nicht enthalten."
