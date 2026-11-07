# Hinweise zu Drittanbieter-Software

## SANE

PixelScan nutzt das getrennt installierte Programm `scanimage` aus dem Projekt sane-backends.

Nach der Datei `LICENSE` der Distribution besteht SANE aus drei Teilen:

- Frontend-Programme, in der Regel GPL-2.0.
- Backend-Bibliotheken, in der Regel GPL-2.0 mit einer Ausnahme, die das Verknüpfen erlaubt, ohne die Lizenz des nutzenden Programms zu ändern. Nicht jedes Backend hat diese Ausnahme.
- Die SANE-API und das Netzwerkprotokoll sind gemeinfrei beschrieben.

PixelScan verlinkt `libsane` nicht und kopiert `scanimage` nicht in das App-Bundle. Die App startet das bereits installierte Programm als eigenen Prozess. Damit wird keine GPL-Pflicht für den Swift-Quelltext ausgelöst, und es werden keine Homebrew-Bibliotheken weitergegeben, deren Quelltext dieser Verteilung beiliegen müsste.

Eine direkte Mitlieferung wäre rechtlich nur mit dem vollständigen korrespondierenden Quelltext und den Lizenztexten aller abhängigen Bibliotheken sauber. Technisch hängt das Homebrew-Binary an weiteren Bibliotheken und ist auf diesem Mac nur arm64. Deshalb installiert die App SANE nicht im Stillen, sondern bietet eine sichtbare Installation über ein bereits vorhandenes Homebrew an.

Die Lizenztexte der lokalen Installation liegen unter `/opt/homebrew/share/doc/sane-backends/`, wenn sane-backends über Homebrew installiert ist. Der Upstream ist https://gitlab.com/sane-project/backends.

## Apple-Frameworks

SwiftUI, AppKit, Network, Vision, PDFKit, ImageIO und Core Image gehören zum macOS-SDK und werden nicht als eigene Bibliotheken ausgeliefert.
