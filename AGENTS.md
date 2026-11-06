# Entwicklungsregeln für Samsung Scan

Diese Regeln gelten für alle weiteren Änderungen an Samsung Scan.

## Arbeitsweise

- Die Anwendung ist eine native macOS-App in Swift und SwiftUI. Sie muss ohne Terminalkenntnisse bedienbar sein.
- Zielsystem ist macOS 27 auf Apple Silicon. Der Code bleibt so weit wie möglich mit macOS 14 und Intel-Macs übersetzbar.
- Die Testadresse eines Scanners darf nicht als feste Adresse für alle Benutzer im Programm stehen. Scanner werden einzeln gespeichert.
- Funktionen, die das Gerät nicht meldet, werden nicht angezeigt. Duplex erscheint nur, wenn das Backend es ausweist.
- Echte Hardwaretests dürfen nur als bestanden dokumentiert werden, wenn sie in diesem Lauf tatsächlich ausgeführt wurden.

## Architektur

- Der Scan läuft über das separat installierte Programm `scanimage` aus sane-backends. Die App verlinkt `libsane` nicht.
- `scanimage` wird mit `Process` und einem Argument-Array gestartet. Es gibt keinen Aufruf über eine Shell.
- Host und Port werden vor dem Aufruf geprüft. Erlaubt sind IPv4-Adressen und DNS-Namen. Der Gerätename hat immer die Form `xerox_mfp:tcp <host> <port>`.
- Auflösung, Quelle, Farbmodus und Scanfläche dürfen nur Werte verwenden, die das Gerät gemeldet hat.
- Temporäre und Sitzungsdateien liegen im Anwendungsordner des Benutzers. Bereits geschriebene Seiten bleiben bei Abbruch, Papierstau und Netzwerkfehlern erhalten.
- Bildbearbeitung, PDF, TIFF und OCR laufen lokal mit AppKit, ImageIO, PDFKit und Vision.

## Sicherheit

- Keine Zugangsdaten, Schlüssel oder privaten Apple-Schnittstellen.
- Keine Änderung an SIP, keinen Sandbox-Escape und keine stillen Administratoraktionen.
- Keine Änderung an Druckertreibern und keine Veränderung der Druckfunktion.
- Die SANE-Konfiguration wird nur geändert, wenn der Benutzer `xerox_mfp` in der App ausdrücklich aktiviert. Dabei wird nur diese eine Zeile in `dll.conf` ergänzt oder auskommentiert.
- Eine Homebrew-Installation startet nur nach einem Klick auf „Mit Homebrew installieren“.
- Die Netzwerksuche verwendet Bonjour und prüft danach höchstens Port 9400 der gefundenen Hosts. Es gibt keinen Subnetz-Sweep.

## Tests

- Vor einem Commit laufen die Unit-Tests für Geräteadressen, Optionen, Prozesssteuerung, Fehlertexte, Seitenverwaltung, Export und OCR.
- Hardwaretests sind mit `SAMSUNG_SCAN_LIVE=1` und `SAMSUNG_SCAN_HOST` geschützt. Ein kleiner Flachbettscan zusätzlich nur mit `SAMSUNG_SCAN_SCAN=1`.
- Mock- und Parser-Tests dürfen keine Scanner-Hardware voraussetzen.

## Git

- Branch ist `main`. Keine Force-Pushes und keine destruktiven Git-Befehle.
- Keine Build-Artefakte, DMGs oder Ableitungsdaten ins Repository legen.
- Wenn die Build-Nummer steigt, wird vorher ein Rollback-Tag `rollback/v<version>-build<n>` auf den letzten bekannten Stand gesetzt.
- Commits beschreiben den Zweck der Änderung.

## Lizenzen

- sane-backends steht unter der GPL. Frontends sind GPL, die meisten Backends haben eine Verknüpfungsausnahme. Samsung Scan bündelt diese Programme nicht und startet `scanimage` als eigenes Programm.
- Die genauen Hinweise stehen in `THIRD_PARTY_NOTICES.md`.
