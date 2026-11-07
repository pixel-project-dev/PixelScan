# Privacy

[English](PRIVACY.md) | [Deutsch](PRIVACY.de.md)

PixelScan works on the Mac. It does not upload scans, preview images or recognized text to a cloud service. There is no account, no advertising, no telemetry and no subscription check.

## What stays on this Mac

| Data | Place |
| --- | --- |
| Scanners, profiles and settings | `~/Library/Application Support/PixelScan/library.json` |
| Open document | `session.json` and `pages` in the same folder |
| Scanner addresses for `xerox_mfp` | `sane.d` in the same folder |
| Diagnostic log | `scan.log` in the same folder |

The log can contain a scanner address you saved, because that address is needed to understand a connection failure. It is not sent anywhere by PixelScan.

## Network

PixelScan opens a connection to a scanner you selected, normally TCP port 9400. Bonjour listens for announced devices on the local network. A printer service is only offered as a scanner candidate when port 9400 responds. PixelScan does not sweep the subnet.

macOS asks for local-network permission because the bundle identifier is `email.hennige.pixelscan`. That permission is used to reach the scanner.

OCR uses the Vision framework on the same Mac.

## Previous Samsung Scan data

If `~/Library/Application Support/Samsung Scan/` contains a library, PixelScan copies the known files into the PixelScan folder when those destination files are absent. The copy includes scanners, addresses, ports, backend assignments, profiles, the last selection, settings and the user SANE configuration.

The original folder is left in place. PixelScan does not ask to delete it and does not delete it. If PixelScan already has a file of the same name, that file is kept and the older file is not copied over it. Repeating the launch does not create a second copy of the same scanner.

## What PixelScan does not do

- It does not change printer drivers.
- It does not edit the system-wide `xerox_mfp.conf`.
- It does not include a private Apple interface.
- It does not change System Integrity Protection.
