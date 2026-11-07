# Roadmap

## Meilensteine

| Meilenstein | Status |
| --- | --- |
| Xcode-Projekt, SwiftUI-Oberfläche, Deutsch und Englisch | umgesetzt |
| Sichere scanimage-Engine ohne Shell | umgesetzt |
| Flachbett, ADF, Vorschau, Scanbereich | umgesetzt |
| Seitenverwaltung und Bildanpassung | umgesetzt |
| PDF, PNG, JPEG, TIFF, lokale OCR | umgesetzt |
| Scannerprofile und mehrere Geräte | umgesetzt |
| Bonjour-Vorschläge ohne Subnetz-Sweep | umgesetzt |
| Unit-Tests ohne Hardware | umgesetzt |
| Hardwaretest über die Engine | am 6. November 2026 für 1.0 und erneut für 1.1 bestanden: Optionen gelesen, Flachbett 40 mm × 40 mm bei 75 dpi |
| Mehrere Backends und Kompatibilitätsdatenbank | umgesetzt in 1.1.0 |
| Einrichtungsassistent | umgesetzt |
| Intel-Hardwaretest von scanimage | offen, auf diesem Mac ist scanimage nur arm64 |
| DMG und lokale Signierung | umgesetzt, sofern Zertifikat und `hdiutil` verfügbar sind |
| Notarisierung | abgeschlossen für das saubere `SamsungScan-1.2.0.dmg`. Gatekeeper akzeptiert die App |
| Mac App Store | geprüft und mit der externen Engine nicht funktionsfähig. Siehe `APP_STORE_FEASIBILITY.md` |
| Anzeige in Digitale Bilder / Vorschau als Scanner | nicht vorgesehen, keine öffentliche API |

## Offene Aufgaben

- Intel-Hardwaretest von `scanimage`, sobald ein Intel-Mac verfügbar ist.
- Bewusster ADF-Test mit eingelegtem Papier. Bisher wurde der Einzug dafür nicht gestartet.
- Weitere Samsung-Modelle nur aufnehmen, nachdem ihre `xerox_mfp`-Optionen gelesen wurden.
- IPv6 ist nicht freigeschaltet, weil die Gerätezeichenkette Host und Port mit einem Leerzeichen trennt und das Backend dafür nicht geprüft ist.
- Automatische Ausrichtung bleibt konservativ. Winkel unter 0,4° und über 12° werden nicht angewendet.
- Mehrfacheinzug wird nur gemeldet, wenn der Backend-Text ihn nennt. `xerox_mfp` 1.4.0 liefert dafür keinen eigenen Statustext. Papierstau, leerer ADF und „Device busy“ sind abgedeckt.

## Technische Einschränkungen

- SANE wird nicht mitgeliefert. Die App sucht `scanimage` unter `/opt/homebrew`, `/usr/local` und im `PATH`.
- Ein Universal-Binary der App ist möglich. Das Homebrew-`scanimage` auf dem Entwicklungsmac ist arm64. Intel-Macs brauchen eine eigene sane-backends-Installation.
- Die App ist nicht sandboxiert, weil sie ein Programm außerhalb des Bundles starten muss.
- Die App ändert keine Druckertreiber.
