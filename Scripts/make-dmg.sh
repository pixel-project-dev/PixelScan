#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP="dist/Samsung Scan.app"
if [[ ! -d "$APP" ]]; then
  echo "dist/Samsung Scan.app fehlt. Zuerst Scripts/build-release.sh ausführen." >&2
  exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$APP" "$STAGE/Samsung Scan.app"
ln -s /Applications "$STAGE/Applications"
mkdir -p dist
rm -f dist/SamsungScan-1.1.0-unnotarized.dmg
cat > "$STAGE/Not notarized.txt" <<'EOF'
This disk image is signed with a Developer ID when a certificate is available.
It is not notarized. macOS Gatekeeper can block the first launch until the image is notarized and stapled.
EOF
hdiutil create \
  -volname "Samsung Scan" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "dist/SamsungScan-1.1.0-unnotarized.dmg"
echo "dist/SamsungScan-1.1.0-unnotarized.dmg"
