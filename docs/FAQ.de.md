# Häufig gestellte Fragen

[English](FAQ.md) | [Deutsch](FAQ.de.md)

## Ist PixelScan kostenlos?

Ja. Es ist dauerhaft kostenlos. Es gibt keine Werbung, kein Abonnement, keinen In-App-Kauf, kein Konto und keine Telemetrie.

## Ist das ein Samsung-Produkt?

Nein. PixelScan ist eine unabhängige Anwendung. Samsung ist eine Marke des jeweiligen Inhabers.

## Funktioniert jeder Scanner?

Nein. Das einzige Gerät mit einem festgehaltenen praktischen Test ist der Samsung ProXpress SL-C2670FW über `xerox_mfp` und TCP 9400. Andere Namen in der SANE-Konfiguration sind von diesem Backend dokumentiert und mit PixelScan nicht bestätigt.

## Funktioniert der Dokumenteneinzug?

Das Referenzgerät meldet einen Einzug, und die Anwendung kann bei `scanimage` einen Stapel anfordern. Ein abgeschlossener Hardwaretest, der Papier einlegt und den Einzug aus dem PixelScan-Fenster startet, wurde nicht durchgeführt.

## Funktioniert es auf einem Intel-Mac?

Das Programm enthält Code für Intel und Apple Silicon. Ein physischer Intel-Mac wurde nicht getestet. Intel-Macs brauchen ein eigenes `scanimage`, üblicherweise unter `/usr/local`. Auf dem Entwicklungsmac fehlt dieses Programm.

## Wo sind meine alten Einstellungen von Samsung Scan?

Sie werden beim ersten Start nach `~/Library/Application Support/PixelScan/` kopiert, wenn dieser Ordner dieselben Dateien noch nicht enthält. Der Ordner `~/Library/Application Support/Samsung Scan/` wird nicht gelöscht.

## Lädt PixelScan meine Dokumente hoch?

Nein. Seiten, PDFs und die Texterkennung bleiben auf dem Mac.

## Warum fragt macOS erneut nach dem lokalen Netzwerk?

PixelScan hat eine neue Bundle-ID. macOS behandelt das als eine andere Anwendung als Samsung Scan.

## Gibt es PixelScan im Mac App Store?

In diesem Release nicht. Das Scannerprogramm liegt außerhalb der App. Eine sandboxierte App-Store-Fassung kann es nicht sehen.

## Wo ist der Quellcode?

Der Quellcode ist proprietär und wird im öffentlichen GitHub-Repository nicht veröffentlicht. Das öffentliche Repository beschränkt sich auf Dokumentation, Versionshinweise, Prüfsummen und, nach Freigabe, das Disk-Image.
