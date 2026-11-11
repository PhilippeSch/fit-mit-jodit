import XCTest
@testable import FitMitJodit

/// Training fortsetzen, nachdem iOS die App im Hintergrund beendet hat.
@MainActor
final class RunRestoreTests: XCTestCase {
    private func makeApp(defaults: UserDefaults, clock: ManualClock) -> AppModel {
        let store = WorkoutStore(container: PersistenceFactory.makeContainer(inMemory: true), defaults: defaults)
        let app = AppModel(store: store, defaults: defaults)
        app.clock = clock
        return app
    }

    func testRunningWorkoutContinuesAtRightPlaceAfterRelaunch() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let clock = ManualClock()
        let first = makeApp(defaults: defaults, clock: clock)
        let s = first.start(Templates.tabata)
        clock.advance(12)
        s.tick()
        // App wird beendet, 50 s später neu geöffnet
        clock.advance(50)
        let second = makeApp(defaults: defaults, clock: clock)
        XCTAssertTrue(second.restoreRunIfNeeded())
        let restored = try! XCTUnwrap(second.session)
        XCTAssertEqual(restored.workout.id, s.workout.id)
        XCTAssertEqual(restored.engine.elapsed(at: clock.now), s.engine.elapsed(at: clock.now), accuracy: 0.001)
        XCTAssertFalse(restored.isFinished)
    }

    func testPausedWorkoutStaysPaused() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let clock = ManualClock()
        let first = makeApp(defaults: defaults, clock: clock)
        let s = first.start(Templates.circuit)
        clock.advance(30)
        s.pause()
        clock.advance(600)
        let second = makeApp(defaults: defaults, clock: clock)
        XCTAssertTrue(second.restoreRunIfNeeded())
        XCTAssertTrue(second.session!.engine.isPaused)
        XCTAssertEqual(second.session!.engine.elapsed(at: clock.now), 30, accuracy: 0.001)
    }

    func testStoppedFinishedOrOldRunsAreNotRestored() {
        let clock = ManualClock()
        // gestoppt
        var defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        var app = makeApp(defaults: defaults, clock: clock)
        app.start(Templates.tabata)
        app.stop()
        XCTAssertFalse(makeApp(defaults: defaults, clock: clock).restoreRunIfNeeded())
        // inzwischen zu Ende gelaufen
        defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        app = makeApp(defaults: defaults, clock: clock)
        app.start(Templates.tabata)
        clock.advance(TimeInterval(Templates.tabata.totalSeconds + 60))
        XCTAssertFalse(makeApp(defaults: defaults, clock: clock).restoreRunIfNeeded())
        // pausiert, aber älter als 4 Stunden
        defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        app = makeApp(defaults: defaults, clock: clock)
        app.start(Templates.circuit).pause()
        clock.advance(5 * 3600)
        XCTAssertFalse(makeApp(defaults: defaults, clock: clock).restoreRunIfNeeded())
    }
}
