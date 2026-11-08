# PixelScan

[English](README.md) | [Deutsch](README.de.md)

![PixelScan icon](docs/pixelscan-icon.png)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/pixelproject-logo-dark.svg">
  <img src="docs/pixelproject-logo-light.svg" alt="pixelproject." width="280">
</picture>

PixelScan is a free, native macOS application for scanning and preparing documents with compatible network and multifunction scanners. It keeps pages, OCR and exports on the Mac. It does not require an account, a subscription or a cloud service.

PixelScan is not a product of Samsung Electronics. Samsung is a trademark of its owner. The first tested device is a Samsung network scanner. The application is built so that further scanner families can be added when their behavior has actually been verified.

## Who it is for

PixelScan is for people who want to scan documents on a Mac without an account or a cloud service. It is aimed at compatible network and multifunction scanners, beginning with older Samsung devices that speak the SANE backend `xerox_mfp`. It is not a promise that every scanner from every manufacturer will work.

## Screenshots

The image above is the application icon shipped with PixelScan.

A window screenshot is not included. The development Mac already has a saved scanner, and a capture of that window would show a private network address. No picture has been created to stand in for the real interface.

## Main features

- Save more than one scanner and choose it again later
- Discover announced scanners with Bonjour, and add an address by hand
- Flatbed scanning and a document feeder when the scanner reports that source
- Preview, scan area, resolution and color mode taken from the values the device reports
- Rotate, crop, brightness, contrast and conservative straightening
- Multipage PDF, PNG, JPEG and TIFF
- Local OCR that can produce a searchable PDF
- Scan profiles for repeated jobs
- German and English interface, light and dark appearance

A function is shown only when the connected scanner reports it. Duplex, for example, appears only if the backend reports duplex.

## Supported macOS versions

PixelScan requires macOS 14 or later. Release builds are universal binaries for Apple Silicon and Intel. The current development and the confirmed scanner test were done on macOS 27 on Apple Silicon.

## Apple Silicon and Intel

The application itself contains both `arm64` and `x86_64` code. The scanner program is separate. On the development Mac, Homebrew’s `scanimage` is installed for Apple Silicon only, at `/opt/homebrew/bin/scanimage`. An Intel Mac normally looks for that program under `/usr/local/bin/scanimage`.

PixelScan warns when the scanner program’s architecture does not match the running application. That warning is covered by an automated test. A scan on a physical Intel Mac has not been run, so Intel hardware support remains unverified.

## Supported scanners

The only device confirmed in practice with this application is the Samsung ProXpress SL-C2670FW, family C2670 Series.

- Backend: `xerox_mfp`
- Network: TCP port 9400
- Confirmed from the device: flatbed, document feeder and automatic source selection
- Duplex was not reported by the reference device
- Options are read from the device. The application does not invent resolutions or color modes

Other Samsung models are named in the SANE `xerox_mfp` configuration shipped with sane-backends 1.4.0. Those names are documentation from the backend. They are not a statement that PixelScan has scanned with those models. Xerox and Dell names that appear in the same backend file are in the same category: recorded, not confirmed here.

No other manufacturer is claimed as supported. Canon `pixma`, eSCL, AirScan and HP `hpaio` are not offered as working scanner setups in this release.

## Compatibility status

| Status | Meaning |
| --- | --- |
| Tested | A person used this application, or its previous release under the name Samsung Scan, with that device and recorded the result |
| Documented by SANE | The backend names the model. PixelScan has not confirmed it |
| Not supported | The combination is known not to work, or the required library is absent |

Details and the distinction between those states are in [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md). The same database is inside the app and is not downloaded.

The flatbed test of the SL-C2670FW was a 40 mm × 40 mm scan at 75 dpi on 6 November 2026. The document feeder was reported by the device and had earlier been exercised from the command line. A final feeder test started from the PixelScan window, with paper loaded, has not been completed.

## Installation

1. Open `PixelScan-1.3.1.dmg`.
2. Drag **PixelScan** to the Applications folder.
3. Open PixelScan from the Applications folder. The first launch can ask for permission to find devices on the local network. Allow it.
4. If macOS asks whether to open an app from an identified developer, the published image is signed with a Developer ID and notarized. Confirm the SHA-256 published with that exact file before you open a copy from anywhere else.

PixelScan does not replace an existing copy by itself. If an older application named Samsung Scan is still in the Applications folder, it can stay there. PixelScan uses a new bundle identifier, `email.hennige.pixelscan`.

The full steps are in [docs/INSTALLATION.md](docs/INSTALLATION.md).

## SANE dependency

PixelScan does not contain the scanner engine. It starts the separately installed command `scanimage` from the SANE project. The app does not link `libsane` and does not copy `scanimage` into its bundle.

On a typical Mac the program is installed with Homebrew:

```sh
brew install sane-backends
```

PixelScan looks for it in this order: a path you chose, `/opt/homebrew/bin/scanimage`, `/usr/local/bin/scanimage`, then `PATH`. The button **Install with Homebrew** runs only after you click it. It does not request an administrator password by itself. Homebrew may ask for one, because that is how Homebrew installs software.

SANE is licensed under the GPL. The reasons PixelScan does not bundle it are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## First setup

The setup assistant checks four things:

- whether `scanimage` is installed
- whether its processor architecture matches PixelScan
- whether the Samsung network backend is available
- whether your scanner list is stored in your own Library folder

You can search for announced devices or type the address. A printer announcement is not treated as a scanner unless TCP port 9400 answers. There is no scan of the whole subnet.

For the known Samsung network devices the address form is a host and port 9400. The application stores that address only in your folder and passes it to `scanimage` as the environment variable `SANE_CONFIG_DIR`. It does not rewrite the system-wide `xerox_mfp.conf`.

## Scanning documents

1. Select the scanner.
2. Choose the source, resolution and color mode. Only reported values are offered.
3. Choose the paper size or a custom area.
4. Use **Preview** to check the page, or **Scan** to capture it.
5. Finished pages stay in the document if a later page stops because of a jam, an empty feeder or a network error.

## ADF and multipage PDFs

When the source is not the flatbed, PixelScan asks `scanimage` for a batch and keeps each finished page. Choose **Export…** and PDF to write those pages into one file. Open that file in Preview to check the page count.

The reference device reports a document feeder. An automated test checks the batch arguments and the messages for an empty feeder and a paper jam. It does not pull paper. A three-page feeder scan from the PixelScan window is still an open hardware test. Do not expect that test to have been signed off.

## OCR and searchable PDFs

OCR uses Apple’s Vision framework on the Mac. Recognized text can be embedded in a PDF so Preview and Spotlight can search it. The image of the page remains. OCR is optional and is part of the OCR scan profile. No page is sent to a recognition service.

## Image editing

For a selected page you can rotate in quarter turns, crop, and adjust brightness and contrast. Automatic straightening is conservative: angles below 0.4° and above 12° are left unchanged. Blank pages can be detected and left out of an export when you turn that option on.

## Privacy

PixelScan is permanently free. It has no advertising, no subscription, no in-app purchase, no account and no telemetry. Scanning, image editing, PDF creation and OCR run locally.

The app needs the local network in order to reach a scanner you chose. It does not upload the scan. Documents and settings stay under:

`~/Library/Application Support/PixelScan/`

On the first launch, PixelScan copies an existing Samsung Scan library into that folder when the new file is not already there. The original Samsung Scan folder is not deleted. A second launch does not copy over files that already exist, so scanners are not duplicated. Details are in [docs/PRIVACY.md](docs/PRIVACY.md).

## Troubleshooting

Common cases:

- The scanner program is missing. Install sane-backends, then return to PixelScan.
- The architecture does not match. Install a `scanimage` built for the same kind of Mac.
- The scanner is visible but will not open. Check power, the address, port 9400, and the local-network permission for PixelScan. A new bundle identifier means macOS asks again even if Samsung Scan was already allowed.
- The document feeder is empty or jammed. The finished pages that were already written remain in the document.
- Gatekeeper warns about an unidentified developer. Use the notarized disk image and compare its SHA-256. A rebuilt image is not notarized until it has been submitted and stapled again.

More cases are in [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Known limitations

- Only the SL-C2670FW has a recorded practical test. Other models named by SANE are not confirmed.
- The Intel hardware test is open.
- The document-feeder test from the PixelScan window is open.
- Duplex is unavailable when the device does not report it.
- IPv6 addresses are not accepted. The backend’s device string separates the host and the port with a space, and that form has not been verified for IPv6.
- PixelScan is not in the Mac App Store. A sandboxed build cannot see a `scanimage` program installed outside the app.
- PixelScan does not appear as a scanner in Image Capture. There is no public API for that.
- eSCL, AirScan and HP `hpaio` are not integrated. `escl` may be mentioned by a SANE configuration even when `libsane-escl.so` is not installed. PixelScan does not pretend that library is present.
- The app does not change printer drivers.

## Downloads and releases

Download PixelScan 1.3.1 from the GitHub release. The release includes the notarized disk image, its checksum and the PixelProject logo.

- [Release page](https://github.com/pixel-project-dev/PixelScan/releases/tag/v1.3.1)
- [Latest release](https://github.com/pixel-project-dev/PixelScan/releases/latest)
- [PixelScan-1.3.1.dmg](https://github.com/pixel-project-dev/PixelScan/releases/download/v1.3.1/PixelScan-1.3.1.dmg)

SHA-256 of the notarized image:

`39a852e6054d42299ac195a0571121d219e9f14cf4cbd7dcfcec78b2e33d56e7`

The previous notarized image remains `PixelScan-1.3.0.dmg`, SHA-256 `2addce0acdbebe3083684cd9009d1787e1adb37460b62c6829ef4b62afbab001`.

The release contains the disk image, the checksum, the PixelProject logo and these notes. The application source is proprietary and is not part of the public repository.

Check the published SHA-256 after download:

```sh
shasum -a 256 -c PixelScan-1.3.1.dmg.sha256
```

## Frequently asked questions

The short answers are in [docs/FAQ.md](docs/FAQ.md). In particular: PixelScan stays free, it is not affiliated with Samsung, it does not scan every scanner on the market, and it does not send documents anywhere.

## License and third-party components

The PixelScan source is proprietary. You may use the signed application at no charge. That permission is not a license to republish the source.

`scanimage` and sane-backends are third-party software under the GPL and are installed separately. Apple’s system frameworks are part of macOS. The notices are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
