# Architektur

Samsung Scan 1.1 spricht Scanner über ein getrennt installiertes `scanimage` an. Die SwiftUI-Oberfläche kennt keine Backend-Befehle. Sie speichert eine Verbindungsart, eine Adresse und einen Port. `DeviceAddress` baut daraus die Gerätezeichenkette.

## Verbindungsarten

| Kennung | Gerätezeichenkette | Wann |
| --- | --- | --- |
| `xerox_mfp` | `xerox_mfp:tcp <host> <port>` | Voreinstellung für Samsung-Netzwerk, Port 9400. Auf dem SL-C2670FW geprüft. |
| `escl` | `escl:http://<host>:<port>` oder `https` | Nur wenn der Benutzer Web-Scan wählt. Das Format folgt `escl_parse_name` im SANE-Backend: nach dem Präfix `escl:` erwartet `sane_open` eine URL mit Port. |
| `pixma` | `pixma:bjnp://<host>:<port>` | Canon BJNP, Standardport 8612 laut `sane-pixma`. Nicht für Samsung. Nur sichtbar, wenn `libsane-pixma.so` vorhanden ist. |

`net` hat keine eigene Gerätezeichenkette. Das Handbuch erwartet `net:<host>:<gerät>` und damit einen `saned`-Namen, keinen Samsung-Port. `sane-airscan` ist ein separates Projekt und auf diesem Mac nicht installiert. `hpaio` gehört zu HPLIP, ist nicht installiert und ist ein HP-Backend.

Eine Prüfung verwendet `scanimage -A`. Das löst keinen Scan aus. Die Prüfung endet nach 20 Sekunden. Ein Scan startet nur über die Tasten Scannen oder Vorschau.

## Erkennung

1. Bonjour: `_uscan._tcp`, `_uscans._tcp`, `_scanner._tcp`, `_ipp._tcp`.
2. `_ipp._tcp` wird verworfen, solange TCP 9400 nicht antwortet. Ein Druckdienst allein ist kein Scanner.
3. Scan-Ankündigungen werden mit dem Port des Dienstes gespeichert. Es gibt keinen Subnetz-Sweep.
4. Die manuelle Adresse bleibt immer erreichbar.

Installierte Backends kommen aus `lib/sane/libsane-<name>.so` neben dem gefundenen `scanimage`. Aktivierte Namen kommen aus `dll.conf`. Ein Name in `dll.conf` ohne Bibliothek, hier `escl`, gilt als nicht installiert.

## Pfade

Gesucht wird in dieser Reihenfolge: vom Benutzer gewählter Pfad, `/opt/homebrew/bin/scanimage`, `/usr/local/bin/scanimage`, danach `PATH`. Das Präfix ist das übergeordnete Verzeichnis von `bin`, nicht fest `/opt/homebrew`. Die CPU-Architektur des Programms wird aus dem Mach-O-Kopf gelesen. Passt sie nicht zur laufenden App, erscheint ein Hinweis. Ein Intel-`scanimage` wurde auf diesem Mac nicht ausgeführt, weil die Homebrew-Datei nur arm64 ist.

## Migration

Scanner aus Version 1.0 haben kein Feld `backendID`. Der Decoder setzt dann `xerox_mfp`. Eine vorhandene Bibliothek wird nicht geleert.

## Systemintegration

`ImageCaptureCore` kann Scanner benutzen. Es gibt keine öffentliche API, die einen SANE-Scanner an TCP 9400 in Digitale Bilder oder die Vorschau einträgt. Die App öffnet fertige PDFs in der Vorschau und zeigt Dateien im Finder.
