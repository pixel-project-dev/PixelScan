# Release 1.1.0

## Build

- Marketing-Version 1.1.0, Build 2
- Deployment-Ziel macOS 14
- Release-Architekturen `arm64` und `x86_64`
- Hardened Runtime im Release
- Keine App-Sandbox, weil `scanimage` außerhalb des Bundles liegt
- Signatur, wenn vorhanden: `Developer ID Application: Norman Hennige (Z9U2P89679)`

```bash
bash Scripts/build-release.sh
```

Das Skript legt ab:

- `dist/Samsung Scan.app`
- `dist/SamsungScan-1.1.0-unnotarized.dmg`

Die DMG enthält die Datei `Not notarized.txt`. Der Dateiname kennzeichnet dasselbe. `spctl` lehnt ein nicht notarisiertes Developer-ID-Programm ab.

## Notarisierung

Auf diesem Mac ist kein `notarytool`-Profil hinterlegt. Der verbleibende Schritt, sobald ein Zugang existiert:

```bash
xcrun notarytool submit "dist/SamsungScan-1.1.0-unnotarized.dmg" --keychain-profile "<profil>" --wait
xcrun stapler staple "dist/Samsung Scan.app"
```

Zugangsdaten gehören nicht ins Repository.

## Intel

Die App ist ein Universal-Binary. `scanimage` von Homebrew auf dem Entwicklungsmac ist nur arm64. Ein Intel-Mac braucht sane-backends unter `/usr/local` oder einen selbst gewählten Pfad. Ein Lauf auf Intel-Hardware hat nicht stattgefunden. Die App meldet, wenn die Architektur des gefundenen `scanimage` nicht zur laufenden App passt.

## Installation für Benutzer

1. DMG öffnen.
2. Samsung Scan nach Programme ziehen.
3. App starten. Falls Gatekeeper blockiert, liegt das an der fehlenden Notarisierung.
4. Dem lokalen Netzwerk zustimmen, wenn macOS fragt.
5. Im Assistenten einen Scanner wählen oder die Adresse eintragen.
6. Fehlt die Scannersoftware, in der Einrichtung **Mit Homebrew installieren** wählen oder die Homebrew-Website öffnen.
