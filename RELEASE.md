# Release 1.2.0

Build 3 ist das notarisierte Website-Release. Es wird nicht hochgeladen, solange der Projektinhaber das nicht freigibt.

Der Git-Tag `v1.2.0` bleibt auf dem signierten Anwendungsstand. Dieses Dokument beschreibt das danach erzeugte, saubere DMG. Der Tag wird dafür nicht verschoben.

## Artefakt

- Datei: `dist/SamsungScan-1.2.0.dmg`
- SHA-256: `86adc0bb83744b08e1fae382ef864ba8101b6d0d783d1556b3080db79253a7d1`
- Dieselbe Summe steht in `dist/SamsungScan-1.2.0.dmg.sha256`
- Inhalt: `Samsung Scan.app`, Verknüpfung auf den Programme-Ordner und `Installation.txt`
- Die Datei `Not notarized.txt` ist nicht enthalten

Geprüft am 7. November 2026 nach dem neuen Paket:

- `codesign --verify --deep --strict` bestätigt die App vor dem Packen, im DMG und nach der Kopie in den Programme-Ordner.
- Die DMG ist mit `Developer ID Application: Norman Hennige (Z9U2P89679)` signiert. Zeitstempel der DMG-Signatur: 7. November 2026, 21:24 Uhr.
- Einreichung `57f3ba4d-bd71-426d-8b83-c4ccadb99417`, Status `Accepted`.
- `xcrun stapler validate` bestätigt das Ticket nach dem Anheften und erneut nach dem Umbenennen.
- `hdiutil verify` meldet die DMG als gültig.
- `spctl --assess --type install` akzeptiert die DMG mit `source=Notarized Developer ID`.
- `spctl --assess --type execute` akzeptiert die App im DMG und in `/Applications` mit `source=Notarized Developer ID`.
- `spctl --assess --type open` meldet auf diesem Mac `rejected` und `source=Insufficient Context`. Dieselbe Meldung kommt auch bei der vorherigen notarisierten DMG. Sie ist keine erfolgreiche Gatekeeper-Prüfung.

Die App im DMG trägt kein eigenes angeheftetes Ticket. Das Ticket hängt an der DMG. Nach dem Anheften wurde der Inhalt nicht mehr verändert.

Ein neuer Build mit `Scripts/build-release.sh` schreibt `dist/SamsungScan-1.2.0-unnotarized.dmg` und überschreibt die notarisierte Datei nicht.

## Signatur der App

- `Developer ID Application: Norman Hennige (Z9U2P89679)`
- Hardened Runtime
- Universal Binary `arm64` und `x86_64`
- Entitlements ohne App-Sandbox: `Config/SamsungScan.entitlements`
- Zeitstempel der App-Signatur: 6. November 2026, 20:38 Uhr
- Version 1.2.0, Build 3

## Installationstest

In `/Applications` lag keine Samsung-Scan-Installation. Die App aus dem neuen DMG wurde dorthin kopiert, gestartet und mit dem Beenden-Befehl von macOS geschlossen. Der Prozess war danach nicht mehr vorhanden.

Die installierte App ist nicht sandboxiert. `--sandbox-probe` fand `/opt/homebrew/bin/scanimage`, startete es mit der Versionsabfrage und meldete `scanimage (sane-backends) 1.4.0`. Es wurde kein Scan gestartet.

Die vorhandene Bibliothek behielt einen Scanner und vier Profile. Beim Start wurden die zuvor fehlenden Felder `backendID` (`xerox_mfp`) und `secureConnection` (`false`) gespeichert. Die systemweite `xerox_mfp.conf` wurde nicht verändert.

## Manueller ADF-Test

Dieser Test wurde nicht ausgeführt. Es wurde kein Papier eingezogen.

Automatisch geprüft, ohne Einzug, sind die Argumente für einen mehrseitigen ADF-Scan und die Meldungen für leeren Einzug und Papierstau.

Manuell, nur mit eingelegtem Papier und ausdrücklicher Freigabe:

1. Drei Blätter in den Dokumenteneinzug legen.
2. Samsung Scan starten.
3. Als Quelle **Dokumenteneinzug** wählen.
4. Farbmodus und Auflösung einstellen.
5. **Scannen** starten.
6. Prüfen, dass drei Seiten im Dokument liegen.
7. Über **Exportieren…** ein mehrseitiges PDF sichern.
8. Das PDF in der Vorschau öffnen und die drei Seiten kontrollieren.

## Intel

Die App enthält `x86_64` und `arm64`. Auf diesem Mac ist `/opt/homebrew/bin/scanimage` nur `arm64`. `/usr/local/bin/scanimage` und `/usr/local/etc/sane.d` fehlen. Die Warnung bei einem Architekturunterschied ist durch einen Unit-Test abgedeckt. Ein Hardwaretest auf einem Intel-Mac ist offen.

## Website

Die DMG liegt bereit für einen kostenlosen Download. Ein Upload auf die Website, ein öffentlicher Gitea-Release und eine Einreichung im Mac App Store haben nicht stattgefunden. Die Anwendung bleibt kostenlos und proprietär.
