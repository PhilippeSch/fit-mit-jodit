# Fit mit Jodit

iOS-App für iPad, iPhone und iPhone Duo mit Begleit-App für die Apple Watch: Intervall-Timer für Gruppentrainings von fitmitjodit. Trainings werden im Baukasten aus Bausteinen zusammengeklickt und in der Laufansicht gross angezeigt (Arbeit grün, Pause orange, Vorbereitung blau). Die App wird öffentlich im App Store veröffentlicht.

## Massgebend
- `docs/SPEC.md` ist die Vorgabe. Bei Widerspruch zwischen Code und SPEC gilt die SPEC.
- `docs/EINGABEN.md` enthält persönliche Werte. Lesen ja, committen nie.
- `docs/PROGRESS.md` hält den Stand fest: erledigt, offen, nächster Schritt, Annahmen.
- `docs/UEBERGABE.md` erklärt, wie man weiterarbeitet: Abläufe (Testbuild, PR, Merge), Philippes Vorlieben, lokale Voraussetzungen, Stolpersteine. Wer ohne Chat-Verlauf einsteigt, liest das zuerst.
- Das Repository ist öffentlich.

## Regeln
1. Nach jeder Änderung bauen, vor jedem Commit die Tests laufen lassen.
2. Nie Schlüssel, .p8-Dateien oder `docs/EINGABEN.md` committen. Vor jedem Commit `git status` prüfen.
3. Keine Drittpakete in der App. fastlane ist nur Werkzeug.
4. Nie einen Test löschen, überspringen oder abschwächen, damit er grün wird.
5. Nichts zur Prüfung einreichen, nichts veröffentlichen. Testbuilds nach TestFlight nur auf Philippes Auftrag; «in beide Gruppen» schliesst die Beta-Prüfung für die externe Testgruppe ein (das ist nicht die Prüfung für den App Store).
6. Layout nur über Size Classes und verfügbare Fläche, nie über Gerätetyp oder feste Bildschirmmasse.
7. Texte immer in Deutsch und Englisch im String Catalog, Deutsch in Schweizer Schreibweise (ss statt ß).
8. Nichts als erledigt melden, was nicht in einem frischen Lauf gesehen wurde.
9. Bedienung von Hand prüfen, bevor sie als erledigt gilt: im Simulator wirklich halten, ziehen, wischen und antippen (auch ungenau, wie ein Mensch), auf iPhone und iPad 11 Zoll. UI-Tests müssen die Geste selbst ausführen (z. B. `press(forDuration:thenDragTo:)`), nicht nur einen Ersatzknopf drücken.
10. Antworten, Commits, PRs und Doku auf Deutsch in Schweizer Schreibweise. Stehen Varianten zur Wahl, als Klickfrage mit wenigen Antworten stellen, die empfohlene zuerst. Mehrdeutige Aufträge mit Aussenwirkung (hochladen, einreichen, mergen) klären statt raten.
11. Gearbeitet wird auf `dev`, `main` bekommt Änderungen nur über Pull Requests. Die Version bleibt 1.0 bis zum Livegang: keine Versionsnummern in Branch-, Tag- oder PR-Namen.
12. Zu Beginn jeder Sitzung `git fetch` (Cloud-Sitzungen pushen Commits und `claude/...`-Branches). Sauberer Baum und nur im Rückstand: `git pull --ff-only`. Sonst melden und fragen, nicht selbst mergen.
13. Commits und PRs ohne KI-Hinweise (kein «Co-Authored-By», kein «Generated with»), mit Philippes GitHub-noreply-Adresse (steht in `git log`). Nach einem Upload `Config/Version.xcconfig` als eigener, letzter Commit `update build number`, dann pushen.
14. Wissen gehört ins Repository, nicht nur in den Chat: nach jedem Arbeitsblock `docs/PROGRESS.md` nachführen; geänderte Abläufe, neue Vorlieben und Stolpersteine in `docs/UEBERGABE.md`. Skripte, die man wieder braucht, nach `Tools/` (der Ordner `build/` ist ignoriert).
15. Standard am Ende eines Arbeitsblocks, ohne Rückfrage (Philippe, 12.11.2026): Ist die Arbeit auf `dev` gepusht und lokal geprüft, einen PR nach `main` öffnen und Auto-Merge einschalten. GitHub mergt, sobald die CI grün ist. Nie an der Regel vorbei mergen (`--admin`); schlägt die CI fehl, beheben oder melden.
16. Klang lässt sich im Simulator nicht prüfen: Hörproben rendern (`Tools/hoerprobe.sh`), Philippe schicken und wählen lassen.

## Subagenten
- `swift-helfer` (Sonnet): klar abgegrenzte Umsetzungsaufgaben nach Vorgabe.
- `build-pruefer` (Sonnet): bauen, testen, nur Fehler in Kurzform melden.
Immer nur ein Subagent gleichzeitig, keine Worktrees, keine parallelen Builds.

## Befehle
Im Kettentest (10.11.2026) geprüft. Simulatoren über die UDID ansprechen, die Namen kommen mehrfach vor.
- Projekt neu erzeugen (nach neuen Targets/Einstellungen): `python3 Tools/gen_project.py`
- Build iPad: `xcodebuild build -project FitMitJodit.xcodeproj -scheme FitMitJodit -destination 'platform=iOS Simulator,id=C9B3BAD3-B150-4014-A87E-711D35799E4C' -derivedDataPath build/DerivedData -quiet` (iPad Pro 13-inch M5, iOS 27.2)
- Build iPad 11 Zoll: dasselbe mit `id=9E8A5E38-0E9B-443D-B5EF-7F76E08997EB` (iPad Pro 11-inch M5, iOS 27.2). Das häufigere iPad-Format: Layout und Bedienung des Baukastens auch dort prüfen, nicht nur auf 13 Zoll.
- Build iPhone: dasselbe mit `id=B4A2B008-6287-41D2-A41C-4D700BDFD6AC` (iPhone 18 Pro Max, iOS 27.2)
- Build iPhone Duo: dasselbe mit `id=DFA3DA79-4E7B-43EE-BBB4-EC32549F3781` (iPhone Duo, iOS 27.2)
- Build Apple Watch: `xcodebuild build -project FitMitJodit.xcodeproj -scheme FitMitJoditWatch -destination 'platform=watchOS Simulator,id=5379D419-6843-4225-8139-0EA0EF101E61' -derivedDataPath build/DerivedData -quiet` (Series 12 46 mm, watchOS 27.2, gepaart mit dem iPhone 18 Pro Max)
- Unit-Tests: `xcodebuild test -project FitMitJodit.xcodeproj -scheme FitMitJoditUnit -destination 'platform=iOS Simulator,id=B4A2B008-6287-41D2-A41C-4D700BDFD6AC' -derivedDataPath build/DerivedData -parallel-testing-enabled NO`
- UI-Tests: `xcodebuild test -project FitMitJodit.xcodeproj -scheme FitMitJodit -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath build/DerivedData -parallel-testing-enabled NO` (Schema FitMitJodit = Unit- und UI-Tests); Watch: Schema `FitMitJoditWatch` mit der Watch-UDID
- Archiv und Upload (fastlane): `fastlane ios beta` (setzt die Build-Nummer in `Config/Version.xcconfig`, Archiv und .ipa unter `build/`, wartet auf die Verarbeitung). Nur Archiv: `fastlane ios archive`. Zertifikat und Profile neu: `fastlane ios signing`
- Store-Texte und Screenshots (fastlane): `fastlane ios metadata` bzw. `fastlane ios metadata screenshots:true`; Rücklesen: `ruby Tools/readback.rb`
- API lesen/schreiben ohne fastlane: `ruby Tools/asc.rb GET /v1/...`
- Prüflauf in einem Befehl: `Tools/pruefen.sh` (schnell: Unit-Tests iPhone und iPad 11 Zoll, Watch-Build), `Tools/pruefen.sh voll` (alle Geräte mit UI-Tests, rund 1.5 Stunden), einzelne Schritte z. B. `Tools/pruefen.sh ui:iphone ui:ipad11`. Logs unter `build/logs/pruefen-*.log`.
- Nach dem Upload (Testtexte, Gruppe «Jodit», Beta-Prüfung): `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 ruby Tools/after_upload.rb --dry`, dann ohne `--dry`.
- Hörproben der Ton-Sets: `Tools/hoerprobe.sh` (Varianten des Halls: `HALL="0.5 1.5" Tools/hoerprobe.sh`), Ergebnis unter `build/hoerprobe/`.
- Pull Request und Merge: `gh pr create --base main --head dev`, dann `gh pr merge <Nummer> --merge --auto` (wartet auf die CI, mit Merge-Commit, nie Squash).

Hinweise:
- Release wird manuell signiert (Apple Distribution, Profile «ch.fitmitjodit.timer AppStore» und «…watchkitapp AppStore», erzeugt per API-Schlüssel). `xcodebuild -authenticationKey…` scheitert mit «Authentication failed», darum dieser Weg.
- fastlane braucht `LANG=en_US.UTF-8` (steht in `fastlane/.env`, die Datei ist lokal und nicht im Repository).
- iCloud/CloudKit ist über `Config/Base.xcconfig` schaltbar (siehe Kommentar dort).
- Meldet ein Testlauf «test runner hung before establishing connection» oder «failed to launch», ohne dass ein Test fehlschlägt: Der Kurzbefehl-Dienst des Simulators hat die App selbst gestartet und ist `xcodebuild` zuvorgekommen. App beenden (`xcrun simctl terminate <UDID> ch.fitmitjodit.timer`) und die Unit-Tests mit dem Schema `FitMitJoditUnit` wiederholen. Der Lauf zählt erst, wenn die Unit-Tests wirklich gelaufen sind.
- Die UDIDs oben gelten für Philippes Mac. Auf einem anderen Mac mit `xcrun simctl list devices` nachsehen und hier sowie in `Tools/pruefen.sh` anpassen.
- `main` ist geschützt: Der CI-Check `build-and-test` muss grün sein. Die CI läuft nur bei Pull Requests und baut mit Xcode 26.6.
