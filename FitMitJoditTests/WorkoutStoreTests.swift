import XCTest
@testable import FitMitJodit

@MainActor
final class WorkoutStoreTests: XCTestCase {
    private func makeStore() -> WorkoutStore {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        return WorkoutStore(container: PersistenceFactory.makeContainer(inMemory: true), defaults: defaults)
    }

    static let newKeys: Set<String> = ["fullbody20", "core10", "legs15", "cardio12", "upper12", "pyramid", "emom12"]

    func testFirstStartSeedsAllTemplatesWithoutICloud() {
        let store = makeStore()
        XCTAssertEqual(store.workouts.count, 11)
        XCTAssertEqual(Set(store.workouts.compactMap(\.templateKey)), Self.newKeys.union(["circuit4515", "tabata", "strength", "warmup"]))
    }

    func testUpdateAddsNewTemplatesButNotDeletedOnes() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        defaults.set(true, forKey: "fmj.templatesSeeded.v1") // Installation der ersten Fassung, Tabata gelöscht
        let store = WorkoutStore(container: PersistenceFactory.makeContainer(inMemory: true), defaults: defaults)
        let keys = Set(store.workouts.compactMap(\.templateKey))
        XCTAssertEqual(keys, Self.newKeys)
    }

    func testParticipantTemplatesHaveNamesAndSpeak() {
        for w in [Templates.fullBody, Templates.core] {
            let steps = StepSequence.expand(w)
            XCTAssertTrue(steps.filter { $0.kind == .work }.allSatisfy(\.hasName))
            XCTAssertTrue(SignalSettings().speaks(steps))
        }
        XCTAssertEqual(Templates.fullBody.totalSeconds, 20 * 60 - 20)
        XCTAssertEqual(Templates.core.totalSeconds, 10 * 60 - 15)
    }

    func testAdditionalTemplates() {
        for w in [Templates.legsGlutes, Templates.cardio, Templates.upperBody, Templates.emom] {
            let steps = StepSequence.expand(w)
            XCTAssertTrue(steps.filter { $0.kind == .work }.allSatisfy(\.hasName), w.name)
            XCTAssertTrue(SignalSettings().speaks(steps), w.name)
        }
        XCTAssertEqual(Templates.legsGlutes.totalSeconds, 15 * 60 - 15)
        XCTAssertEqual(Templates.cardio.totalSeconds, 12 * 60 - 10)
        XCTAssertEqual(Templates.upperBody.totalSeconds, 12 * 60 - 20)
        XCTAssertEqual(Templates.emom.totalSeconds, 12 * 60)
        XCTAssertEqual(Templates.pyramid.totalSeconds, 340 + 8 * 15)
        // Feste IDs pro Vorlage, keine doppelten
        let ids = Templates.all().map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testCreateRenameDuplicateDelete() {
        let store = makeStore()
        let w = store.create(name: "Montag")
        XCTAssertEqual(store.workouts.count, Templates.all().count + 1)
        store.rename(w, to: "Dienstag")
        XCTAssertEqual(store.workout(id: w.id)?.name, "Dienstag")
        let copy = store.duplicate(store.workout(id: w.id)!)
        XCTAssertNotEqual(copy.id, w.id)
        XCTAssertEqual(store.workouts.count, Templates.all().count + 2)
        store.delete(copy)
        XCTAssertEqual(store.workouts.count, Templates.all().count + 1)
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
        XCTAssertEqual(store.search("").count, 11)
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
        XCTAssertEqual(again.workouts.count, Templates.all().count + 1) // keine erneuten Vorlagen
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
