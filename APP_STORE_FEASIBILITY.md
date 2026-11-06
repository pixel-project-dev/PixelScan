# Mac-App-Store-Prüfung

Stand: 6. November 2026, Samsung Scan 1.2.0 Build 3.

## Ergebnis

Die bestehende Architektur ist im Mac App Store **nicht funktionsfähig**. Ein App-Store-Build wird nicht ausgeliefert.

## Was tatsächlich lief

`Scripts/sandbox-experiment.sh` hat die Website-App mit `Config/SamsungScan-Sandbox.entitlements` neu signiert und mit `--sandbox-probe` gestartet. Die App meldete:

- `sandboxed=true`
- `scanimageFound=false`
- `scanimageStarted=false`
- `wroteTemporaryFile=true`

Die Sandbox sieht `/opt/homebrew/bin/scanimage` nicht. Ein Scan konnte deshalb nicht empfangen werden. Der Netzwerkzugriff zum Scanner wurde in diesem Lauf nicht geprüft, weil die Engine nicht startete. Eine temporäre Datei im Container ließ sich schreiben.

Ein erfolgreicher Start der sandkastenisierten App ist kein Nachweis für eine Annahme im App Store.

## Einordnung

| Frage | Stand |
| --- | --- |
| Sandbox-Build startet | getestet, ja |
| Engine finden und starten | getestet, nein |
| Netzwerkscan in der Sandbox | nicht getestet, die Engine fehlte |
| Dokument speichern | nur eine temporäre Datei im Container, getestet |
| App-Store-Einreichung | nicht erfolgt |

## Richtlinien und Lizenzen

Apple erlaubt in der Sandbox keinen freien Start fremder Programme und keinen freien Lesezugriff auf Homebrew. Eine temporäre Ausnahme für `/opt/homebrew` wäre ein Sonderrecht und ist für den App Store nicht als zulässig nachgewiesen.

`scanimage` ist ein GPL-2.0-Frontend. Es ins App-Bundle zu kopieren, würde die proprietäre App mit Weitergabepflichten belasten, die nicht geklärt sind. Die App verlinkt `libsane` nicht.

Öffentliche Scanner-APIs von ImageCaptureCore nehmen Geräte entgegen. Sie bieten keine Schnittstelle, um diesen SANE-Scanner für die Vorschau anzumelden.

## Nicht gebaut

Eine zweite Engine über eSCL oder eine eigene Sandbox-Engine wurde nicht implementiert. Für das Referenzgerät antwortete eSCL früher mit HTTP 404, und `libsane-escl.so` ist in diesem Homebrew-Build nicht vorhanden. Der Nutzen einer zweiten Engine ist damit nicht nachgewiesen.

Die Website-Version bleibt die funktionsfähige Fassung.
