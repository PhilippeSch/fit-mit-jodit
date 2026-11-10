import XCTest
@testable import FitMitJodit

@MainActor
final class WorkoutStoreTests: XCTestCase {
    private func makeStore() -> WorkoutStore {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        return WorkoutStore(container: PersistenceFactory.makeContainer(inMemory: true), defaults: defaults)
    }

    func testFirstStartSeedsFourTemplatesWithoutICloud() {
        let store = makeStore()
        XCTAssertEqual(store.workouts.count, 4)
        XCTAssertEqual(Set(store.workouts.compactMap(\.templateKey)), ["circuit4515", "tabata", "strength", "warmup"])
    }

    func testCreateRenameDuplicateDelete() {
        let store = makeStore()
        let w = store.create(name: "Montag")
        XCTAssertEqual(store.workouts.count, 5)
        store.rename(w, to: "Dienstag")
        XCTAssertEqual(store.workout(id: w.id)?.name, "Dienstag")
        let copy = store.duplicate(store.workout(id: w.id)!)
        XCTAssertNotEqual(copy.id, w.id)
        XCTAssertEqual(store.workouts.count, 6)
        store.delete(copy)
        XCTAssertEqual(store.workouts.count, 5)
        XCTAssertNil(store.workout(id: copy.id))
    }

    func testFavoritesFirstThenLastUsed() {
        let store = makeStore()
        let tabata = store.workouts.first { $0.templateKey == "tabata" }!
        let warmup = store.workouts.first { $0.templateKey == "warmup" }!
        store.markUsed(tabata)
        store.toggleFavorite(warmup)
        XCTAssertEqual(store.sorted.first?.id, warmup.id)
        XCTAssertEqual(store.sorted[1].id, tabata.id)
    }

    func testSearch() {
        let store = makeStore()
        XCTAssertEqual(store.search("taba").map(\.templateKey), ["tabata"])
        XCTAssertEqual(store.search("").count, 4)
    }

    func testPersistsAcrossReload() {
        let container = PersistenceFactory.makeContainer(inMemory: true)
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let store = WorkoutStore(container: container, defaults: defaults)
        var w = store.create(name: "Persistenz")
        w.items = [.block(Block(kind: .work, seconds: 40, exerciseName: "Plank"))]
        store.upsert(w)
        store.addPaletteItem(PaletteItem(kind: .work, seconds: 20))
        store.settings.leadInSeconds = 5
        let again = WorkoutStore(container: container, defaults: defaults)
        XCTAssertEqual(again.workout(id: w.id)?.items, w.items)
        XCTAssertEqual(again.palette.count, PaletteItem.defaults.count + 1)
        XCTAssertEqual(again.settings.leadInSeconds, 5)
        XCTAssertEqual(again.workouts.count, 5) // keine erneuten Vorlagen
    }

    func testCustomExerciseNamesAreRemembered() {
        let store = makeStore()
        var w = store.create(name: "Eigene")
        w.items = [.block(Block(kind: .work, seconds: 30, exerciseName: "Jodit-Spezial"))]
        store.upsert(w)
        XCTAssertEqual(store.customExerciseNames, ["Jodit-Spezial"])
        store.rememberName("jodit-spezial")
        XCTAssertEqual(store.customExerciseNames.count, 1)
    }
}
