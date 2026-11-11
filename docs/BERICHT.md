# BERICHT: Fit mit Jodit, Nachtlauf 10./11.11.2026

## Kurzfassung
- **TestFlight:** Build **1.0 (202611110111)** verarbeitet, «In Beta-Test», ohne Compliance-Hinweis, Gruppe «Intern» (per API am 11.11.2026, 01:21 geprüft). Enthält iOS-App, Watch-App, Live-Activity-Widget, iCloud (Production-Profil mit Container und Push).
- **Store-Eintrag:** de-DE und en-US hochgeladen und zurückgelesen (alle Felder gleich), Screenshots iPhone 6,9" (4), iPad 13" (7, davon 2 quer), Apple Watch (3), je Sprache. Kategorie, Altersfreigabe, Preis gratis, 175 Länder per API.
- **Für dich offen:** App-Datenschutz «Veröffentlichen» (Einverständniserklärung), iCloud-Schema nach Production, Gerätetests. Siehe `docs/MORGEN-CHECKLISTE.md`, Abschnitt 5.

## Abnahme (frischer Lauf am 11.11.2026)
| # | Punkt | Stand | Beleg |
|---|---|---|---|
| 1 | Build ohne Warnungen, Unit- und UI-Tests grün für iPad, iPhone, iPhone Duo, beide Sprachen | **teilweise** | Build ohne Compiler-Warnungen (iOS, Watch, Widget). Unit-Tests 44/44 grün. UI-Tests: iPhone 18 Pro Max (de) alle grün, iPhone Duo (de+en) alle grün, Apple Watch grün. iPhone (en) alle grün. iPad (de+en): 15 von 17 grün, Unit-Tests 44/44. **Offen:** Bedienungshilfen-Audit auf dem iPad meldet «Dynamic Type teilweise nicht unterstützt» für eine Blockkachel im Baukasten (auf iPhone und Duo grün). Nicht abgeschwächt, Ursache nicht gefunden. |
| 2 | «3 × 45 s mit 15 s Pause, 1 min Pause, mal 4» in unter einer Minute, ohne Zeitabweichung | erfüllt | UI-Test `testBuildCircuitFromBlocks` (36–56 s inkl. Teststart) auf iPhone, iPad, Duo; Unit-Tests `testBuildCircuitFromBlocks` (Gesamtdauer 14:00) und `testSixtyMinutesWithoutDrift` (Abweichung < 1 µs) |
| 3 | Pausen orange, Arbeit grün, Vorbereitung blau, jeweils mit Text | erfüllt | Theme (Kontrast zu Weiss ≥ 5:1), Screenshots 03/04, UI-Test prüft Titel «Arbeit»/«Work» |
| 4 | Töne, Halbzeit, Ansagen funktionieren, abschaltbar, Ansagen standardmässig aus, auch ohne Übungsnamen | im Simulator teilweise | Unit-Tests Signalplan (Zeitpunkte, Abschalten, Ansagetexte mit/ohne Namen, «Letzte Runde», kein gesprochener Countdown); UI-Test `testSignalsOnOff` (Ansagen standardmässig aus). Hörbarkeit und Ducking: **Gerätetest** |
| 5 | Laufansicht lesbar bei 1/3, 1/2, voller Breite (iPad) und auf dem Duo auf/zu | erfüllt (Simulator) | UI-Test `testRunViewReadableAtThirdHalfAndFullWidth` auf iPad und Duo; Screenshot 05 (schmal neben Musik-App). Auf-/Zuklappen: **Gerätetest** |
| 6 | Live Activity zeigt Countdown und Blockname | im Simulator nicht prüfbar | Widget gebaut und im Build enthalten; Sperrbildschirm: **Gerätetest** |
| 7 | Export und Import einer Trainingsdatei | erfüllt | Unit-Tests `ExportImportTests` (hin und zurück, fremde Dateien abgelehnt); UI-Test `testExport` (Teilen-Blatt). AirDrop: **Gerätetest** |
| 8 | Alle Texte auf Deutsch und Englisch | erfüllt | Unit-Test `testEveryStringHasEnglishTranslation` (Katalog vollständig), UI-Tests in beiden Sprachen |
| 9 | Archiv und .ipa unter `build/` | erfüllt | `build/FitMitJodit.xcarchive`, `build/FitMitJodit.ipa` (Build 202611110111) |
| 10 | Build 1.0 in TestFlight grün | erfüllt | API: processingState VALID, internalBuildState IN_BETA_TESTING, usesNonExemptEncryption false, Gruppe «Intern» |
| 11 | Store-Eintrag de-DE/en-US, Screenshots iPhone und iPad beide Sprachen | erfüllt | `ruby Tools/readback.rb`: alle Felder gleich; API: Screenshot-Sets APP_IPHONE_67 (4), APP_IPAD_PRO_3GEN_129 (7), APP_WATCH_SERIES_10 (3) je Sprache |
| 12 | Watch zeigt Training, schaltet automatisch weiter, steuert iPhone und iPad | im Simulator teilweise | Unit-Tests `WatchSyncTests` (Uhr rechnet aus Zeitstempel denselben Zustand, Nachrichten, Haptik-Plan); Watch-UI-Tests (Ruhezustand, Liste, Laufansicht). Echte Verbindung Uhr–iPhone–iPad: **Gerätetest** |
| 13 | Datenschutz-Seite erreichbar, Issues offen, URLs im Store-Eintrag | erfüllt | `docs/Privacy.md` auf main, Repository öffentlich mit Issues, URLs zurückgelesen |
| 14 | GitHub-Actions-Lauf auf dem Pull Request grün | erfüllt | Lauf 42930655752 (Xcode 26.6, Unit-Tests iPhone-Simulator, Watch-Build) grün, Pull Request PhilippeSch/fit-mit-jodit#1 |


## Was gebaut wurde
- **iOS-App** (iPhone, iPad, iPhone Duo; iOS 17.0+) mit Bibliothek, Baukasten, Laufansicht, Signalen, Live Activity, Spotify-Link, Export/Import, Weiterleitung zum iPad.
- **Watch-App** (watchOS 10.0+, Companion): Fernbedienung mit eigenem Countdown aus dem Zeitstempel, Haptik bei Blockwechsel und in den letzten 3 Sekunden, Trainingsliste zum Starten, Musikseite (`NowPlayingView`).
- **Widget-Erweiterung** für die Live Activity (Sperrbildschirm, Dynamic Island), Countdown rendert das System (`Text(timerInterval:)`).
- **Gemeinsamer Code** (`Shared/`): Datenmodell, Runden-Auflösung, Timer-Engine, Signalplan, Nachrichtenformat, Haptik-Plan, Theme, Übungsliste, String Catalog.
- **Werkzeuge:** `Tools/gen_project.py` erzeugt das Xcode-Projekt (synchronisierte Ordner), `Tools/asc.rb` spricht die App-Store-Connect-API, `Tools/readback.rb` vergleicht die Store-Texte, fastlane-Lanes `signing`, `archive`, `beta`, `metadata`.

## Hintergrund-Signale: gewählte Lösung, Begründung, Restrisiko
**Lösung:** Während eines laufenden Trainings hält die App eine Audiositzung (`UIBackgroundModes: audio`, Kategorie `.playback` mit `.mixWithOthers`) mit einer stillen Spur aktiv. Dadurch läuft die App weiter, wenn Spotify im Vordergrund ist, und spielt ihre Töne und Ansagen pünktlich. Für jeden Ton wird die Sitzung kurz mit `.duckOthers` aktiviert (Spotify wird leiser) und danach ohne Ducking neu aktiviert (Musik wieder laut). Nach dem Training wird die Sitzung beendet (`notifyOthersOnDeactivation`). Die Uhrzeit kommt immer aus Zeitstempeln; nach der Rückkehr aus dem Hintergrund stimmt die Anzeige sofort, verpasste Signale werden nicht als Lawine nachgeholt (nur das letzte Fenster von 1.5 s).

**Begründung:** Lokale Mitteilungen mit Ton sind nicht sekundengenau, verlangen eine Erlaubnis und erscheinen als Banner; Halbzeit- und 3-2-1-Töne wären so nicht machbar. Der Audio-Hintergrundmodus ist für Apps vorgesehen, die hörbare Inhalte abspielen – das tut der Timer während des ganzen Trainings (Töne, Ansagen). Die stille Spur dient nur dazu, zwischen den Tönen die Sitzung offen zu halten; sie läuft nur während eines Trainings und endet mit ihm.

**Restrisiko:** Apples Prüfung (Richtlinie 2.5.4) kann den Audio-Hintergrundmodus beanstanden, wenn sie ihn als «nur um wach zu bleiben» einstuft. In den Prüfer-Hinweisen steht, dass die App während eines Trainings im Hintergrund hörbare Intervall-Signale abspielt. Falls Apple ablehnt: Ausweg wäre, Signale im Hintergrund über zeitgesteuerte Mitteilungen mit eigenem Ton zu planen (ungenauer, mit Erlaubnis-Dialog). Ducking und Hintergrund lassen sich im Simulator nicht prüfen → Gerätetest.

## Weiterleitung Uhr → iPhone → iPad
Uhr ↔ iPhone über WatchConnectivity, iPhone ↔ iPad über MultipeerConnectivity (verschlüsselt, nur lokales Netz, Bonjour-Dienst `_fmj-remote._tcp`). Erste Kopplung muss auf dem iPad bestätigt werden, danach automatisch. Das iPad schickt bei jedem Blockwechsel, Pause und Sprung seinen Zustand (Timer-Engine mit Zeitstempeln), die Uhr rechnet selbst weiter.
**Restrisiko:** iOS hält MultipeerConnectivity nur, solange die App auf dem iPhone im Vordergrund ist. Darum gibt es auf dem iPhone die Ansicht «iPad steuern», die den Bildschirm wach hält. Mit gesperrtem iPhone reisst die Verbindung ab – nur auf echten Geräten prüfbar.

## Musik
Spotify wird nur verlinkt (Anleitung «iOS Content Linking»: `spotify.link/content_linking` mit `~campaign` = Bundle-ID, `canOpenURL("spotify:")`, sonst Browser bzw. App Store). Keine Steuerung von Spotify aus der App. Auf der Uhr steuert die System-Ansicht `NowPlayingView` die Musik des iPhone (auch Spotify). Auf dem iPad gibt es keine öffentliche Schnittstelle, um die Musik einer anderen App zu steuern.

## iPhone Duo
Gelesen: Apples Tech Talks «Prepare your app for iPhone Duo» und «Strike a pose with adaptive layouts on iPhone Duo», Forum-Zusammenfassung, und die SDK-Header (iOS 27.2): `ReservedRegion` mit Art `.division` (der Falz) und `GeometryProxy.reservedRegions(kind:)`, verfügbar ab iOS 27.1. Umsetzung: Layout über Size Classes und verfügbare Fläche; wo ein aktiver Falz die Ansicht senkrecht teilt, legen Laufansicht (links Blockname/Info, rechts Countdown und Knöpfe) und Baukasten (links Zeitleiste, rechts Palette) ihren Inhalt links und rechts davon ab. Alles hinter `if #available(iOS 27.1, *)`; ab iOS 17 sonst unverändert.
**Restrisiko:** Im Simulator war der Falz nur über das Gerät «iPhone Duo» prüfbar; Auf- und Zuklappen während eines Trainings ist ein Gerätetest.

## Getroffene Annahmen
- Release-Builds werden manuell signiert (Apple Distribution, Profile per API-Schlüssel), weil `xcodebuild -authenticationKey…` mit «Authentication failed» scheitert und Xcode anfangs kein Konto hatte.
- Build-Nummer als Zeitstempel `YYYYMMDDHHMM` (wie in den anderen Projekten), gesetzt von `fastlane ios bump`.
- Interne Testgruppe «Intern» mit Zugriff auf alle Builds; Philippe als interner Tester eingetragen.
- Altersfreigabe: «Gesundheits- oder Wellness-Themen» = ja (Fitness-App), alles andere nein/keine.
- Marketing-URL: https://fitmitjodit.ch. Support: GitHub Issues. Datenschutz: `docs/Privacy.md` (wie CyclePulse).
- Markenfarbe aus fitmitjodit.ch abgeleitet (Website ist grau/neutral): #5E5858 hell, #D6D0D0 dunkel. Schrift Raleway (SIL OFL, von Google Fonts, Lizenz unter `FitMitJodit/Fonts/`).
- Die Watch startet ein Training auf dem iPad, wenn das iPhone mit einem iPad verbunden ist und dort nichts anderes läuft, sonst auf dem iPhone.
- iCloud-Container im Browser angelegt (Freigabe von Philippe), CloudKit eingeschaltet. Production-Schema nicht von Hand angelegt (nicht rückgängig zu machen) → Morgen-Checkliste.
- App-Datenschutz: Antwort gesichert, aber «Veröffentlichen» nicht bestätigt (Einverständniserklärung).
- Store-Screenshot-Tests wurden im Schlusslauf nicht wiederholt; sie liefen um 00:17–00:30 grün und die Bilder sind hochgeladen.

## Nicht hochgeladen / Befehle
Alles ist hochgeladen. Für spätere Builds: `fastlane ios beta` (neuer Zeitstempel, Upload, wartet auf Verarbeitung), Texte/Screenshots: `fastlane ios metadata screenshots:true`, Screenshots neu: siehe `CLAUDE.md`.

## Während der Nacht gefundene und behobene Fehler
- Testdaten landeten im echten App-Speicher (SwiftData-Speicher im Arbeitsspeicher ohne eigenen Namen).
- Laufansicht für VoiceOver ein einziges Element; Knöpfe jetzt bei VoiceOver immer sichtbar.
- «mal N», «Fertig» und «+» lagen auf dem iPhone ausserhalb des Bildschirms; «Starten» verschwand bei schmaler Breite im Überlaufmenü.
- Fliesslayout brach auf dem iPad wegen eines Rundungsfehlers jeden Block in eine eigene Zeile um.
- Watch-App stürzte mit laufendem Training ab (Toolbar in vertikalen Seiten); Stopp war auf der Uhr nicht erreichbar.
- Audiositzung wurde auf dem Haupt-Thread aktiviert.
- Zeitstempel wurden beim Austausch iPhone↔Uhr auf ganze Sekunden gerundet.
- Querformat-Screenshots hatten falsche Pixelmasse (EXIF-Drehung).

