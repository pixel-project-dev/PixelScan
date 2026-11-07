#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP="dist/Samsung Scan.app"
DMG="dist/SamsungScan-1.2.0-unnotarized.dmg"
if [[ ! -d "$APP" ]]; then
  echo "dist/Samsung Scan.app fehlt. Zuerst Scripts/build-release.sh ausführen." >&2
  exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/Samsung Scan.app"
ln -s /Applications "$STAGE/Applications"
mkdir -p dist
rm -f "$DMG" "$DMG.sha256"
cat > "$STAGE/Installation.txt" <<'EOF'
Samsung Scan 1.2.0

1. Ziehen Sie Samsung Scan auf den Ordner Programme.
2. Öffnen Sie Samsung Scan aus dem Programme-Ordner.
3. Erlauben Sie den Zugriff auf das lokale Netzwerk, wenn macOS danach fragt.
4. Folgen Sie der Einrichtung und fügen Sie den Scanner hinzu.
EOF
hdiutil create \
  -volname "Samsung Scan" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG"
shasum -a 256 "$DMG" > "$DMG.sha256"
echo "$DMG"
cat "$DMG.sha256"
echo "Diese Datei ist nicht notarisiert und ersetzt dist/SamsungScan-1.2.0.dmg nicht."
