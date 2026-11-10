# PROGRESS

KETTENTEST: grün (10.11.2026, 22:55), mit einer Einschränkung beim iCloud-Container

| Schritt | Status | Beleg |
|---|---|---|
| git, öffentliches GitHub-Repository, Push | grün | github.com/PhilippeSch/fit-mit-jodit, `EINGABEN.md`, `.p8`, `fastlane/.env`, Prüfkontakt ignoriert |
| Xcode-Projekt (iOS 17, iPhone+iPad, Watch-App watchOS 10, Unit-/UI-Tests) | grün | Build ohne Warnungen; Tests grün auf iPad Pro 13", iPhone 18 Pro Max, iPhone Duo, Apple Watch Series 12 |
| fastlane mit API-Schlüssel | grün | Lanes `signing`, `archive`, `beta`, `metadata` |
| Signieren, Archiv, Upload Build 1.0 (1) | grün | manuelle Distribution-Signierung (Zertifikat und Profile per API), Archiv und .ipa unter `build/` |
| TestFlight | grün | per API: processingState VALID, internalBuildState READY_FOR_BETA_TESTING, usesNonExemptEncryption false, Gruppe «Intern» (alle Builds); Philippe als interner Tester eingeladen |
| Store-Texte de-DE und en-US | grün | hochgeladen und mit `Tools/readback.rb` zurückgelesen: alle Felder gleich |
| GitHub Actions | grün | Lauf 42908305670 (manuell), Xcode 26.6 auf `macos-latest`, Version im Workflow fest |
| Befehle in CLAUDE.md | grün | |
| iCloud-Container | offen | API kann keine Container anlegen; `xcodebuild` sieht kein Xcode-Konto. App läuft bis dahin mit lokalem Speicher, CloudKit über `Config/Base.xcconfig` zuschaltbar |

## Erledigt
- Teil 0 Kettentest (siehe oben)

## Offen
- iCloud-Container `iCloud.ch.fitmitjodit.timer` anlegen und der App-ID zuweisen
- Teile 1 bis 15

## Nächster Schritt
Teil 1: Datenmodell, Bibliothek, Vorlagen

## Annahmen
- Interne Testgruppe mit Zugriff auf alle Builds, darum keine Zuweisung pro Build nötig.
- Release-Signierung manuell statt automatisch, weil die Schlüssel-Anmeldung von xcodebuild scheitert.
- Sync-Ersatz, falls der Container fehlt: lokaler Speicher (SPEC: «Fällt iCloud aus … läuft die App mit lokalem Speicher weiter»).
