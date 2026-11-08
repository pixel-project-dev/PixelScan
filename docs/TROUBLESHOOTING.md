# Troubleshooting

[English](TROUBLESHOOTING.md) | [Deutsch](TROUBLESHOOTING.de.md)

## The scanner program is missing

Install sane-backends with Homebrew, or choose an existing `scanimage` in setup. PixelScan does not hide an administrator installation. If Homebrew is absent, the app opens the Homebrew website instead of installing it.

## The architecture warning appears

`scanimage` was built for a different processor than the running PixelScan process. Install the matching SANE build. On Apple Silicon that is normally Homebrew under `/opt/homebrew`. On Intel it is normally `/usr/local`. A universal PixelScan application does not make an Apple-Silicon-only `scanimage` run on Intel.

## The scanner does not open

Check that the device is on, that the host and port are the ones you saved, and that macOS allowed local network access for PixelScan. For the tested Samsung device the port is 9400. Invalid argument from `scanimage` on first contact has previously meant that the local-network permission was still missing.

## No scanners are discovered

Bonjour only suggests a device it can justify. An IPP printer is not added unless TCP 9400 responds. `_uscan._tcp` and `_uscans._tcp` are scanner services and can be offered without a port sweep. You can always type the address.

## The feeder stops

An empty feeder ends the batch. A jam stops it. Pages that were already written stay in the document. The reference device’s feeder has not had a final test from this window.

## Export or OCR fails

PDF, PNG, JPEG, TIFF and OCR use frameworks that are part of macOS. They do not need a network connection. If a page file was removed from the application-support folder, the session drops that page on the next load.

## Gatekeeper

Use the notarized `PixelScan-1.3.1.dmg` and its SHA-256 file. An unnotarized rebuild is a different file and can be rejected. Changing the disk image after the ticket is stapled invalidates the ticket. The older notarized image `PixelScan-1.3.0.dmg` remains valid for that version.

## Old settings did not appear

Look in `~/Library/Application Support/Samsung Scan/` and `~/Library/Application Support/PixelScan/`. PixelScan copies a missing file once. It does not replace a PixelScan file that already exists, and it never deletes the old folder. If the old library was created before a backend field existed, PixelScan reads it as `xerox_mfp` when it loads the copy.
