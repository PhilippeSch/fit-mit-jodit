import SwiftData
import XCTest
@testable import FitMitJodit

/// Regressionstests für die Befunde aus dem Code-Review vom 11.11.2026.
@MainActor
final class ReviewFixTests: XCTestCase {
    private func defaults() -> UserDefaults { UserDefaults(suiteName: "test-\(UUID().uuidString)")! }

    /// Befund 4: Vorlagen haben feste IDs, doppelte Vorlagen (zwei Geräte vor dem Sync) werden zusammengeführt.
    func testTemplatesHaveStableIDsAndDuplicatesMerge() {
        XCTAssertEqual(Templates.all().map(\.id), Templates.all().map(\.id))
        XCTAssertEqual(Templates.id(for: "tabata"), Templates.id(for: "tabata"))
        XCTAssertNotEqual(Templates.id(for: "tabata"), Templates.id(for: "warmup"))
        let container = PersistenceFactory.makeContainer(inMemory: true)
        let store = WorkoutStore(container: container, defaults: defaults())
        // Zweites «Gerät» mit alter, zufälliger ID derselben Vorlage
        var dup = Templates.tabata
        dup.id = UUID()
        dup.modifiedAt = Date().addingTimeInterval(-60)
        store.context.insert(StoredWorkout(dup))
        try? store.context.save()
        store.reload()
        XCTAssertEqual(store.workouts.filter { $0.templateKey == "tabata" }.count, 1)
    }

    /// Befund 6: Laden schreibt die Einstellungen nicht zurück (kein neuer Zeitstempel).
    func testLoadingDoesNotResaveSettings() throws {
        let container = PersistenceFactory.makeContainer(inMemory: true)
        let d = defaults()
        let a = WorkoutStore(container: container, defaults: d)
        a.settings.leadInSeconds = 20
        let ctx = ModelContext(container)
        let before = try ctx.fetch(FetchDescriptor<StoredValue>()).first { $0.key == "settings" }?.modifiedAt
        let b = WorkoutStore(container: container, defaults: d)
        XCTAssertEqual(b.settings.leadInSeconds, 20)
        let after = try ModelContext(container).fetch(FetchDescriptor<StoredValue>()).first { $0.key == "settings" }?.modifiedAt
        XCTAssertEqual(before, after)
    }

    /// Befund 7: Der Baukasten überschreibt Favorit und Name aus der Bibliothek nicht.
    func testEditorKeepsLibraryChanges() {
        let store = WorkoutStore(container: PersistenceFactory.makeContainer(inMemory: true), defaults: defaults())
        let w = store.create(name: "Montag")
        let editor = EditorModel(workout: w)
        editor.onChange = { old, new in store.applyEdit(from: old, to: new) }
        store.toggleFavorite(w)
        store.rename(store.workout(id: w.id)!, to: "Dienstag")
        editor.append(kind: .work, seconds: 45)
        let cur = store.workout(id: w.id)!
        XCTAssertTrue(cur.isFavorite)
        XCTAssertEqual(cur.name, "Dienstag")
        XCTAssertEqual(cur.items.count, 1)
    }

    /// Befund 11: Wiederholen entfernt nicht mehr vorhandene Blöcke aus der Auswahl.
    func testRedoPrunesSelection() {
        let m = EditorModel(workout: Workout(name: "x", items: []))
        let a = m.append(kind: .work, seconds: 30)
        m.selection = [a]
        m.deleteSelection()
        m.undo()
        m.selection = [a]
        m.redo()
        XCTAssertTrue(m.selection.isEmpty)
    }

    /// Befund 12: Blöcke lassen sich aus einer Runde heraus und zwischen Runden ziehen.
    func testDragOutOfAndBetweenRounds() {
        let m = EditorModel(workout: Workout(name: "x", items: []))
        let a = m.append(kind: .work, seconds: 30)
        let b = m.append(kind: .rest, seconds: 10)
        let c = m.append(kind: .work, seconds: 20)
        m.selection = [a, b]
        m.makeRound(repeats: 3)
        // a aus der Runde vor c ziehen
        XCTAssertTrue(m.moveBlock(a, before: c))
        XCTAssertEqual(m.items.last?.id, c)
        XCTAssertNotNil(m.location(of: a))
        XCTAssertNil(m.location(of: a)?.inner)
        // b (letzter Block der Runde) heraus: leere Runde verschwindet
        XCTAssertTrue(m.moveBlock(b, before: a))
        XCTAssertFalse(m.items.contains { if case .round = $0 { return true } else { return false } })
        // Unbekanntes Ziel: keine Änderung
        XCTAssertFalse(m.moveBlock(a, before: UUID()))
    }

    /// Befund 9: «Start» ans iPad trägt das ganze Training.
    func testStartWorkoutMessageRoundTrip() {
        let m = RemoteMessage.startWorkout(Templates.circuit)
        guard case .startWorkout(let w)? = RemoteMessage.decode(m.encoded()) else { return XCTFail() }
        XCTAssertEqual(StepSequence.expand(w), StepSequence.expand(Templates.circuit))
    }
}
