import XCTest
@testable import FitMitJodit

@MainActor
final class EditorModelTests: XCTestCase {
    /// Abnahme 2: «3 × 45 s Arbeit mit 15 s Pause, 1 min Pause, mal 4» zusammenklicken.
    func testBuildCircuitFromBlocks() {
        let m = EditorModel(workout: Workout(name: "Test", items: []))
        var ids: [UUID] = []
        ids.append(m.append(kind: .work, seconds: 45))
        ids.append(m.append(kind: .rest, seconds: 15))
        ids.append(m.append(kind: .work, seconds: 45))
        ids.append(m.append(kind: .rest, seconds: 15))
        ids.append(m.append(kind: .work, seconds: 45))
        ids.append(m.append(kind: .rest, seconds: 60))
        m.selection = Set(ids)
        XCTAssertTrue(m.canMakeRound)
        XCTAssertNotNil(m.makeRound(repeats: 4))
        XCTAssertEqual(m.items.count, 1)
        XCTAssertEqual(m.workout.totalSeconds, Templates.circuit.totalSeconds)
        XCTAssertEqual(m.workout.roundCount, 4)
    }

    func testUndoRedo() {
        let m = EditorModel(workout: Workout(name: "Test", items: []))
        m.append(kind: .work, seconds: 45)
        m.append(kind: .rest, seconds: 15)
        XCTAssertEqual(m.items.count, 2)
        m.undo()
        XCTAssertEqual(m.items.count, 1)
        m.undo()
        XCTAssertEqual(m.items.count, 0)
        XCTAssertFalse(m.canUndo)
        m.redo()
        m.redo()
        XCTAssertEqual(m.items.count, 2)
        // Neue Änderung löscht den Wiederholen-Verlauf
        m.undo()
        m.append(kind: .prep, seconds: 10)
        XCTAssertFalse(m.canRedo)
        XCTAssertEqual(m.items.count, 2)
    }

    func testUndoRound() {
        let m = EditorModel(workout: Workout(name: "Test", items: []))
        let a = m.append(kind: .work, seconds: 20)
        let b = m.append(kind: .rest, seconds: 10)
        m.selection = [a, b]
        m.makeRound(repeats: 8)
        XCTAssertEqual(m.items.count, 1)
        m.undo()
        XCTAssertEqual(m.items.count, 2)
    }

    func testAppendAfterSelectedBlock() {
        let m = EditorModel(workout: Workout(name: "Test", items: []))
        let a = m.append(kind: .work, seconds: 45)
        _ = m.append(kind: .work, seconds: 30)
        m.selection = [a]
        let c = m.append(kind: .rest, seconds: 15)
        XCTAssertEqual(m.items.map(\.id)[1], c)
    }

    func testDuplicateDeleteDurationNameAndClamp() {
        let m = EditorModel(workout: Workout(name: "Test", items: []))
        let a = m.append(kind: .work, seconds: 45)
        m.selection = [a]
        m.duplicateSelection()
        XCTAssertEqual(m.items.count, 2)
        m.selection = [a]
        m.setDuration(9999)
        XCTAssertEqual(m.block(a)?.seconds, 600)
        m.setDuration(1)
        XCTAssertEqual(m.block(a)?.seconds, 5)
        m.setExerciseName("  Kniebeugen ")
        XCTAssertEqual(m.block(a)?.exerciseName, "Kniebeugen")
        m.setExerciseName("")
        XCTAssertNil(m.block(a)?.exerciseName)
        m.deleteSelection()
        XCTAssertEqual(m.items.count, 1)
    }

    func testRoundNeedsAdjacentTopLevelBlocks() {
        let m = EditorModel(workout: Workout(name: "Test", items: []))
        let a = m.append(kind: .work, seconds: 45)
        _ = m.append(kind: .rest, seconds: 15)
        let c = m.append(kind: .work, seconds: 45)
        m.selection = [a, c]
        XCTAssertFalse(m.canMakeRound)
        // Keine Runden in Runden
        m.selection = [a]
        let r = m.makeRound(repeats: 2)!
        if case .round(let round) = m.items[0] { m.selection = [round.blocks[0].id] }
        XCTAssertFalse(m.canMakeRound)
        m.dissolveRound(r)
        XCTAssertEqual(m.items.count, 3)
    }

    func testMoveWithoutDragging() {
        let m = EditorModel(workout: Workout(name: "Test", items: []))
        let a = m.append(kind: .work, seconds: 45)
        let b = m.append(kind: .rest, seconds: 15)
        m.moveBlock(a, by: 1)
        XCTAssertEqual(m.items.map(\.id), [b, a])
        m.moveBlock(a, before: b)
        XCTAssertEqual(m.items.map(\.id), [a, b])
    }
}

final class SpotifyLinkTests: XCTestCase {
    func testValidLinks() throws {
        XCTAssertEqual(try SpotifyLink.validate("https://open.spotify.com/playlist/37i9dQZF1DX76Wlfdnj7AP?si=abc").get().absoluteString,
                       "https://open.spotify.com/playlist/37i9dQZF1DX76Wlfdnj7AP")
        XCTAssertEqual(try SpotifyLink.validate("open.spotify.com/intl-de/album/4aawyAB9vmqN3uQ7FjRGTy").get().absoluteString,
                       "https://open.spotify.com/album/4aawyAB9vmqN3uQ7FjRGTy")
        XCTAssertEqual(try SpotifyLink.validate("spotify:playlist:37i9dQZF1DX76Wlfdnj7AP").get().absoluteString,
                       "https://open.spotify.com/playlist/37i9dQZF1DX76Wlfdnj7AP")
    }

    func testInvalidLinks() {
        XCTAssertEqual(SpotifyLink.validate("   ").failure, .empty)
        XCTAssertEqual(SpotifyLink.validate("https://www.youtube.com/watch?v=x").failure, .notSpotify)
        XCTAssertEqual(SpotifyLink.validate("https://open.spotify.com/user/abc").failure, .unsupportedType)
        XCTAssertEqual(SpotifyLink.validate("https://open.spotify.com/playlist/").failure, .missingID)
        XCTAssertEqual(SpotifyLink.validate("https://open.spotify.com.evil.com/playlist/abc").failure, .notSpotify)
    }

    func testContentLinkingURLs() {
        let canonical = URL(string: "https://open.spotify.com/playlist/37i9dQZF1DX76Wlfdnj7AP")!
        let app = SpotifyLink.appLink(for: canonical).absoluteString
        XCTAssertTrue(app.hasPrefix("https://spotify.link/content_linking?"))
        XCTAssertTrue(app.contains("~campaign="))
        XCTAssertTrue(app.contains("$canonical_url=https"))
        let web = SpotifyLink.webLink(for: canonical).absoluteString
        XCTAssertTrue(web.contains("utm_campaign="))
    }
}

final class ExportImportTests: XCTestCase {
    func testRoundTrip() throws {
        var w = Templates.circuit
        w.spotifyLink = "https://open.spotify.com/playlist/abc"
        w.items = w.items.map { item in
            guard case .round(var r) = item else { return item }
            r.blocks[0].exerciseName = "Kniebeugen"
            return .round(r)
        }
        let data = try WorkoutFile(workout: w).encoded()
        let back = try WorkoutFile.importWorkout(from: data)
        XCTAssertNotEqual(back.id, w.id, "Import legt ein neues Training an")
        XCTAssertEqual(back.name, w.name)
        XCTAssertEqual(back.spotifyLink, w.spotifyLink)
        XCTAssertEqual(StepSequence.expand(back), StepSequence.expand(w))
    }

    func testRejectsForeignFiles() {
        XCTAssertThrowsError(try WorkoutFile.importWorkout(from: Data("hallo".utf8)))
        XCTAssertThrowsError(try WorkoutFile.importWorkout(from: Data(#"{"format":"x","version":1,"workout":{}}"#.utf8)))
    }

    func testFileName() {
        XCTAssertEqual(WorkoutFile.fileName(for: Workout(name: "Montag/Kraft", items: [])), "Montag-Kraft.fmjworkout")
    }
}

private extension Result {
    var failure: Failure? { if case .failure(let f) = self { return f } else { return nil } }
}
