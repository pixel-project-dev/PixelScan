# Vertrieb

Es gibt zwei vorbereitete Konfigurationen. Veröffentlicht wird ohne Freigabe des Projektinhabers nichts.

## Website

Das ist der vollständige Weg.

- Signatur: `Developer ID Application: Norman Hennige (Z9U2P89679)`
- Hardened Runtime
- Entitlements in `Config/SamsungScan.entitlements`: Netzwerkclient und vom Benutzer gewählte Dateien, keine App-Sandbox
- DMG mit Programm und Verknüpfung zum Programme-Ordner
- Prüfsumme SHA-256 neben der DMG

Aktueller Stand ist **1.2.0 Build 3, Release Candidate 1**.

`notarytool` hat auf diesem Mac kein Keychain-Profil. Die DMG heißt deshalb `SamsungScan-1.2.0-rc1-unnotarized.dmg`. Gatekeeper lehnt die signierte, nicht notarisierte App ab (`source=Unnotarized Developer ID`).

Notarisieren, sobald ein Profil existiert, ohne Zugangsdaten ins Repository zu schreiben:

```bash
xcrun notarytool store-credentials samsung-scan
xcrun notarytool submit "dist/SamsungScan-1.2.0-rc1-unnotarized.dmg" --keychain-profile samsung-scan --wait
xcrun stapler staple "dist/Samsung Scan.app"
spctl --assess --type execute --verbose "dist/Samsung Scan.app"
```

Der Tag `v1.2.0` wird erst gesetzt, wenn dieser Schritt erfolgreich war.

## Mac App Store

Eine zweite Entitlement-Datei `Config/SamsungScan-Sandbox.entitlements` schaltet die App-Sandbox ein. `Scripts/sandbox-experiment.sh` signiert eine Kopie und startet `--sandbox-probe`.

Diese Variante ist kein Release. Solange die Scanner-Engine außerhalb der Sandbox liegt, bleibt die Website-Version die funktionsfähige Fassung. Details stehen in `APP_STORE_FEASIBILITY.md`.
