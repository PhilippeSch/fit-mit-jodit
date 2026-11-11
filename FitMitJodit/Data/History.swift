import Foundation

/// Ein absolviertes (oder nach mindestens einer Minute abgebrochenes) Training.
struct HistoryEntry: Codable, Equatable, Identifiable, Sendable {
    var id: UUID = UUID()
    var workoutID: UUID
    var name: String
    var startedAt: Date
    /// Trainierte Zeit ohne Vorlauf, in Sekunden.
    var seconds: Int
    var completed: Bool
}

/// Kennzahlen für die Übersicht.
struct HistorySummary: Equatable {
    var count: Int
    var seconds: Int

    /// Trainings der laufenden Kalenderwoche (Wochenbeginn nach Gerätesprache und Region).
    static func week(_ entries: [HistoryEntry], now: Date, calendar: Calendar = .current) -> HistorySummary {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return HistorySummary(count: 0, seconds: 0) }
        let inWeek = entries.filter { week.contains($0.startedAt) }
        return HistorySummary(count: inWeek.count, seconds: inWeek.reduce(0) { $0 + $1.seconds })
    }

    /// Minuten pro Wochentag (7 Werte, beginnend mit dem ersten Tag der Woche).
    static func minutesPerDay(_ entries: [HistoryEntry], now: Date, calendar: Calendar = .current) -> [Int] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return Array(repeating: 0, count: 7) }
        var result = Array(repeating: 0, count: 7)
        for e in entries where week.contains(e.startedAt) {
            let day = calendar.dateComponents([.day], from: calendar.startOfDay(for: week.start), to: calendar.startOfDay(for: e.startedAt)).day ?? 0
            if (0..<7).contains(day) { result[day] += e.seconds }
        }
        return result.map { Int((Double($0) / 60).rounded()) }
    }
}
