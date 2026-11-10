import XCTest
@testable import FitMitJodit

final class SequenceTests: XCTestCase {
    func testRoundExpandsIntoBlockSequence() {
        let w = Templates.circuit
        let steps = StepSequence.expand(w)
        // 4 Runden à 6 Blöcke, die letzte 60-s-Pause entfällt.
        XCTAssertEqual(steps.count, 23)
        XCTAssertEqual(steps.first?.kind, .work)
        XCTAssertEqual(steps.first?.round, 1)
        XCTAssertEqual(steps.last?.kind, .work)
        XCTAssertEqual(steps.last?.round, 4)
        XCTAssertEqual(steps.filter { $0.kind == .work }.count, 12)
    }

    func testTrailingRestIsKeptWhenSwitchedOff() {
        var w = Templates.circuit
        w.skipTrailingRest = false
        let steps = StepSequence.expand(w)
        XCTAssertEqual(steps.count, 24)
        XCTAssertEqual(steps.last?.kind, .rest)
        XCTAssertEqual(steps.last?.seconds, 60)
    }

    func testTotalDurationOfCircuit() {
        // 4 × (3×45 + 2×15 + 60) − 60 = 4 × 225 − 60
        XCTAssertEqual(Templates.circuit.totalSeconds, 840)
    }

    func testTemplates() {
        XCTAssertEqual(StepSequence.expand(Templates.tabata).count, 15) // 8×2 − letzte Pause
        XCTAssertEqual(Templates.tabata.totalSeconds, 8 * 30 - 10)
        XCTAssertEqual(StepSequence.expand(Templates.warmup).count, 6)
        XCTAssertEqual(Templates.warmup.totalSeconds, 180)
        XCTAssertEqual(Templates.strength.totalSeconds, 3 * (4 * 60 + 3 * 30 + 90) - 90)
    }

    func testLeadIn() {
        let steps = StepSequence.withLeadIn(StepSequence.expand(Templates.warmup), leadInSeconds: 10)
        XCTAssertEqual(steps.count, 7)
        XCTAssertTrue(steps[0].isLeadIn)
        XCTAssertEqual(steps[0].kind, .prep)
        XCTAssertEqual(steps[0].seconds, 10)
        XCTAssertEqual(StepSequence.withLeadIn(steps, leadInSeconds: 0).count, 7)
    }

    func testOnlyRestIsNotRemovedCompletely() {
        let w = Workout(name: "x", items: [.block(Block(kind: .rest, seconds: 30))])
        XCTAssertEqual(StepSequence.expand(w).count, 1)
    }
}

final class TimerEngineTests: XCTestCase {
    private func engine(_ w: Workout = Templates.circuit, leadIn: Int = 10, clock: ManualClock) -> TimerEngine {
        TimerEngine(steps: StepSequence.withLeadIn(StepSequence.expand(w), leadInSeconds: leadIn), startAt: clock.now)
    }

    func testRunsThroughBlocksByTimestamp() {
        let clock = ManualClock()
        let e = engine(clock: clock)
        XCTAssertEqual(e.state(at: clock.now).displaySeconds, 10)
        XCTAssertTrue(e.state(at: clock.now).step?.isLeadIn ?? false)
        clock.advance(10)
        XCTAssertEqual(e.state(at: clock.now).step?.kind, .work)
        XCTAssertEqual(e.state(at: clock.now).displaySeconds, 45)
        clock.advance(44.5)
        XCTAssertEqual(e.state(at: clock.now).displaySeconds, 1)
        clock.advance(0.5)
        XCTAssertEqual(e.state(at: clock.now).step?.kind, .rest)
        XCTAssertEqual(e.state(at: clock.now).displaySeconds, 15)
    }

    func testPauseAndResume() {
        let clock = ManualClock()
        var e = engine(clock: clock)
        clock.advance(20) // 10 s in den ersten Block
        e.pause(at: clock.now)
        clock.advance(300)
        XCTAssertTrue(e.state(at: clock.now).isPaused)
        XCTAssertEqual(e.state(at: clock.now).displaySeconds, 35)
        e.resume(at: clock.now)
        clock.advance(5)
        XCTAssertEqual(e.state(at: clock.now).displaySeconds, 30)
        XCTAssertFalse(e.state(at: clock.now).isPaused)
    }

    func testSkipForwardAndBack() {
        let clock = ManualClock()
        var e = engine(clock: clock)
        clock.advance(15) // 5 s im ersten Arbeitsblock (Index 1)
        e.skipForward(at: clock.now)
        XCTAssertEqual(e.state(at: clock.now).stepIndex, 2)
        XCTAssertEqual(e.state(at: clock.now).displaySeconds, 15)
        clock.advance(1)
        e.skipBack(at: clock.now) // innerhalb 2 s: zum vorherigen Schritt
        XCTAssertEqual(e.state(at: clock.now).stepIndex, 1)
        XCTAssertEqual(e.state(at: clock.now).displaySeconds, 45)
        clock.advance(10)
        e.skipBack(at: clock.now) // nach 10 s: Schritt neu beginnen
        XCTAssertEqual(e.state(at: clock.now).stepIndex, 1)
        XCTAssertEqual(e.state(at: clock.now).displaySeconds, 45)
    }

    func testSkipWhilePausedStaysPaused() {
        let clock = ManualClock()
        var e = engine(clock: clock)
        e.pause(at: clock.now)
        e.skipForward(at: clock.now)
        clock.advance(100)
        XCTAssertEqual(e.state(at: clock.now).stepIndex, 1)
        XCTAssertEqual(e.state(at: clock.now).displaySeconds, 45)
        XCTAssertTrue(e.isPaused)
    }

    func testReturnFromBackgroundJumpsToCorrectBlock() {
        let clock = ManualClock()
        let e = engine(clock: clock)
        // App war 3 Minuten im Hintergrund, kein Tick dazwischen.
        clock.advance(10 + 180)
        let st = e.state(at: clock.now)
        // 180 s nach Vorlauf: 45+15+45+15+45 = 165, dann 15 s in der 60-s-Pause.
        XCTAssertEqual(st.stepIndex, 6)
        XCTAssertEqual(st.step?.kind, .rest)
        XCTAssertEqual(st.step?.seconds, 60)
        XCTAssertEqual(st.displaySeconds, 45)
    }

    func testSixtyMinutesWithoutDrift() {
        let clock = ManualClock()
        let w = Workout(name: "Lang", items: [.round(Round(repeats: 60, blocks: [Block(kind: .work, seconds: 45), Block(kind: .rest, seconds: 15)]))],
                        skipTrailingRest: false)
        let start = clock.now
        let e = TimerEngine(steps: StepSequence.expand(w), startAt: start)
        XCTAssertEqual(e.totalDuration, 3600)
        // Viele kleine, unregelmässige Ticks wie im echten Betrieb.
        var t: TimeInterval = 0
        while t < 3599 {
            let dt = [0.016, 0.25, 0.5, 1.0, 0.033][Int(t) % 5]
            clock.advance(dt)
            t += dt
        }
        let st = e.state(at: clock.now)
        // Die Anzeige folgt exakt der Uhr, nicht der Summe der Ticks.
        XCTAssertEqual(st.totalElapsed, clock.now.timeIntervalSince(start), accuracy: 0.000_001)
        XCTAssertEqual(st.totalElapsed, t, accuracy: 0.01)
        clock.set(Date(timeIntervalSinceReferenceDate: 800_000_000 + 3600))
        XCTAssertTrue(e.state(at: clock.now).isFinished)
        // Genau am Wechsel nach 59 Runden + 45 s beginnt die letzte Pause.
        clock.set(Date(timeIntervalSinceReferenceDate: 800_000_000 + 59 * 60 + 45))
        XCTAssertEqual(e.state(at: clock.now).step?.kind, .rest)
        XCTAssertEqual(e.state(at: clock.now).stepIndex, 119)
    }

    func testEndDates() {
        let clock = ManualClock()
        var e = engine(Templates.warmup, leadIn: 0, clock: clock)
        XCTAssertEqual(e.endDate(), clock.now + 180)
        XCTAssertEqual(e.stepEndDate(at: clock.now), clock.now + 30)
        e.pause(at: clock.now)
        XCTAssertNil(e.endDate())
    }

    func testEngineIsCodableForWatchSync() throws {
        let clock = ManualClock()
        var e = engine(clock: clock)
        clock.advance(33.437)
        let data = try JSONEncoder.fmj.encode(e)
        let back = try JSONDecoder.fmj.decode(TimerEngine.self, from: data)
        // Laufend und pausiert: Zustand auf beiden Seiten auf die Millisekunde gleich.
        XCTAssertEqual(back.state(at: clock.now).remaining, e.state(at: clock.now).remaining, accuracy: 0.002)
        e.pause(at: clock.now)
        let back2 = try JSONDecoder.fmj.decode(TimerEngine.self, from: try JSONEncoder.fmj.encode(e))
        clock.advance(10)
        XCTAssertEqual(back2.state(at: clock.now).remaining, e.state(at: clock.now).remaining, accuracy: 0.002)
        XCTAssertTrue(back2.isPaused)
    }
}

final class SignalTests: XCTestCase {
    func testSignalTimesForCircuit() {
        let steps = StepSequence.withLeadIn(StepSequence.expand(Templates.circuit), leadInSeconds: 10)
        let events = SignalPlanner.plan(steps: steps, settings: SignalSettings())
        // Kein Startsignal für den Vorlauf, aber Countdown 3-2-1 vor dem ersten Block.
        XCTAssertFalse(events.contains { $0.at == 0 && $0.kind == .blockStart(.prep) })
        XCTAssertTrue(events.contains { $0.at == 7 && $0.kind == .countdown(3) })
        XCTAssertTrue(events.contains { $0.at == 9 && $0.kind == .countdown(1) })
        XCTAssertTrue(events.contains { $0.at == 10 && $0.kind == .blockStart(.work) })
        // Halbzeit im ersten 45-s-Block
        XCTAssertTrue(events.contains { $0.at == 32.5 && $0.kind == .halftime })
        // Keine Halbzeit in Pausen
        XCTAssertFalse(events.contains { $0.kind == .halftime && $0.at == 55 + 7.5 })
        XCTAssertEqual(events.last?.kind, .finished)
        XCTAssertEqual(events.last?.at, 850)
        // Standard: keine Ansagen
        XCTAssertFalse(events.contains { if case .announcement = $0.kind { return true } else { return false } })
    }

    func testTogglesSwitchSignalsOff() {
        let steps = StepSequence.expand(Templates.circuit)
        var s = SignalSettings()
        s.tonesEnabled = false
        s.halftimeEnabled = false
        XCTAssertTrue(SignalPlanner.plan(steps: steps, settings: s).isEmpty)
        s.halftimeEnabled = true
        XCTAssertTrue(SignalPlanner.plan(steps: steps, settings: s).allSatisfy { $0.kind == .halftime })
    }

    func testDueEventsWithoutAvalancheAfterBackground() {
        let events = SignalPlanner.plan(steps: StepSequence.expand(Templates.tabata), settings: SignalSettings())
        XCTAssertEqual(SignalPlanner.due(events, from: 16.5, to: 17.2).map(\.kind), [.countdown(3)])
        // 100 s im Hintergrund: nur das letzte Fenster
        let late = SignalPlanner.due(events, from: 0, to: 100)
        XCTAssertTrue(late.allSatisfy { $0.at > 98.5 })
        // Start bei 0
        XCTAssertTrue(SignalPlanner.due(events, from: -0.01, to: 0.1).contains { $0.kind == .blockStart(.work) })
    }

    func testAnnouncementsWithAndWithoutNames() {
        let work = Step(kind: .work, seconds: 45, exerciseName: nil)
        let named = Step(kind: .work, seconds: 45, exerciseName: "Kniebeugen")
        let rest = Step(kind: .rest, seconds: 15)
        XCTAssertEqual(Announcements.text(for: work, next: rest, isLastRoundStart: false), String(localized: "Los"))
        XCTAssertEqual(Announcements.text(for: named, next: rest, isLastRoundStart: false), "Kniebeugen")
        XCTAssertEqual(Announcements.text(for: rest, next: work, isLastRoundStart: false), String(localized: "Pause"))
        let restWithNext = Announcements.text(for: rest, next: named, isLastRoundStart: false)
        XCTAssertEqual(restWithNext, String(localized: "Pause") + ". " + String(localized: "gleich: \("Kniebeugen")"))
        XCTAssertTrue(Announcements.text(for: work, next: nil, isLastRoundStart: true)?.hasPrefix(String(localized: "Letzte Runde")) ?? false)
    }

    func testLastRoundAndFinishedAnnouncements() {
        var s = SignalSettings()
        s.voiceEnabled = true
        let events = SignalPlanner.plan(steps: StepSequence.expand(Templates.circuit), settings: s)
        let texts: [String] = events.compactMap { if case .announcement(let t) = $0.kind { return t } else { return nil } }
        XCTAssertEqual(texts.filter { $0.hasPrefix(String(localized: "Letzte Runde")) }.count, 1)
        XCTAssertEqual(texts.last, Announcements.finished)
        // Kein gesprochener Countdown
        XCTAssertFalse(texts.contains { ["3", "2", "1"].contains($0) })
    }
}
