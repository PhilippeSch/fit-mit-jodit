import Foundation

/// Merkt sich das laufende Training, damit es weiterläuft, falls iOS die App im Hintergrund beendet.
/// Der Timer rechnet mit Zeitstempeln: Nach dem Öffnen steht er dort, wo er ohne Unterbruch stünde.
struct SavedRun: Codable, Equatable {
    var workout: Workout
    var engine: TimerEngine
    var savedAt: Date
}

struct RunPersistence {
    static let key = "fmj.activeRun.v1"
    /// Ältere Stände verwerfen (z. B. Training am Vortag nie beendet).
    static let maxAge: TimeInterval = 4 * 3600
    let defaults: UserDefaults

    func save(_ run: SavedRun) {
        if let data = try? JSONEncoder.fmj.encode(run) { defaults.set(data, forKey: Self.key) }
    }

    func clear() { defaults.removeObject(forKey: Self.key) }

    /// Gespeichertes Training, sofern es zum Zeitpunkt `now` noch nicht vorbei und nicht zu alt ist.
    func load(now: Date) -> SavedRun? {
        guard let data = defaults.data(forKey: Self.key),
              let run = try? JSONDecoder.fmj.decode(SavedRun.self, from: data) else { return nil }
        guard now.timeIntervalSince(run.savedAt) < Self.maxAge, !run.engine.state(at: now).isFinished else {
            clear()
            return nil
        }
        return run
    }
}
