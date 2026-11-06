# Samsung Scan

Native macOS-App für Samsung-Netzwerkscanner über das SANE-Backend `xerox_mfp`.

Samsung Scan ist eine unabhängige Anwendung. Samsung ist eine Marke des jeweiligen Inhabers.

## Installation

1. Die DMG `dist/SamsungScan-1.1.0-unnotarized.dmg` öffnen. Sie ist nicht notarisiert. macOS kann den ersten Start blockieren, bis das Abbild notarisiert und geklammert wurde.
2. `Samsung Scan` in den Ordner Programme ziehen.
3. Die App starten.
4. Beim ersten Start fehlt in der Regel SANE. In der Einrichtung entweder den vorhandenen `scanimage`-Pfad wählen oder, wenn Homebrew schon installiert ist, **Mit Homebrew installieren** wählen.
5. Scanner hinzufügen und die IP-Adresse eintragen. Der Port ist normalerweise `9400`.
6. **Scannen** drücken.

Ohne Homebrew öffnet die Einrichtung die Homebrew-Website. Es gibt keine versteckte Administratoraktion und keine Änderung an Druckertreibern.

SANE wird nicht in die App kopiert. Die Gründe stehen in `THIRD_PARTY_NOTICES.md`.

## Scanner hinzufügen

- **Scanner hinzufügen** öffnet Name, IP-Adresse und Port.
- Der Einrichtungsassistent sucht Scanner und bietet danach die manuelle Adresse an.
- **Suchen** hört auf Bonjour. Druckdienste werden nur übernommen, wenn TCP 9400 antwortet. Scan-Dienste `_uscan._tcp` und `_uscans._tcp` werden direkt angezeigt. Das lokale Subnetz wird nicht durchsucht.
- Unter **Erweitert** lässt sich die Verbindungsart wechseln. Samsung-Netzwerk bleibt die Voreinstellung.
- **Verbindung prüfen** liest die Geräteoptionen mit `scanimage -A`.
- Scanner lassen sich umbenennen und entfernen. Der zuletzt benutzte Scanner wird gemerkt.

Die mitgelieferten Profile:

- Dokument: Flachbett, 300 dpi, Graustufen, PDF
- Foto: Flachbett, 600 dpi, Farbe, JPEG
- Mehrseitiges Dokument: ADF, 300 dpi, Graustufen, PDF
- OCR-Dokument: Flachbett, 300 dpi, Graustufen, PDF mit Texterkennung

Profile können überschrieben, neu angelegt und auf die Standardwerte zurückgesetzt werden.

## Scannen

- Quelle, Papierformat, Auflösung und Farbmodus stammen aus den gemeldeten Geräteoptionen.
- **Vorschau** scannt das Flachbett in niedriger Auflösung. Ein Rechteck wird zum Scanbereich des nächsten Scans.
- Der Dokumenteneinzug sammelt Seiten, bis der Einzug leer ist. Bei Abbruch, Papierstau oder Netzwerkfehler bleiben fertige Seiten im Dokument.
- Seiten lassen sich drehen, zuschneiden, in Helligkeit und Kontrast ändern, verschieben und löschen.
- **Leere Seiten erkennen** markiert helle Seiten und löscht sie erst nach einer Bestätigung.
- Export: PDF, mehrseitiges PDF, PNG, JPEG und mehrseitiges TIFF. PDF kann lokal erkannten deutschen und englischen Text enthalten.
- **In Vorschau öffnen** schreibt ein vorläufiges PDF und öffnet es in der Vorschau.

## Fehlerbehebung

| Meldung | Was tun |
| --- | --- |
| Scanner nicht erreichbar | Gerät eingeschaltet, gleiche Netzwerkzone, IP prüfen |
| Port nicht erreichbar | Port 9400, keine Firewall zwischen Mac und Gerät |
| Scanner beschäftigt | Laufenden Scan am Gerät abwarten |
| Dokumenteneinzug leer | Papier einlegen |
| Papierstau | Stau beheben, bereits gescannte Seiten sind noch in der App |
| SANE fehlt | Einrichtung öffnen und `scanimage` installieren oder auswählen |
| xerox_mfp nicht aktiv | In der Einrichtung die Backend-Zeile aktivieren |

Das Protokoll liegt in `~/Library/Application Support/Samsung Scan/scan.log`.

## Build

Voraussetzungen: Xcode 27, macOS 27. Für echte Scans zusätzlich `sane-backends` mit `xerox_mfp`.

```bash
xcodebuild -project SamsungScan.xcodeproj -scheme SamsungScan -destination 'platform=macOS' -configuration Debug -derivedDataPath build/DerivedData test
```

Release, Signierung und DMG:

```bash
Scripts/build-release.sh
```

Die Debug-App liegt danach unter `build/DerivedData/Build/Products/Debug/Samsung Scan.app`. Release und DMG liegen unter `dist/`.

Hardwaretest, nur wenn der Scanner erreichbar ist:

```bash
SAMSUNG_SCAN_LIVE=1 SAMSUNG_SCAN_HOST=192.168.1.20 SAMSUNG_SCAN_PORT=9400 SAMSUNG_SCAN_SCAN=1 \
  xcodebuild -project SamsungScan.xcodeproj -scheme SamsungScan -destination 'platform=macOS' -derivedDataPath build/DerivedData test -only-testing:SamsungScanTests/LiveScannerTests
```

`SAMSUNG_SCAN_SCAN=1` macht einen kleinen Flachbettausschnitt von 40 mm × 40 mm. Der Einzug wird von diesem Test nicht gestartet.

Dieselbe Prüfung ohne das App-Bundle, direkt mit der Scanner-Engine:

```bash
printf 'SAMSUNG_SCAN_LIVE=1\nSAMSUNG_SCAN_HOST=192.168.1.20\nSAMSUNG_SCAN_PORT=9400\nSAMSUNG_SCAN_SCAN=1\n' > /tmp/samsung-scan-live.env
swiftc -o /tmp/samsung-live-check \
  Scripts/live-check-main.swift \
  SamsungScan/L10n.swift SamsungScan/Models.swift SamsungScan/DeviceName.swift \
  SamsungScan/CapabilityParser.swift SamsungScan/ScanCommandBuilder.swift \
  SamsungScan/ScanErrorMapper.swift SamsungScan/ProgressParser.swift \
  SamsungScan/ProcessRunner.swift SamsungScan/SANELocator.swift \
  SamsungScan/TCPProbe.swift SamsungScan/ScanimageDriver.swift \
  -framework Network -framework ImageIO -framework CoreImage -framework UniformTypeIdentifiers
/tmp/samsung-live-check
```

Beim ersten Start der App kann macOS nach dem Zugriff auf das lokale Netzwerk fragen. Die Abfrage muss erlaubt werden, sonst erreicht auch `scanimage` aus der App das Gerät nicht.

## Manuelle Prüfung

Die automatisierten Tests benutzen keinen echten Einzug. Einmalig von Hand prüfen:

1. Eine Seite auf das Glas legen, Flachbett, 300 dpi, Farbe, einzelne Seite.
2. Vorschau erzeugen, einen Bereich ziehen und nur diesen Bereich scannen.
3. Mehrere Seiten in den ADF legen und ein mehrseitiges PDF exportieren.
4. Eine Seite drehen, zuschneiden und löschen.
5. Ein durchsuchbares PDF erzeugen und in der Vorschau nach einem Wort suchen.
6. Den Scanner ausschalten und prüfen, dass die Meldung verständlich ist und vorhandene Seiten bleiben.
