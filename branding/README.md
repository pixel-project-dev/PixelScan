# PixelProject-Logo

Das Logo ist die Wortmarke **pixelproject.** Es besteht aus dem quadratischen Pixelraster, dem weißen oder dunklen Wort `pixel` und dem grünen Wort `project.` einschließlich des Punkts.

Ein Klick auf das vollständige Logo in PixelScan öffnet `https://pixel-project.de` im Standardbrowser. Die App lädt das Logo lokal und öffnet die Website nicht von selbst.

## Dateien

| Datei | Verwendung |
| --- | --- |
| `pixelproject-logo.svg` | Original mit dunkler Fläche `#11131a` |
| `pixelproject-logo-dark.svg` | Dieselbe Darstellung für dunkle Oberflächen |
| `pixelproject-logo-transparent.svg` | Dieselben Farben ohne Hintergrundfläche |
| `pixelproject-logo-light.svg` | Helle Fläche, mit den unten beschriebenen Kontrastanpassungen |
| `pixelproject-mark.svg` | Nur das Pixelraster, zur Wiederverwendung in anderen PixelProject-Anwendungen |
| `previews/logo-128.png`, `logo-256.png`, `logo-512.png`, `logo-1024.png` | Kontrollbilder der Originalfassung |

Die SVG-Dateien sind die Master. Sie enthalten keine Rasterbilder, keine externe Schrift und kein JavaScript. In PixelScan liegen daraus erzeugte PDF-Vektoren unter `PixelScan/Assets.xcassets/PixelProjectLogo.imageset/`.

## Farben

Die Werte stammen aus der PixelProject-Website, nicht aus den geglätteten Pixeln der Bildvorlage.

| Rolle | HEX |
| --- | --- |
| Dunkler Hintergrund | `#11131a` |
| Helle Schrift und Originalwort `pixel` | `#f7f8f4` |
| Pixelraster und Originalwort `project.` | `#bdff65` |
| Heller Hintergrund | `#f5f7fa` |
| Wort `pixel` auf hellem Grund | `#171c26` |
| Wort `project.` auf hellem Grund | `#3d6410` |

In der hellen Fassung bleibt das Pixelraster neongrün. Das Wort `project.` wechselt auf `#3d6410`, weil `#bdff65` auf `#f5f7fa` keinen ausreichenden Textkontrast hat. Das ist die einzige bewusste Farbabweichung der Wortmarke.

## Schrift

Die Website setzt die Wortmarke mit `-apple-system` bei `font-weight: 750` und `letter-spacing: -0.045em`. Das Raster ist das Zeichen ▦. Eine eigene Schriftdatei liegt im Website-Projekt nicht.

Die SVG-Pfade stammen aus den Glyphen der auf diesem Mac installierten Schrift San Francisco. Die Schriftdatei ist nicht eingebettet. Die Strichstärke entspricht dem Schriftmerkmal 0.48, also der Nähe von CSS-Gewicht 750. Die Bildvorlage ist ein geglättetes Raster von 346 × 100 Punkten. Die SVG ist deshalb dieselbe Marke in Vektorform, aber keine pixelgenaue Kopie dieser Vorlage.

## Größen

Die Wortmarke ist breit. Geeignete Darstellungsbreiten sind 180 bis 260 Punkte in Fenstern und 128, 256, 512 oder 1024 Pixel für Exporte. Das Raster allein bleibt quadratisch.

## Export

`Scripts/export-pixelproject-logo.swift` erzeugt die SVG-Dateien, die Kontrollbilder und die beiden PDF-Assets neu:

```sh
swift Scripts/export-pixelproject-logo.swift
```

Für PNG oder PDF in einer anderen Anwendung kann dieselbe SVG in einem Vektorprogramm geöffnet werden. Die App selbst braucht dafür keine Netzwerkverbindung.

## Wiederverwendung

AdminDock und weitere PixelProject-Anwendungen können `pixelproject-mark.svg` oder eine der Wortmarken direkt verwenden. Die helle Wortmarke ist die richtige Wahl auf weißem oder hellgrauem Grund. Ein anklickbares Logo soll auf `https://pixel-project.de` zeigen.
