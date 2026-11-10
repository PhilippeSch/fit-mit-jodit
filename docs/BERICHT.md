# BERICHT: Fit mit Jodit, Nachtlauf 10./11.11.2026

<!-- ABNAHME -->

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

<!-- ANNAHMEN -->
