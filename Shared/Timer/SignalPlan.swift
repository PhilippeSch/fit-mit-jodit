import Foundation

/// Was zu einem Zeitpunkt erklingen soll.
enum SignalKind: Equatable, Sendable, Codable {
    /// Ton in den letzten 3 Sekunden (3, 2, 1).
    case countdown(Int)
    /// Startsignal beim Blockwechsel.
    case blockStart(BlockKind)
    /// Signal bei Halbzeit eines Blocks.
    case halftime
    /// Sprachansage.
    case announcement(String)
    /// Ende des Trainings.
    case finished
}

struct SignalEvent: Equatable, Sendable {
    /// Zeitpunkt relativ zum Trainingsbeginn (inkl. Vorlauf).
    var at: TimeInterval
    var kind: SignalKind
}

struct SignalSettings: Codable, Equatable, Sendable {
    var tonesEnabled = true
    var tonesVolume: Double = 0.8
    var halftimeEnabled = true
    var halftimeVolume: Double = 0.8
    var voiceEnabled = false
    var voiceVolume: Double = 1.0
    var toneSet: ToneSet = .beeps
}

enum ToneSet: String, Codable, CaseIterable, Sendable, Identifiable {
    case beeps, boxingBell, softGong
    var id: String { rawValue }
}

/// Texte der Sprachansagen. Ohne Übungsnamen sagt die Stimme «Los» bzw. nur «Pause».
enum Announcements {
    static func text(for step: Step, next: Step?, isLastRoundStart: Bool) -> String? {
        var parts: [String] = []
        if isLastRoundStart { parts.append(String(localized: "Letzte Runde", comment: "Sprachansage")) }
        switch step.kind {
        case .rest:
            parts.append(String(localized: "Pause", comment: "Sprachansage zu Beginn einer Pause"))
            if let next, next.kind == .work, let name = next.exerciseName, next.hasName {
                parts.append(String(localized: "gleich: \(name)", comment: "Sprachansage, nächste Übung"))
            }
        case .work:
            if let name = step.exerciseName, step.hasName {
                parts.append(name)
            } else {
                parts.append(String(localized: "Los", comment: "Sprachansage ohne Übungsnamen"))
            }
        case .prep:
            if step.isLeadIn {
                parts.append(String(localized: "Bereit machen", comment: "Sprachansage Vorlauf"))
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: ". ")
    }

    static var finished: String { String(localized: "Geschafft", comment: "Sprachansage am Ende") }
}

enum SignalPlanner {
    /// Alle Signale eines Trainings in zeitlicher Reihenfolge.
    static func plan(steps: [Step], settings: SignalSettings) -> [SignalEvent] {
        var events: [SignalEvent] = []
        var t: TimeInterval = 0
        // Index des ersten Schritts der letzten Runde einer Runde (Ansage «Letzte Runde»).
        var lastRoundStarts = Set<Int>()
        for (i, s) in steps.enumerated() {
            if let r = s.round, let n = s.roundCount, n > 1, r == n {
                if i == 0 || steps[i - 1].round != r || steps[i - 1].roundCount != n { lastRoundStarts.insert(i) }
            }
        }
        for (i, s) in steps.enumerated() {
            let len = TimeInterval(s.seconds)
            if settings.tonesEnabled, !s.isLeadIn {
                events.append(SignalEvent(at: t, kind: .blockStart(s.kind)))
            }
            if settings.voiceEnabled,
               let text = Announcements.text(for: s, next: i + 1 < steps.count ? steps[i + 1] : nil,
                                             isLastRoundStart: lastRoundStarts.contains(i)) {
                events.append(SignalEvent(at: t, kind: .announcement(text)))
            }
            if settings.halftimeEnabled, s.kind == .work, s.seconds >= 10 {
                events.append(SignalEvent(at: t + len / 2, kind: .halftime))
            }
            if settings.tonesEnabled, s.seconds >= 4 {
                for n in stride(from: 3, through: 1, by: -1) {
                    events.append(SignalEvent(at: t + len - TimeInterval(n), kind: .countdown(n)))
                }
            }
            t += len
        }
        if !steps.isEmpty {
            if settings.tonesEnabled { events.append(SignalEvent(at: t, kind: .finished)) }
            if settings.voiceEnabled { events.append(SignalEvent(at: t, kind: .announcement(Announcements.finished))) }
        }
        return events.sorted { $0.at < $1.at }
    }

    /// Ereignisse, die zwischen zwei Zeitpunkten fällig wurden (halboffenes Intervall (from, to]).
    /// Liegt `to - from` über `maxCatchUp`, werden nur die Ereignisse im letzten Fenster geliefert,
    /// damit nach der Rückkehr aus dem Hintergrund keine Ton-Lawine entsteht.
    static func due(_ events: [SignalEvent], from: TimeInterval, to: TimeInterval, maxCatchUp: TimeInterval = 1.5) -> [SignalEvent] {
        guard to > from else { return [] }
        let lower = max(from, to - maxCatchUp)
        // Ereignisse genau bei 0 sollen beim Start feuern: from < 0 erlauben.
        return events.filter { $0.at > lower && $0.at <= to || ($0.at == 0 && from < 0 && to >= 0) }
    }
}
