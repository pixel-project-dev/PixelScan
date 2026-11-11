# Entwicklungsregeln für PixelScan

Diese Regeln gelten für alle weiteren Änderungen an PixelScan. Der frühere Produktname ist Samsung Scan. Bestehende Daten unter `~/Library/Application Support/Samsung Scan/` werden kopiert und nicht gelöscht.

## Arbeitsweise

- Die Anwendung ist eine native macOS-App in Swift und SwiftUI. Sie muss ohne Terminalkenntnisse bedienbar sein.
- Zielsystem ist macOS 27 auf Apple Silicon. Der Code bleibt so weit wie möglich mit macOS 14 und Intel-Macs übersetzbar.
- Die Testadresse eines Scanners darf nicht als feste Adresse für alle Benutzer im Programm stehen. Scanner werden einzeln gespeichert.
- Funktionen, die das Gerät nicht meldet, werden nicht angezeigt. Duplex erscheint nur, wenn das Backend es ausweist.
- Echte Hardwaretests dürfen nur als bestanden dokumentiert werden, wenn sie in diesem Lauf tatsächlich ausgeführt wurden.

## Architektur

- Der Scan läuft über das separat installierte Programm `scanimage` aus sane-backends. Die App verlinkt `libsane` nicht.
- `scanimage` wird mit `Process` und einem Argument-Array gestartet. Es gibt keinen Aufruf über eine Shell.
- Host und Port werden vor dem Aufruf geprüft. Erlaubt sind IPv4-Adressen und DNS-Namen. Samsung-Netzwerkgeräte verwenden `xerox_mfp:tcp <host> <port>`. Weitere Gerätezeichenketten baut nur `DeviceAddress` für die dort zugelassenen Backends.
- Auflösung, Quelle, Farbmodus und Scanfläche dürfen nur Werte verwenden, die das Gerät gemeldet hat.
- Temporäre und Sitzungsdateien liegen im Anwendungsordner des Benutzers. Bereits geschriebene Seiten bleiben bei Abbruch, Papierstau und Netzwerkfehlern erhalten.
- Bildbearbeitung, PDF, TIFF und OCR laufen lokal mit AppKit, ImageIO, PDFKit und Vision.

## Sicherheit

- Keine Zugangsdaten, Schlüssel oder privaten Apple-Schnittstellen.
- Keine Änderung an SIP, keinen Sandbox-Escape und keine stillen Administratoraktionen.
- Keine Änderung an Druckertreibern und keine Veränderung der Druckfunktion.
- Scanneradressen für `xerox_mfp` schreibt die App in den eigenen Ordner des Benutzers und übergibt ihn als `SANE_CONFIG_DIR`. Die systemweite `xerox_mfp.conf` wird nicht automatisch verändert.
- Die gemeinsame `dll.conf` wird nur geändert, wenn der Benutzer ein Backend ausdrücklich aktiviert. Erlaubt sind nur `xerox_mfp`, `escl`, `pixma` und `net`. Dabei wird nur diese eine Zeile ergänzt oder auskommentiert.
- Eine Homebrew-Installation startet nur nach einem Klick auf „Mit Homebrew installieren“.
- Die Netzwerksuche verwendet Bonjour. `_ipp._tcp` gilt nur dann als Vorschlag, wenn TCP 9400 antwortet. `_uscan._tcp` und `_uscans._tcp` sind Scan-Dienste und werden ohne zusätzlichen Port-Sweep übernommen. Es gibt keinen Subnetz-Sweep.

## Tests

- Vor einem Commit laufen die Unit-Tests für Geräteadressen, Backends, Kompatibilität, Optionen, Prozesssteuerung, Fehlertexte, Seitenverwaltung, Export und OCR.
- Hardwaretests sind mit `PIXELSCAN_LIVE=1` und `PIXELSCAN_HOST` geschützt. Ein kleiner Flachbettscan zusätzlich nur mit `PIXELSCAN_SCAN=1`. Die älteren Namen `SAMSUNG_SCAN_LIVE`, `SAMSUNG_SCAN_HOST` und `SAMSUNG_SCAN_SCAN` werden noch gelesen.
- Mock- und Parser-Tests dürfen keine Scanner-Hardware voraussetzen.

## Git

- Branch ist `main`. Keine Force-Pushes und keine destruktiven Git-Befehle, außer einer ausdrücklich freigegebenen einmaligen Migration.
- Das öffentliche GitHub-Repository `pixel-project-dev/PixelScan` enthält den Quellcode. Ein privates Gitea-Remote kann parallel bleiben.
- Keine Build-Artefakte, DMGs oder Ableitungsdaten ins Repository legen.
- Wenn die Build-Nummer steigt, wird vorher ein Rollback-Tag `rollback/v<version>-build<n>` auf den letzten bekannten Stand gesetzt.
- Commits beschreiben den Zweck der Änderung.

## Lizenzen

- Der eigene Quellcode steht unter der MIT-Lizenz (`LICENSE`).
- sane-backends steht unter der GPL. Frontends sind GPL, die meisten Backends haben eine Verknüpfungsausnahme. PixelScan bündelt diese Programme nicht und startet `scanimage` als eigenes Programm.
- Die genauen Hinweise stehen in `LICENSES.md` und `THIRD_PARTY_NOTICES.md`.
