# SPEC: Fit mit Jodit

Version 3. Persönliche Werte (Team-ID, Bundle-ID, Kontaktdaten, Pfad zum API-Schlüssel) stehen in `docs/EINGABEN.md`.

## ZIEL
Baue eine iOS-App «Fit mit Jodit» für den App Store: ein Intervall-Timer für Gruppentrainings, Hauptgerät iPad im Querformat, dazu iPhone inklusive iPhone Duo und eine Begleit-App für die Apple Watch. Trainings werden aus Bausteinen zusammengeklickt, benannt, gespeichert und im Training gross angezeigt. Musik läuft in Spotify, entweder daneben im geteilten Bildschirm oder im Hintergrund.

Am Ende steht ein Stand, der bis auf den Test auf echten Geräten und den Klick «Zur Prüfung einreichen» einreichungsfertig ist: Archiv erstellt, Build in TestFlight verarbeitet und ohne Warnung, Store-Eintrag in Deutsch und Englisch ausgefüllt, Screenshots hochgeladen, alle Tests grün, CI grün.

## KONTEXT
Die App ist für die Kurse von fitmitjodit (fitmitjodit.ch, Personal Training und Group Fitness) und wird öffentlich im App Store veröffentlicht. Im Kurs machen alle dieselbe Übung gleichzeitig, die Trainerin gibt sie vor. Typischer Ablauf: 3 Übungen à 45 Sekunden mit kurzer Pause dazwischen, dann eine Minute Pause, das Ganze mehrmals. Die Trainerin steht mehrere Meter vom iPad weg. Spotify wird bewusst nicht per SDK oder API eingebunden, weil Spotify neue Apps auf 5 Konten begrenzt.

## FARBEN UND BLOCKTYPEN
| Typ | Farbe | Bedeutung |
|---|---|---|
| Arbeit | Grün | Übung läuft |
| Pause | Orange | kurze oder lange Pause |
| Vorbereitung | Blau | Vorlauf vor dem Start, Bereitmachen |

Die Farben sind fest, damit sie aus Distanz eindeutig bleiben. Der Typ steht zusätzlich immer als Text da, Farbe ist nie das einzige Merkmal. Weisse Schrift muss auf allen drei Farben gut lesbar sein.

## FUNKTIONEN

### 1. Bibliothek
Liste gespeicherter Trainings mit Name, Gesamtdauer und einer kleinen farbigen Vorschau der Blockfolge. Oben angeheftete Favoriten (Stern), darunter nach letzter Benutzung sortiert, dazu eine Suche. Anlegen, duplizieren, umbenennen, löschen (mit Rückfrage).

Beim ersten Start liegen vier Vorlagen bereit, die sich kopieren und ändern lassen:
1. Zirkel 45/15: 3 Übungen à 45 s, 15 s Pause dazwischen, 1 min Pause, 4 Runden
2. Tabata: 20 s Arbeit, 10 s Pause, 8 Runden
3. Kraft: 4 Übungen à 60 s, 30 s Pause dazwischen, 90 s Pause, 3 Runden
4. Warm-up: 6 Übungen à 30 s ohne Pause

Zusätzlich zwei Vorlagen für Teilnehmende zu Hause, mit Übungsnamen und Ansage: «Ganzkörper 20» (10 Übungen à 40 s, 20 s Pause, 2 Runden) und «Bauch & Rumpf 10» (5 Übungen à 45 s, 15 s Pause, 2 Runden). Neue Vorlagen erscheinen auch nach einem Update, gelöschte kommen nicht zurück.

**Zielgruppen:** Jodit im Kurs (Trainings oft ohne Übungsnamen) und Teilnehmende zu Hause (Trainings mit Namen und Ansage).

**Willkommen und Werbung:** Beim ersten Start ein Willkommensbildschirm «Willkommen bei Fit mit Jodit» mit Foto von Jodit. Im Abschlussbild und in den Einstellungen eine Karte «Trainiere mit Jodit» mit Foto und Link zu fitmitjodit.ch. Fotos vorläufig von fitmitjodit.ch, als austauschbare Assets («PhotoWelcome», «PhotoGroup»); Originale folgen.

### 2. Baukasten (Editor)
Aufbau von oben nach unten: Namensfeld, Zeitleiste, Palette.

**Zeitleiste:** die Blöcke des Trainings als farbige Kacheln in Reihenfolge. Die Breite entspricht der Dauer, auf der Kachel stehen Dauer und, falls vergeben, der Übungsname. Auf schmalen Breiten bricht die Zeitleiste in Zeilen um. Auch die Blöcke innerhalb einer Runde brechen um; die ganze Spalte scrollt, damit auch lange Trainings auf dem iPhone bearbeitbar bleiben. Gesamtdauer und Anzahl Runden stehen laufend darüber.

**Palette:** Bausteine zum Antippen. Start mit 45 s Arbeit, 30 s Arbeit, 15 s Pause, 1 min Pause, 10 s Vorbereitung. Antippen hängt den Baustein ans Ende der Zeitleiste, oder hinter den markierten Block. Baustein halten ändert seine Dauer (Rad in 5-Sekunden-Schritten, 5 s bis 10 min). «+» legt einen eigenen Baustein an (Typ und Dauer). Die Palette gilt für alle Trainings und bleibt gespeichert, Bausteine lassen sich daraus wieder entfernen.

**Blöcke bearbeiten:** Block antippen markiert ihn, weitere antippen erweitert die Auswahl. Für die Auswahl erscheint eine Leiste mit: Übung wählen, Dauer, Duplizieren, Löschen, «mal N». Halten und ziehen verschiebt Blöcke.

**Runden:** «mal N» fasst die markierten, nebeneinander liegenden Blöcke zu einer Runde zusammen, sichtbar als Klammer mit Zähler. Der Zähler ist antippbar. Runden lassen sich auflösen. Keine Runden in Runden.

**Übungsnamen:** Namen sind freiwillig. Ein Block ohne Namen heisst in der Anzeige «Arbeit» beziehungsweise «Pause». «Übung wählen» öffnet eine mitgelieferte Liste von rund 60 gängigen Übungen in Deutsch und Englisch mit Suche. Eigene Namen lassen sich eintippen, werden gemerkt und erscheinen künftig in der Liste.

**Komfort:** Rückgängig und Wiederholen. Eine Pause ganz am Ende des Trainings wird beim Ablauf übersprungen (abschaltbar), damit nach der letzten Runde nicht noch eine Minute Pause läuft.

**Gefühl:** dezent verspielt. Ein angetippter Baustein fliegt mit kurzer Animation in die Zeitleiste und rastet mit Haptik ein, die Zeitleiste wächst sichtbar mit. Keine Soundeffekte im Baukasten, kein Konfetti.

### 3. Laufansicht
Sehr grosser Countdown, darüber der Name des aktuellen Blocks, darunter der nächste Block, Runde x von y und der Gesamtfortschritt. Ganzer Bildschirm in der Farbe des Blocktyps. Aus 5 m lesbar. In einer Pause steht gross «Pause» und, falls der nächste Block einen Namen hat, «Gleich: Kniebeugen».

**Vorlauf:** vor dem ersten Block 10 s «Bereit machen» in Blau, in den Einstellungen von 0 bis 30 s änderbar.

**Bedienung:** Die Knöpfe sind ausgeblendet. Einmal tippen zeigt für einige Sekunden Pause, Block zurück, Block vor und Stopp. Stopp verlangt eine Bestätigung. Der Bildschirm bleibt wach.

**Abschluss:** Abschlussbild «Geschafft» mit Gesamtzeit und den Knöpfen «Nochmals» und «Fertig».

### 4. Signale
Einzeln abschaltbar, mit eigener Lautstärke:
1. Töne in den letzten 3 Sekunden und ein Startsignal beim Blockwechsel. Standard: ein.
2. Signal bei Halbzeit des Blocks. Standard: ein.
3. Sprachansagen in der App-Sprache. Modus «Aus», «Automatisch» (Standard) oder «Immer»; «Automatisch» spricht nur bei Trainings mit Übungsnamen (Teilnehmende zu Hause), Trainings ohne Namen (Kursstunde, Jodit sagt selbst an) bleiben bei den Tönen. Ausführliche Ansagen (Standard ein): Dauer mitsagen («Kniebeugen, 45 Sekunden»), 6 s vor Ende einer Pause «Bereit machen: Liegestütze, 45 Sekunden», in Arbeitsblöcken ab 30 s «Noch 10 Sekunden». (Geändert am 11.11.2026, vorher: Standard aus.) Eingeschaltet sagt die Stimme zu Beginn einer Pause «Pause» und, falls vorhanden, «gleich: Kniebeugen», zu Beginn einer Übung den Übungsnamen oder ohne Namen «Los», dazu «Letzte Runde» und «Geschafft». Kein gesprochener Countdown.

Drei Ton-Sets zur Wahl: sportliche Piepser (Standard), Boxglocke, sanfter Gong. Erzeuge die Töne selbst (synthetisch), verwende keine fremden Sounddateien. Während Ton und Ansage wird die Musik anderer Apps kurz leiser und kehrt danach auf volle Lautstärke zurück.

### 5. Spotify-Link
Jedes Training kann einen Spotify-Link speichern (Playlist, Album). Ein Knopf «In Spotify öffnen» in Trainingsdetail und Laufansicht öffnet genau diesen Inhalt in der Spotify-App. Ohne Link öffnet der Knopf Spotify allgemein.

### 6. Nebeneinander
Die App muss in jeder Fenstergrösse sauber funktionieren, von einem Drittel der iPad-Breite bis Vollbild, damit Spotify daneben Platz hat. Die Laufansicht bleibt auch schmal gut lesbar. Ein einmaliger Hinweis erklärt, wie man Spotify daneben legt. Gilt genauso für das Innendisplay des iPhone Duo.

### 7. Hintergrund
Wechselt man zu Spotify, läuft der Timer weiter, Töne und Ansagen kommen weiterhin. Zusätzlich eine Live Activity mit Countdown und Blockname auf Sperrbildschirm und Dynamic Island, wo das System sie unterstützt.

### 8. Austausch
iCloud-Sync zwischen Geräten derselben Apple-ID (Trainings, Palette, eigene Übungsnamen, Einstellungen). Zusätzlich Export und Import einzelner Trainings als Datei (eigener Dateityp, per AirDrop oder Nachricht teilbar).

### 9. Sprachen
Deutsch und Englisch, folgt der Gerätesprache.

### 10. Apple Watch (Begleit-App)
**Pflichtteil.** Eine watchOS-App, die zusammen mit der iOS-App ausgeliefert wird (Companion, braucht das iPhone). Die Trainerin trägt die Uhr im Kurs und muss nicht zum iPad oder iPhone laufen. Typischer Kurs: Timer gross auf dem iPad, Spotify auf dem iPhone (Box per Bluetooth am iPhone), Uhr am Handgelenk. Lies vor der Umsetzung Apples aktuelle Doku zu WatchConnectivity, watchOS-App-Struktur und `NowPlayingView`.
1. **Fernbedienung:** Läuft auf dem iPhone ein Training, zeigt die Uhr Blockname, Typ (Farbe und Text wie auf dem iPhone), Countdown, nächsten Block und Runde x von y. Knöpfe: Pause/Weiter, Block vor, Block zurück, Stopp mit Bestätigung. Die Digital Crown ist nicht nötig.
2. **Automatisch weiterschalten:** Der Ablauf schaltet wie in der Laufansicht automatisch von Block zu Block. Die Uhr läuft synchron mit, ohne pro Sekunde Daten zu brauchen: das iPhone schickt Endzeitpunkt und Blockfolge, die Uhr rechnet selbst. Bei jedem Blockwechsel eine deutliche Haptik (unterschiedlich für Arbeit, Pause, letzte 3 Sekunden).
3. **Training starten:** Liste der Trainings (Favoriten oben) auf der Uhr, Antippen startet das Training auf dem verbundenen iPhone. Ist kein iPhone erreichbar, klare Meldung.
4. **Musik:** Keine Spotify-Anbindung per SDK oder Web API (siehe SPOTIFY). Stattdessen die System-Ansicht `NowPlayingView` aus WatchKit als eigene Seite: Sie steuert die gerade laufende Musik auf dem iPhone, also auch Spotify (Play/Pause, Titel vor, Lautstärke), so wie es andere Trainings-Apps machen. Musik läuft im Kurs auf dem iPhone, das reicht. Auf dem iPad gibt es keine Musiksteuerung in der App (keine öffentliche Schnittstelle), dort bleibt Spotify daneben oder das Kontrollzentrum. Ist sie auf der Zielversion nicht verfügbar, nur einen Hinweis zeigen. Begründung und Restrisiko im Bericht nennen.
5. **Weiterleitung zum iPad:** Eine Watch ist nur mit dem iPhone gekoppelt. Läuft das Training auf dem iPad, leitet die iPhone-App die Befehle der Uhr im lokalen Netz ans iPad weiter und den Zustand des iPad zurück an die Uhr: Uhr ↔ iPhone (WatchConnectivity) ↔ iPad (MultipeerConnectivity oder Network-Framework mit Bonjour, nur Apple-Frameworks). Kopplung iPhone–iPad einmalig bestätigen, danach automatisch, nur Geräte derselben Apple-ID oder ausdrücklich bestätigte. Auf dem iPhone ein Modus «Fernbedienung fürs iPad», der den Zustand des iPad zeigt und die Verbindung hält, solange er offen ist; Bildschirm bleibt dabei wach. Die Uhr zeigt klar, welches Gerät sie gerade steuert und ob die Verbindung steht. Läuft das Training auf dem iPhone selbst, entfällt die Weiterleitung. Im Simulator mit Unit-Tests der Nachrichten und einem Test iPhone-Simulator ↔ iPad-Simulator prüfen, soweit möglich; der Rest ist Gerätetest. Rechtfertigung für den lokalen Netzzugriff (`NSLocalNetworkUsageDescription`, `NSBonjourServices`) in beiden Sprachen, Datenschutz-Seite entsprechend ergänzen (nur lokales Netz, nichts verlässt die Geräte).
6. **Technik:** SwiftUI, watchOS 10.0 als Mindestversion, WatchConnectivity für Steuerung und Trainingsliste, gemeinsamer Code (Blocktypen, Auflösung von Runden, Timer-Rechnung) in einem geteilten Modul statt kopiert. Texte Deutsch und Englisch im String Catalog. Keine eigene Datenhaltung auf der Uhr ausser einem Cache der Trainingsliste.
7. **Komplikation:** optional und erst ganz am Ende: eine Komplikation (WidgetKit), die die App startet.

## GERÄTE
1. iPad: Hauptgerät, Querformat bevorzugt, alle Ausrichtungen und Fenstergrössen.
2. iPhone: kompaktes Layout, Hochformat bevorzugt.
3. iPhone Duo (Apples faltbares iPhone, seit Oktober 2026, Innendisplay 7,6 Zoll, Aussendisplay 5,4 Zoll, iOS 27.1). Lies vor der Umsetzung Apples aktuelle Entwicklerdoku zum iPhone Duo und verlasse dich nicht auf Erinnerung. Anforderungen:
   1. Aufgeklappt nutzt die App das ganze Innendisplay mit einem Layout wie auf einem kleinen iPad: Baukasten mit Zeitleiste und Palette nebeneinander, Laufansicht mit maximal grossem Countdown.
   2. Zugeklappt läuft dasselbe kompakte Layout wie auf dem iPhone.
   3. Auf- und Zuklappen während eines laufenden Trainings unterbricht weder Timer noch Signale, die Ansicht wechselt ohne Sprung.
   4. Nichts Wichtiges (Countdown, Knöpfe, Blockname) liegt auf dem Falz oder unter den Kameras.
   5. Neben Spotify im geteilten Bildschirm des Innendisplays bleibt die Laufansicht lesbar.
   6. Layout nur über Size Classes und die verfügbare Fläche steuern, nie über Gerätetyp, Ausrichtung oder feste Bildschirmmasse. Duo-spezifische Schnittstellen nur hinter Verfügbarkeitsprüfungen, damit die App weiter ab iOS 17 läuft.

## TECHNIK
Swift, SwiftUI, eine universelle App, Mindestversion iOS und iPadOS 17.0, gebaut mit dem aktuellen Xcode und SDK. SwiftData mit CloudKit (private Datenbank), Modelle CloudKit-tauglich anlegen. Fällt iCloud aus oder ist niemand angemeldet, läuft die App mit lokalem Speicher weiter. Texte im String Catalog (de, en). Timer rechnet mit Zeitstempeln statt gezählten Ticks, die Uhr ist für Tests austauschbar. Audio über AVAudioSession mit Ducking, Ansagen über AVSpeechSynthesizer. Live Activity über ActivityKit mit einem Countdown, den das System selbst rendert. Kein UIRequiresFullScreen, kein UIScreen.main. Für die Signale im Hintergrund wähle eine Lösung, die Apples Review-Richtlinien einhält, begründe sie und nenne das Restrisiko. Keine Drittpakete in der App.

## SPOTIFY
Kein Spotify-SDK, keine Spotify Web API, kein Login, keine Client-ID. Nur Verlinkung nach Spotifys Anleitung «iOS Content Linking» (https://developer.spotify.com/documentation/ios/tutorials/content-linking). Lies sie vor der Umsetzung und halte dich daran: Web-Links von open.spotify.com verwenden, Bundle-ID als Kampagnen-Parameter mitgeben, prüfen ob Spotify installiert ist, sonst App Store oder Browser. Eingefügte Links prüfen und bei ungültigem Link klar melden. Lies vor der Verwendung von Name und Logo Spotifys aktuelle Design-Richtlinien. Im Zweifel nur der Text «In Spotify öffnen», kein Logo.

## BRANDING
App-Name «Fit mit Jodit». Lade die vorläufigen Logos von https://fitmitjodit.ch/Home/ (Logo_fmj_aktuell_weiss.png und Logo_Jodit_white.png, beide weiss auf transparent, niedrige Auflösung) und leite Akzentfarbe und Schrift aus der Website ab. Die Markenfarbe gilt für Bibliothek, Baukasten und Knöpfe, nicht für die drei Blockfarben. Lege Farben und Schriften in einer zentralen Theme-Datei ab, Logo und App-Icon als austauschbare Assets. Hochaufgelöste Logos folgen später.

**App-Icon:** Das Icon liegt fertig bereit unter `assets/icon/AppIcon-1024.png` (1024 x 1024, ohne Transparenz, Quelle `AppIcon.svg`): dunkler Grund, ein Ring aus grünen und orangen Segmenten wie eine Runde im Baukasten, in der Mitte ein weisses J. Verwende es unverändert für alle Icon-Grössen. Baue kein eigenes Icon und setze das Website-Logo nicht ins Icon. Dasselbe Ringmotiv darf im Startbildschirm und im Abschlussbild vorkommen.

## QUALITÄT UND TESTS
1. Unit-Tests: Timer-Logik mit künstlicher Uhr (inklusive Pause, Sprung vor und zurück, Rückkehr aus dem Hintergrund, 60 Minuten ohne Abweichung), Auflösen von Runden in eine Blockfolge, Überspringen der Schlusspause, Vorlauf, Zeitpunkte aller Signale, Text der Ansagen mit und ohne Übungsnamen, Prüfung von Spotify-Links, Export und Import hin und zurück, Datenmodell ohne iCloud, Rückgängig im Baukasten.
2. UI-Tests (XCUITest) auf iPad, iPhone und iPhone Duo, dazu ein UI-Test der Watch-App im Watch-Simulator (Ansicht ohne iPhone, Trainingsliste mit Testdaten). Unit-Tests für die Watch-Synchronisierung (Endzeitpunkt, Pause, Sprung) mit künstlicher Uhr (aufgeklappt und zugeklappt, sofern der Simulator vorhanden ist): Training aus Bausteinen bauen (3 mal 45 s Arbeit mit 15 s Pause, 1 min Pause, mal 4), Übung aus der Liste wählen, eigenen Baustein anlegen, sortieren, duplizieren, löschen, Favorit setzen, starten, pausieren, Block überspringen, stoppen mit Bestätigung, Signale ein und aus, Export. Laufansicht bei einem Drittel, der Hälfte und voller iPad-Breite.
3. Beide Sprachen: UI-Tests einmal auf Deutsch und einmal auf Englisch. Ein Test schlägt fehl, wenn ein Text nur in einer Sprache vorhanden ist.
4. Bedienungshilfen: automatische Prüfung der Hauptansichten (performAccessibilityAudit), VoiceOver-Labels auf allen Bedienelementen, Bausteine und Blöcke auch ohne Ziehen bedienbar.
5. Build ohne Warnungen. Kein auskommentierter oder übersprungener Test, um grün zu werden. Ein Test, der sich nicht reparieren lässt, wird im Bericht als offen genannt.
6. Was der Simulator nicht prüfen kann, kommt in `docs/MORGEN-CHECKLISTE.md` als Gerätetest: Ducking, Signale im Hintergrund, Live Activity auf dem Sperrbildschirm, Spotify-Link, iCloud-Sync zwischen zwei Geräten, AirDrop, Haptik, Watch-Fernbedienung mit echtem iPhone, Weiterleitung Uhr → iPhone → iPad im Kurs-WLAN (auch nach Sperren des iPhone), Musiksteuerung auf der Uhr.

## DISTRIBUTION
Werkzeug: fastlane, authentifiziert mit dem App-Store-Connect-API-Schlüssel aus `docs/EINGABEN.md`. Die ganze Kette wird als Teil 0 mit einem leeren Gerüst getestet (Build 1), bevor die App gebaut wird. Was die API nicht kann (App-Datenschutz, allenfalls App-Eintrag, Altersfreigabe, Preis), wird einmalig direkt nach dem Kettentest im Browser eingetragen, nach den Regeln des Vollprompts.

1. Version 1.0. Build-Nummer höher als jede bereits hochgeladene. `ITSAppUsesNonExemptEncryption` auf NO.
2. Signieren, archivieren, exportieren. Archiv (.xcarchive) und .ipa unter `build/` ablegen, nicht im Repository.
3. Nach App Store Connect hochladen und warten, bis Apple den Build verarbeitet hat.
4. TestFlight gilt als grün, wenn alle Punkte zutreffen: Verarbeitung abgeschlossen, Status bereit zum Testen, kein Hinweis «Fehlende Compliance», keine Warnung oder Ablehnung zur Lieferung, Build der internen Testgruppe aus `docs/EINGABEN.md` zugewiesen. Prüfe das per API und halte den Status im Bericht fest.
5. Store-Texte in `fastlane/metadata` für de-DE und en-US: Name, Untertitel, Beschreibung, Schlüsselwörter, Werbetext, Support-URL, Marketing-URL, Datenschutz-URL, Copyright, Kontakt für die Prüfung, Hinweise für die Prüfer (wie man ein Training startet, dass Spotify optional ist), Text «Was zu testen ist» für TestFlight. Hochladen ohne Einreichung, danach zurücklesen und vergleichen.
6. Stil der Store-Texte: sachlich und konkret, was die App tut und für wen. Keine Superlative, keine Füllsätze. Spotify nur im Beschreibungstext als Funktion erwähnen, nicht in Name, Untertitel, Schlüsselwörtern oder Screenshots.
7. Screenshots automatisch aus den UI-Tests: iPhone 6,9 Zoll (1320 x 2868) und iPad 13 Zoll (2064 x 2752, zusätzlich quer), je Deutsch und Englisch, je 4 bis 6 Bilder mit der Vorlage Zirkel 45/15: Bibliothek, Baukasten, Laufansicht Arbeit (grün), Laufansicht Pause (orange), Laufansicht schmal neben Platz für eine Musik-App. Dazu Apple Watch (Series 12 46 mm, Grösse laut Apples Screenshot-Spezifikation prüfen), je 2 bis 3 Bilder pro Sprache: Laufansicht Arbeit, Laufansicht Pause, Trainingsliste. Ohne Rahmen und ohne Werbetext im Bild. Hochladen.
8. Nicht einreichen. `submit_for_review` bleibt aus.
9. Fehlt der API-Schlüssel oder der App-Eintrag: alles lokal vorbereiten (Metadaten, Screenshots, Archiv) und in `docs/BERICHT.md` den einen Befehl nennen, der am Morgen alles hochlädt.

## DATENSCHUTZ UND SUPPORT
App Store Connect verlangt eine Datenschutz-URL und eine Support-URL. Keine eigene Webseite, kein GitHub Pages, sondern wie bei den anderen Apps des Entwicklers (Vorbild: github.com/PhilippeSch/CyclePulse):
1. Das Projekt-Repository `PhilippeSch/fit-mit-jodit` ist öffentlich, Issues sind eingeschaltet.
2. Datenschutz: `docs/Privacy.md` im Repository, Englisch und Deutsch auf einer Seite (Sprungmarken oben), mit Datum. Inhalt: die App erhebt und überträgt keine Daten, kein Server, kein Konto, keine Analyse, Trainings liegen auf dem Gerät und in der privaten iCloud des Nutzers, iPhone und Watch tauschen Daten direkt aus, Spotify wird nur per Link geöffnet. Kontakt: Support-Adresse aus `docs/EINGABEN.md`. Aufbau wie `docs/Privacy.md` in CyclePulse.
3. Datenschutz-URL: `https://github.com/PhilippeSch/fit-mit-jodit/blob/main/docs/Privacy.md`
4. Support-URL: `https://github.com/PhilippeSch/fit-mit-jodit/issues`
5. Store-Texte zusätzlich lesbar unter `AppStore/Store-de.md` und `AppStore/Store-en.md` ablegen (wie in CyclePulse), Quelle für fastlane bleibt `fastlane/metadata`.
6. Weil das Repository öffentlich ist: nie Telefonnummer, Team-ID, Schlüssel oder Inhalte aus `docs/EINGABEN.md` committen.

## CI
GitHub Actions im öffentlichen Repository: ein Workflow, der auf macOS baut und die Unit-Tests auf einem iPhone-Simulator laufen lässt. Auslöser: Pull Requests und manueller Start, nicht jeder Push (macOS-Minuten zählen zehnfach). Xcode-Version fest auf die Version setzen, die im Kettentest auf dem GitHub-Runner funktioniert hat. Kein Signing und keine Geheimnisse in GitHub. Arbeite auf einem Branch, öffne am Ende einen Pull Request, warte auf den Lauf und repariere, bis er grün ist. Merge erst bei grünem Lauf.

## VORGEHEN
Reihenfolge:

0. Kettentest mit leerem Gerüst: Repository, Xcode-Projekt, fastlane, Archiv, Upload, TestFlight, CI
1. Datenmodell, Bibliothek, Vorlagen
2. Baukasten mit Palette, Zeitleiste, Runden, Übungsliste
3. Timer und Laufansicht mit Vorlauf und Abschlussbild
4. Signale und Ton-Sets
5. Hintergrund und Live Activity
6. Spotify-Link
7. Sync und Dateiexport
8. Übersetzung
9. Branding und App-Icon
10. iPhone Duo und alle Fenstergrössen
10a. Apple-Watch-Begleit-App (Fernbedienung, Haptik, Trainingsliste, Musiksteuerung)
11. UI-Tests, Bedienungshilfen, Screenshots
12. Datenschutz-Seite (docs/Privacy.md) und Support über Issues
13. Store-Texte, Archiv, Upload, TestFlight grün
14. CI und Pull Request
15. Berichte

Nach jedem Teil muss der Build für iPad- und iPhone-Simulator fehlerfrei sein und die Tests müssen laufen, bevor du weitermachst. Die Teile 1 bis 10 haben Vorrang: Eine App, die sauber läuft, ist wichtiger als ein vollständiger Store-Eintrag. Die Watch-App (10a) ist Pflicht, inklusive Weiterleitung zum iPad. Sie kommt nach den Teilen 1 bis 10 und vor Teil 11 und hat Vorrang vor Store-Eintrag und CI. Lade nach Teil 5 und nach Teil 10a je einen Zwischenstand nach TestFlight, damit auch bei einem Abbruch ein testbarer Build bereitliegt.

## NICHT
Kein Benutzerkonto, kein eigener Server, keine Analyse- oder Werbe-SDKs. Keine Steuerung von Spotify über SDK oder API und keine eigene Anzeige des laufenden Titels; erlaubt ist nur die System-Ansicht `NowPlayingView` auf der Uhr. Kein HealthKit, keine eigenständige Watch-App ohne iPhone, keine Workout-Session auf der Uhr. Keine fremden Sounddateien, Bilder oder Schriften ohne klare Lizenz. Keine Zugangsdaten, kein API-Schlüssel und keine `EINGABEN.md` im Repository. Keine Einreichung zur Prüfung, keine Veröffentlichung der App. App-Namen nicht eigenmächtig kürzen, sondern melden, falls er auf dem Homescreen abgeschnitten wird.

## ABNAHME
1. Build ohne Warnungen, Unit- und UI-Tests grün für iPad, iPhone und iPhone Duo, in beiden Sprachen.
2. Das Training «3 mal 45 s Arbeit mit 15 s Pause, 1 min Pause, mal 4» lässt sich im Baukasten in unter einer Minute zusammenklicken und läuft ohne Zeitabweichung.
3. Pausen erscheinen orange, Arbeit grün, Vorbereitung blau, jeweils mit Text.
4. Töne, Halbzeit-Signal und Ansagen funktionieren, sind abschaltbar, Ansagen sind standardmässig aus und funktionieren auch ohne Übungsnamen.
5. Laufansicht ist bei einem Drittel, der Hälfte und voller Breite auf dem iPad lesbar, auf dem iPhone Duo auf- und zugeklappt.
6. Live Activity zeigt Countdown und Blockname.
7. Export und Import einer Trainingsdatei funktioniert.
8. Alle Texte auf Deutsch und Englisch vorhanden.
9. Archiv und .ipa liegen unter `build/`.
10. Der Build 1.0 ist in TestFlight grün nach der Definition in DISTRIBUTION.
11. Store-Eintrag in de-DE und en-US ausgefüllt, Screenshots für iPhone und iPad in beiden Sprachen hochgeladen.
12. Watch-App zeigt das laufende Training, schaltet automatisch weiter, Pause/Vor/Zurück/Stopp steuern das iPhone und über die Weiterleitung das iPad (im Simulator mit gepaartem iPhone-Simulator geprüft, sonst als Gerätetest gemeldet).
13. docs/Privacy.md auf main erreichbar, Issues offen, beide URLs im Store-Eintrag.
14. GitHub-Actions-Lauf auf dem Pull Request grün.

## BERICHTE
`docs/BERICHT.md`: was gebaut wurde, Stand jedes Abnahmepunkts (erfüllt mit Beleg, offen mit Grund, im Simulator nicht prüfbar), die gewählte Lösung für Hintergrund-Signale mit Restrisiko, getroffene Annahmen, alles was nicht hochgeladen werden konnte mit dem Befehl dazu.

`docs/MORGEN-CHECKLISTE.md`: die mitgelieferte Checkliste ergänzen um alles, was in dieser Nacht konkret offen geblieben ist.
