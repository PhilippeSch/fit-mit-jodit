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

## Schritt B (App Store Connect, einmalig)
- Per API: Kategorie Gesundheit und Fitness (über Store-Texte), Altersfreigabe (alles «keine»/«nein», einzig «Gesundheits- oder Wellness-Themen» = ja), Preis gratis (Basis USA, Preispunkt 0), verfügbar in allen 175 Ländern und neuen Ländern.
- Im Browser: App-Datenschutz «Nein, wir erfassen keine Daten» gesichert. Der Dialog «Veröffentlichen» verlangt eine Einverständniserklärung; nicht bestätigt, steht in der Morgen-Checkliste. Danach Browser nicht mehr benutzt.

## Erledigt
- Teil 0 Kettentest (siehe oben)
- Teil 1 Datenmodell (SwiftData, CloudKit-tauglich), Bibliothek mit Suche, Favoriten, zuletzt benutzt, Vorlagen
- Teil 2 Baukasten: Palette, Zeitleiste (Breite nach Dauer, Umbruch), Runden «mal N», Übungsliste (60, de/en), Rückgängig/Wiederholen, eigene Bausteine
- Teil 3 Timer (Zeitstempel, künstliche Uhr in Tests), Laufansicht mit Vorlauf und Abschlussbild
- Teil 4 Signale: drei synthetische Ton-Sets, Halbzeit, Sprachansagen (Standard aus), Ducking
- Teil 5 Hintergrund (Audio-Hintergrundmodus) und Live Activity (Widget-Erweiterung) — Zwischenstand Build 2 in TestFlight
- Teil 6 Spotify-Link nach «iOS Content Linking»
- Teil 7 Export/Import (.fmjworkout); iCloud-Sync vorbereitet, aber ohne Container aus (siehe oben)
- Teil 8 Deutsch/Englisch (String Catalog, Test auf fehlende Übersetzungen)
- Teil 9 Branding: Markenfarbe aus fitmitjodit.ch, Raleway (OFL), Logos als Assets, Icon unverändert
- Teil 10 iPhone Duo: Falz über ReservedRegion `.division` (ab iOS 27.1, Verfügbarkeitsprüfung), Laufansicht und Baukasten weichen dem Falz aus
- Teil 10a Watch-App: Fernbedienung, Countdown aus Zeitstempel, Haptik, Trainingsliste, NowPlayingView; Weiterleitung iPhone–iPad (MultipeerConnectivity)
- Tests: 44 Unit-Tests grün; UI-Tests auf iPhone (de/en) grün

## Offen
- iCloud-Container `iCloud.ch.fitmitjodit.timer` anlegen und der App-ID zuweisen
- UI-Tests auf iPad und iPhone Duo, Laufansicht bei 1/3, 1/2 und voller Breite
- Screenshots, Upload Store-Texte/Screenshots, finaler Build, CI auf Pull Request, Berichte

## Nächster Schritt
Teil 11: UI-Tests auf iPad/Duo/Watch, Breitentests, Screenshots

## Annahmen
- Interne Testgruppe mit Zugriff auf alle Builds, darum keine Zuweisung pro Build nötig.
- Release-Signierung manuell statt automatisch, weil die Schlüssel-Anmeldung von xcodebuild scheitert.
- Ohne Container: lokaler Speicher (SPEC: «Fällt iCloud aus … läuft die App mit lokalem Speicher weiter»).
- Marketing-URL: https://fitmitjodit.ch
- Hintergrund-Signale über den Audio-Hintergrundmodus mit stiller Spur während eines Trainings (Begründung im Bericht).
- Watch startet ein Training auf dem iPad, wenn das iPhone mit einem iPad verbunden ist und dort nichts anderes läuft, sonst auf dem iPhone.
