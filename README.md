# Fit mit Jodit

Intervall-Timer für Gruppen- und Heimtraining, entwickelt für die Kurse von [fitmitjodit](https://fitmitjodit.ch). Für iPhone, iPad, iPhone Duo und Apple Watch.

## Funktionen
- **Baukasten:** Trainings aus Bausteinen zusammenklicken (z. B. 45 s Arbeit, 15 s Pause, 1 min Pause). Blöcke markieren und «mal N» macht daraus eine Runde. Übungsnamen sind freiwillig, aus einer Liste mit 70 Übungen (davon 10 Dehnübungen) oder selbst eingetippt.
- **Laufansicht:** Grosser Countdown, aus mehreren Metern lesbar. Arbeit grün, Pause orange, Vorbereitung blau, jeweils mit Text. Bedienung mit einem Tipp: Pause, Block vor/zurück, Stopp. Sperre gegen versehentliches Tippen. Beendet iOS die App im Hintergrund, läuft das Training beim Öffnen an der richtigen Stelle weiter.
- **Signale:** Töne in den letzten 3 Sekunden und zur Halbzeit, drei Ton-Sets (synthetisch erzeugt). Musik anderer Apps wird während der Töne kurz leiser.
- **Ansagen:** «Automatisch» sagt Trainings mit Übungsnamen an, mit Dauer, «Bereit machen» und «Noch 10 Sekunden». Trainings ohne Namen bleiben bei den Tönen.
- **Vorlagen:** Zirkel 45/15, Tabata, Kraft, Warm-up, Pyramide sowie mit Übungsnamen Ganzkörper 20, Bauch & Rumpf 10, Beine & Po 15, Cardio 12, Oberkörper 12, EMOM 12 und Dehnen 10.
- **Apple Watch:** Fernbedienung für das Training auf dem iPhone oder, über das iPhone, auf dem iPad. Vibriert beim Blockwechsel, auch mit gesenktem Arm, und steuert die Musik des iPhone.
- **Live Activity:** Countdown und Blockname auf Sperrbildschirm und Dynamic Island.
- **Spotify:** Pro Training ein Link, der die Playlist in Spotify öffnet. Auf dem iPad passt Spotify im geteilten Bildschirm daneben.
- **Sync und Teilen:** iCloud-Sync über die private Datenbank des Nutzers, Export einzelner Trainings als Datei, QR-Code zum Weitergeben an Teilnehmende (ohne Server).
- **Verlauf:** Absolvierte Trainings mit Wochenübersicht.
- **Siri und Kurzbefehle:** «Starte Tabata mit Fit mit Jodit», Pause/Weiter, nächster Block, beenden.
- **Sprachen:** Deutsch und Englisch.

Kein Konto, keine Werbung von Dritten, keine Datenerhebung. Siehe [Datenschutz](docs/Privacy.md).

## Technik
- Swift und SwiftUI, iOS/iPadOS 17.0+, watchOS 10.0+, keine Drittpakete.
- SwiftData mit CloudKit, ActivityKit, App Intents, WatchConnectivity, MultipeerConnectivity, AVFoundation.
- Der Timer rechnet mit Zeitstempeln statt gezählten Ticks.

## Projektaufbau
| Ordner | Inhalt |
|---|---|
| `FitMitJodit/` | iOS-App |
| `FitMitJoditWatch/` | Watch-App |
| `FitMitJoditWidgets/` | Live Activity |
| `Shared/` | Gemeinsamer Code: Datenmodell, Timer, Signale, Texte |
| `FitMitJoditTests/`, `FitMitJoditUITests/`, `FitMitJoditWatchUITests/` | Unit- und UI-Tests |
| `Config/` | Team, Bundle-ID, Version, CloudKit-Schema |
| `Tools/` | Projektgenerator und Hilfsskripte |
| `fastlane/` | Upload nach TestFlight, Store-Texte |
| `docs/` | Vorgabe, Datenschutz, Projektnotizen |

Das Xcode-Projekt wird aus `Tools/gen_project.py` erzeugt. Build- und Testbefehle stehen in `CLAUDE.md`.

## Support
Fragen und Fehler bitte als [Issue](https://github.com/PhilippeSch/fit-mit-jodit/issues) melden.
