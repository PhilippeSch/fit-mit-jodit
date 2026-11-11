import AppIntents
import XCTest
@testable import FitMitJodit

/// Siri und Kurzbefehle: über die gemeinsame App-Instanz starten, pausieren, springen, beenden.
@MainActor
final class IntentTests: XCTestCase {
    override func tearDown() async throws {
        AppModel.shared.stop()
    }

    func testQueryOffersAllWorkouts() async throws {
        let app = AppModel.shared
        let suggested = try await WorkoutEntityQuery().suggestedEntities()
        XCTAssertEqual(suggested.map(\.id), app.store.sorted.map(\.id))
        let tabata = try await WorkoutEntityQuery().entities(matching: "taba")
        XCTAssertTrue(tabata.contains { $0.name == "Tabata" })
    }

    func testStartPauseSkipStop() async throws {
        let app = AppModel.shared
        let w = try XCTUnwrap(app.store.workouts.first { $0.templateKey == "tabata" })
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
