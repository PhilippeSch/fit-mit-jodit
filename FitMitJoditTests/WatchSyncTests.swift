import XCTest
@testable import FitMitJodit

final class WatchSyncTests: XCTestCase {
    /// Die Uhr bekommt einmal den Zustand und rechnet selbst weiter: gleiche Anzeige wie auf dem iPhone.
    func testWatchComputesSameStateFromSnapshot() throws {
        let clock = ManualClock()
        var engine = TimerEngine(steps: StepSequence.withLeadIn(StepSequence.expand(Templates.circuit), leadInSeconds: 10), startAt: clock.now)
        clock.advance(12.345)
        let snap = RemoteSnapshot(workoutID: UUID(), workoutName: "Zirkel", engine: engine, hostName: "iPad", hostIsPad: true)
        let data = RemoteMessage.snapshot(snap).encoded()
        guard case .snapshot(let received?)? = RemoteMessage.decode(data) else { return XCTFail("nicht dekodierbar") }
        for _ in 0..<50 {
            clock.advance(3.7)
            XCTAssertEqual(received.state(at: clock.now).stepIndex, engine.state(at: clock.now).stepIndex)
            XCTAssertEqual(received.state(at: clock.now).displaySeconds, engine.state(at: clock.now).displaySeconds)
        }
        // Pause und Sprung auf dem iPhone: neuer Zustand, Uhr folgt.
        engine.pause(at: clock.now)
        engine.skipForward(at: clock.now)
        let snap2 = RemoteSnapshot(workoutID: UUID(), workoutName: "Zirkel", engine: engine, hostName: "iPhone", hostIsPad: false)
        guard case .snapshot(let r2?)? = RemoteMessage.decode(RemoteMessage.snapshot(snap2).encoded()) else { return XCTFail() }
        clock.advance(30)
        XCTAssertTrue(r2.state(at: clock.now).isPaused)
        XCTAssertEqual(r2.state(at: clock.now), engine.state(at: clock.now))
        // 197 s: in der 1-min-Pause von Runde 1, Sprung vor führt in Runde 2.
        XCTAssertEqual(r2.state(at: clock.now).step?.round, 2)
        XCTAssertEqual(r2.roundText(at: clock.now), String(localized: "Runde \(2) von \(4)"))
    }

    func testMessagesRoundTrip() {
        let id = UUID()
        let msgs: [RemoteMessage] = [
            .command(.togglePause, workoutID: nil), .command(.start, workoutID: id), .snapshot(nil),
            .workouts([WorkoutSummary(id: id, name: "Tabata", totalSeconds: 230, isFavorite: true)]),
            .target(name: "iPad", connected: true),
        ]
        for m in msgs { XCTAssertEqual(RemoteMessage.decode(m.encoded()), m) }
    }

    func testHapticsForBlockChangeAndCountdown() {
        let clock = ManualClock()
        let engine = TimerEngine(steps: StepSequence.expand(Templates.tabata), startAt: clock.now)
        let p = HapticPlanner()
        XCTAssertEqual(p.next(state: engine.state(at: clock.now)), [])
        clock.advance(16.5) // 3.5 s übrig: noch nichts
        XCTAssertEqual(p.next(state: engine.state(at: clock.now)), [])
        clock.advance(0.6) // 3 s
        XCTAssertEqual(p.next(state: engine.state(at: clock.now)), [.countdown])
        XCTAssertEqual(p.next(state: engine.state(at: clock.now)), [], "nicht doppelt")
        clock.advance(1)
        XCTAssertEqual(p.next(state: engine.state(at: clock.now)), [.countdown])
        clock.advance(2) // Pause beginnt
        XCTAssertEqual(p.next(state: engine.state(at: clock.now)), [.restStart])
        clock.advance(10) // Arbeit beginnt
        XCTAssertTrue(p.next(state: engine.state(at: clock.now)).contains(.workStart))
        clock.advance(1000)
        XCTAssertEqual(p.next(state: engine.state(at: clock.now)), [.finished])
        XCTAssertEqual(p.next(state: engine.state(at: clock.now)), [])
    }
}
