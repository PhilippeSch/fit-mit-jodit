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
- Gerätetests (Ducking, Hintergrund, Live Activity, Watch, Weiterleitung iPad, Spotify, Sync, AirDrop, Duo auf/zu), dazu die Punkte unter «Neu (12.11.2026)» in der Morgen-Checkliste: Verschieben im Baukasten, Dunkelmodus, Fernbedienung beim ersten Start
- iOS 17: Das Verschieben nutzt dort den SwiftUI-Ersatzweg (`LegacyHoldToDrag`). Ungeprüft, weil keine iOS-17-Laufzeit installiert ist
- Erledigt seit 11.11.2026: App-Datenschutz veröffentlicht, iCloud-Schema in Production. Seit 12.11.2026: Bedienungshilfen-Audit auf dem iPad (Ursache war die Typ-Beschriftung der Palette in `caption2`)

## Nächster Schritt
Rückmeldungen aus dem Gerätetest von Philippe und Jodit abwarten und umsetzen.

## Stand 11.11.2026, 01:45
- Teile 0–15 umgesetzt, finaler Build 1.0 (202611110111) in TestFlight grün, Store-Texte und Screenshots hochgeladen, CI auf PR #1 grün, Berichte geschrieben.

## Stand 11.11.2026, Vormittag
- Fünf neue Vorlagen (Beine & Po 15, Cardio 12, Oberkörper 12, EMOM 12, Pyramide) und «Dehnen 10» mit 10 neuen Dehnübungen.
- Uhr bleibt während des Trainings aktiv (erweiterte Laufzeit), Haptik auch bei gesenktem Arm.
- Training läuft nach Neustart der App weiter; Laufansicht sperrbar; Siri und Kurzbefehle; Teilen per QR-Code; Trainingsverlauf mit Wochenübersicht.
- Satzliste für Jodits Aufnahmen um Teil G/H (Nr. 97–106) ergänzt, PDF neu erzeugt.
- Offen: Gerätetests der neuen Funktionen (siehe Morgen-Checkliste «Neu»), neuer TestFlight-Build nach Freigabe der Beta-Prüfung.

## Stand 12.11.2026
- Verschieben im Baukasten neu gebaut (SPEC 2 und 8b): Block halten und ziehen, die nächstgelegene Einfügestelle gilt, Balken zeigt sie an; in eine Runde hinein und heraus, ganze Runden verschiebbar, Nachscrollen am Rand. Pfeile gehen der Reihe nach durch Runden.
- Palette auf dem iPad schon ab 460 pt Breite rechts neben der Zeitleiste (iPad 11 Zoll hochkant mit Trainingsliste).
- Dunkelmodus: Markenfarbe hell (#EFEAEA), Hauptknöpfe mit dunkler Schrift (`Theme.onBrand`).
- Rückfragen (Fernbedienung erlauben, Import) in eigenem Fenster (`TopAlert`), eine einzige Vollbild-Darstellung an der Wurzel. Behebt: Willkommensbildschirm schloss sich bei einer Anfrage des iPhone von selbst, Training lief danach ohne sichtbare Laufansicht.
- Stimmenliste lädt im Hintergrund (`VoiceLibrary`), kein Hänger mehr beim ersten Start.
- Countdown-Töne entschärft (11.11.2026 abends, Build 202611112006).
- Tests: 92 Unit-Tests und 40 UI-Tests grün auf iPhone 18 Pro Max, iPad Pro 11 Zoll, iPad Pro 13 Zoll und iPhone Duo, 3 Tests auf der Uhr. Neu: `EditorDragTests` (19), `EditorDragUITests` (10, ziehen wirklich), `PromptOverCoverUITests` (2). Von Hand geprüft auf iPhone, iPad 11 Zoll und iPad 13 Zoll.
- Bekannt, kein App-Fehler: Im Gesamtschema `FitMitJodit` startet der Unit-Test-Teil auf dem Simulator manchmal nicht («test runner hung before establishing connection» oder «failed to launch»). Der Dienst für Kurzbefehle (`linkd`) startet die App nach der Installation oder nach dem Ende eines Laufs selbst im Hintergrund; kommt er `xcodebuild` zuvor, läuft die App ohne Testanbindung (Stichprobe: Haupt-Thread untätig, keine XCTest-Bibliothek geladen). Abhilfe: App im Simulator beenden (`xcrun simctl terminate <UDID> ch.fitmitjodit.timer`) und die Unit-Tests mit dem Schema `FitMitJoditUnit` wiederholen.

## Annahmen
- Interne Testgruppe mit Zugriff auf alle Builds, darum keine Zuweisung pro Build nötig.
- Release-Signierung manuell statt automatisch, weil die Schlüssel-Anmeldung von xcodebuild scheitert.
- Ohne Container: lokaler Speicher (SPEC: «Fällt iCloud aus … läuft die App mit lokalem Speicher weiter»).
- Marketing-URL: https://fitmitjodit.ch
- Hintergrund-Signale über den Audio-Hintergrundmodus mit stiller Spur während eines Trainings (Begründung im Bericht).
- Watch startet ein Training auf dem iPad, wenn das iPhone mit einem iPad verbunden ist und dort nichts anderes läuft, sonst auf dem iPhone.
