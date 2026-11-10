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
Der Kettentest (Teil 0 der SPEC) trägt hier die exakten Befehle ein, sobald das Xcode-Projekt steht:
- Build iPad:
- Build iPhone:
- Build iPhone Duo:
- Build Apple Watch:
- Unit-Tests:
- UI-Tests:
- Archiv und Upload (fastlane):
- Store-Texte und Screenshots (fastlane):
