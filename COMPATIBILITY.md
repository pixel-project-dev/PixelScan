# Kompatibilität

Die Datenbank liegt in `SamsungScan/Resources/compatibility.json`, Schema 1. Sie wird mit der App ausgeliefert und nicht aus dem Netzwerk geladen.

## Status

| Status | Bedeutung |
| --- | --- |
| `tested` | Mit Samsung Scan praktisch geprüft. |
| `backendSupportConfirmed` | In einer Backend-Quelle genannt, mit Samsung Scan nicht geprüft. |
| `experimental` | Nur ein technischer Hinweis. |
| `unsupported` | Die Inkompatibilität wurde festgestellt. |

Ein Kommentar in `xerox_mfp.conf` ist kein Test. USB-Kennungen belegen keine Netzwerkverbindung.

## Getestet

Samsung ProXpress SL-C2670FW, Familie C2670 Series.

- Backend `xerox_mfp`, TCP, Port 9400
- Flachbett und ADF ja, Duplex wurde vom Gerät nicht gemeldet
- macOS 27.2, arm64
- Nachweis: `scanimage` 1.4.0 und die Samsung-Scan-Engine, zuletzt am 6. November 2026 mit einem Flachbettausschnitt von 40 mm × 40 mm. Der Einzug wurde in diesem Lauf nicht gestartet.
- Die eSCL-Abfrage des eingebauten Webservers dieses Geräts lieferte früher HTTP 404. Das gilt nur für dieses Gerät.

## Vom Backend genannt, nicht mit Samsung Scan geprüft

`xerox_mfp.conf` von sane-backends 1.4.0 nennt weitere Samsung-, Xerox- und Dell-Modelle. Die Datenbank übernimmt diese Namen mit dem Status `backendSupportConfirmed`.

Zwei Einträge beschreiben Netzwerkmodus ausdrücklich als auskommentierte Zeile `tcp host port`:

- Samsung SCX-4500W Series
- Samsung SCX-4729FW

Auch diese beiden sind nicht mit Samsung Scan geprüft.

## Nicht eingebaute Backends

| Backend | Stand auf dem Entwicklungsmac |
| --- | --- |
| `escl` | In `dll.conf` genannt, Bibliothek `libsane-escl.so` fehlt. Gerätezeichenkette ist vorbereitet, wird nicht automatisch verwendet. |
| `airscan` | Paket nicht installiert. Keine Gerätezeichenkette, weil keine lokale Handbuchseite vorliegt. |
| `pixma` | Bibliothek vorhanden. Canon BJNP/MFNP, nicht für Samsung. |
| `net` | Bibliothek vorhanden. Braucht `saned`, nicht den Samsung-Port. |
| `hpaio` | Nicht Teil dieses sane-backends-Pakets. HP-Backend, nicht integriert. |
