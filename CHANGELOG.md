# Changelog

## 1.0.0

Erste Fassung von Samsung Scan.

- Native macOS-App mit SwiftUI, Hell- und Dunkelmodus, Deutsch und Englisch.
- Scanner-Engine über `scanimage` und `xerox_mfp`, ohne Shell und ohne fest eingebaute IP-Adresse.
- Flachbett, Vorschau, Scanbereich und mehrseitiger Dokumenteneinzug.
- Seitenverwaltung, Drehung, Zuschnitt, Helligkeit, Kontrast, Ausrichtung und Erkennung leerer Seiten.
- Export als PDF, PNG, JPEG und TIFF, einschließlich mehrseitigem PDF und lokaler OCR.
- Mehrere Scanner, Profile, Bonjour-Vorschläge und geführte SANE-Einrichtung.
- Öffnen fertiger Dokumente in der Vorschau.
- Unit-Tests für Konfiguration, Optionen, Prozesse, Fehler, Export, OCR und Seiten.
- Am 6. November 2026 hat die Scanner-Engine den Samsung ProXpress über TCP 9400 gelesen und einen Flachbettausschnitt von 40 mm × 40 mm bei 75 dpi geschrieben. Der Dokumenteneinzug wurde dabei nicht gestartet.
