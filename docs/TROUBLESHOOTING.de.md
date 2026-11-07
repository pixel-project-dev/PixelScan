# Fehlerbehebung

[English](TROUBLESHOOTING.md) | [Deutsch](TROUBLESHOOTING.de.md)

## Das Scannerprogramm fehlt

Installieren Sie sane-backends mit Homebrew oder wählen Sie in der Einrichtung ein vorhandenes `scanimage`. PixelScan verbirgt keine Administratorinstallation. Fehlt Homebrew, öffnet die App die Homebrew-Website, statt es selbst zu installieren.

## Die Architekturwarsung erscheint

`scanimage` wurde für einen anderen Prozessor gebaut als der laufende PixelScan-Prozess. Installieren Sie den passenden SANE-Build. Auf Apple Silicon ist das normalerweise Homebrew unter `/opt/homebrew`. Auf Intel ist es normalerweise `/usr/local`. Eine universelle PixelScan-Anwendung bringt ein nur für Apple Silicon gebautes `scanimage` nicht auf einem Intel-Mac zum Laufen.

## Der Scanner lässt sich nicht öffnen

Prüfen Sie, ob das Gerät eingeschaltet ist, ob Host und Port die gespeicherten Werte sind und ob macOS PixelScan den Zugriff auf das lokale Netzwerk erlaubt hat. Beim geprüften Samsung-Gerät ist der Port 9400. Die Meldung „Invalid argument“ von `scanimage` beim ersten Kontakt bedeutete früher, dass die lokale Netzwerkerlaubnis noch fehlte.

## Es werden keine Scanner gefunden

Bonjour schlägt nur ein Gerät vor, das es begründen kann. Ein IPP-Drucker wird nicht übernommen, solange TCP 9400 nicht antwortet. `_uscan._tcp` und `_uscans._tcp` sind Scandienste und können ohne Portsuche übernommen werden. Die Adresse kann immer von Hand eingegeben werden.

## Der Einzug stoppt

Ein leerer Einzug beendet den Stapel. Ein Stau stoppt ihn. Bereits geschriebene Seiten bleiben im Dokument. Der Einzug des Referenzgeräts hatte noch keinen abschließenden Test aus diesem Fenster.

## Export oder Texterkennung schlägt fehl

PDF, PNG, JPEG, TIFF und die Texterkennung verwenden Frameworks, die zu macOS gehören. Sie brauchen keine Netzwerkverbindung. Wurde eine Seitendatei aus dem Application-Support-Ordner entfernt, lässt die Sitzung diese Seite beim nächsten Laden weg.

## Gatekeeper

Verwenden Sie die notarisierte `PixelScan-1.3.0.dmg` und ihre SHA-256-Datei. Ein nicht notarisiertes neues Image ist eine andere Datei und kann abgelehnt werden. Eine Änderung des Disk-Images nach dem Anheften des Tickets macht das Ticket ungültig.

## Alte Einstellungen sind nicht erschienen

Sehen Sie in `~/Library/Application Support/Samsung Scan/` und `~/Library/Application Support/PixelScan/` nach. PixelScan kopiert eine fehlende Datei einmal. Es ersetzt keine PixelScan-Datei, die bereits existiert, und es löscht den alten Ordner nie. Wenn die alte Bibliothek entstand, bevor ein Backend-Feld existierte, liest PixelScan die Kopie beim Laden als `xerox_mfp`.
