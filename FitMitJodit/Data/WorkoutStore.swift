import CryptoKit
import Foundation
import Observation
import SwiftData

/// Mitgelieferte Vorlagen (SPEC Teil 1).
enum Templates {
    /// Vorlagen mit fester ID je Schlüssel: Auf zwei Geräten angelegt, werden sie über iCloud zu einem Eintrag.
    static func all() -> [Workout] {
        [circuit, tabata, strength, warmup, fullBody, core, legsGlutes, cardio, upperBody, pyramid, emom].map { w in
            var w = w
            if let key = w.templateKey { w.id = id(for: key) }
            return w
        }
    }

    /// Stabile UUID aus dem Vorlagen-Schlüssel (MD5 der Zeichenkette, nur als Kennung, nicht kryptografisch).
    static func id(for key: String) -> UUID {
        var d = Array(Insecure.MD5.hash(data: Data("fmj.template.\(key)".utf8)))
        d[6] = (d[6] & 0x0F) | 0x30 // Version 3
        d[8] = (d[8] & 0x3F) | 0x80
        return UUID(uuid: (d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9], d[10], d[11], d[12], d[13], d[14], d[15]))
    }

    /// Übungsname aus dem Katalog in der Gerätesprache.
    private static func ex(_ id: String) -> String? {
        ExerciseCatalog.all.first { $0.id == id }.map { ExerciseCatalog.localizedName($0) }
    }

    /// Für Teilnehmende zu Hause: mit Übungsnamen, damit die Stimme ansagt, was kommt.
    /// 10 Übungen à 40 s, 20 s Pause, 2 Runden (20 Minuten).
    static var fullBody: Workout {
        let ids = ["jumping_jacks", "squats", "push_ups", "forward_lunges", "plank",
                   "mountain_climbers", "glute_bridge", "burpees", "russian_twists", "side_plank"]
        var blocks: [Block] = []
        for id in ids {
            blocks.append(Block(kind: .work, seconds: 40, exerciseName: ex(id)))
            blocks.append(Block(kind: .rest, seconds: 20))
        }
        return Workout(name: String(localized: "Ganzkörper 20"),
                       items: [.round(Round(repeats: 2, blocks: blocks))], templateKey: "fullbody20")
    }

    /// Übungen mit fester Arbeits- und Pausenzeit als eine Runde.
    private static func station(_ ids: [String], work: Int, rest: Int) -> [Block] {
        ids.flatMap { [Block(kind: .work, seconds: work, exerciseName: ex($0)), Block(kind: .rest, seconds: rest)] }
    }

    /// Beine und Po: 5 Übungen à 45 s, 15 s Pause, 3 Runden (15 Minuten).
    static var legsGlutes: Workout {
        let ids = ["squats", "forward_lunges", "glute_bridge", "sumo_squats", "donkey_kicks"]
        return Workout(name: String(localized: "Beine & Po 15"),
                       items: [.round(Round(repeats: 3, blocks: station(ids, work: 45, rest: 15)))], templateKey: "legs15")
    }

    /// Cardio: 6 Übungen à 30 s, 10 s Pause, 3 Runden (12 Minuten).
    static var cardio: Workout {
        let ids = ["jumping_jacks", "high_knees", "skater_hops", "mountain_climbers", "jump_squats", "burpees"]
        return Workout(name: String(localized: "Cardio 12"),
                       items: [.round(Round(repeats: 3, blocks: station(ids, work: 30, rest: 10)))], templateKey: "cardio12")
    }

    /// Oberkörper ohne Geräte: 6 Übungen à 40 s, 20 s Pause, 2 Runden (12 Minuten).
    static var upperBody: Workout {
        let ids = ["push_ups", "chair_dips", "plank_shoulder_taps", "pike_push_ups", "superman", "knee_push_ups"]
        return Workout(name: String(localized: "Oberkörper 12"),
                       items: [.round(Round(repeats: 2, blocks: station(ids, work: 40, rest: 20)))], templateKey: "upper12")
    }

    /// Pyramide: Arbeit 20 → 60 → 20 Sekunden, je 15 s Pause.
    static var pyramid: Workout {
        let works = [20, 30, 40, 50, 60, 50, 40, 30, 20]
        let items: [TimelineItem] = works.flatMap { [TimelineItem.block(Block(kind: .work, seconds: $0)),
                                                     .block(Block(kind: .rest, seconds: 15))] }
        return Workout(name: String(localized: "Pyramide"), items: items, templateKey: "pyramid")
    }

    /// EMOM: jede Minute eine neue Aufgabe, abwechselnd zwei Übungen, 12 Minuten.
    static var emom: Workout {
        let blocks = [Block(kind: .work, seconds: 60, exerciseName: ex("squats")),
                      Block(kind: .work, seconds: 60, exerciseName: ex("push_ups"))]
        return Workout(name: String(localized: "EMOM 12"),
                       items: [.round(Round(repeats: 6, blocks: blocks))], templateKey: "emom12")
    }

    /// Bauch und Rumpf: 5 Übungen à 45 s, 15 s Pause, 2 Runden (10 Minuten).
    static var core: Workout {
        let ids = ["crunches", "plank", "bicycle_crunches", "dead_bug", "side_plank"]
        var blocks: [Block] = []
        for id in ids {
            blocks.append(Block(kind: .work, seconds: 45, exerciseName: ex(id)))
            blocks.append(Block(kind: .rest, seconds: 15))
        }
        return Workout(name: String(localized: "Bauch & Rumpf 10"),
                       items: [.round(Round(repeats: 2, blocks: blocks))], templateKey: "core10")
    }

    static var circuit: Workout {
        let blocks: [Block] = [
            Block(kind: .work, seconds: 45), Block(kind: .rest, seconds: 15),
            Block(kind: .work, seconds: 45), Block(kind: .rest, seconds: 15),
            Block(kind: .work, seconds: 45), Block(kind: .rest, seconds: 60),
        ]
        return Workout(name: String(localized: "Zirkel 45/15"), items: [.round(Round(repeats: 4, blocks: blocks))],
                       templateKey: "circuit4515")
    }

    static var tabata: Workout {
        Workout(name: String(localized: "Tabata"),
                items: [.round(Round(repeats: 8, blocks: [Block(kind: .work, seconds: 20), Block(kind: .rest, seconds: 10)]))],
                templateKey: "tabata")
    }

    static var strength: Workout {
        var blocks: [Block] = []
        for i in 0..<4 {
            blocks.append(Block(kind: .work, seconds: 60))
            blocks.append(Block(kind: .rest, seconds: i < 3 ? 30 : 90))
        }
        return Workout(name: String(localized: "Kraft"), items: [.round(Round(repeats: 3, blocks: blocks))],
                       templateKey: "strength")
    }

    static var warmup: Workout {
        Workout(name: String(localized: "Warm-up"),
                items: (0..<6).map { _ in .block(Block(kind: .work, seconds: 30)) },
                templateKey: "warmup")
    }
}

/// Ein Baustein der Palette (gilt für alle Trainings).
struct PaletteItem: Codable, Hashable, Identifiable, Sendable {
    var id: UUID = UUID()
    var kind: BlockKind
    var seconds: Int

    static let defaults: [PaletteItem] = [
        PaletteItem(kind: .work, seconds: 45),
        PaletteItem(kind: .work, seconds: 30),
        PaletteItem(kind: .rest, seconds: 15),
        PaletteItem(kind: .rest, seconds: 60),
        PaletteItem(kind: .prep, seconds: 10),
    ]
}

/// App-Einstellungen, die über iCloud mitlaufen.
struct AppSettings: Codable, Equatable, Sendable {
    var signals = SignalSettings()
    /// Vorlauf vor dem ersten Block, 0 bis 30 s.
    var leadInSeconds: Int = 10
    var hasSeenSplitViewHint = false

    init() {}

    /// Tolerant einlesen, damit neue Felder bei einem Update keine Einstellungen zurücksetzen.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        signals = try c.decodeIfPresent(SignalSettings.self, forKey: .signals) ?? SignalSettings()
        leadInSeconds = try c.decodeIfPresent(Int.self, forKey: .leadInSeconds) ?? 10
        hasSeenSplitViewHint = try c.decodeIfPresent(Bool.self, forKey: .hasSeenSplitViewHint) ?? false
    }
}

@MainActor
@Observable
final class WorkoutStore {
    private(set) var workouts: [Workout] = []
    private(set) var palette: [PaletteItem] = PaletteItem.defaults
    private(set) var customExerciseNames: [String] = []
    var settings = AppSettings() { didSet { if !isLoading, settings != oldValue { saveValue(settings, key: Keys.settings) } } }
    /// Während des Ladens nichts zurückschreiben (sonst überschreibt ein alter Stand neuere Änderungen anderer Geräte).
    @ObservationIgnored private var isLoading = false
    @ObservationIgnored private var remoteObserver: NSObjectProtocol?

    let context: ModelContext
    private let defaults: UserDefaults

    private enum Keys {
        static let palette = "palette"
        static let names = "customExerciseNames"
        static let settings = "settings"
        static let seededTemplates = "seededTemplates"
    }

    init(container: ModelContainer, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        context = ModelContext(container)
        context.autosaveEnabled = true
        reload()
        seedTemplatesIfNeeded()
        // Änderungen aus iCloud (andere Geräte) sofort übernehmen.
        remoteObserver = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        }
    }

    // MARK: Laden

    func reload() {
        let stored = (try? context.fetch(FetchDescriptor<StoredWorkout>())) ?? []
        // Doppelte Einträge (z. B. nach Sync von zwei Geräten) zusammenführen: neueste Fassung gewinnt.
        var byID: [UUID: StoredWorkout] = [:]
        for s in stored {
            if let existing = byID[s.workoutID] {
                if s.modifiedAt > existing.modifiedAt { context.delete(existing); byID[s.workoutID] = s } else { context.delete(s) }
            } else {
                byID[s.workoutID] = s
            }
        }
        // Dieselbe Vorlage zweimal (z. B. von zwei Geräten vor dem ersten Sync): neueste behalten.
        var byTemplate: [String: StoredWorkout] = [:]
        for st in byID.values {
            guard let key = st.templateKey else { continue }
            if let other = byTemplate[key] {
                let (keep, drop) = st.modifiedAt > other.modifiedAt ? (st, other) : (other, st)
                byTemplate[key] = keep
                byID[drop.workoutID] = nil
                context.delete(drop)
            } else {
                byTemplate[key] = st
            }
        }
        if context.hasChanges { try? context.save() }
        let loaded = byID.values.compactMap(\.workout)
        if loaded != workouts { workouts = loaded }
        isLoading = true
        defer { isLoading = false }
        let p = loadValue([PaletteItem].self, key: Keys.palette) ?? PaletteItem.defaults
        if p != palette { palette = p }
        let n = loadValue([String].self, key: Keys.names) ?? []
        if n != customExerciseNames { customExerciseNames = n }
        if let s = loadValue(AppSettings.self, key: Keys.settings), s != settings { settings = s }
    }

    /// Jede Vorlage genau einmal anlegen (auch neue Vorlagen nach einem Update), nie eine gelöschte zurückholen.
    /// Welche schon angelegt wurden, steht lokal und zusätzlich über iCloud synchronisiert.
    func seedTemplatesIfNeeded() {
        let keysKey = "fmj.templatesSeeded.keys"
        var seeded = Set(defaults.stringArray(forKey: keysKey) ?? [])
        seeded.formUnion(loadValue([String].self, key: Keys.seededTemplates) ?? [])
        // Übergang von der ersten Fassung: die vier ursprünglichen Vorlagen gelten als angelegt.
        if defaults.bool(forKey: "fmj.templatesSeeded.v1") {
            seeded.formUnion(["circuit4515", "tabata", "strength", "warmup"])
        }
        let present = Set(workouts.compactMap(\.templateKey))
        var changed = false
        for t in Templates.all() {
            guard let key = t.templateKey, !seeded.contains(key) else { continue }
            if !present.contains(key) { upsert(t) }
            seeded.insert(key)
            changed = true
        }
        defaults.set(Array(seeded).sorted(), forKey: keysKey)
        if changed { saveValue(Array(seeded).sorted(), key: Keys.seededTemplates) }
    }

    /// Änderung aus dem Baukasten übernehmen: nur die Felder, die der Baukasten wirklich geändert hat,
    /// in die aktuelle Fassung schreiben (Name, Favorit oder «zuletzt benutzt» aus der Bibliothek bleiben erhalten).
    func applyEdit(from old: Workout, to new: Workout) {
        var cur = workout(id: new.id) ?? new
        if old.items != new.items { cur.items = new.items }
        if old.name != new.name { cur.name = new.name }
        if old.skipTrailingRest != new.skipTrailingRest { cur.skipTrailingRest = new.skipTrailingRest }
        if old.spotifyLink != new.spotifyLink { cur.spotifyLink = new.spotifyLink }
        upsert(cur)
    }

    // MARK: Sortierung

    /// Favoriten oben, darunter nach letzter Benutzung (neueste zuerst), dann nach Name.
    var sorted: [Workout] {
        workouts.sorted { a, b in
            if a.isFavorite != b.isFavorite { return a.isFavorite }
            switch (a.lastUsed, b.lastUsed) {
            case let (x?, y?) where x != y: return x > y
            case (_?, nil): return true
            case (nil, _?): return false
            default: return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        }
    }

    func search(_ query: String) -> [Workout] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return sorted }
        return sorted.filter { $0.name.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    func workout(id: UUID) -> Workout? { workouts.first { $0.id == id } }

    // MARK: Ändern

    func upsert(_ w: Workout) {
        var w = w
        w.modifiedAt = Date()
        let id = w.id
        let existing = try? context.fetch(FetchDescriptor<StoredWorkout>(predicate: #Predicate { $0.workoutID == id }))
        if let s = existing?.first {
            s.update(from: w)
        } else {
            context.insert(StoredWorkout(w))
        }
        try? context.save()
        if let i = workouts.firstIndex(where: { $0.id == w.id }) { workouts[i] = w } else { workouts.append(w) }
        rememberNames(in: w)
    }

    @discardableResult
    func create(name: String) -> Workout {
        let w = Workout(name: name, items: [])
        upsert(w)
        return w
    }

    @discardableResult
    func duplicate(_ w: Workout) -> Workout {
        let copy = w.duplicated(name: String(localized: "\(w.name) Kopie"))
        upsert(copy)
        return copy
    }

    func rename(_ w: Workout, to name: String) {
        var w = w
        w.name = name
        upsert(w)
    }

    func toggleFavorite(_ w: Workout) {
        var w = w
        w.isFavorite.toggle()
        upsert(w)
    }

    func markUsed(_ w: Workout) {
        var w = w
        w.lastUsed = Date()
        upsert(w)
    }

    func delete(_ w: Workout) {
        let id = w.id
        if let found = try? context.fetch(FetchDescriptor<StoredWorkout>(predicate: #Predicate { $0.workoutID == id })) {
            found.forEach { context.delete($0) }
        }
        try? context.save()
        workouts.removeAll { $0.id == w.id }
    }

    // MARK: Palette

    func addPaletteItem(_ item: PaletteItem) {
        palette.append(item)
        saveValue(palette, key: Keys.palette)
    }

    func updatePaletteItem(_ item: PaletteItem) {
        guard let i = palette.firstIndex(where: { $0.id == item.id }) else { return }
        palette[i] = item
        saveValue(palette, key: Keys.palette)
    }

    func removePaletteItem(_ item: PaletteItem) {
        palette.removeAll { $0.id == item.id }
        saveValue(palette, key: Keys.palette)
    }

    // MARK: Übungsnamen

    func rememberName(_ name: String) {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return }
        let known = ExerciseCatalog.all.contains { $0.german.caseInsensitiveCompare(n) == .orderedSame || $0.english.caseInsensitiveCompare(n) == .orderedSame }
        guard !known, !customExerciseNames.contains(where: { $0.caseInsensitiveCompare(n) == .orderedSame }) else { return }
        customExerciseNames.append(n)
        customExerciseNames.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        saveValue(customExerciseNames, key: Keys.names)
    }

    private func rememberNames(in w: Workout) {
        for b in w.items.flatMap(\.blocks) where b.hasName { rememberName(b.exerciseName ?? "") }
    }

    // MARK: Werte

    private func loadValue<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let found = (try? context.fetch(FetchDescriptor<StoredValue>(predicate: #Predicate { $0.key == key }))) ?? []
        guard let newest = found.max(by: { $0.modifiedAt < $1.modifiedAt }) else { return nil }
        return try? JSONDecoder.fmj.decode(T.self, from: newest.payload)
    }

    private func saveValue<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder.fmj.encode(value) else { return }
        let found = (try? context.fetch(FetchDescriptor<StoredValue>(predicate: #Predicate { $0.key == key }))) ?? []
        if let first = found.first {
            first.payload = data
            first.modifiedAt = Date()
            found.dropFirst().forEach { context.delete($0) }
        } else {
            context.insert(StoredValue(key: key, payload: data))
        }
        try? context.save()
    }
}
