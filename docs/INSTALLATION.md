# Installation

[English](INSTALLATION.md) | [Deutsch](INSTALLATION.de.md)

## Requirements

- macOS 14 or later
- A Mac with Apple Silicon or an Intel processor
- A scanner that speaks a backend PixelScan can actually use
- The separate SANE program `scanimage`

The application is universal. The scanner program is not included and must match the processor of the Mac. On the development Mac only an Apple Silicon build of `scanimage` is installed. An Intel Mac has not been used for a hardware test.

## Install PixelScan

1. Obtain `PixelScan-1.3.1.dmg` from the GitHub release. The previous image `PixelScan-1.3.0.dmg` remains available there.
2. Compare the SHA-256 checksum with the published `.sha256` file.
3. Open the disk image.
4. Drag PixelScan to Applications.
5. Eject the disk image and open PixelScan from Applications.
6. Allow local network access when macOS asks. The bundle identifier is `email.hennige.pixelscan`, so an earlier allowance for Samsung Scan does not carry over.

An existing Samsung Scan application is not deleted or replaced.

## Install the scanner program

PixelScan looks for `scanimage` in a path you choose, then `/opt/homebrew/bin/scanimage`, `/usr/local/bin/scanimage`, and `PATH`.

If Homebrew is already installed, use **Install with Homebrew** inside PixelScan. That button is the only way the app starts the installation. If Homebrew is missing, use **Open Homebrew Website**, install Homebrew yourself, and then return.

```sh
brew install sane-backends
```

PixelScan does not change printer drivers and does not edit the system-wide SANE configuration.

## Move existing settings

On first launch PixelScan copies these items from `~/Library/Application Support/Samsung Scan/` when the destination does not already have them:

- `library.json` (scanners, profiles, last selection, settings)
- `session.json`, `pages` and `inbox`
- `scan.log`
- `sane.d`

The copy goes to `~/Library/Application Support/PixelScan/`. The original folder stays. Running the migration again does not overwrite a file that is already present.
