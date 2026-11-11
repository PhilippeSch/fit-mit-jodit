import XCTest

/// Hauptabläufe auf iPad, iPhone und iPhone Duo. Läuft in der Gerätesprache des Simulators;
/// für den zweiten Durchgang wird die Sprache über die Startargumente umgestellt (siehe `language`).
class FlowUITests: XCTestCase {
    /// Überschreiben, um die Sprache zu wechseln.
    var language: String { "de" }

    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-AppleLanguages", "(\(language))", "-AppleLocale", language == "de" ? "de_CH" : "en_US"]
        app.launch()
    }

    // MARK: Hilfen

    private func tap(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let e = app.descendants(matching: .any)[id].firstMatch
        XCTAssertTrue(e.waitForExistence(timeout: 10), "\(id) fehlt", file: file, line: line)
        // Warten, bis Übergänge (Navigation, Blätter) abgeschlossen sind.
        let hittable = expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: e)
        wait(for: [hittable], timeout: 5)
        e.tap()
    }

    /// Wischt die Palette, bis der Baustein sichtbar ist (wie von Hand).
    private func tapInPalette(_ id: String) {
        let e = app.descendants(matching: .any)[id].firstMatch
        XCTAssertTrue(e.waitForExistence(timeout: 5), "\(id) fehlt")
        var tries = 0
        while !e.isHittable && tries < 6 {
            app.descendants(matching: .any)["palette"].firstMatch.swipeLeft()
            tries += 1
        }
        while !e.isHittable && tries < 12 {
            app.descendants(matching: .any)["palette"].firstMatch.swipeRight()
            tries += 1
        }
        e.tap()
    }

    private func openNewWorkout() {
        tap("newWorkout")
        XCTAssertTrue(app.descendants(matching: .any)["emptyTimeline"].waitForExistence(timeout: 10))
    }

    private func tiles(_ id: String) -> XCUIElementQuery { app.buttons.matching(identifier: id) }

    // MARK: Abläufe

    /// Abnahme 2: «3 × 45 s Arbeit mit 15 s Pause, 1 min Pause, mal 4» zusammenklicken.
    func testBuildCircuitFromBlocks() {
        let started = Date()
        openNewWorkout()
        for id in ["palette-work-45", "palette-rest-15", "palette-work-45", "palette-rest-15", "palette-work-45", "palette-rest-60"] {
            tapInPalette(id)
        }
        XCTAssertEqual(tiles("tile-work-45").count, 3)
        // Alle Blöcke markieren und «mal 4»
        for i in 0..<3 { tiles("tile-work-45").element(boundBy: i).tap() }
        for i in 0..<2 { tiles("tile-rest-15").element(boundBy: i).tap() }
        tiles("tile-rest-60").firstMatch.tap()
        tap("makeRound")
        let stepper = app.steppers["repeatsStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        tap("applyRepeats")
        XCTAssertTrue(app.buttons["roundCounter"].waitForExistence(timeout: 5))
        let total = app.descendants(matching: .any)["totalDuration"].firstMatch
        XCTAssertTrue(total.label.contains("14:00"), "Gesamtdauer: \(total.label)")
        XCTAssertLessThan(Date().timeIntervalSince(started), 60, "in unter einer Minute zusammengeklickt")
    }

    func testPickExerciseCustomBlockDuplicateDeleteSort() {
        openNewWorkout()
        tap("palette-work-45")
        tap("palette-rest-15")
        // Übung wählen
        tiles("tile-work-45").firstMatch.tap()
        tap("pickExercise")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Burpee")
        let first = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'exercise-'")).firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        let name = first.label
        first.tap()
        XCTAssertTrue(tiles("tile-work-45").firstMatch.label.contains(name))
        // Duplizieren und löschen (Auswahl nach «Übung wählen» erst aufheben)
        tap("deselect")
        tiles("tile-work-45").firstMatch.tap()
        tap("duplicate")
        XCTAssertEqual(tiles("tile-work-45").count, 2)
        tap("deleteBlocks")
        XCTAssertEqual(tiles("tile-work-45").count, 1)
        // Sortieren ohne Ziehen (Bedienungshilfe-Aktion)
        let work = tiles("tile-work-45").firstMatch
        let before = work.frame.minX
        // Sortieren ohne Ziehen: Block markieren, «Nach rechts»
        work.tap()
        tap("selMoveRight")
        tap("deselect")
        sleep(1)
        // Nach dem Verschieben steht die Arbeit hinter der Pause (gleiche Zeile: weiter rechts, sonst tiefer).
        let w = tiles("tile-work-45").firstMatch.frame, r = tiles("tile-rest-15").firstMatch.frame
        XCTAssertTrue(w.minX > r.minX || w.minY > r.minY, "Reihenfolge unverändert: Arbeit \(w), Pause \(r)")
        _ = before
        // Eigener Baustein
        tap("addPaletteItem")
        tap("addCustomBlock")
        XCTAssertTrue(app.descendants(matching: .any)["palette-work-40"].waitForExistence(timeout: 5))
        tapInPalette("palette-work-40")
        XCTAssertTrue(tiles("tile-work-40").firstMatch.waitForExistence(timeout: 3))
    }

    /// Lange Trainings: bis zum letzten Block scrollen und ihn bearbeiten (Fehler aus dem Gerätetest am 11.11.2026).
    func testScrollToLastBlockInLongWorkout() {
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == 'workout-Kraft' OR identifier == 'workout-Strength'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.textFields["workoutName"].waitForExistence(timeout: 10))
        // Erst einen Block markieren, damit die Auswahl-Leiste Platz braucht.
        tiles("tile-work-60").firstMatch.tap()
        let last = tiles("tile-rest-90").firstMatch
        XCTAssertTrue(last.waitForExistence(timeout: 5))
        sleep(1) // Auswahl-Leiste gleitet herein
        // Antippen scrollt den Block ins Bild (wie von Hand). Liegt er unter Leiste oder Palette,
        // trifft der Tipp nicht den Block und er wird nicht markiert.
        last.tap()
        XCTAssertTrue(last.isSelected, "Letzter Block nicht erreichbar oder nicht markierbar")
        tap("pickDuration")
        XCTAssertTrue(app.buttons["applyDuration"].waitForExistence(timeout: 5))
        tap("applyDuration")
    }

    func testFavoriteAndDelete() {
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-'")).element(boundBy: 2)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.press(forDuration: 1.2)
        let fav = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", language == "de" ? "Favorit" : "favorite")).firstMatch
        XCTAssertTrue(fav.waitForExistence(timeout: 5))
        fav.tap()
        XCTAssertTrue(app.images.matching(NSPredicate(format: "label CONTAINS[c] %@", language == "de" ? "Favorit" : "Favorite")).firstMatch.waitForExistence(timeout: 5))
        // Löschen mit Rückfrage
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-'"))
        let count = rows.count
        rows.element(boundBy: count - 1).press(forDuration: 1.2)
        let del = app.buttons.matching(NSPredicate(format: "label == %@", language == "de" ? "Löschen" : "Delete")).firstMatch
        XCTAssertTrue(del.waitForExistence(timeout: 5))
        del.tap()
        tap("confirmDelete")
        XCTAssertEqual(rows.count, count - 1)
    }

    func testRunPauseSkipStop() {
        let circuit = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-Zirkel' OR identifier BEGINSWITH 'workout-Circuit'")).firstMatch
        XCTAssertTrue(circuit.waitForExistence(timeout: 10))
        circuit.tap()
        XCTAssertTrue(app.textFields["workoutName"].waitForExistence(timeout: 10))
        tap("start")
        XCTAssertTrue(app.descendants(matching: .any)["countdown"].waitForExistence(timeout: 10))
        // Knöpfe einblenden, pausieren
        app.descendants(matching: .any)["countdown"].firstMatch.tap()
        tap("pauseResume")
        XCTAssertTrue(app.descendants(matching: .any)["pausedBadge"].waitForExistence(timeout: 5))
        // Block überspringen (Vorlauf → erste Arbeit)
        tap("skipForward")
        let title = app.descendants(matching: .any)["runTitle"].firstMatch
        XCTAssertTrue(title.label == (language == "de" ? "Arbeit" : "Work"), "Titel: \(title.label)")
        // Stopp mit Bestätigung
        tap("stop")
        tap("confirmStop")
        // Zurück im Training, die Laufansicht ist weg.
        XCTAssertTrue(app.textFields["workoutName"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["countdown"].exists)
    }

    /// Sperre: Tippen zeigt keine Knöpfe mehr, Entsperren nur mit langem Drücken.
    func testLockRunScreen() {
        let circuit = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-Zirkel' OR identifier BEGINSWITH 'workout-Circuit'")).firstMatch
        XCTAssertTrue(circuit.waitForExistence(timeout: 10))
        circuit.tap()
        XCTAssertTrue(app.textFields["workoutName"].waitForExistence(timeout: 10))
        tap("start")
        let countdown = app.descendants(matching: .any)["countdown"].firstMatch
        XCTAssertTrue(countdown.waitForExistence(timeout: 10))
        countdown.tap()
        tap("lock")
        let pause = app.descendants(matching: .any)["pauseResume"].firstMatch
        XCTAssertTrue(pause.waitForNonExistence(timeout: 5))
        countdown.tap()
        let unlock = app.descendants(matching: .any)["unlock"].firstMatch
        XCTAssertTrue(unlock.waitForExistence(timeout: 5))
        XCTAssertFalse(pause.exists, "Knöpfe trotz Sperre sichtbar")
        // Kurzes Tippen entsperrt nicht
        unlock.tap()
        XCTAssertFalse(pause.exists)
        unlock.press(forDuration: 1.5)
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        pause.tap() // pausiert: Knöpfe bleiben sichtbar
        XCTAssertTrue(app.descendants(matching: .any)["pausedBadge"].waitForExistence(timeout: 5))
        tap("stop")
        tap("confirmStop")
    }

    func testSignalsOnOff() {
        tap("settings")
        let tones = app.switches["toggleTones"]
        XCTAssertTrue(tones.waitForExistence(timeout: 5))
        XCTAssertEqual(tones.value as? String, "1")
        // Ansagen standardmässig «Automatisch» (nur Trainings mit Übungsnamen)
        let auto = app.buttons[language == "de" ? "Automatisch" : "Automatic"]
        XCTAssertTrue(auto.waitForExistence(timeout: 5))
        XCTAssertTrue(auto.isSelected, "Ansagen standardmässig «Automatisch»")
        tones.switches.firstMatch.tap()
        XCTAssertEqual(tones.value as? String, "0")
        app.buttons[language == "de" ? "Aus" : "Off"].tap()
        XCTAssertTrue(app.buttons[language == "de" ? "Aus" : "Off"].isSelected)
        XCTAssertFalse(app.switches["toggleVoiceDetailed"].exists)
        app.buttons[language == "de" ? "Immer" : "Always"].tap()
        // Auf kleineren Blättern (iPad) liegt der Schalter evtl. unterhalb des sichtbaren Bereichs
        let detailed = app.switches["toggleVoiceDetailed"]
        var t = 0
        while !detailed.waitForExistence(timeout: 1) && t < 4 { app.swipeUp(); t += 1 }
        XCTAssertTrue(detailed.exists)
        tap("closeSettings")
    }

    func testExport() {
        let circuit = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-'")).firstMatch
        XCTAssertTrue(circuit.waitForExistence(timeout: 10))
        circuit.tap()
        tap("export")
        // Teilen-Blatt erscheint
        let sheet = app.otherElements["ActivityListView"].firstMatch
        let anyShare = app.navigationBars["UIActivityContentView"].firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 8) || anyShare.exists || app.collectionViews.count > 0)
    }

    func testAccessibilityAudit() throws {
        try app.performAccessibilityAudit(for: [.dynamicType, .sufficientElementDescription, .hitRegion]) { issue in
            // Systemelemente (Suchfeld, Navigationsleiste) sind nicht unsere.
            issue.element?.elementType == .searchField || issue.element?.elementType == .navigationBar
        }
        let circuit = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-'")).firstMatch
        if circuit.waitForExistence(timeout: 5) { circuit.tap() }
        try app.performAccessibilityAudit(for: [.sufficientElementDescription]) { issue in
            issue.element?.elementType == .searchField || issue.element?.elementType == .navigationBar
        }
    }
}

final class FlowUITestsEnglish: FlowUITests {
    override var language: String { "en" }
}
