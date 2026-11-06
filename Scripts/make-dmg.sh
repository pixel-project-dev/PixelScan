#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP="dist/Samsung Scan.app"
DMG="dist/SamsungScan-1.2.0-rc1-unnotarized.dmg"
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
cat > "$STAGE/Not notarized.txt" <<'EOF'
Samsung Scan 1.2.0 Release Candidate 1.
This disk image is signed with a Developer ID when a certificate is available.
It is not notarized. macOS Gatekeeper can block the first launch until the image is notarized and stapled.
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
