# Installation

Samsung Scan ist kostenlos. Es braucht kein Konto und keine Cloud.

## Programm installieren

1. Die DMG öffnen.
2. `Samsung Scan` auf den Alias **Programme** ziehen.
3. Die App aus dem Programme-Ordner starten.
4. Die DMG `SamsungScan-1.2.0.dmg` ist notarisiert. Gatekeeper akzeptiert die App. Eine Textdatei `Not notarized.txt` im Abbild ist ein überholter Hinweis aus dem Release Candidate und beschreibt nicht den Signaturstatus.

## Scannerprogramm

Samsung Scan bringt die Scanner-Engine nicht mit. Beim ersten Start prüft die Einrichtung vier Punkte:

- Ist das Scannerprogramm vorhanden?
- Passt seine Prozessorarchitektur zu diesem Mac?
- Ist die Samsung-Unterstützung installiert?
- Liegt die eigene Scannerliste im Benutzerordner?

Fehlt das Programm:

1. Homebrew installieren, falls es fehlt. Die App öffnet dazu [https://brew.sh](https://brew.sh).
2. In Samsung Scan **Scannersoftware installieren** wählen. Das startet Homebrew nur nach diesem Klick. macOS kann nach einem Kennwort fragen, weil Homebrew das so verlangt.
3. Den Scanner über seine Adresse hinzufügen. Für die bekannten Samsung-Netzwerkgeräte ist der Port 9400.

Die App sucht das Programm unter dem selbst gewählten Pfad, `/opt/homebrew/bin/scanimage`, `/usr/local/bin/scanimage` und im `PATH`. Ein Intel-Mac verwendet üblicherweise `/usr/local`. Auf dem Entwicklungsmac ist das Homebrew-Programm nur für Apple Silicon gebaut. Ein Intel-Gerät wurde nicht getestet.

## Scanner

Der Assistent sucht angekündigte Geräte. Ein Drucker allein wird nicht als Scanner übernommen. Die Adresse kann immer von Hand eingegeben werden. Technische Namen stehen unter **Erweitert**.

## Daten auf diesem Mac

Bibliothek, Seiten und die Scannerliste liegen in:

`~/Library/Application Support/Samsung Scan/`

Die Liste der Samsung-Netzwerkadressen steht in `sane.d/xerox_mfp.conf` in diesem Ordner. Die systemweite Datei unter Homebrew wird dabei nicht ersetzt.
