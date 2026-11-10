# Fit mit Jodit

iOS-App für iPad, iPhone und iPhone Duo mit Begleit-App für die Apple Watch: Intervall-Timer für Gruppentrainings von fitmitjodit. Trainings werden im Baukasten aus Bausteinen zusammengeklickt und in der Laufansicht gross angezeigt (Arbeit grün, Pause orange, Vorbereitung blau). Die App wird öffentlich im App Store veröffentlicht.

## Massgebend
- `docs/SPEC.md` ist die Vorgabe. Bei Widerspruch zwischen Code und SPEC gilt die SPEC.
- `docs/EINGABEN.md` enthält persönliche Werte. Lesen ja, committen nie.
- `docs/PROGRESS.md` hält den Stand fest: erledigt, offen, nächster Schritt, Annahmen.

## Regeln
1. Nach jeder Änderung bauen, vor jedem Commit die Tests laufen lassen.
2. Nie Schlüssel, .p8-Dateien oder `docs/EINGABEN.md` committen. Vor jedem Commit `git status` prüfen.
3. Keine Drittpakete in der App. fastlane ist nur Werkzeug.
4. Nie einen Test löschen, überspringen oder abschwächen, damit er grün wird.
5. Nichts zur Prüfung einreichen, nichts veröffentlichen.
6. Layout nur über Size Classes und verfügbare Fläche, nie über Gerätetyp oder feste Bildschirmmasse.
7. Texte immer in Deutsch und Englisch im String Catalog, Deutsch in Schweizer Schreibweise (ss statt ß).
8. Nichts als erledigt melden, was nicht in einem frischen Lauf gesehen wurde.

## Subagenten
- `swift-helfer` (Sonnet): klar abgegrenzte Umsetzungsaufgaben nach Vorgabe.
- `build-pruefer` (Sonnet): bauen, testen, nur Fehler in Kurzform melden.
Immer nur ein Subagent gleichzeitig, keine Worktrees, keine parallelen Builds.

## Befehle
Im Kettentest (10.11.2026) geprüft. Simulatoren über die UDID ansprechen, die Namen kommen mehrfach vor.
- Projekt neu erzeugen (nach neuen Targets/Einstellungen): `python3 Tools/gen_project.py`
- Build iPad: `xcodebuild build -project FitMitJodit.xcodeproj -scheme FitMitJodit -destination 'platform=iOS Simulator,id=C9B3BAD3-B150-4014-A87E-711D35799E4C' -derivedDataPath build/DerivedData -quiet` (iPad Pro 13-inch M5, iOS 27.2)
- Build iPhone: dasselbe mit `id=B4A2B008-6287-41D2-A41C-4D700BDFD6AC` (iPhone 18 Pro Max, iOS 27.2)
- Build iPhone Duo: dasselbe mit `id=DFA3DA79-4E7B-43EE-BBB4-EC32549F3781` (iPhone Duo, iOS 27.2)
- Build Apple Watch: `xcodebuild build -project FitMitJodit.xcodeproj -scheme FitMitJoditWatch -destination 'platform=watchOS Simulator,id=5379D419-6843-4225-8139-0EA0EF101E61' -derivedDataPath build/DerivedData -quiet` (Series 12 46 mm, watchOS 27.2, gepaart mit dem iPhone 18 Pro Max)
- Unit-Tests: `xcodebuild test -project FitMitJodit.xcodeproj -scheme FitMitJoditUnit -destination 'platform=iOS Simulator,id=B4A2B008-6287-41D2-A41C-4D700BDFD6AC' -derivedDataPath build/DerivedData -parallel-testing-enabled NO`
- UI-Tests: `xcodebuild test -project FitMitJodit.xcodeproj -scheme FitMitJodit -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath build/DerivedData -parallel-testing-enabled NO` (Schema FitMitJodit = Unit- und UI-Tests); Watch: Schema `FitMitJoditWatch` mit der Watch-UDID
- Archiv und Upload (fastlane): `fastlane ios beta` (setzt die Build-Nummer in `Config/Version.xcconfig`, Archiv und .ipa unter `build/`, wartet auf die Verarbeitung). Nur Archiv: `fastlane ios archive`. Zertifikat und Profile neu: `fastlane ios signing`
- Store-Texte und Screenshots (fastlane): `fastlane ios metadata` bzw. `fastlane ios metadata screenshots:true`; Rücklesen: `ruby Tools/readback.rb`
- API lesen/schreiben ohne fastlane: `ruby Tools/asc.rb GET /v1/...`

Hinweise:
- Release wird manuell signiert (Apple Distribution, Profile «ch.fitmitjodit.timer AppStore» und «…watchkitapp AppStore», erzeugt per API-Schlüssel). `xcodebuild -authenticationKey…` scheitert mit «Authentication failed», darum dieser Weg.
- fastlane braucht `LANG=en_US.UTF-8` (steht in `fastlane/.env`, die Datei ist lokal und nicht im Repository).
- iCloud/CloudKit ist über `Config/Base.xcconfig` schaltbar (siehe Kommentar dort).
