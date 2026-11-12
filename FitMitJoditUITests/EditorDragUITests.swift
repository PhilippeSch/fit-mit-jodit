import XCTest

/// Verschieben im Baukasten, so wie es jemand von Hand macht: Block halten, ziehen, irgendwo in der Nähe loslassen.
///
/// Anlass: Im Gerätetest vom 12.11.2026 liess sich ein Block nur ablegen, wenn man genau eine Kachel traf, und in
/// eine Runde mit nur einem Block kam man gar nicht hinein. Die bisherigen UI-Tests hatten das Ziehen nie benutzt,
/// nur den Knopf «Nach rechts». Diese Tests ziehen wirklich, lassen bewusst ungenau los (freie Fläche, Rand, weit
/// daneben) und prüfen, dass Wischen weiter scrollt und Antippen weiter markiert.
final class EditorDragUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch()
    }

    // MARK: Hilfen

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func tap(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let e = element(id)
        guard e.waitForExistence(timeout: 10) else { return XCTFail("\(id) fehlt\n\(app.debugDescription)", file: file, line: line) }
        let hittable = expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: e)
        wait(for: [hittable], timeout: 5)
        e.tap()
    }

    /// Baustein in der Palette antippen; liegt sie unten (schmale Breite), vorher hinwischen.
    private func tapInPalette(_ id: String) {
        let e = element(id)
        XCTAssertTrue(e.waitForExistence(timeout: 5), "\(id) fehlt")
        var tries = 0
        while !e.isHittable && tries < 6 { element("palette").swipeLeft(); tries += 1 }
        while !e.isHittable && tries < 12 { element("palette").swipeRight(); tries += 1 }
        e.tap()
    }

    private func tiles(_ id: String) -> XCUIElementQuery { app.buttons.matching(identifier: id) }
    private func tile(_ id: String) -> XCUIElement { tiles(id).firstMatch }
    private var round: XCUIElement { app.otherElements["round"].firstMatch }
    private var roundCounter: XCUIElement { app.buttons["roundCounter"].firstMatch }

    private func openNewWorkout() {
        tap("newWorkout")
        XCTAssertTrue(element("emptyTimeline").waitForExistence(timeout: 10))
    }

    /// Wie mit dem Finger: kurz halten, ziehen, am Ziel kurz verweilen, loslassen.
    private func drag(_ e: XCUIElement, to target: XCUICoordinate, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(e.waitForExistence(timeout: 5), "Element zum Ziehen fehlt", file: file, line: line)
        e.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.6, thenDragTo: target, withVelocity: .slow, thenHoldForDuration: 0.4)
        sleep(1) // Einrasten abwarten
    }

    private func point(in e: XCUIElement, _ dx: CGFloat, _ dy: CGFloat) -> XCUICoordinate {
        e.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
    }

    /// Stand vom Bildschirmfoto: eine Runde mit nur einem Arbeitsblock, die Pause steht dahinter.
    private func buildRoundWithPauseBehind() {
        openNewWorkout()
        tapInPalette("palette-work-45")
        tile("tile-work-45").tap()
        tap("makeRound")
        tap("applyRepeats")
        XCTAssertTrue(roundCounter.waitForExistence(timeout: 5))
        tapInPalette("palette-rest-15")
        XCTAssertTrue(tile("tile-rest-15").waitForExistence(timeout: 5))
        XCTAssertFalse(round.frame.contains(tile("tile-rest-15").frame), "Ausgangslage: Pause steht ausserhalb der Runde")
        XCTAssertTrue(roundCounter.label.contains("0:45"), roundCounter.label)
    }

    /// Lesereihenfolge: steht `a` vor `b` (gleiche Zeile weiter links, sonst weiter oben)?
    private func isBefore(_ a: XCUIElement, _ b: XCUIElement) -> Bool {
        let fa = a.frame, fb = b.frame
        return fa.maxY <= fb.minY + 1 || (fa.minY < fb.maxY && fa.minX < fb.minX)
    }

    // MARK: In die Runde hinein

    /// Der Fall aus dem Gerätetest: Pause auf die freie Fläche der Runde ziehen, ohne eine Kachel zu treffen.
    func testDragPauseIntoFreeSpaceOfRound() {
        buildRoundWithPauseBehind()
        drag(tile("tile-rest-15"), to: point(in: round, 0.8, 0.7))
        XCTAssertTrue(roundCounter.label.contains("1:00"), "Pause nicht in der Runde: \(roundCounter.label)")
        XCTAssertTrue(round.frame.contains(tile("tile-rest-15").frame), "Pause liegt nicht in der Runde")
        XCTAssertTrue(isBefore(tile("tile-work-45"), tile("tile-rest-15")), "Pause gehört hinter die Arbeit")
        // Kein Block bleibt angehoben oder markiert zurück.
        XCTAssertFalse(element("deselect").exists, "Ziehen hat einen Block markiert")
    }

    /// Auf den Kopf der Runde gezogen (Zähler, Dauer): landet ebenfalls in der Runde.
    func testDragPauseOntoRoundHeader() {
        buildRoundWithPauseBehind()
        drag(tile("tile-rest-15"), to: point(in: round, 0.7, 0.15))
        XCTAssertTrue(roundCounter.label.contains("1:00"), "Pause nicht in der Runde: \(roundCounter.label)")
    }

    /// Auf die linke Hälfte des Blocks in der Runde: davor. So lässt sich die Reihenfolge wählen.
    func testDragPauseBeforeBlockInRound() {
        buildRoundWithPauseBehind()
        drag(tile("tile-rest-15"), to: point(in: tile("tile-work-45"), 0.15, 0.5))
        XCTAssertTrue(roundCounter.label.contains("1:00"), "Pause nicht in der Runde: \(roundCounter.label)")
        XCTAssertTrue(isBefore(tile("tile-rest-15"), tile("tile-work-45")), "Pause gehört vor die Arbeit")
    }

    // MARK: Aus der Runde heraus

    /// Block aus der Runde auf die leere Fläche weit unter der Zeitleiste: landet am Ende, ausserhalb der Runde.
    func testDragBlockOutOfRoundIntoEmptySpace() {
        buildRoundWithPauseBehind()
        drag(tile("tile-rest-15"), to: point(in: round, 0.8, 0.7))
        XCTAssertTrue(roundCounter.label.contains("1:00"))
        drag(tile("tile-rest-15"), to: point(in: round, 0.5, 1.0).withOffset(CGVector(dx: 0, dy: 90)))
        XCTAssertTrue(roundCounter.label.contains("0:45"), "Pause noch in der Runde: \(roundCounter.label)")
        XCTAssertFalse(round.frame.contains(tile("tile-rest-15").frame))
        XCTAssertTrue(isBefore(round, tile("tile-rest-15")), "Pause gehört hinter die Runde")
    }

    // MARK: Umsortieren

    /// Drei Blöcke nebeneinander: den letzten nach vorn ziehen, den ersten ganz nach hinten ins Leere.
    func testReorderBlocksByDragging() {
        openNewWorkout()
        for id in ["palette-work-45", "palette-rest-15", "palette-work-30"] { tapInPalette(id) }
        let a = tile("tile-work-45"), b = tile("tile-rest-15"), c = tile("tile-work-30")
        XCTAssertTrue(isBefore(a, b) && isBefore(b, c))
        // Letzten vor den ersten: linke Kante des ersten treffen reicht.
        drag(c, to: point(in: a, 0.1, 0.5))
        XCTAssertTrue(isBefore(c, a) && isBefore(a, b), "erwartet 30, 45, 15")
        // Jetzt den vordersten ins Leere rechts unten: ans Ende.
        drag(c, to: point(in: b, 1.0, 1.0).withOffset(CGVector(dx: 60, dy: 120)))
        XCTAssertTrue(isBefore(a, b) && isBefore(b, c), "erwartet wieder 45, 15, 30")
    }

    /// Eine ganze Runde am Kopf anfassen und hinter den Block dahinter ziehen.
    func testDragWholeRound() {
        buildRoundWithPauseBehind()
        XCTAssertTrue(isBefore(round, tile("tile-rest-15")))
        let handle = point(in: round, 0.6, 0.15)
        let target = point(in: tile("tile-rest-15"), 0.5, 1.0).withOffset(CGVector(dx: 40, dy: 70))
        handle.press(forDuration: 0.6, thenDragTo: target, withVelocity: .slow, thenHoldForDuration: 0.4)
        sleep(1)
        XCTAssertTrue(isBefore(tile("tile-rest-15"), round), "Runde gehört hinter die Pause")
        XCTAssertTrue(roundCounter.label.contains("0:45"), "Inhalt der Runde unverändert")
    }

    // MARK: Ziehen darf nichts anderes stören

    /// Wischen, das auf einem Block beginnt, scrollt und verschiebt nichts; Antippen markiert.
    func testSwipeOnBlocksScrollsAndTapSelects() {
        let row = element("workout-Ganzkörper 20")
        let list = app.collectionViews.firstMatch
        var n = 0
        while !(row.exists && row.isHittable) && n < 6 { list.swipeUp(velocity: .slow); n += 1 }
        if n > 0 { sleep(1) }
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.textFields["workoutName"].waitForExistence(timeout: 10))
        let total = element("totalDuration").label
        let all = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'tile-'"))
        let first = all.element(boundBy: 0), last = all.element(boundBy: all.count - 1)
        let labelsBefore = (0..<all.count).map { all.element(boundBy: $0).label }
        let start = element("start")
        let startY = start.frame.minY
        // Auf einem Block ansetzen und zügig nach oben wischen.
        let from = point(in: all.element(boundBy: 6), 0.5, 0.5)
        from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: 0, dy: -260)), withVelocity: .fast, thenHoldForDuration: 0)
        sleep(1)
        XCTAssertEqual((0..<all.count).map { all.element(boundBy: $0).label }, labelsBefore, "Wischen hat Blöcke verschoben")
        XCTAssertEqual(element("totalDuration").label, total)
        XCTAssertFalse(element("deselect").exists, "Wischen hat einen Block markiert")
        // Wo der Inhalt nicht ganz auf den Bildschirm passt, muss er sich bewegt haben.
        let lastVisible = last.exists && last.isHittable
        if !lastVisible || start.frame.minY != startY {
            XCTAssertLessThan(start.frame.minY, startY, "Wischen auf einem Block scrollt nicht")
        }
        // Antippen markiert weiterhin.
        let target = first.isHittable ? first : all.element(boundBy: 8)
        target.tap()
        XCTAssertTrue(element("deselect").waitForExistence(timeout: 5), "Antippen markiert nicht")
        XCTAssertTrue(target.isSelected)
    }

    /// Langes Training auf kleinem Bildschirm: Block halten, an den unteren Rand ziehen, die Zeitleiste läuft nach,
    /// und er lässt sich am Ende ablegen.
    func testDragToEdgeScrollsAlong() {
        let row = element("workout-Ganzkörper 20")
        let list = app.collectionViews.firstMatch
        var n = 0
        while !(row.exists && row.isHittable) && n < 6 { list.swipeUp(velocity: .slow); n += 1 }
        if n > 0 { sleep(1) }
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.textFields["workoutName"].waitForExistence(timeout: 10))
        // Am Ende drei Blöcke anhängen, damit der Inhalt sicher länger ist als ein iPhone-Bildschirm.
        for _ in 0..<3 { tapInPalette("palette-rest-60") }
        let scroll = element("editorScroll")
        // Erster Block der Runde (die Reihenfolge der Abfrage ist nicht die Reihenfolge auf dem Bildschirm).
        let first = app.buttons.matching(NSPredicate(format: "identifier == 'tile-work-40' AND label CONTAINS 'Hampelmann'")).firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(round.frame.contains(first.frame), "Ausgangslage: Block liegt in der Runde")
        let before = roundCounter.label
        // Nach oben, falls das Anhängen gescrollt hat.
        var up = 0
        while !first.isHittable && up < 4 { scroll.swipeDown(); up += 1 }
        if up > 0 { sleep(1) }
        // Block an den unteren Rand der Zeitleiste ziehen und dort halten, bis sie nachgelaufen ist.
        let edge = point(in: scroll, 0.6, 1.0).withOffset(CGVector(dx: 0, dy: -24))
        first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.6, thenDragTo: edge, withVelocity: .slow, thenHoldForDuration: 3)
        sleep(1)
        XCTAssertNotEqual(roundCounter.label, before, "Block hat die Runde nicht verlassen")
        // Er steht jetzt bei den angehängten Blöcken am Ende: hinter der Runde und hinter einem der angehängten Blöcke.
        XCTAssertFalse(round.frame.contains(first.frame), "Block liegt noch in der Runde")
        XCTAssertTrue(isBefore(round, first), "Block gehört hinter die Runde")
        XCTAssertTrue(isBefore(tile("tile-rest-60"), first), "Block ist nicht bis zu den letzten Blöcken gekommen")
    }

    /// Lange drücken, ohne zu ziehen: zählt wie Antippen. Der Block wird markiert und bleibt an seinem Platz.
    func testLongPressWithoutMovingSelects() {
        openNewWorkout()
        tapInPalette("palette-work-45")
        tapInPalette("palette-rest-15")
        let work = tile("tile-work-45")
        XCTAssertTrue(work.waitForExistence(timeout: 5))
        work.press(forDuration: 0.8)
        XCTAssertTrue(element("deselect").waitForExistence(timeout: 5), "langes Drücken markiert nicht")
        XCTAssertTrue(work.isSelected)
        XCTAssertFalse(tile("tile-rest-15").isSelected)
        XCTAssertTrue(isBefore(work, tile("tile-rest-15")), "Reihenfolge hat sich geändert")
    }

    // MARK: Ohne Ziehen

    /// «Nach links» geht der Reihe nach: in die Runde hinein, darin weiter, vorn wieder hinaus.
    func testArrowButtonsStepThroughRound() {
        buildRoundWithPauseBehind()
        let rest = tile("tile-rest-15"), work = tile("tile-work-45")
        rest.tap()
        tap("selMoveLeft")
        XCTAssertTrue(roundCounter.label.contains("1:00"), "Pause nicht in der Runde: \(roundCounter.label)")
        XCTAssertTrue(isBefore(work, rest))
        tap("selMoveLeft")
        XCTAssertTrue(roundCounter.label.contains("1:00"))
        XCTAssertTrue(isBefore(rest, work), "Pause gehört jetzt vor die Arbeit")
        tap("selMoveLeft")
        XCTAssertTrue(roundCounter.label.contains("0:45"), "Pause noch in der Runde: \(roundCounter.label)")
        XCTAssertTrue(isBefore(rest, round), "Pause gehört vor die Runde")
    }
}
