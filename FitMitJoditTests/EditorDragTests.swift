import XCTest
@testable import FitMitJodit

/// Verschieben im Baukasten: Einfügestelle zu einem Punkt (reine Geometrie) und Ablegen im Modell.
/// Ausgangslage aus dem Gerätetest vom 12.11.2026: Ein Block liess sich nur ablegen, wenn man genau eine
/// Kachel traf, und in eine Runde mit nur einem Block kam man gar nicht hinein.
@MainActor
final class EditorDragTests: XCTestCase {

    // MARK: Einfügestelle finden

    /// Drei Kacheln in einer Zeile, darunter eine zweite Zeile mit einer Kachel.
    private func twoRows() -> [DropLocator.Entry] {
        [CGRect(x: 0, y: 0, width: 100, height: 56), CGRect(x: 108, y: 0, width: 60, height: 56),
         CGRect(x: 176, y: 0, width: 100, height: 56), CGRect(x: 0, y: 68, width: 100, height: 56)]
            .map { DropLocator.Entry(id: UUID(), frame: $0, blocks: nil) }
    }

    /// Block, Runde mit zwei Blöcken (volle Breite), Block: wie auf dem Bildschirm untereinander.
    private func withRound() -> (entries: [DropLocator.Entry], round: UUID) {
        let round = UUID()
        let entries = [
            DropLocator.Entry(id: UUID(), frame: CGRect(x: 0, y: 0, width: 100, height: 56), blocks: nil),
            DropLocator.Entry(id: round, frame: CGRect(x: 0, y: 68, width: 400, height: 130),
                              blocks: [(UUID(), CGRect(x: 8, y: 128, width: 100, height: 56)),
                                       (UUID(), CGRect(x: 114, y: 128, width: 60, height: 56))]),
            DropLocator.Entry(id: UUID(), frame: CGRect(x: 0, y: 210, width: 100, height: 56), blocks: nil),
        ]
        return (entries, round)
    }

    private func slot(_ p: CGPoint, _ e: [DropLocator.Entry], round: Bool = false) -> DropSlot? {
        DropLocator.locate(point: p, entries: e, draggingRound: round)?.slot
    }

    func testEveryPointHasATarget() {
        let e = twoRows()
        // Auch weit daneben: links oben, rechts unten, im Zwischenraum.
        for p in [CGPoint(x: -200, y: -300), CGPoint(x: 900, y: 900), CGPoint(x: 104, y: 62), CGPoint(x: 500, y: 20)] {
            XCTAssertNotNil(slot(p, e), "kein Ziel für \(p)")
        }
        XCTAssertNil(DropLocator.locate(point: .zero, entries: [], draggingRound: false))
    }

    func testLeftHalfInsertsBeforeRightHalfAfter() {
        let e = twoRows()
        XCTAssertEqual(slot(CGPoint(x: 120, y: 30), e), DropSlot(item: 1), "linke Hälfte der zweiten Kachel: davor")
        XCTAssertEqual(slot(CGPoint(x: 160, y: 30), e), DropSlot(item: 2), "rechte Hälfte der zweiten Kachel: danach")
        XCTAssertEqual(slot(CGPoint(x: 10, y: 30), e), DropSlot(item: 0))
    }

    func testFreeSpaceRightOfARowAppendsToThatRow() {
        let e = twoRows()
        XCTAssertEqual(slot(CGPoint(x: 380, y: 30), e), DropSlot(item: 3), "rechts neben der ersten Zeile: hinter deren letzter Kachel")
        XCTAssertEqual(slot(CGPoint(x: 380, y: 100), e), DropSlot(item: 4), "rechts neben der letzten Zeile: ans Ende")
        XCTAssertEqual(slot(CGPoint(x: 200, y: 600), e), DropSlot(item: 4), "weit unter der Zeitleiste: ans Ende")
    }

    func testIndicatorSitsInTheGap() throws {
        let e = twoRows()
        let t = try XCTUnwrap(DropLocator.locate(point: CGPoint(x: 120, y: 30), entries: e, draggingRound: false))
        // Zwischen erster (bis 100) und zweiter Kachel (ab 108), so hoch wie die Zeile.
        XCTAssertEqual(t.indicator.midX, 104, accuracy: 0.01)
        XCTAssertEqual(t.indicator.minY, 0)
        XCTAssertEqual(t.indicator.height, 56)
        XCTAssertNil(t.roundID)
    }

    func testDropAnywhereInsideRoundLandsInRound() throws {
        let (e, round) = withRound()
        // Freie Fläche rechts neben den Blöcken: ans Ende der Runde.
        let free = try XCTUnwrap(DropLocator.locate(point: CGPoint(x: 320, y: 150), entries: e, draggingRound: false))
        XCTAssertEqual(free.slot, DropSlot(item: 1, inner: 2))
        XCTAssertEqual(free.roundID, round)
        // Kopfzeile der Runde (über den Blöcken): die waagrechte Lage entscheidet.
        XCTAssertEqual(slot(CGPoint(x: 300, y: 95), e), DropSlot(item: 1, inner: 2))
        XCTAssertEqual(slot(CGPoint(x: 20, y: 95), e), DropSlot(item: 1, inner: 0))
        // Zwischen den beiden Blöcken.
        XCTAssertEqual(slot(CGPoint(x: 100, y: 150), e), DropSlot(item: 1, inner: 1))
    }

    func testEdgeOfRoundCountsAsBeforeOrAfter() throws {
        let (e, _) = withRound()
        let above = try XCTUnwrap(DropLocator.locate(point: CGPoint(x: 200, y: 72), entries: e, draggingRound: false))
        XCTAssertEqual(above.slot, DropSlot(item: 1), "oberer Rand der Runde: davor")
        XCTAssertNil(above.roundID)
        XCTAssertGreaterThan(above.indicator.width, above.indicator.height, "vor einer Runde: waagrechter Balken")
        XCTAssertEqual(slot(CGPoint(x: 200, y: 194), e), DropSlot(item: 2), "unterer Rand der Runde: danach")
    }

    func testDraggedRoundNeverTargetsInsideARound() {
        let (e, _) = withRound()
        XCTAssertEqual(slot(CGPoint(x: 200, y: 100), e, round: true), DropSlot(item: 1), "obere Hälfte: vor die Runde")
        XCTAssertEqual(slot(CGPoint(x: 200, y: 170), e, round: true), DropSlot(item: 2), "untere Hälfte: hinter die Runde")
        XCTAssertEqual(slot(CGPoint(x: 80, y: 30), e, round: true), DropSlot(item: 1), "rechte Hälfte des ersten Blocks: danach")
    }

    func testRowsSplitByVerticalPosition() {
        let frames = twoRows().map(\.frame)
        XCTAssertEqual(DropLocator.rows(of: frames), [[0, 1, 2], [3]])
    }

    // MARK: Ablegen im Modell

    /// Vorbereitung, Runde mit einem Arbeitsblock, Pause dahinter: der Stand vom Bildschirmfoto.
    private func screenshotCase() -> (m: EditorModel, prep: UUID, work: UUID, rest: UUID, round: UUID) {
        let m = EditorModel(workout: Workout(name: "Neu", items: []))
        let prep = m.append(kind: .prep, seconds: 10)
        let work = m.append(kind: .work, seconds: 45)
        m.selection = [work]
        let round = m.makeRound(repeats: 4)!
        let rest = m.append(kind: .rest, seconds: 15)
        return (m, prep, work, rest, round)
    }

    private func roundBlocks(_ m: EditorModel, _ index: Int) -> [UUID] {
        if case .round(let r) = m.items[index] { return r.blocks.map(\.id) }
        return []
    }

    func testDropPauseIntoRoundWithSingleBlock() {
        let c = screenshotCase()
        XCTAssertTrue(c.m.wouldMove(c.rest, to: DropSlot(item: 1, inner: 1)))
        XCTAssertTrue(c.m.move(c.rest, to: DropSlot(item: 1, inner: 1)))
        XCTAssertEqual(c.m.items.map(\.id), [c.prep, c.round])
        XCTAssertEqual(roundBlocks(c.m, 1), [c.work, c.rest], "Pause hinter der Arbeit in der Runde")
        c.m.undo()
        XCTAssertEqual(c.m.items.map(\.id), [c.prep, c.round, c.rest], "ein Schritt zurück stellt alles wieder her")
    }

    func testDropBeforeBlockInsideRound() {
        let c = screenshotCase()
        XCTAssertTrue(c.m.move(c.prep, to: DropSlot(item: 1, inner: 0)))
        // Der Vorlauf stand vor der Runde: Die Runde rückt um eins nach vorn, das Ziel bleibt dieselbe Runde.
        XCTAssertEqual(c.m.items.map(\.id), [c.round, c.rest])
        XCTAssertEqual(roundBlocks(c.m, 0), [c.prep, c.work])
    }

    func testDropOutOfRoundToEnd() {
        let c = screenshotCase()
        c.m.move(c.rest, to: DropSlot(item: 1, inner: 1))
        XCTAssertTrue(c.m.move(c.work, to: DropSlot(item: 2)))
        XCTAssertEqual(roundBlocks(c.m, 1), [c.rest])
        XCTAssertEqual(c.m.items.map(\.id), [c.prep, c.round, c.work])
    }

    func testLastBlockLeavingRoundRemovesRound() {
        let c = screenshotCase()
        XCTAssertTrue(c.m.move(c.work, to: DropSlot(item: 3)))
        XCTAssertEqual(c.m.items.map(\.id), [c.prep, c.rest, c.work], "leere Runde verschwindet, die Stelle zählt richtig weiter")
    }

    func testDroppingWhereItAlreadyIsChangesNothing() {
        let c = screenshotCase()
        let undoBefore = c.m.canUndo
        // Vor und hinter sich selbst, und der einzige Block in seiner eigenen Runde.
        for (id, slot) in [(c.rest, DropSlot(item: 2)), (c.rest, DropSlot(item: 3)),
                           (c.work, DropSlot(item: 1, inner: 0)), (c.work, DropSlot(item: 1, inner: 1)),
                           (c.round, DropSlot(item: 1)), (c.round, DropSlot(item: 2))] {
            XCTAssertFalse(c.m.wouldMove(id, to: slot))
            XCTAssertFalse(c.m.move(id, to: slot))
        }
        XCTAssertEqual(c.m.items.map(\.id), [c.prep, c.round, c.rest])
        XCTAssertEqual(c.m.canUndo, undoBefore)
        var undoSteps = 0
        while c.m.canUndo { c.m.undo(); undoSteps += 1 }
        XCTAssertEqual(undoSteps, 4, "nur die vier Schritte des Aufbaus, kein leerer Rückgängig-Schritt")
    }

    func testMoveWithinRound() {
        let m = EditorModel(workout: Workout(name: "x", items: []))
        let a = m.append(kind: .work, seconds: 30), b = m.append(kind: .rest, seconds: 10), c = m.append(kind: .work, seconds: 20)
        m.selection = [a, b, c]
        m.makeRound(repeats: 2)
        XCTAssertTrue(m.move(a, to: DropSlot(item: 0, inner: 3)))
        XCTAssertEqual(roundBlocks(m, 0), [b, c, a])
        XCTAssertTrue(m.move(a, to: DropSlot(item: 0, inner: 1)))
        XCTAssertEqual(roundBlocks(m, 0), [b, a, c])
    }

    func testMoveBetweenRounds() {
        let m = EditorModel(workout: Workout(name: "x", items: []))
        let a = m.append(kind: .work, seconds: 30), b = m.append(kind: .rest, seconds: 10)
        let c = m.append(kind: .work, seconds: 20), d = m.append(kind: .rest, seconds: 5)
        m.selection = [a, b]
        m.makeRound(repeats: 2)
        m.selection = [c, d]
        m.makeRound(repeats: 3)
        XCTAssertTrue(m.move(a, to: DropSlot(item: 1, inner: 1)))
        XCTAssertEqual(roundBlocks(m, 0), [b])
        XCTAssertEqual(roundBlocks(m, 1), [c, a, d])
    }

    func testMoveWholeRound() {
        let c = screenshotCase()
        XCTAssertTrue(c.m.move(c.round, to: DropSlot(item: 3)))
        XCTAssertEqual(c.m.items.map(\.id), [c.prep, c.rest, c.round])
        XCTAssertTrue(c.m.move(c.round, to: DropSlot(item: 0)))
        XCTAssertEqual(c.m.items.map(\.id), [c.round, c.prep, c.rest])
        XCTAssertEqual(roundBlocks(c.m, 0), [c.work], "der Inhalt der Runde bleibt")
    }

    func testRoundCannotBeDroppedIntoRound() {
        let c = screenshotCase()
        XCTAssertFalse(c.m.move(c.round, to: DropSlot(item: 1, inner: 0)))
        XCTAssertEqual(c.m.items.map(\.id), [c.prep, c.round, c.rest])
    }

    func testUnknownBlockOrBrokenSlotChangesNothing() {
        let c = screenshotCase()
        XCTAssertFalse(c.m.move(UUID(), to: DropSlot(item: 0)))
        // Stelle zeigt auf einen Block statt auf eine Runde.
        XCTAssertFalse(c.m.move(c.rest, to: DropSlot(item: 0, inner: 0)))
        XCTAssertEqual(c.m.items.map(\.id), [c.prep, c.round, c.rest])
        // Zu grosse Zahlen landen am Ende statt abzustürzen.
        XCTAssertTrue(c.m.move(c.prep, to: DropSlot(item: 99)))
        XCTAssertEqual(c.m.items.map(\.id), [c.round, c.rest, c.prep])
    }

    // MARK: Ohne Ziehen: «Nach links» und «Nach rechts»

    /// Die Pfeile gehen der Reihe nach durch die Zeitleiste, auch in eine Runde hinein und wieder hinaus.
    func testArrowsStepThroughRound() {
        let m = EditorModel(workout: Workout(name: "x", items: []))
        let a = m.append(kind: .prep, seconds: 10), x = m.append(kind: .work, seconds: 45)
        let y = m.append(kind: .rest, seconds: 15), b = m.append(kind: .rest, seconds: 60)
        m.selection = [x, y]
        let r = m.makeRound(repeats: 4)!
        XCTAssertEqual(m.items.map(\.id), [a, r, b])

        m.moveBlock(a, by: 1)
        XCTAssertEqual(m.items.map(\.id), [r, b])
        XCTAssertEqual(roundBlocks(m, 0), [a, x, y], "von links in die Runde: an den Anfang")
        m.moveBlock(a, by: 1)
        XCTAssertEqual(roundBlocks(m, 0), [x, a, y])
        m.moveBlock(a, by: 1)
        XCTAssertEqual(roundBlocks(m, 0), [x, y, a])
        m.moveBlock(a, by: 1)
        XCTAssertEqual(m.items.map(\.id), [r, a, b], "am Ende der Runde: wieder hinaus, direkt dahinter")
        m.moveBlock(a, by: 1)
        XCTAssertEqual(m.items.map(\.id), [r, b, a])
        m.moveBlock(a, by: 1)
        XCTAssertEqual(m.items.map(\.id), [r, b, a], "am Ende der Zeitleiste bleibt der Block stehen")

        // Und denselben Weg zurück.
        m.moveBlock(a, by: -1)
        m.moveBlock(a, by: -1)
        XCTAssertEqual(roundBlocks(m, 0), [x, y, a], "von rechts in die Runde: ans Ende")
        m.moveBlock(a, by: -1)
        m.moveBlock(a, by: -1)
        XCTAssertEqual(roundBlocks(m, 0), [a, x, y])
        m.moveBlock(a, by: -1)
        XCTAssertEqual(m.items.map(\.id), [a, r, b], "am Anfang der Runde: wieder hinaus, direkt davor")
        m.moveBlock(a, by: -1)
        XCTAssertEqual(m.items.map(\.id), [a, r, b])
    }
}
