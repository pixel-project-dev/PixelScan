#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

SOURCE="dist/Samsung Scan.app"
if [[ ! -d "$SOURCE" ]]; then
  echo "dist/Samsung Scan.app fehlt." >&2
  exit 1
fi

TARGET="build/Samsung Scan Sandbox.app"
rm -rf "$TARGET"
mkdir -p build
cp -R "$SOURCE" "$TARGET"
codesign --force --deep --options runtime --timestamp \
  --entitlements Config/SamsungScan-Sandbox.entitlements \
  --sign "Developer ID Application: Norman Hennige (Z9U2P89679)" \
  "$TARGET"
codesign --verify --verbose=2 "$TARGET"
codesign -d --entitlements - "$TARGET" > build/sandbox-entitlements.txt
"$TARGET/Contents/MacOS/Samsung Scan" --sandbox-probe > build/sandbox-probe.txt 2> build/sandbox-probe.err || true
echo "wrote build/sandbox-probe.txt"
