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
8. Die drei Ton-Sets anhören. Laut genug über Musik?
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
