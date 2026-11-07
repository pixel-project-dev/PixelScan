# Installation

[English](INSTALLATION.md) | [Deutsch](INSTALLATION.de.md)

## Voraussetzungen

- macOS 14 oder neuer
- Ein Mac mit Apple Silicon oder Intel-Prozessor
- Ein Scanner, der ein Backend spricht, das PixelScan tatsächlich verwenden kann
- Das getrennte SANE-Programm `scanimage`

Die Anwendung ist ein Universal Binary. Das Scannerprogramm ist nicht enthalten und muss zum Prozessor des Macs passen. Auf dem Entwicklungsmac ist nur ein Apple-Silicon-Build von `scanimage` installiert. Ein Intel-Mac wurde für keinen Hardwaretest verwendet.

## PixelScan installieren

1. Holen Sie `PixelScan-1.3.0.dmg` von der betreuenden Person oder, nach der Veröffentlichung, aus dem GitHub-Release.
2. Vergleichen Sie die SHA-256-Prüfsumme mit der veröffentlichten `.sha256`-Datei.
3. Öffnen Sie das Disk-Image.
4. Ziehen Sie PixelScan in den Ordner Programme.
5. Werfen Sie das Disk-Image aus und öffnen Sie PixelScan aus dem Ordner Programme.
6. Erlauben Sie den Zugriff auf das lokale Netzwerk, wenn macOS danach fragt. Die Bundle-ID ist `email.hennige.pixelscan`. Eine frühere Erlaubnis für Samsung Scan gilt deshalb nicht weiter.

Eine vorhandene Anwendung Samsung Scan wird nicht gelöscht und nicht ersetzt.

## Scannerprogramm installieren

PixelScan sucht `scanimage` zuerst unter einem selbst gewählten Pfad, dann unter `/opt/homebrew/bin/scanimage`, `/usr/local/bin/scanimage` und im `PATH`.

Wenn Homebrew bereits installiert ist, verwenden Sie in PixelScan **Mit Homebrew installieren**. Nur dieser Klick startet die Installation. Fehlt Homebrew, verwenden Sie **Homebrew-Website öffnen**, installieren Sie Homebrew selbst und kehren Sie danach zurück.

```sh
brew install sane-backends
```

PixelScan ändert keine Druckertreiber und bearbeitet die systemweite SANE-Konfiguration nicht.

## Vorhandene Einstellungen übernehmen

Beim ersten Start kopiert PixelScan diese Objekte aus `~/Library/Application Support/Samsung Scan/`, wenn das Ziel sie noch nicht hat:

- `library.json` (Scanner, Profile, letzte Auswahl, Einstellungen)
- `session.json`, `pages` und `inbox`
- `scan.log`
- `sane.d`

Die Kopie liegt unter `~/Library/Application Support/PixelScan/`. Der ursprüngliche Ordner bleibt. Eine erneute Migration überschreibt keine Datei, die bereits vorhanden ist.
