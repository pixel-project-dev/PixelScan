# Frequently asked questions

[English](FAQ.md) | [Deutsch](FAQ.de.md)

## Is PixelScan free?

Yes. It is permanently free. There is no advertising, subscription, in-app purchase, account or telemetry.

## Is this a Samsung product?

No. PixelScan is an independent application. Samsung is a trademark of its owner.

## Will every scanner work?

No. The only device with a recorded practical test is the Samsung ProXpress SL-C2670FW over `xerox_mfp` and TCP 9400. Other names in the SANE configuration are documented by that backend and have not been confirmed with PixelScan.

## Does the document feeder work?

The reference device reports a feeder, and the application can request a batch from `scanimage`. A finished hardware test that loads paper and starts the feeder from the PixelScan window has not been done.

## Does it work on an Intel Mac?

The application binary contains Intel and Apple Silicon code. A physical Intel Mac has not been tested. Intel Macs need their own `scanimage`, usually under `/usr/local`. The development Mac does not have that program.

## Where are my old Samsung Scan settings?

They are copied on first launch into `~/Library/Application Support/PixelScan/` if that folder does not already contain the same files. The folder `~/Library/Application Support/Samsung Scan/` is not deleted.

## Does PixelScan upload my documents?

No. Pages, PDFs and OCR stay on the Mac.

## Why does macOS ask for the local network again?

PixelScan has a new bundle identifier. macOS treats that as a different application from Samsung Scan.

## Can I get it from the Mac App Store?

Not in this release. The scanner program lives outside the app. A sandboxed App Store build cannot see it.

## Where is the source code?

PixelScan is open source under the MIT License. The source is in this repository: https://github.com/pixel-project-dev/PixelScan
