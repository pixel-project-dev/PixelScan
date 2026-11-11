#!/bin/bash
# The application source is published with git to the github remote.
# This script only copies release assets into a separate directory when asked.
# It does not rewrite git history and it does not push.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${PIXELSCAN_PUBLIC_RELEASE:-}" != "1" ]]; then
  echo "Öffentliche Veröffentlichung ist nicht freigegeben. Es wird nichts übertragen." >&2
  echo "Quellcode: git push github main" >&2
  exit 1
fi

DEST="${1:-}"
if [[ -z "$DEST" || "$DEST" == *samsung_scan* ]]; then
  echo "Ziel muss ein getrenntes Verzeichnis außerhalb dieses Repositorys sein." >&2
  exit 1
fi

mkdir -p "$DEST/releases"
if [[ "${PIXELSCAN_PUBLIC_DMG:-}" == "1" && -f dist/PixelScan-1.3.2.dmg && -f dist/PixelScan-1.3.2.dmg.sha256 ]]; then
  cp dist/PixelScan-1.3.2.dmg dist/PixelScan-1.3.2.dmg.sha256 "$DEST/releases/"
  cp branding/pixelproject-logo-light.svg branding/pixelproject-logo-dark.svg "$DEST/releases/"
  echo "Release-Dateien nach $DEST/releases kopiert. Es wurde nichts gepusht."
else
  echo "Die DMG wird nicht kopiert. Quellcode gehört in den git-Push nach GitHub."
fi
