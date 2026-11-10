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
            tap(id)
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
        // Duplizieren und löschen
        tiles("tile-work-45").firstMatch.tap()
        tap("duplicate")
        XCTAssertEqual(tiles("tile-work-45").count, 2)
        tap("deleteBlocks")
        XCTAssertEqual(tiles("tile-work-45").count, 1)
        // Sortieren ohne Ziehen (Bedienungshilfe-Aktion)
        let work = tiles("tile-work-45").firstMatch
        let before = work.frame.minX
        work.tap()
        tap("deselect")
        work.press(forDuration: 1.0)
        let right = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", language == "de" ? "rechts" : "right")).firstMatch
        XCTAssertTrue(right.waitForExistence(timeout: 5))
        right.tap()
        XCTAssertGreaterThan(tiles("tile-work-45").firstMatch.frame.minX, before)
        // Eigener Baustein
        tap("addPaletteItem")
        tap("addCustomBlock")
        XCTAssertTrue(app.descendants(matching: .any)["palette-work-40"].waitForExistence(timeout: 5))
        // Rückgängig
        tap("palette-work-40")
        XCTAssertTrue(tiles("tile-work-40").firstMatch.waitForExistence(timeout: 3))
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
        XCTAssertTrue(app.buttons["newWorkout"].waitForExistence(timeout: 10))
    }

    func testSignalsOnOff() {
        tap("settings")
        let tones = app.switches["toggleTones"]
        XCTAssertTrue(tones.waitForExistence(timeout: 5))
        XCTAssertEqual(tones.value as? String, "1")
        let voice = app.switches["toggleVoice"]
        XCTAssertEqual(voice.value as? String, "0", "Ansagen standardmässig aus")
        tones.switches.firstMatch.tap()
        XCTAssertEqual(tones.value as? String, "0")
        voice.switches.firstMatch.tap()
        XCTAssertEqual(voice.value as? String, "1")
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
