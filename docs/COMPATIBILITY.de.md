# Kompatibilität

[English](COMPATIBILITY.md) | [Deutsch](COMPATIBILITY.de.md)

PixelScan liefert eine lokale Kompatibilitätsdatenbank mit. Sie wird nicht heruntergeladen und ändert sich nicht von selbst, wenn ein neuer Scanner gefunden wird.

## Getestet

Samsung ProXpress SL-C2670FW, Familie C2670 Series.

- Backend `xerox_mfp`, TCP, Port 9400
- Flachbett: bestätigt mit einem Scan von 40 mm × 40 mm bei 75 dpi am 6. November 2026
- Dokumenteneinzug: das Gerät meldet ihn, und eine frühere Verwendung über die Kommandozeile wurde abgeschlossen. Ein aus dem PixelScan-Fenster gestarteter Einzugsscan ist nicht abgenommen
- Duplex: das Referenzgerät hat es nicht gemeldet, deshalb zeigt PixelScan für dieses Gerät kein Duplex
- Eine eSCL-Abfrage an den eingebauten Webserver dieses Geräts lieferte HTTP 404. Das gilt nur für dieses Gerät

Der Test wurde festgehalten, als die Anwendung noch Samsung Scan hieß. PixelScan 1.3.0 verwendet denselben Codepfad. Die Umbenennung erzeugt kein neues Hardwareergebnis.

## Von SANE dokumentiert, nicht bestätigt

sane-backends 1.4.0 nennt in `xerox_mfp.conf` weitere Samsung-Modelle und einige Xerox- und Dell-Modelle. PixelScan speichert diese Namen mit dem Status „vom Backend dokumentiert“. Ein Kommentar oder eine USB-Kennung ist kein Netzwerkscan und kein PixelScan-Test.

Zwei Samsung-Einträge beschreiben den Netzwerkmodus als auskommentierte Zeile `tcp host port` und bleiben unbestätigt:

- Samsung SCX-4500W Series
- Samsung SCX-4729FW

## Nicht als unterstützt angeboten

| Backend | Was bekannt ist |
| --- | --- |
| `escl` | Eine Gerätezeichenkette existiert. Auf dem Entwicklungsmac fehlt `libsane-escl.so`, deshalb wird das Backend nicht automatisch verwendet |
| `pixma` | Als Canon-Bibliothek vorhanden. Das ist keine Samsung-Einrichtung |
| `net` | Vorhanden, benötigt `saned`. Das ist nicht der Samsung-Port 9400 |
| `airscan` | Nicht installiert und nicht eingebunden |
| `hpaio` | Nicht Teil dieses sane-backends-Pakets und nicht eingebunden |

Ein Scanner, der nicht in der Zeile „Getestet“ steht, gilt als unbekannt, bis seine Optionen gelesen und eine Seite gespeichert wurde.
