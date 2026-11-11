# PixelScan

## Ziel

PixelScan 1.3.2 Build 6 ist die veröffentlichte Fassung einer eigenständigen, kostenlosen macOS-Anwendung für kompatible Netzwerkscanner. Die vorherigen Releases 1.3.1 Build 5 und 1.3.0 Build 4 bleiben als Dateien erhalten. Der frühere Name ist Samsung Scan. Der Quellcode steht unter der MIT-Lizenz und liegt öffentlich auf GitHub. Die Bundle-ID ist `email.hennige.pixelscan`. Das Referenzgerät ist der Samsung ProXpress SL-C2670FW über `xerox_mfp` und TCP 9400. Ein Intel-Hardwaretest und ein ADF-Scan aus dem Fenster mit Papier stehen noch aus. Die Wortmarke und ihre Verwendung stehen in `branding/README.md`.

Die App richtet sich an Personen ohne Terminalkenntnisse. Sie unterstützt Hell- und Dunkelmodus mit einem Umschalter in der Symbolleiste und die Sprachen Deutsch, Englisch, Französisch, Spanisch und Italienisch. Die Texterkennung bleibt auf Deutsch und Englisch.

PixelScan ist kein Produkt von Samsung Electronics. Samsung ist eine Marke des jeweiligen Inhabers.

Öffentliche Texte stehen in `README.md`, `README.de.md` und `docs/`. Interne Release-Schritte stehen in `RELEASE.md`. Der Quellcode wird mit `git push github main` veröffentlicht. `Scripts/publish-github.sh` kopiert nur freigegebene Release-Dateien.

Entwicklung:

```sh
xcodebuild -project PixelScan.xcodeproj -scheme PixelScan -destination 'platform=macOS' -configuration Debug -derivedDataPath build/DerivedData test
```

## Architektur

```text
SwiftUI
  Einrichtungsassistent, Scannerliste, Seiten, Export
  AppModel
    gespeichertes Backend, Profile, Sitzung
  DeviceAddress / DiscoveryPolicy / CompatibilityDatabase
  ScanimageDriver
    scanimage -A oder Scan, Argument-Array, Abbruch, Prüfzeit 20 s
  Bildstrecke
    Zuschnitt, Drehung, Helligkeit, Kontrast, Ausrichtung
    PDF, PNG, JPEG, TIFF, Vision-OCR
```

`scanimage` bleibt ein separates Programm. Die App übergibt keinen Text an eine Shell. Die Gerätezeichenkette wird nur aus einer geprüften Adresse und einem Port zusammengesetzt.

Die Entscheidung gegen eine direkte Verknüpfung mit `libsane` hat zwei Gründe. Der bereits erfolgreiche Weg über `scanimage` und `xerox_mfp` bleibt erhalten, und die GPL-Programme werden nicht in das App-Binary eingebunden. Damit hängt die App auch nicht an den Homebrew-Bibliothekspfaden von `libsane`.

## Technologiestack

- Swift 5, SwiftUI, AppKit
- Network.framework für die Portprüfung und Bonjour
- ImageIO, Core Image, PDFKit, Vision
- Xcode 27, Deployment-Ziel macOS 14
- sane-backends 1.4.0, Programm `scanimage`, Samsung-Pfad `xerox_mfp`

## Unterstützte Scanner

Direkt geprüft:

- Samsung ProXpress SL-C2670FW, LAN, TCP 9400, Backend `xerox_mfp`
- Quellen: Flatbed, ADF, Auto
- Auflösungen: 75, 100, 150, 200, 300, 600 dpi
- Farbmodi: Color, Gray, Lineart, Halftone
- Scanfläche etwa 215,9 mm × 297,18 mm
- Keine Duplex-Option in der Geräteabfrage

Weitere Samsung-Netzwerkscanner können gespeichert werden, wenn sie dieselbe `xerox_mfp`-Schnittstelle sprechen. Die App liest die Optionen beim Verbinden vom Gerät und bietet nur diese an.

## Funktionsumfang

- Scanner hinzufügen, umbenennen, entfernen und prüfen
- Mehrere Scanner, zuletzt verwendeter Scanner, bearbeitbare Profile
- Bonjour-Vorschläge ohne Subnetz-Scan. Druckdienste nur bei offenem TCP 9400
- Einrichtungsassistent und Kompatibilitätsdatenbank
- Flachbett, Vorschau, Scanbereich, ADF mit mehreren Seiten
- Seiten sortieren, löschen, drehen, zuschneiden, Helligkeit, Kontrast
- Automatische Ausrichtung, wenn Vision ein belastbares Rechteck findet
- Leere Seiten erkennen und auf Wunsch entfernen
- PDF einschließlich mehrseitigem PDF, PNG, JPEG, mehrseitiges TIFF
- Durchsuchbares PDF mit lokaler Vision-OCR für Deutsch und Englisch
- Öffnen in der Vorschau und Anzeigen im Finder
- Geführte SANE-Einrichtung, ohne die Druckfunktion anzufassen

## Systemintegration

Image Capture und die Vorschau können diesen Scanner nicht über eine öffentliche Schnittstelle anzeigen. Das Gerät antwortet auf `/eSCL/ScannerCapabilities` mit HTTP 404 und spricht den Scan über TCP 9400. Eine eigene ICA-Scannererweiterung wäre eine private Schnittstelle und wird nicht gebaut. Fertige Dokumente öffnet die App in der Vorschau.

## Daten

Die Bibliothek, die Sitzung und das Protokoll liegen in `~/Library/Application Support/PixelScan/`. Ein vorhandener Ordner `Samsung Scan` wird kopiert und nicht gelöscht.
