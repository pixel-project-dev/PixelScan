#!/bin/bash
# Refuses to publish unless a person explicitly sets PIXELSCAN_PUBLIC_RELEASE=1.
# Even then it copies only an allowlist into a separate directory. It does not
# add GitHub as a remote of this private repository and it does not push source.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${PIXELSCAN_PUBLIC_RELEASE:-}" != "1" ]]; then
  echo "Öffentliche Veröffentlichung ist nicht freigegeben. Es wird nichts übertragen." >&2
  exit 1
fi

DEST="${1:-}"
if [[ -z "$DEST" || "$DEST" == *samsung_scan* ]]; then
  echo "Ziel muss ein getrenntes Verzeichnis außerhalb dieses Repositorys sein." >&2
  exit 1
fi

mkdir -p "$DEST/docs"
cp README.md README.de.md "$DEST/"
cp docs/pixelscan-icon.png "$DEST/docs/"
cp branding/pixelproject-logo-light.svg branding/pixelproject-logo-dark.svg "$DEST/docs/"
cp docs/INSTALLATION.md docs/INSTALLATION.de.md "$DEST/docs/"
cp docs/COMPATIBILITY.md docs/COMPATIBILITY.de.md "$DEST/docs/"
cp docs/FAQ.md docs/FAQ.de.md "$DEST/docs/"
cp docs/PRIVACY.md docs/PRIVACY.de.md "$DEST/docs/"
cp docs/TROUBLESHOOTING.md docs/TROUBLESHOOTING.de.md "$DEST/docs/"
cp THIRD_PARTY_NOTICES.md "$DEST/THIRD_PARTY_NOTICES.md"
if [[ "${PIXELSCAN_PUBLIC_DMG:-}" == "1" && -f dist/PixelScan-1.3.1.dmg && -f dist/PixelScan-1.3.1.dmg.sha256 ]]; then
  mkdir -p "$DEST/releases"
  cp dist/PixelScan-1.3.1.dmg dist/PixelScan-1.3.1.dmg.sha256 "$DEST/releases/"
  cp branding/pixelproject-logo-light.svg branding/pixelproject-logo-dark.svg "$DEST/releases/"
else
  echo "Die DMG wird nicht kopiert."
fi
echo "Nur freigegebene Dateien nach $DEST kopiert. Es wurde nichts gepusht."
