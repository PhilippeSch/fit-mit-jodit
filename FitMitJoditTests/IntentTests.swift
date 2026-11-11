import AppIntents
import XCTest
@testable import FitMitJodit

/// Siri und Kurzbefehle: über die gemeinsame App-Instanz starten, pausieren, springen, beenden.
@MainActor
final class IntentTests: XCTestCase {
    /// Eigenes Testtraining, unabhängig davon, was im Simulator gespeichert ist.
    private var testWorkout = Workout(name: "Siri-Test \(UUID().uuidString.prefix(6))",
                                      items: [.block(Block(kind: .work, seconds: 30)), .block(Block(kind: .rest, seconds: 10)),
                                              .block(Block(kind: .work, seconds: 30))])

    override func setUp() async throws {
        AppModel.shared.store.upsert(testWorkout)
    }

    override func tearDown() async throws {
        AppModel.shared.stop()
        AppModel.shared.store.delete(testWorkout)
    }

    func testQueryOffersAllWorkouts() async throws {
        let app = AppModel.shared
        let suggested = try await WorkoutEntityQuery().suggestedEntities()
        XCTAssertEqual(suggested.map(\.id), app.store.sorted.map(\.id))
        let found = try await WorkoutEntityQuery().entities(matching: String(testWorkout.name.suffix(6)))
        XCTAssertEqual(found.map(\.id), [testWorkout.id])
    }

    func testStartPauseSkipStop() async throws {
        let app = AppModel.shared
        let w = try XCTUnwrap(app.store.workout(id: testWorkout.id))
        var start = StartWorkoutIntent()
        start.workout = WorkoutEntity(w)
        _ = try await start.perform()
        let s = try XCTUnwrap(app.session)
        XCTAssertEqual(s.workout.id, w.id)
        _ = try await TogglePauseIntent().perform()
        XCTAssertTrue(s.engine.isPaused)
        let before = s.state.stepIndex
        _ = try await SkipBlockIntent().perform()
        XCTAssertEqual(s.state.stepIndex, before + 1)
        _ = try await StopWorkoutIntent().perform()
        XCTAssertNil(app.session)
        // Ohne laufendes Training: klare Meldung statt stiller Fehler
        do {
            _ = try await TogglePauseIntent().perform()
            XCTFail("Fehler erwartet")
        } catch let e as IntentFailure {
            XCTAssertEqual(e, .noRun)
        }
    }
}
