# Fit mit Jodit: Paket für den Nachtlauf

Die ZIP-Datei entpackt sich in den Ordner `fit-mit-jodit`. Das ist der Projektordner: hineinwechseln und dort Claude Code starten.

## Inhalt
| Datei | Zweck |
|---|---|
| `README.md` | Diese Anleitung |
| `docs/SPEC.md` | Vollständige Vorgabe: App-Konzept, Tests, TestFlight, Store-Eintrag, CI |
| `docs/EINGABEN.md` | Deine Werte (Team-ID, Bundle-ID, API-Schlüssel, Kontakt). Bleibt lokal |
| `docs/MORGEN-CHECKLISTE.md` | Was du am Morgen selbst prüfst und klickst |
| `prompts/01-startprompt.md` | Abend, höchstens 10 Minuten: nur prüfen, Ampel |
| `prompts/02-nachtprompt.md` | Vollprompt: Kettentest bis TestFlight, dann die ganze App |
| `assets/icon/` | App-Icon als PNG 1024 x 1024 und als SVG-Quelle |
| `CLAUDE.md` | Projektregeln für Claude Code, wird automatisch gelesen |
| `.claude/agents/` | Die zwei Sonnet-Subagenten swift-helfer und build-pruefer |
| `.gitignore` | Hält Schlüssel, `EINGABEN.md` und Build-Ergebnisse aus dem Repository |

`.claude` und `.gitignore` sind im Finder versteckt (Cmd, Shift, Punkt blendet sie ein). Ein Xcode-Projekt liegt bewusst nicht bei, es lässt sich nur auf einem Mac erzeugen und prüfen. Der Vollprompt legt es als Erstes an.

## Ablauf
1. Vorbereitung von Hand (Liste unten).
2. Startprompt, höchstens 10 Minuten: prüft nur und endet mit einer Ampel.
3. Auto-Modus einschalten, Vollprompt senden.
4. Der Vollprompt beginnt mit einem Kettentest: leeres Gerüst bis TestFlight und GitHub Actions. Das Ergebnis steht nach etwa 20 bis 30 Minuten zuoberst in `docs/PROGRESS.md`. Wer so lange wach ist, schaut kurz hinein.
5. Danach trägt Claude Code einmalig in Chrome ein, was die API nicht kann, und baut dann die App.
6. Am Morgen: `docs/BERICHT.md` und `docs/MORGEN-CHECKLISTE.md`.

## Vorbereitung von Hand
1. **Apple Developer Program.** Mitgliedschaft muss aktiv sein. Ohne sie gibt es kein App Store Connect und kein TestFlight.
2. **Bundle-ID wählen und registrieren.** Die Bundle-ID ist ein Name, den du selbst wählst (z. B. `ch.fitmitjodit.timer`). Registriere sie auf developer.apple.com: Account, Certificates, Identifiers & Profiles, Identifiers, Plus, App IDs, App. Beschreibung «Fit mit Jodit», Bundle ID «Explicit» mit deinem Namen, bei den Capabilities iCloud ankreuzen. Sie lässt sich nach dem ersten Upload nicht mehr ändern.
3. **App-Eintrag anlegen** in App Store Connect: Apps, Plus, Neue App. Plattform iOS, Name «Fit mit Jodit», Primärsprache Deutsch, die eben registrierte Bundle-ID aus der Liste wählen, beliebige SKU. Dauert zwei Minuten und ist die Voraussetzung für jeden Upload. Ist der Name vergeben, entscheidest du jetzt über einen anderen.
4. **API-Schlüssel erzeugen** in App Store Connect: Benutzer und Zugriff, Integrationen, App Store Connect API, Team-Schlüssel. Rolle Admin (meine Annahme, damit auch das automatische Signing geht, nicht verifiziert, der Kettentest zeigt es). Die .p8-Datei lässt sich nur einmal laden. Lege sie ausserhalb des Projektordners ab, z. B. `~/keys/`.
5. **Mac:** aktuelles Xcode mit Simulatoren für iPad 13 Zoll, iPhone 6,9 Zoll und iPhone Duo (laut Entwicklerberichten ab Xcode 27.1), einmal geöffnet. `claude update`, `gh auth login`, fastlane installiert (`brew install fastlane`).
6. **Chrome:** Erweiterung «Claude in Chrome» installieren, in einem eigenen Profil, in dem nur Apple angemeldet ist. Bei App Store Connect anmelden und das Fenster offen lassen.
7. **Paket entpacken** an den Ort, wo das Projekt liegen soll (z. B. `~/Developer/`), `docs/EINGABEN.md` ausfüllen.
8. **Auto-Modus** in Claude Code verfügbar machen (im Team-Plan eventuell durch den Admin).
9. **Nutzung prüfen:** Einstellungen, Nutzung. Beide Balken ansehen.
10. **Mac wach halten:** Netzteil, in einem zweiten Terminal `caffeinate -dims`.

## Was am Morgen steht und was nicht
Ziel: App gebaut, Tests grün, Archiv erstellt, Build in TestFlight verarbeitet und ohne Warnung, Store-Eintrag in Deutsch und Englisch ausgefüllt, Screenshots hochgeladen, CI grün.

Nicht in der Nacht möglich:
1. Test auf echten Geräten. Ducking, Signale im Hintergrund, Live Activity und Spotify-Link lassen sich im Simulator nicht prüfen. «TestFlight grün» heisst: Apple hat den Build angenommen und verarbeitet. Dass er auf dem Gerät richtig funktioniert, zeigt erst dein Test am Morgen.
2. Einreichen zur Prüfung. Bewusst gesperrt, das machst du nach dem Gerätetest.
3. Apples Prüfung selbst. Die läuft erst nach dem Einreichen.

## Chrome in der Nacht: was erlaubt ist
Claude Code benutzt Chrome genau einmal, direkt nach dem Kettentest, nur auf appstoreconnect.apple.com und nur für App-Datenschutz, Altersfreigabe, Kategorie und Preis (und den App-Eintrag, falls du ihn nicht angelegt hast). Es gibt kein Passwort und keinen Code ein. Bist du nicht mehr angemeldet, wandert der Schritt in die Morgen-Checkliste.

Das eigene Chrome-Profil ist die Bedingung dafür: So erreicht der Agent nur Apple und keine anderen Seiten, bei denen du angemeldet bist.

## Das App-Konzept in Kürze
1. **Baukasten:** unten eine Palette mit Bausteinen (45 s Arbeit, 30 s Arbeit, 15 s Pause, 1 min Pause, Vorbereitung, eigene). Antippen hängt den Baustein an die Zeitleiste. Blöcke markieren und «mal N» macht daraus eine Runde.
2. **Farben:** Arbeit grün, Pause orange, Vorbereitung blau.
3. **Übungsnamen:** freiwillig, aus einer Liste von rund 60 Übungen oder eigene.
4. **Signale:** Töne und Halbzeit ein, Sprachansagen standardmässig aus, drei Ton-Sets.
5. **Laufansicht:** 10 s Vorlauf, Knöpfe blenden sich aus, Stopp mit Bestätigung, Abschlussbild.
6. **Bibliothek:** vier Vorlagen, Favoriten, zuletzt benutzt, Suche.
7. **Geräte:** iPad, iPhone, iPhone Duo auf- und zugeklappt.
8. **Icon:** dunkler Grund, Ring aus grünen und orangen Segmenten, weisses J.
9. **Apple Watch:** Begleit-App als Fernbedienung mit Haptik beim Blockwechsel, Trainingsliste, Musiksteuerung über die System-Ansicht (auch Spotify).

## Kosten und Grenzen
1. Der Umfang ist gross: App mit Baukasten, drei Gerätetypen, Tests, Screenshots, Store-Eintrag, CI. Ob alles in eine Nacht und ins Nutzungsfenster passt, kann ich nicht zusichern. Darum haben die Teile 1 bis 10 Vorrang, es gibt zwei Zwischenstände in TestFlight, und `docs/PROGRESS.md` erlaubt am Morgen ein «weiter».
2. Weil der Startprompt nur prüft, zeigt sich ein Problem mit Signing oder Upload erst im Kettentest, also nach dem Start des Vollprompts. Scheitert er, baut Claude Code die App trotzdem und bereitet den Upload lokal vor.
3. GitHub Actions: macOS-Läufe zählen im privaten Repository zehnfach gegen die Freiminuten (2'000 im Gratis-Plan, also rund 200 echte Minuten). Der Workflow läuft deshalb nur bei Pull Requests und von Hand.
4. Die Datenschutz- und Support-Seite braucht ein öffentliches Repository für GitHub Pages. Sie wird nur veröffentlicht, wenn du es in `EINGABEN.md` erlaubst.
5. Die Angaben zum iPhone Duo stammen aus MacRumors und einem Entwicklerblog, nicht aus Apples Doku. Claude Code liest vor der Umsetzung Apples eigene Doku.

## Quellen
- Claude Code mit Chrome: https://code.claude.com/docs/en/chrome
- App-Datenschutz nicht per API-Schlüssel: https://docs.fastlane.tools/uploading-app-privacy-details/
- App anlegen nur auf der Website: https://developer.apple.com/forums/thread/851298
- GitHub Actions, Minutenfaktor macOS: https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions
- Screenshot-Grössen: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- iPhone Duo, Überblick: https://www.macrumors.com/roundup/iphone-duo/
- iPhone Duo für Entwickler: https://ziplyne.agency/blog/iphone-duo-for-developers-screen-sizes-layout-rules-and-the-new-apis
