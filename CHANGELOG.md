# Changelog

## 1.3.1

Build 5. Die PixelProject-Wortmarke ist als SVG hinterlegt und in Über PixelScan, den Einstellungen und auf der Willkommensseite des Einrichtungsassistenten sichtbar. Ein Klick öffnet `https://pixel-project.de` im Standardbrowser. Die veröffentlichte Fassung 1.3.0 Build 4 bleibt unverändert. Es gibt kein neues öffentliches Release.

## 1.3.0

Build 4. Der Produktname ist PixelScan. Die Bundle-ID ist `email.hennige.pixelscan`. Beim ersten Start werden vorhandene Daten aus `~/Library/Application Support/Samsung Scan/` nach `~/Library/Application Support/PixelScan/` kopiert. Der alte Ordner bleibt erhalten, und vorhandene PixelScan-Dateien werden nicht überschrieben.

Die öffentliche Dokumentation ist zweisprachig. Ein Upload nach GitHub oder auf eine Website gehört nicht zu diesem Stand.

Offen bleiben der Intel-Hardwaretest und ein ADF-Scan aus dem PixelScan-Fenster mit eingelegtem Papier.

## 1.2.0

Build 3. Die DMG `SamsungScan-1.2.0.dmg` ist erneut notarisiert und enthält nur die App, die Verknüpfung zum Programme-Ordner und `Installation.txt`. Gatekeeper akzeptiert die enthaltene App mit `source=Notarized Developer ID`.

Offen bleiben ein Hardwaretest auf einem Intel-Mac und ein bewusster ADF-Scan mit eingelegtem Papier. Der Einzug wurde in den Release-Prüfungen nicht gestartet. Die manuellen Schritte stehen in `RELEASE.md`.

- Diagnose der Scannerinstallation: Programm, Prozessor, Samsung-Unterstützung und benutzereigene Scannerliste.
- Scanneradressen liegen unter `~/Library/Application Support/Samsung Scan/sane.d`. Die systemweite `xerox_mfp.conf` wird nicht überschrieben.
- Website-Build mit Hardened Runtime, Netzwerk-Entitlement und SHA-256 der DMG.
- Experimenteller Sandbox-Build: die App startet, findet `scanimage` außerhalb des Containers nicht und kann eine temporäre Datei schreiben. Kein App-Store-Release.
- Am 6. November 2026 hat `scanimage` mit dieser Benutzerkonfiguration die Optionen des SL-C2670FW gelesen. Ein Einzugsscan wurde nicht gestartet.

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
