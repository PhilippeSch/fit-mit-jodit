import Foundation

/// Steuerbefehle von der Uhr (oder vom iPhone als Fernbedienung fürs iPad).
enum RemoteCommand: String, Codable, Sendable {
    case togglePause, skipForward, skipBack, stop, start, requestState
}

/// Zustand eines laufenden Trainings. Die Gegenseite rechnet mit `engine` selbst weiter,
/// es braucht also keine Daten pro Sekunde.
struct RemoteSnapshot: Codable, Equatable, Sendable {
    var workoutID: UUID
    var workoutName: String
    var engine: TimerEngine
    /// Gerät, auf dem das Training läuft (z. B. «iPad»).
    var hostName: String
    var hostIsPad: Bool

    func state(at date: Date) -> RunState { engine.state(at: date) }

    func roundText(at date: Date) -> String? {
        guard let s = engine.state(at: date).step, let r = s.round, let n = s.roundCount else { return nil }
        return String(localized: "Runde \(r) von \(n)")
    }
}

/// Kurzinfo für die Trainingsliste auf der Uhr.
struct WorkoutSummary: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var totalSeconds: Int
    var isFavorite: Bool
}

enum RemoteMessage: Codable, Sendable, Equatable {
    case command(RemoteCommand, workoutID: UUID?)
    /// nil = kein Training läuft.
    case snapshot(RemoteSnapshot?)
    case workouts([WorkoutSummary])
    /// Antwort des iPhone, wohin es Befehle schickt und ob die Verbindung steht.
    case target(name: String, connected: Bool)

    func encoded() -> Data { (try? JSONEncoder.fmj.encode(self)) ?? Data() }

    static func decode(_ data: Data) -> RemoteMessage? { try? JSONDecoder.fmj.decode(RemoteMessage.self, from: data) }

    static let key = "m"
}

