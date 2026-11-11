# Release 1.3.2

PixelScan 1.3.2 Build 6 ist das notarisierte Release mit fünf Oberflächensprachen und dem Umschalter für hell und dunkel. Die veröffentlichten Images `dist/PixelScan-1.3.1.dmg` und `dist/PixelScan-1.3.0.dmg` bleiben unverändert. Der Tag `v1.3.1` bleibt auf `87998f4e87a95ba28f770af91789477cc351223f`. Der Rollback-Tag `rollback/v1.3.1-build5` steht auf `1c2236a368c69dfeb5f5d10b6f844ce29ad2ba38`, dem letzten Stand vor der Erhöhung der Build-Nummer.

## Artefakt

- Datei: `dist/PixelScan-1.3.2.dmg`
- SHA-256: `81ba933d7b8c1351563b31eb0ab24658d4686709069574142bf499af6cdc6e20`
- Die veröffentlichte Prüfsummendatei nennt den Dateinamen `PixelScan-1.3.2.dmg`, ohne Ordner `dist/`
- Inhalt: `PixelScan.app`, Verknüpfung auf den Programme-Ordner und `Installation.txt`
- Version 1.3.2, Build 6
- Universal Binary `arm64` und `x86_64`
- Einreichung `449ddee7-73a1-4317-a77d-da8075bfbbb9`, Status `Accepted`
- `xcrun stapler validate` hat das Ticket bestätigt
- `hdiutil verify` hat die DMG als gültig gemeldet
- `spctl --assess --type install` hat die DMG mit `source=Notarized Developer ID` akzeptiert

Geprüft am 8. November 2026. Ein neuer Hardwaretest wurde nicht ausgeführt. Die App aus diesem Image wurde nicht nach `/Applications` kopiert.

# Release 1.3.1

PixelScan 1.3.1 Build 5 ist das notarisierte Release mit der PixelProject-Wortmarke. Das veröffentlichte Image `dist/PixelScan-1.3.0.dmg` bleibt unverändert. Der Tag `v1.3.0` und der Rollback-Tag `rollback/v1.3.0-build4` bleiben auf `db091f1e0e09a24706955e9cff05495455397fff`.

## Artefakt

- Datei: `dist/PixelScan-1.3.1.dmg`
- SHA-256: `39a852e6054d42299ac195a0571121d219e9f14cf4cbd7dcfcec78b2e33d56e7`
- Die veröffentlichte Prüfsummendatei nennt den Dateinamen `PixelScan-1.3.1.dmg`, ohne Ordner `dist/`
- Inhalt: `PixelScan.app`, Verknüpfung auf den Programme-Ordner und `Installation.txt`
- Version 1.3.1, Build 5
- Universal Binary `arm64` und `x86_64`
- Einreichung `e1556839-4b33-4b5f-a09e-10ce2503145b`, Status `Accepted`
- `xcrun stapler validate` hat das Ticket bestätigt
- `hdiutil verify` hat die DMG als gültig gemeldet
- `spctl --assess --type install` hat die DMG mit `source=Notarized Developer ID` akzeptiert

Geprüft am 8. November 2026. Ein neuer Hardwaretest wurde nicht ausgeführt. Die App aus diesem Image wurde nicht nach `/Applications` kopiert.

# Release 1.3.0

PixelScan 1.3.0 Build 4 ist das notarisierte Release. Es wird nicht öffentlich hochgeladen, solange der Projektinhaber das nicht freigibt.

Der Tag `v1.2.0` bleibt auf dem letzten Samsung-Scan-Stand. Der Rollback-Tag `rollback/v1.2.0-build3` zeigt auf denselben Stand, bevor die Build-Nummer auf 4 erhöht wurde.

## Artefakt

- Datei: `dist/PixelScan-1.3.0.dmg`
- SHA-256: `2addce0acdbebe3083684cd9009d1787e1adb37460b62c6829ef4b62afbab001`
- Dieselbe Summe steht in `dist/PixelScan-1.3.0.dmg.sha256`
- Inhalt: `PixelScan.app`, Verknüpfung auf den Programme-Ordner und `Installation.txt`
- Anzeigename: PixelScan
- Bundle-ID: `email.hennige.pixelscan`
- Version 1.3.0, Build 4
- Universal Binary `arm64` und `x86_64`

Geprüft am 7. November 2026:

- `codesign --verify --deep --strict` bestätigt die App vor dem Packen, im DMG und nach der Kopie nach `/Applications`.
- Die App und die DMG sind mit `Developer ID Application: Norman Hennige (Z9U2P89679)` signiert.
- Einreichung `3ec3433b-a732-4d38-8ab1-8a0c13c19c37`, Status `Accepted`.
- `xcrun stapler validate` bestätigt das Ticket.
- `hdiutil verify` meldet die DMG als gültig.
- `spctl --assess --type install` akzeptiert die DMG mit `source=Notarized Developer ID`.
- `spctl --assess --type execute` akzeptiert die App im DMG und in `/Applications` mit `source=Notarized Developer ID`.
- `spctl --assess --type open` meldet `rejected` und `source=Insufficient Context`. Das ist keine bestandene Gatekeeper-Prüfung. Dieselbe Art der Prüfung lieferte auf diesem Mac auch bei der notarisierten 1.2.0-DMG dieses Ergebnis.

Das Ticket hängt an der DMG. Nach dem Anheften wurde der Inhalt nicht mehr verändert.

`Scripts/build-release.sh` schreibt nur `dist/PixelScan-1.3.0-unnotarized.dmg` und ersetzt die notarisierte Datei nicht. `Scripts/notarize-dmg.sh` reicht ein und heftet an, lädt aber nichts zu GitHub hoch. `Scripts/publish-github.sh` bricht ohne ausdrückliche Freigabe ab.

## Installationstest

In `/Applications` lag keine PixelScan-Installation. Die vorhandene App `Samsung Scan` wurde nicht ersetzt. PixelScan wurde aus dem DMG kopiert, gestartet und mit dem Beenden-Befehl von macOS geschlossen.

`--sandbox-probe` fand `scanimage` und startete die Versionsabfrage: `scanimage (sane-backends) 1.4.0`. Es wurde kein Scan ausgeführt. Die App ist nicht sandboxiert.

Die Bibliothek unter `~/Library/Application Support/Samsung Scan/` blieb unverändert. PixelScan übernahm einen Scanner und vier Profile nach `~/Library/Application Support/PixelScan/`. Das Backend in der Kopie ist `xerox_mfp`, der Port ist 9400. Die systemweite `xerox_mfp.conf` trägt weiterhin das Änderungsdatum 6. November 2026.

## Tests

41 Tests, davon ein übersprungener Hardwaretest, keine Fehler. Enthalten sind Engine, Backend, Bild und PDF, Release-Konfiguration, Bundle-ID, Anwendungspfad und die Migration.

## Offen

- Intel-Hardwaretest. `/opt/homebrew/bin/scanimage` ist nur `arm64`. `/usr/local/bin/scanimage` fehlt.
- ADF-Scan aus dem PixelScan-Fenster mit eingelegtem Papier. Die automatischen Stapelprüfungen ziehen kein Papier ein.

## Veröffentlichung

Ältere Notiz vor der Open-Source-Freigabe: Die Anwendung war kostenlos und proprietär. Der Quellcode steht inzwischen unter der MIT-Lizenz und liegt auf GitHub.
