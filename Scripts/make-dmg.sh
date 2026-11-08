#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP="dist/PixelScan.app"
DMG="dist/PixelScan-1.3.1-unnotarized.dmg"
if [[ ! -d "$APP" ]]; then
  echo "dist/PixelScan.app fehlt. Zuerst Scripts/build-release.sh ausführen." >&2
  exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/PixelScan.app"
ln -s /Applications "$STAGE/Applications"
mkdir -p dist
rm -f "$DMG" "$DMG.sha256"
cat > "$STAGE/Installation.txt" <<'EOF'
PixelScan 1.3.1

1. Drag PixelScan to the Applications folder.
2. Open PixelScan from the Applications folder.
3. Allow local network access if macOS asks.
4. Follow the setup assistant and add the scanner.

PixelScan 1.3.1

1. Ziehen Sie PixelScan auf den Ordner Programme.
2. Öffnen Sie PixelScan aus dem Programme-Ordner.
3. Erlauben Sie den Zugriff auf das lokale Netzwerk, wenn macOS danach fragt.
4. Folgen Sie der Einrichtung und fügen Sie den Scanner hinzu.
EOF
hdiutil create \
  -volname "PixelScan" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG"
shasum -a 256 "$DMG" > "$DMG.sha256"
echo "$DMG"
cat "$DMG.sha256"
echo "Diese Datei ist nicht notarisiert und ersetzt weder dist/PixelScan-1.3.0.dmg noch dist/PixelScan-1.3.1.dmg."
