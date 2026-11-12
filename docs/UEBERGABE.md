# Übergabe: so arbeitest du an «Fit mit Jodit» weiter

Für alle, die neu einsteigen: ein Mensch, ein anderes Claude-Konto oder eine neue Sitzung ohne den bisherigen Chat-Verlauf. Dieses Dokument und die Dateien, auf die es verweist, reichen aus. Der Chat-Verlauf früherer Sitzungen ist nicht nötig.

Das Repository ist **öffentlich**. Persönliche Werte, Schlüssel und Telefonnummern gehören nie hinein (siehe Abschnitt 7).

## 1. In fünf Minuten

- **Was:** Intervall-Timer für iPhone, iPad, iPhone Duo und Apple Watch, gebaut für die Kurse von fitmitjodit. Trainings werden im Baukasten zusammengeklickt und in der Laufansicht gross angezeigt.
- **Wer:** Philippe entwickelt, besitzt das Apple- und das GitHub-Konto und entscheidet. Jodit ist die Trainerin, für ihre Kurse ist die App gedacht; sie testet über TestFlight.
- **Wo es steht:** Die App ist in TestFlight bei zwei Testgruppen. Im App Store ist sie noch nicht, und es ist nichts zur Prüfung für den Store eingereicht. Den Tagesstand führt `docs/PROGRESS.md` ganz oben.
- **Lesereihenfolge:** `CLAUDE.md` (Regeln und Befehle), dann `docs/SPEC.md` (Vorgabe), dann `docs/PROGRESS.md` (Stand), dann dieses Dokument.

## 2. Wo was steht

| Datei | Inhalt | Pflege |
|---|---|---|
| `CLAUDE.md` | Regeln, Befehle, Hinweise | Bei neuen Regeln und Befehlen ergänzen |
| `docs/SPEC.md` | Die Vorgabe. Bei Widerspruch zum Code gilt sie | Jede gewünschte Änderung zuerst hier festhalten (mit Datum) |
| `docs/PROGRESS.md` | Aktueller Stand, Offenes, nächster Schritt, Verlauf | Nach jedem Arbeitsblock nachführen |
| `docs/UEBERGABE.md` | Dieses Dokument: Abläufe, Vorlieben, Stolpersteine | Wenn sich ein Ablauf ändert oder etwas Neues gelernt wurde |
| `docs/MORGEN-CHECKLISTE.md` | Was Philippe und Jodit auf echten Geräten prüfen, Schritte bis zum Einreichen | Neue Prüfpunkte unter «Neu (Datum)» |
| `docs/BERICHT.md` | Bericht zum ersten Bau (10./11.11.2026): Lösungen, Begründungen, Restrisiken | Nur lesen |
| `docs/Privacy.md` | Datenschutzerklärung (öffentlich verlinkt) | Bei Änderungen am Datenumgang |
| `docs/EINGABEN.md` | Persönliche Werte. Nur lokal, nie committen | Philippe |
| `README.md` | Öffentliche Beschreibung der App | Bei neuen Funktionen |
| `fastlane/testflight/whats_new-*.txt` | «Was zu testen ist» für die Tester, Deutsch und Englisch | Vor jedem Upload |
| `fastlane/metadata/` | Store-Texte | Bei Änderungen, dann `fastlane ios metadata` |
| `Tools/` | Projektgenerator und Hilfsskripte (Abschnitt 4) | |

## 3. So wünscht Philippe die Zusammenarbeit

Diese Punkte stammen aus seinen Rückmeldungen. Sie stehen als Regeln auch in `CLAUDE.md`.

1. **Deutsch, Schweizer Schreibweise** (ss statt ß, «Anführungszeichen»). Auch Commit-Texte, PR-Texte und Doku.
2. **Auswahl als Klickfragen:** Stehen Varianten zur Wahl, die Frage mit wenigen anklickbaren Antworten stellen, die empfohlene zuerst.
3. **Mehrdeutiges klären, nicht raten,** sobald etwas nach aussen wirkt (hochladen, einreichen, veröffentlichen, mergen). Beispiel: «neu veröffentlichen» wurde nachgefragt und hiess am Ende «nichts weiter».
4. **Bedienung von Hand prüfen, wie ein normaler Mensch.** Philippe war zu Recht skeptisch, als das Verschieben im Baukasten nur mit «Roboter-Tests» geprüft war. Seither gilt: im Simulator wirklich halten, ziehen, wischen, ungenau tippen, auf dem iPhone und auf dem **iPad 11 Zoll** (das häufigere Format, nicht nur 13 Zoll). UI-Tests müssen die Geste selbst ausführen.
5. **Ehrlich berichten:** sagen, was in einem frischen Lauf gesehen wurde, und ebenso, was nicht geprüft ist. Klang und echte Geräte lassen sich hier nicht prüfen, das gehört in jeden Bericht.
6. **Klang wählt Philippe mit dem Ohr:** Hörproben rendern und schicken, Varianten zur Wahl stellen (Abschnitt 9).
7. **Alles Wichtige ins Repository,** nichts nur im Chat lassen. Ein anderes Konto muss jederzeit weiterarbeiten können.

## 4. Vom Auftrag zum Testbuild

1. **Vorgabe:** Die gewünschte Änderung in `docs/SPEC.md` festhalten (Abschnitt «Ergänzungen» mit Datum), dann umsetzen.
2. **Bauen und testen:** nach jeder Änderung bauen. Vor jedem Commit `Tools/pruefen.sh` (schnell, rund 4 Minuten). Nach Änderungen an Bedienung oder Layout zusätzlich die UI-Tests der betroffenen Geräte, z. B. `Tools/pruefen.sh ui:iphone ui:ipad11`. Vor einem Upload nach grösseren Änderungen `Tools/pruefen.sh voll` (rund 1.5 Stunden). Lange Läufe im Hintergrund starten.
3. **Von Hand prüfen** (Regel 9 in `CLAUDE.md`).
4. **Doku:** `docs/PROGRESS.md` nachführen, Prüfpunkte für echte Geräte in die Checkliste, Texte für die Tester in `fastlane/testflight/whats_new-*.txt` (neue Punkte mit «(neu in diesem Build)», ältere Markierungen dabei auf ein Datum umstellen, höchstens 4000 Zeichen).
5. **Commit auf `dev`** und pushen (Abschnitt 5).
6. **Upload,** nur wenn Philippe ihn verlangt:
   ```
   LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 fastlane ios beta > build/logs/beta-$(date +%Y%m%d-%H%M).log 2>&1
   ```
   Setzt die Build-Nummer (Zeitstempel JJJJMMTTHHMM), archiviert, lädt hoch und wartet auf die Verarbeitung durch Apple (5 bis 20 Minuten, im Hintergrund starten).
7. **Nach dem Upload:**
   ```
   LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 ruby Tools/after_upload.rb --dry
   LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 ruby Tools/after_upload.rb
   ```
   Setzt die Testtexte in beiden Sprachen, weist den Build der externen Gruppe «Jodit» zu und reicht ihn zur Beta-Prüfung ein. Danach den Stand zurücklesen (das Skript noch einmal mit `--dry`).
8. **Build-Nummer committen:** `Config/Version.xcconfig` als eigener, letzter Commit mit dem Text `update build number`, dann pushen.
9. **PR von `dev` nach `main`,** wenn Philippe es verlangt (Abschnitt 5).

## 5. Git und GitHub

- **Branches:** Gearbeitet wird auf `dev`. `main` ist der Standardbranch und bekommt Änderungen nur über Pull Requests. `dev` wird nie gelöscht.
- **Version:** bleibt 1.0 bis zum Livegang. Keine Versionsnummern in Branch-, Tag- oder PR-Namen.
- **Zu Beginn jeder Sitzung** `git fetch` und nachsehen, was sich geändert hat. Philippe arbeitet auch in Cloud-Sitzungen, die Commits und Branches (`claude/...`) pushen, ohne dass dieser Mac es weiss. Ist der Arbeitsbaum sauber und der Branch nur im Rückstand: `git pull --ff-only`. Bei Abweichungen oder offenen Änderungen nicht selbst mergen, sondern melden und fragen.
- **Commits:** deutsche, sprechende Texte. Keine KI-Hinweise in Commits und PRs (kein «Co-Authored-By», kein «Generated with»). Als Absender Philippes GitHub-noreply-Adresse (steht in `git log`), nie eine private Adresse; vor dem ersten Commit `git config user.email` prüfen. Vor jedem Commit `git status` ansehen: keine Schlüssel, kein `docs/EINGABEN.md`.
- **Pull Request:** `gh pr create --base main --head dev`, Text auf Deutsch mit «Was ändert sich», «Geprüft», «Nicht geprüft».
- **CI:** `.github/workflows/ci.yml`, Job `build-and-test`, läuft nur bei Pull Requests und von Hand (macOS-Läufe sind teuer), rund 10 Minuten. Die CI baut mit Xcode 26.6, lokal ist Xcode 27.2: Der Code muss mit beiden bauen.
- **Regel für `main`** (seit 12.11.2026): Der Check `build-and-test` muss grün sein, bevor gemergt werden kann. Kein Review nötig. Der Branch muss dabei nicht auf dem neuesten Stand von `main` sein (`dev` enthält die Merge-Commits von `main` nicht, das ist in Ordnung).
- **Mergen:** mit Merge-Commit, nicht mit Squash (sonst laufen `dev` und `main` auseinander). Auto-Merge ist erlaubt und erledigt das Warten auf die CI:
  ```
  gh pr merge <Nummer> --merge --auto
  ```
  Nur mergen, wenn Philippe es verlangt. `gh pr merge --admin` umgeht die Regel und ist für Notfälle, nur auf seinen ausdrücklichen Wunsch.
- **Stand der Einrichtung:** Regel und Auto-Merge sind am 12.11.2026 eingerichtet und zurückgelesen. Die PRs 1 bis 5 wurden noch ohne diese Regel gemergt. PR 6 war der erste mit Regel und Auto-Merge: Solange der Check lief, war der PR gesperrt (`gh pr view <Nummer> --json mergeStateStatus` zeigt dann `BLOCKED`).

## 6. TestFlight und App Store Connect

- **App:** Bundle-ID `ch.fitmitjodit.timer`, dazu `.watchkitapp` und `.widgets`.
- **Gruppen:** «Intern» (interne Tester, bekommt jeden Build von selbst) und «Jodit» (externe Tester, braucht je Build die Zuweisung und die Beta-Prüfung). «In beide Gruppen hochladen» heisst: Upload und danach `Tools/after_upload.rb`.
- **Beta-Prüfung:** nur für externe Tester und nicht die Prüfung für den App Store. Beim ersten Build einer Version kann sie bis zu einem Tag dauern, Folgebuilds gibt Apple meist innert Minuten frei.
- **Zustände lesen:** `ruby Tools/asc.rb GET /v1/builds/<id>/buildBetaDetail` zeigt `internalBuildState` und `externalBuildState`. Gut ist `IN_BETA_TESTING` beziehungsweise `BETA_APPROVED`.
- **Nie ohne ausdrückliche Freigabe:** etwas zur Prüfung für den App Store einreichen oder veröffentlichen. Im Fastfile ist das bewusst nirgends eingebaut. Die Schritte bis zum Einreichen stehen in `docs/MORGEN-CHECKLISTE.md`, Abschnitte 2 bis 4.
- **Signieren:** Release wird von Hand signiert (Apple Distribution, App-Store-Profile per API-Schlüssel). Zertifikat und Profile neu holen: `fastlane ios signing`.
- **Eigenheiten der API:**
  - `Tools/asc.rb` gibt zuerst den Statuscode aus, dann den JSON-Text, und braucht `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8`.
  - `GET /v1/builds/<id>/betaGroups` ist nicht erlaubt (403). Die Zugehörigkeit von der Gruppe her lesen: `GET /v1/betaGroups/<gruppe>/builds`. Dieser Aufruf kennt kein `sort`.
  - Die API kann keine iCloud-Container anlegen.

## 7. Was lokal liegen muss und nicht im Repository ist

| Lokal | Wozu | Woher |
|---|---|---|
| `docs/EINGABEN.md` | Persönliche Werte (Team, Schlüssel-Angaben, Prüfkontakt) | Von Philippe |
| `fastlane/.env` | `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`, `LANG`, `LC_ALL` | Werte aus `docs/EINGABEN.md` |
| App-Store-Connect-Schlüssel (`.p8`) | Upload und API | App Store Connect › Benutzer und Zugriff › Integrationen. Pfad in `ASC_KEY_PATH` |
| Verteilungszertifikat im Schlüsselbund, Profile | Signieren | `fastlane ios signing` |
| `fastlane/metadata/review_information/` | Prüfkontakt mit Telefonnummer | Von Philippe |
| `gh` angemeldet als Philippe | PRs, CI, Einstellungen | `gh auth login` |
| `build/` | Archive, Logs, Hörproben, Wegwerf-Skripte | Entsteht beim Arbeiten, darf jederzeit gelöscht werden |

Alles davon steht in `.gitignore`. Wer Werte braucht, liest sie lokal; in Befehle, URLs, Commits und Doku kommen sie nicht.

## 8. Neuer Mac oder neues Konto einrichten

1. Xcode mit den Simulatoren installieren: iPhone, iPad 11 Zoll, iPad 13 Zoll, iPhone Duo (ab iOS 27.1) und eine Apple Watch, gepaart mit dem iPhone.
2. Die UDIDs in `CLAUDE.md` und `Tools/pruefen.sh` gelten für Philippes Mac. Mit `xcrun simctl list devices` die eigenen nachsehen und anpassen. Simulatoren immer über die UDID ansprechen, die Namen kommen mehrfach vor.
3. `fastlane` und `gh` installieren (Homebrew), `gh auth login`.
4. Die lokalen Dateien aus Abschnitt 7 anlegen, dann `fastlane ios signing`.
5. `git config user.email` auf Philippes GitHub-noreply-Adresse setzen.
6. Probe: `Tools/pruefen.sh` muss grün sein, `ruby Tools/after_upload.rb --dry` muss den letzten Build zeigen.
7. Ein Claude-Konto bringt keine Notizen aus früheren Sitzungen mit. Was dort stand, steht in `CLAUDE.md` und hier.

## 9. Töne: was aus der Abstimmung mit Philippe bekannt ist

**Verlauf seiner Rückmeldungen**
1. 11.11.2026: Der Countdown 3-2-1 klang zu hart. Geändert: Spitzenpegel 60 % statt 90 %, Piepser klingen ab, weiche Rampen, die Musik wird für den ganzen Countdown nur einmal leiser gestellt.
2. 12.11.2026: «Eher ein Ping», gewünscht ein «Gong wie von einer Glocke, wo der letzte Ton höher ist». Daraus entstand das Ton-Set «Glocke».
3. Die erste Fassung (hoch, trocken, kurz) gefiel nicht: «noch voller, ggf. mit mehr Hall».
4. Die zweite Fassung (tiefer, mehr Teiltöne, länger, mit Hall) gab es in zwei Hörproben. Gewählt: die mit mehr Hall, «gut für den Anfang». Weiteres Feilen ist also möglich.

**Wo man dreht** (`FitMitJodit/Run/AudioSignalPlayer.swift`, `enum ToneSynth`)
- `ChimeNote`: Tonhöhen (Countdown a', Start einer Pause cis'', Start einer Übung e'', Halbzeit und Schluss a''). Tiefer klingt voller, höher setzt sich über Musik besser durch.
- `chimePartials`: Klangfarbe (Teiltöne einer gestimmten Glocke, je mit Anteil und Lebensdauer).
- `chimeHall`: Anteil des Halls. 1.0 heisst gleich viel Nachhall wie trockener Klang.
- `withHall`: der Raum (`room` 0.88 gibt rund 1.7 s Nachhall, `damp` dämpft die Höhen).
- `buffer(for:set:format:)`: je Ton `ring` (wie lange er von selbst klingt), `duration` (Länge des Puffers) und `fade` (Ausblenden am Ende).

**Grenzen**
- Kein Ton länger als 3.5 s: Vier Stimmen spielen reihum, und nach dem Schlusston wird die Audiositzung nach 3.5 s freigegeben.
- Spitzenpegel je Ton 0.6, die Summe überlagerter Töne muss unter 1.0 bleiben.
- Je länger ein Ton, desto länger bleibt die Musik anderer Apps leise. Die Musik kommt erst zurück, wenn der letzte Ton verklungen ist, weil iOS beim Freigeben die Audio-Engine kurz anhält. Bei der Glocke sind das rund 3 s nach dem Schlusston; bei kurzen Blöcken wie Tabata fällt das auf.
- Wer schon Einstellungen gesichert hat, behält sein gewähltes Ton-Set. Ein neuer Standard wirkt nur auf neue Installationen.

**Werkzeug**
```
Tools/hoerprobe.sh
HALL="0.5 1.5" Tools/hoerprobe.sh
```
Rendert die Töne mit dem echten Code der App nach `build/hoerprobe/` und gibt Messwerte aus (Pegel, Nachklang, Klangfarbe). Die Dateien an Philippe schicken und ihn per Klickfrage wählen lassen. Im Simulator lässt sich Klang nicht prüfen. Offen ist sein Urteil auf dem Gerät: voll genug, laut genug über Musik, stört die länger leise Musik?

## 10. Bekannte Stolpersteine

- **Testlauf startet nicht** («test runner hung before establishing connection», «failed to launch»): kein Fehler der App. Der Kurzbefehl-Dienst des Simulators startet die App selbst und kommt `xcodebuild` zuvor. `Tools/pruefen.sh` beendet die App vorher und wiederholt den Lauf. Ein Lauf zählt erst, wenn «Executed N tests» dasteht.
- **Meldungen zu CloudKit im Testlog** («Unable to initialize without an iCloud account»): normal, der Simulator ist nicht bei iCloud angemeldet.
- **Kein paralleles Bauen:** immer nur ein `xcodebuild`, ein Subagent, keine Worktrees. Während ein Testlauf läuft, keine Swift-Dateien ändern.
- **Von Hand im Simulator:** nach einer Aktion 1 bis 2 Sekunden warten, bevor ein Bildschirmfoto zählt. Die Bedienelemente der Laufansicht blenden sich nach 4 Sekunden aus; ein spätes Tippen blendet sie nur wieder ein. Den Stopp-Weg decken die UI-Tests ab.
- **fastlane** braucht `LANG=en_US.UTF-8`. `xcodebuild -authenticationKey…` scheitert mit «Authentication failed», darum das Signieren von Hand.
- **Ignorierter Ordner `build/`:** Was dort liegt, sieht kein anderes Konto. Skripte, die man wieder braucht, gehören nach `Tools/`.
- **zsh:** Muster mit `*` in Anführungszeichen setzen, sonst bricht der Befehl mit «no matches found» ab.
- **iOS 17:** Das Verschieben im Baukasten nutzt dort einen Ersatzweg (`LegacyHoldToDrag`). Er ist ungeprüft, weil keine iOS-17-Laufzeit installiert ist.

## 11. Offene Punkte

Der aktuelle Stand, das Offene und der nächste Schritt stehen in `docs/PROGRESS.md` ganz oben. Stand beim Schreiben (12.11.2026): Die Rückmeldungen aus den Gerätetests von Philippe und Jodit stehen aus, darunter das Urteil zur Glocke.
