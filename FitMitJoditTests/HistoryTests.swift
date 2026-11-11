import XCTest
@testable import FitMitJodit

@MainActor
final class HistoryTests: XCTestCase {
    private func makeApp(_ defaults: UserDefaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!,
                         container: ModelContainerBox = .init(), clock: ManualClock) -> AppModel {
        let store = WorkoutStore(container: container.container, defaults: defaults)
        let app = AppModel(store: store, defaults: defaults)
        app.clock = clock
        return app
    }

    func testFinishedWorkoutIsRecordedWithoutLeadIn() {
        let clock = ManualClock()
        let app = makeApp(clock: clock)
        let s = app.start(Templates.tabata)
        clock.advance(TimeInterval(Templates.tabata.totalSeconds + app.store.settings.leadInSeconds + 1))
        s.tick()
        XCTAssertTrue(s.isFinished)
        XCTAssertEqual(app.store.history.count, 1)
        let e = app.store.history[0]
        XCTAssertTrue(e.completed)
        XCTAssertEqual(e.seconds, Templates.tabata.totalSeconds)
        XCTAssertEqual(e.name, "Tabata")
        // «Fertig» nach dem Abschluss legt keinen zweiten Eintrag an
        app.stop()
        XCTAssertEqual(app.store.history.count, 1)
    }

    func testStoppedWorkoutOnlyRecordedAfterOneMinute() {
        let clock = ManualClock()
        let app = makeApp(clock: clock)
        let lead = TimeInterval(app.store.settings.leadInSeconds)
        app.start(Templates.circuit)
        clock.advance(lead + 30)
        app.stop()
        XCTAssertTrue(app.store.history.isEmpty, "unter einer Minute: kein Eintrag")
        app.start(Templates.circuit)
        clock.advance(lead + 90)
        app.stop()
        XCTAssertEqual(app.store.history.count, 1)
        XCTAssertFalse(app.store.history[0].completed)
        XCTAssertEqual(app.store.history[0].seconds, 90)
    }

    func testHistoryPersistsAndCanBeDeleted() {
        let clock = ManualClock()
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let box = ModelContainerBox()
        let app = makeApp(defaults, container: box, clock: clock)
        let a = HistoryEntry(workoutID: UUID(), name: "A", startedAt: clock.now, seconds: 600, completed: true)
        let b = HistoryEntry(workoutID: UUID(), name: "B", startedAt: clock.now.addingTimeInterval(3600), seconds: 300, completed: false)
        app.store.addHistory(a)
        app.store.addHistory(b)
        let again = makeApp(defaults, container: box, clock: clock)
        XCTAssertEqual(again.store.history.map(\.name), ["B", "A"], "neueste zuerst")
        again.store.deleteHistory(b)
        XCTAssertEqual(makeApp(defaults, container: box, clock: clock).store.history.map(\.name), ["A"])
    }

    func testWeekSummary() {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Montag
        cal.timeZone = TimeZone(identifier: "Europe/Zurich")!
        let wednesday = cal.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 18))!
        let monday = cal.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 9))!
        let lastWeek = cal.date(from: DateComponents(year: 2026, month: 11, day: 8, hour: 9))!
        let entries = [
            HistoryEntry(workoutID: UUID(), name: "x", startedAt: monday, seconds: 1200, completed: true),
            HistoryEntry(workoutID: UUID(), name: "y", startedAt: wednesday, seconds: 600, completed: true),
            HistoryEntry(workoutID: UUID(), name: "z", startedAt: lastWeek, seconds: 3000, completed: true),
        ]
        XCTAssertEqual(HistorySummary.week(entries, now: wednesday, calendar: cal), HistorySummary(count: 2, seconds: 1800))
        XCTAssertEqual(HistorySummary.minutesPerDay(entries, now: wednesday, calendar: cal), [20, 0, 10, 0, 0, 0, 0])
    }
}

/// Ein Speicher, der über mehrere Store-Instanzen hinweg bestehen bleibt (wie nach einem Neustart).
struct ModelContainerBox {
    let container = PersistenceFactory.makeContainer(inMemory: true)
}
