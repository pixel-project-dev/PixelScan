# Vertrieb

Es gibt zwei vorbereitete Konfigurationen. Veröffentlicht wird ohne Freigabe des Projektinhabers nichts.

## Website

Das ist der vollständige Weg.

- Signatur: `Developer ID Application: Norman Hennige (Z9U2P89679)`
- Hardened Runtime
- Entitlements in `Config/SamsungScan.entitlements`: Netzwerkclient und vom Benutzer gewählte Dateien, keine App-Sandbox
- DMG mit Programm und Verknüpfung zum Programme-Ordner
- Prüfsumme SHA-256 neben der DMG

Aktueller Stand ist **PixelScan 1.3.0 Build 4**. Die vorgesehene Download-Datei ist `dist/PixelScan-1.3.0.dmg`. Die ältere Datei `dist/SamsungScan-1.2.0.dmg` bleibt der letzte Stand unter dem bisherigen Namen.

SHA-256: `2addce0acdbebe3083684cd9009d1787e1adb37460b62c6829ef4b62afbab001`

Ein Upload auf eine Website oder nach GitHub erfolgt erst nach ausdrücklicher Freigabe. `Scripts/publish-github.sh` bricht ohne diese Freigabe ab und überträgt keinen Quellcode.

## Mac App Store

Eine zweite Entitlement-Datei `Config/SamsungScan-Sandbox.entitlements` schaltet die App-Sandbox ein. `Scripts/sandbox-experiment.sh` signiert eine Kopie und startet `--sandbox-probe`.

Diese Variante ist kein Release. Solange die Scanner-Engine außerhalb der Sandbox liegt, bleibt die Website-Version die funktionsfähige Fassung. Details stehen in `APP_STORE_FEASIBILITY.md`.
