# Startprompt (am Abend, höchstens 10 Minuten, nur prüfen)

Start im Projektordner mit: `claude --model opus --chrome`

Chrome ist offen, mit der Erweiterung «Claude in Chrome», in einem eigenen Profil, in dem nur Apple angemeldet ist. Bei App Store Connect bist du bereits angemeldet.

```
Prüfe nur, ob für den Nachtlauf alles bereit ist. Ändere nichts
am Projekt, lege nichts an, lade nichts hoch. Höchstens
10 Minuten. Halte dich kurz.

1. Werkzeuge: Xcode-Version. Simulatoren für iPad 13 Zoll,
   iPhone 6,9 Zoll und iPhone Duo vorhanden? git? gh angemeldet,
   mit Rechten für Repositories und Workflows? Ruby und fastlane?
2. Paket: Sind docs/SPEC.md, docs/EINGABEN.md, CLAUDE.md,
   .gitignore, assets/icon/AppIcon-1024.png vorhanden? Erkennst
   du die Subagenten swift-helfer und build-pruefer?
3. docs/EINGABEN.md: Welche Felder sind leer? Liegt die
   .p8-Datei am angegebenen Pfad und ausserhalb dieses Ordners?
4. API-Schlüssel, nur lesend: Kommst du in App Store Connect?
   Welche Rolle hat der Schlüssel? Ist die Bundle-ID
   registriert? Gibt es den App-Eintrag mit dieser Bundle-ID?
   Gibt es die interne Testgruppe?
5. Chrome: Steht die Verbindung zur Erweiterung? Öffne
   appstoreconnect.apple.com und sag mir, ob ich angemeldet
   bin und ob offene Verträge oder Hinweise angezeigt werden.
   Gib nie ein Passwort oder einen Code ein, klicke nichts an.
6. Ist der Auto-Modus verfügbar? Wie spät ist es, und welche
   ZEITGRENZE steht in EINGABEN.md?
7. Lies docs/SPEC.md einmal quer. Nenne nur echte Widersprüche
   oder Lücken, die den Nachtlauf stoppen würden.

Antworte mit einer Ampel: pro Punkt grün oder rot, bei rot ein
Satz, was ich jetzt tun muss. Fehlt der App-Eintrag oder
funktioniert der API-Schlüssel nicht, nenne das zuerst: ohne
beides gibt es in der Nacht kein TestFlight.
```
