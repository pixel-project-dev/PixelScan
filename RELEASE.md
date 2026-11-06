# Release 1.2.0

Build 3 ist das notariserte Website-Release. Es wird nicht hochgeladen, solange der Projektinhaber das nicht freigibt.

## Artefakt

- Datei: `dist/SamsungScan-1.2.0.dmg`
- SHA-256: `7a74e9f712a00b270353fc0106b7d8157dfde906cc66acdda592ccae7ddcb1b8`
- Dieselbe Summe steht in `dist/SamsungScan-1.2.0.dmg.sha256`
- Inhalt: `Samsung Scan.app`, Alias auf den Programme-Ordner und eine ältere Textdatei `Not notarized.txt`
- Die Textdatei stammt aus dem Release Candidate. Sie wurde nicht entfernt, weil jede Änderung der DMG das Notarisierungsticket ungültig machen würde.

Geprüft am 7. November 2026:

- `hdiutil verify` meldet die DMG als gültig.
- `xcrun stapler validate` bestätigt das Ticket der umbenannten DMG.
- `codesign --verify --deep --strict` bestätigt die App im DMG.
- `spctl --assess --type execute` akzeptiert die App mit `source=Notarized Developer ID`.
- Eine Kopie aus dem DMG startete und ließ sich wieder beenden. Sie wurde nicht in den Programme-Ordner des Macs gelegt.

Die App im DMG trägt kein eigenes angeheftetes Ticket. Gatekeeper akzeptiert sie trotzdem als notarisierte Developer-ID-App. Das Ticket hängt an der DMG.

## Signatur

- `Developer ID Application: Norman Hennige (Z9U2P89679)`
- Hardened Runtime
- Universal Binary `arm64` und `x86_64`
- Entitlements ohne App-Sandbox: `Config/SamsungScan.entitlements`
- Zeitstempel der Signatur: 6. November 2026, 20:38 Uhr

Ein neuer Build mit `Scripts/build-release.sh` erzeugt eine andere, zunächst nicht notarisierte DMG. Die Datei `dist/SamsungScan-1.2.0.dmg` darf dabei nicht überschrieben werden.

## Offene Hardwaretests

- Intel: nicht ausgeführt. `scanimage` von Homebrew auf dem Entwicklungsmac ist nur arm64.
- ADF: nicht ausgeführt. Die Prüfungen haben kein Papier aus dem Einzug gezogen. Flachbett und die gemeldeten ADF-Optionen des SL-C2670FW wurden früher geprüft.

## Website

Die DMG liegt bereit für einen kostenlosen Download. Ein Upload auf die Website hat nicht stattgefunden.
