#!/bin/bash
# Signs and notarizes a PixelScan disk image. It never uploads the image to GitHub.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="dist/PixelScan.app"
DMG="dist/PixelScan-1.3.0.dmg"
IDENTITY="Developer ID Application: Norman Hennige (Z9U2P89679)"
PROFILE="SamsungScan-Notary"

if [[ ! -d "$APP" ]]; then
  echo "dist/PixelScan.app fehlt." >&2
  exit 1
fi
codesign --verify --deep --strict "$APP"

STAGE="$(mktemp -d)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$STAGE" "$WORKDIR"' EXIT
cp -R "$APP" "$STAGE/PixelScan.app"
ln -s /Applications "$STAGE/Applications"
cat > "$STAGE/Installation.txt" <<'EOF'
PixelScan 1.3.0

1. Drag PixelScan to the Applications folder.
2. Open PixelScan from the Applications folder.
3. Allow local network access if macOS asks.
4. Follow the setup assistant and add the scanner.

PixelScan 1.3.0

1. Ziehen Sie PixelScan auf den Ordner Programme.
2. Öffnen Sie PixelScan aus dem Programme-Ordner.
3. Erlauben Sie den Zugriff auf das lokale Netzwerk, wenn macOS danach fragt.
4. Folgen Sie der Einrichtung und fügen Sie den Scanner hinzu.
EOF

CANDIDATE="$WORKDIR/PixelScan-1.3.0.dmg"
hdiutil create -volname "PixelScan" -srcfolder "$STAGE" -ov -format UDZO "$CANDIDATE"
codesign --force --timestamp --sign "$IDENTITY" "$CANDIDATE"
codesign --verify --strict "$CANDIDATE"
xcrun notarytool submit "$CANDIDATE" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$CANDIDATE"
xcrun stapler validate "$CANDIDATE"
spctl --assess --type install --verbose=4 "$CANDIDATE"
hdiutil verify "$CANDIDATE"
mkdir -p dist
mv "$CANDIDATE" "$DMG"
shasum -a 256 "$DMG" | tee "$DMG.sha256"
shasum -a 256 -c "$DMG.sha256"
echo "Notarisiert: $DMG"
echo "Kein GitHub-Upload."
