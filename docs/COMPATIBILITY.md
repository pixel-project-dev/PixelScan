# Compatibility

[English](COMPATIBILITY.md) | [Deutsch](COMPATIBILITY.de.md)

PixelScan ships a local compatibility database. It is not downloaded and it does not change itself when a new scanner is found.

## Tested

Samsung ProXpress SL-C2670FW, family C2670 Series.

- Backend `xerox_mfp`, TCP, port 9400
- Flatbed: confirmed with a 40 mm × 40 mm scan at 75 dpi on 6 November 2026
- Document feeder: the device reports it, and an earlier command-line use finished. A feeder scan started from the PixelScan window has not been signed off
- Duplex: the reference device did not report it, so PixelScan does not show duplex for that device
- An eSCL request to the embedded web server of this unit returned HTTP 404. That result is only about this unit

The test was recorded while the application was still named Samsung Scan. The same code path is what PixelScan 1.3.0 uses. Renaming the application does not add a new hardware result.

## Documented by SANE, not confirmed

sane-backends 1.4.0 names further Samsung models, and some Xerox and Dell models, in `xerox_mfp.conf`. PixelScan stores those names with the status “documented by the backend”. A comment or a USB identifier is not a network scan and is not a PixelScan test.

Two Samsung entries document network mode as a commented `tcp host port` line and are still unconfirmed:

- Samsung SCX-4500W Series
- Samsung SCX-4729FW

## Not offered as supported

| Backend | What is known |
| --- | --- |
| `escl` | A device string exists. On the development Mac `libsane-escl.so` is missing, so the backend is not used automatically |
| `pixma` | Present as a Canon library. It is not a Samsung setup |
| `net` | Present, and it needs `saned`. It is not the Samsung port 9400 |
| `airscan` | Not installed and not integrated |
| `hpaio` | Not part of this sane-backends package and not integrated |

A scanner that is not in the tested row must be treated as unknown until its options have been read and a page has been saved.
