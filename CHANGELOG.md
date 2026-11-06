# Changelog

## 1.1.0

- Modulare Geräteadressen für `xerox_mfp`, eSCL und das Canon-Protokoll `pixma`. Samsung-Geräte bleiben bei `xerox_mfp`.
- Backend-Auswahl nur nach vorhandener Bibliothek. `escl` ist in diesem Homebrew-Build in `dll.conf` genannt, `libsane-escl.so` fehlt und wird nicht automatisch geprüft.
- `sane-airscan` und `hpaio` sind nicht installiert und werden nicht eingebaut.
- Bonjour unterscheidet Druckdienste von Scan-Diensten. Ein Drucker wird nur vorgeschlagen, wenn TCP 9400 antwortet.
- Einrichtungsassistent, erweiterte Verbindungsart und Erkennung von Apple-Silicon- und Intel-`scanimage`.
- Versionierte Kompatibilitätsdatenbank. Nur der SL-C2670FW steht auf „getestet“.
- Bestehende Scanner ohne gespeichertes Backend werden als Samsung-Netzwerk weiterverwendet.
- Eine Geräteprüfung bricht nach 20 Sekunden ab.
- Am 6. November 2026 hat die Engine 1.1 den SL-C2670FW erneut gelesen und einen Flachbettausschnitt von 40 mm × 40 mm geschrieben. Der Einzug wurde nicht gestartet.

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
