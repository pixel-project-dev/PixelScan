# Vertrieb

Es gibt zwei vorbereitete Konfigurationen. Veröffentlicht wird ohne Freigabe des Projektinhabers nichts.

## Website

Das ist der vollständige Weg.

- Signatur: `Developer ID Application: Norman Hennige (Z9U2P89679)`
- Hardened Runtime
- Entitlements in `Config/SamsungScan.entitlements`: Netzwerkclient und vom Benutzer gewählte Dateien, keine App-Sandbox
- DMG mit Programm und Verknüpfung zum Programme-Ordner
- Prüfsumme SHA-256 neben der DMG

Aktueller Stand ist **1.2.0 Build 3**. Die Download-Datei ist `dist/SamsungScan-1.2.0.dmg`.

SHA-256: `7a74e9f712a00b270353fc0106b7d8157dfde906cc66acdda592ccae7ddcb1b8`

Gatekeeper akzeptiert die App aus dieser DMG mit `source=Notarized Developer ID`. Das Ticket blieb beim Umbenennen der notarisierten Release-Candidate-DMG erhalten. Ein Upload auf die Website erfolgt erst nach ausdrücklicher Freigabe.

## Mac App Store

Eine zweite Entitlement-Datei `Config/SamsungScan-Sandbox.entitlements` schaltet die App-Sandbox ein. `Scripts/sandbox-experiment.sh` signiert eine Kopie und startet `--sandbox-probe`.

Diese Variante ist kein Release. Solange die Scanner-Engine außerhalb der Sandbox liegt, bleibt die Website-Version die funktionsfähige Fassung. Details stehen in `APP_STORE_FEASIBILITY.md`.
