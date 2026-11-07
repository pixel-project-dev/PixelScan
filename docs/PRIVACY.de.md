# Datenschutz

[English](PRIVACY.md) | [Deutsch](PRIVACY.de.md)

PixelScan arbeitet auf dem Mac. Scans, Vorschaubilder und erkannter Text werden nicht an einen Cloud-Dienst hochgeladen. Es gibt kein Konto, keine Werbung, keine Telemetrie und keine Abonnementprüfung.

## Was auf diesem Mac bleibt

| Daten | Ort |
| --- | --- |
| Scanner, Profile und Einstellungen | `~/Library/Application Support/PixelScan/library.json` |
| Offenes Dokument | `session.json` und `pages` im selben Ordner |
| Scanneradressen für `xerox_mfp` | `sane.d` im selben Ordner |
| Diagnoseprotokoll | `scan.log` im selben Ordner |

Das Protokoll kann eine von Ihnen gespeicherte Scanneradresse enthalten, weil diese Adresse zum Verstehen eines Verbindungsfehlers nötig ist. PixelScan sendet sie nicht weiter.

## Netzwerk

PixelScan öffnet eine Verbindung zu einem von Ihnen gewählten Scanner, normalerweise über TCP-Port 9400. Bonjour hört auf Geräte, die sich im lokalen Netzwerk melden. Ein Druckerdienst wird nur dann als Scannerkandidat angeboten, wenn Port 9400 antwortet. PixelScan durchsucht das Subnetz nicht.

macOS fragt nach der lokalen Netzwerkerlaubnis, weil die Bundle-ID `email.hennige.pixelscan` ist. Diese Erlaubnis wird verwendet, um den Scanner zu erreichen.

Die Texterkennung verwendet das Vision-Framework auf demselben Mac.

## Bisherige Daten von Samsung Scan

Wenn `~/Library/Application Support/Samsung Scan/` eine Bibliothek enthält, kopiert PixelScan die bekannten Dateien in den PixelScan-Ordner, sofern die Zieldateien fehlen. Die Kopie umfasst Scanner, Adressen, Ports, Backend-Zuordnungen, Profile, die letzte Auswahl, Einstellungen und die benutzereigene SANE-Konfiguration.

Der ursprüngliche Ordner bleibt liegen. PixelScan fragt nicht nach dem Löschen und löscht ihn nicht. Wenn PixelScan bereits eine Datei desselben Namens hat, bleibt diese Datei erhalten und die ältere Datei wird nicht darüber kopiert. Ein erneuter Start legt keine zweite Kopie desselben Scanners an.

## Was PixelScan nicht tut

- Es ändert keine Druckertreiber.
- Es bearbeitet die systemweite `xerox_mfp.conf` nicht.
- Es verwendet keine private Apple-Schnittstelle.
- Es ändert die Systemintegritätsschutz-Einstellung nicht.
