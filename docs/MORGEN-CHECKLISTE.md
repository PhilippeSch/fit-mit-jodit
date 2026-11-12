# Morgen-Checkliste

Erst lesen: `docs/BERICHT.md`. Was dort als offen steht, hat Vorrang. Claude Code ergänzt diese Liste in der Nacht um konkrete offene Punkte.

## 1. Gerätetest (etwa 20 Minuten)
TestFlight auf iPad und iPhone öffnen, neuesten Build laden. Falls ein iPhone Duo zur Hand ist, auch dort.

1. Im Baukasten zusammenklicken: 3 mal 45 s Arbeit mit 15 s Pause, 1 min Pause, mal 4. Fühlt es sich flüssig an, rasten die Bausteine sauber ein?
2. Starten. Vorlauf blau, Arbeit grün, Pause orange? Countdown aus 5 m lesbar?
3. Spotify läuft: Wird die Musik bei den Tönen leiser und danach wieder laut?
4. iPad: Spotify daneben legen. Bleibt die Laufansicht schmal lesbar, läuft der Timer weiter?
5. iPhone: während des Trainings zu Spotify wechseln. Kommen die Töne weiter? Stimmt die Zeit bei der Rückkehr?
6. Gerät sperren. Zeigt der Sperrbildschirm Countdown und Blockname?
7. Ansagen einschalten, je einen Block mit und ohne Übungsnamen testen.
8. Die vier Ton-Sets anhören (neu: «Glocke»). Laut genug über Musik?
9. Training mit Spotify-Link: Öffnet der Knopf die richtige Playlist?
10. Ein Training am iPhone anlegen. Erscheint es auf dem iPad (gleiche Apple-ID)?
11. Training per AirDrop an ein anderes Gerät schicken und öffnen.
12. iPhone Duo: während eines laufenden Trainings auf- und zuklappen. Läuft alles weiter, liegt nichts auf dem Falz?
13. Sprache des Geräts auf Englisch stellen, einmal durchklicken.
14. Ein ganzes Training von 30 Minuten im echten Kurs laufen lassen.

Punkt 3 und 5 sind die wahrscheinlichsten Fehlerquellen. Fällt einer durch, nicht einreichen.

## 2. App Store Connect prüfen
1. TestFlight: neuester Build verarbeitet, ohne Warnung, in der internen Gruppe.
2. Texte in Deutsch und Englisch lesen und korrigieren. Sie stehen unter deinem beziehungsweise Jodits Namen.
3. Screenshots ansehen, schlechte entfernen.
4. App-Datenschutz, Altersfreigabe, Preis und Länder ansehen. Laut `docs/PROGRESS.md` in der Nacht gesetzt oder hier noch offen.
5. Den getesteten Build der Version 1.0 zuordnen.
6. Datenschutz-URL und Support-URL im Browser öffnen.

## 3. Vor dem Einreichen klären
1. Jodit ist mit Name, Logo, Texten und Kontaktadresse einverstanden.
2. Anbietername im Store stimmt (Inhaber des Developer-Kontos).
3. Hochaufgelöstes Logo eingesetzt, falls schon vorhanden.
4. Datenschutzerklärung von jemandem gelesen, der dafür geradesteht.

## 4. Einreichen
Erst jetzt in App Store Connect «Zur Prüfung hinzufügen» und einreichen. Die Prüfung durch Apple dauert danach noch, die App ist nicht sofort im Store.

## 5. Konkret offen aus der Nacht (10./11.11.2026)
Ausführlich in `docs/BERICHT.md`.

0. **TestFlight-Build wählen:** In TestFlight den neuesten Build nehmen (Build-Nummer als Zeitstempel, z. B. 202611110111). Build 1 ist das leere Gerüst, Build 2 ein Zwischenstand.

1. ~~App-Datenschutz veröffentlichen~~ erledigt am 11.11.2026 («Keine Daten erfasst»).
2. **iCloud-Sync prüfen**: Schema ist seit 11.11.2026 in Production (`Config/CloudKit/schema.ckdb`, über die CloudKit-Konsole importiert und übertragen). Auf zwei Geräten mit derselben Apple-ID ein Training anlegen und schauen, ob es auf dem anderen erscheint (kann einige Minuten dauern). Kommt nichts an: in der CloudKit-Konsole unter Logs nach Fehlern schauen und Claude Code melden.
3. **Watch mit echtem iPhone**: Watch-App öffnen, Training auf dem iPhone starten. Zeigt die Uhr Block und Countdown, vibriert sie beim Wechsel, wirken Pause/Vor/Zurück/Stopp?
4. **Weiterleitung zum iPad**: iPhone und iPad im selben WLAN, App auf beiden offen. Auf dem iPad die Anfrage «Fernbedienung erlauben?» bestätigen. Training auf dem iPad starten, auf dem iPhone «iPad steuern» öffnen, mit der Uhr Pause/Vor drücken. Test auch mit gesperrtem iPhone (erwartet: Verbindung reisst ab, Restrisiko im Bericht).
5. **Musik auf der Uhr**: Spotify auf dem iPhone, auf der Uhr ganz nach unten wischen (Musikseite). Play/Pause, nächster Titel, Lautstärke.
6. **Live Activity**: Beim ersten Training fragt iOS evtl. nach Live Activities; erlauben.
7. **Watch-Haptik bei gesenktem Handgelenk**: Die Uhr-App hält sich während eines Trainings mit einer erweiterten Laufzeit (Typ Physiotherapie, höchstens 1 Stunde) aktiv. Im Kurs prüfen, ob die Haptik bei jedem Blockwechsel auch mit gesenktem Arm kommt und ob nach 60 Minuten ein Hinweis erscheint.

## Neu (12.11.2026)
- **Verschieben im Baukasten:** Block kurz halten, ziehen, irgendwo in der Nähe loslassen. In eine Runde hinein (auch wenn sie nur einen Block hat), aus der Runde heraus, ganze Runde am Kopf anfassen. Spürt man die Haptik beim Anheben und Ablegen? Scrollt Wischen auf einem Block weiterhin?
- **Langes Training auf dem iPhone:** Block an den unteren Rand ziehen und halten: läuft die Zeitleiste nach?
- **iPad 11 Zoll hochkant:** Stehen die Bausteine rechts neben der Zeitleiste?
- **Töne:** Klingt der Countdown 3-2-1 sauber, auch mit Spotify im Hintergrund?
- **Glocke (neues Ton-Set, Standard):** Einstellungen › Ton-Set › «Glocke» wählen (bleibt sonst beim bisherigen Set), «Probehören», dann ein Tabata mit Spotify im Hintergrund. Klingt sie voll genug? Laut genug über der Musik? Stört es, dass die Musik rund 3 Sekunden nach dem Schlusston leise bleibt?
- **Fernbedienung beim ersten Start:** iPad-App frisch öffnen (Willkommensbildschirm steht) und daneben die iPhone-App öffnen: Erscheint «Fernbedienung erlauben?» über dem Willkommensbildschirm, und bleibt dieser stehen? Dasselbe einmal während eines laufenden Trainings auf dem iPad: Das Training muss weiterlaufen.
- **Dunkelmodus:** Wirken Knöpfe und Symbole in Bibliothek und Baukasten aktiv (hell), ist «Starten» gut lesbar, und hebt sich ein deaktiviertes «mal N» klar ab?

## Neu (11.11.2026)
- **Fortsetzen:** Training starten, App im App-Umschalter wegwischen, wieder öffnen: läuft das Training an der richtigen Stelle weiter?
- **Sperre:** Im Kurs sperren, mit der Uhr pausieren und weiterschalten; Entsperren mit langem Drücken.
- **Siri:** «Starte Tabata mit Fit mit Jodit», «Pause in Fit mit Jodit», «Nächster Block in Fit mit Jodit» (Deutsch und Englisch). Erscheinen die Trainings in der Kurzbefehle-App?
- **QR-Code:** Auf dem iPad QR-Code zeigen, mit einem zweiten iPhone (App installiert) über die Kamera scannen; aus 2–3 m Distanz versuchen.
- **Verlauf:** Nach dem Kurs prüfen, ob das Training im Verlauf steht und auf dem zweiten Gerät über iCloud erscheint.

