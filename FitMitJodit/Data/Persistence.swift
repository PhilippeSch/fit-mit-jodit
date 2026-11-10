import Foundation
import SwiftData

/// Gespeichertes Training. Der Inhalt liegt als JSON in `payload`, damit das Modell
/// CloudKit-tauglich bleibt (keine Beziehungen, keine Pflichtfelder ohne Standardwert, keine Unique-Constraints).
@Model
final class StoredWorkout {
    var workoutID: UUID = UUID()
    var name: String = ""
    var payload: Data = Data()
    var modifiedAt: Date = Date()
    var isFavorite: Bool = false
    var lastUsed: Date?
    var templateKey: String?

    init(_ w: Workout) {
        workoutID = w.id
        update(from: w)
    }

    func update(from w: Workout) {
        name = w.name
        payload = (try? JSONEncoder.fmj.encode(w)) ?? Data()
        modifiedAt = w.modifiedAt
        isFavorite = w.isFavorite
        lastUsed = w.lastUsed
        templateKey = w.templateKey
    }

    var workout: Workout? {
        guard var w = try? JSONDecoder.fmj.decode(Workout.self, from: payload) else { return nil }
        w.id = workoutID
        w.isFavorite = isFavorite
        w.lastUsed = lastUsed
        return w
    }
}

/// Kleine Werte, die über iCloud mitlaufen: Palette, eigene Übungsnamen, Einstellungen.
@Model
final class StoredValue {
    var key: String = ""
    var payload: Data = Data()
    var modifiedAt: Date = Date()

    init(key: String, payload: Data) {
        self.key = key
        self.payload = payload
        modifiedAt = Date()
    }
}

enum PersistenceFactory {
    static let schema = Schema([StoredWorkout.self, StoredValue.self])

    /// iCloud nur, wenn der Build dafür eingerichtet ist (Info.plist `FMJCloudKitContainer`) und
    /// nicht in Tests. Fällt iCloud aus, läuft die App mit lokalem Speicher weiter.
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        if inMemory {
            return try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
        if let id = Bundle.main.object(forInfoDictionaryKey: "FMJCloudKitContainer") as? String,
           !id.isEmpty, !id.hasPrefix("$"),
           let c = try? ModelContainer(for: schema,
                                       configurations: ModelConfiguration(cloudKitDatabase: .private(id))) {
            return c
        }
        if let c = try? ModelContainer(for: schema, configurations: ModelConfiguration(cloudKitDatabase: .none)) {
            return c
        }
        // Letzter Ausweg: im Speicher, damit die App nie abstürzt.
        return try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
}
