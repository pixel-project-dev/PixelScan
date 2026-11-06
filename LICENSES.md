# Lizenzen

## Eigener Code

Der Quellcode von Samsung Scan ist proprietär. Die Anwendung ist dauerhaft kostenlos, ohne Werbung, Konto, Abo, In-App-Kauf, Telemetrie oder Cloud-Pflicht. Das Repository bleibt privat. Diese Datei ist keine Erlaubnis, den Quellcode zu veröffentlichen.

Ein fertiges Binärpaket darf weitergegeben werden, solange die Pflichten der mitgelieferten und der getrennt genutzten Komponenten eingehalten werden. Die App selbst enthält kein SANE-Programm.

## SANE

Geprüft an `/opt/homebrew/Cellar/sane-backends/1.4.0_2/LICENSE` und `COPYING`.

- Die Frontend-Programme, darunter `scanimage`, stehen unter der GPL-2.0.
- Die meisten Backend-Bibliotheken stehen unter der GPL-2.0 mit der SANE-Linking-Exception. Nicht jedes Backend übernimmt die Exception.
- Die SANE-API und das Netzwerkprotokoll sind Public Domain.

Samsung Scan verlinkt `libsane` nicht und startet `scanimage` als eigenes Programm. Die App kopiert `scanimage` nicht in das Bundle.

### Warum keine mitgelieferte Laufzeit

Drei Varianten wurden geprüft.

| Variante | Entscheidung |
| --- | --- |
| A. Getrennt installiertes `scanimage` | Verwendet. Die App sucht das Programm und kann Homebrew nur nach einem Klick starten. |
| B. Separat ausgelieferte SANE-Laufzeit | Nicht umgesetzt. Ein mitgegebenes `scanimage` wäre ein GPL-Frontend. Die Quellcode-Weitergabe und die arm64-only Homebrew-Bibliotheken sind dafür nicht geklärt. |
| C. SANE ins App-Bundle | Nicht umgesetzt. Dieselbe GPL-Pflicht, dazu Signierung und Notarisierung fremder Bibliotheken. |

Offene Frage, kein Rechtsgutachten: Ob das bloße Starten eines bereits vom Benutzer installierten GPL-Programms weitere Pflichten auslöst, ist hier nicht entschieden. Sicher ist nur, dass Samsung Scan keinen SANE-Code einbindet oder verteilt.

`sane-airscan` und HPLIP/`hpaio` stehen getrennt unter der GPL und werden nicht mitgeliefert.

## Apple-Frameworks

AppKit, SwiftUI, ImageIO, PDFKit, Vision und Network.framework sind Systembestandteile. OCR läuft lokal. Es werden keine privaten Apple-Schnittstellen verwendet.
