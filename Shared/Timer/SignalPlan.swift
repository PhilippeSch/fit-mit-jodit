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

/// Wann gesprochen wird. «Automatisch»: nur bei Trainings mit Übungsnamen (z. B. für Teilnehmende zu Hause);
/// Trainings ohne Namen (Kursstunde, Jodit sagt selbst an) bleiben bei den Tönen.
enum VoiceMode: String, Codable, CaseIterable, Sendable, Identifiable {
    case off, auto, always
    var id: String { rawValue }
}

struct SignalSettings: Codable, Equatable, Sendable {
    var tonesEnabled = true
    var tonesVolume: Double = 0.8
    var halftimeEnabled = true
    var halftimeVolume: Double = 0.8
    var voiceMode: VoiceMode = .auto
    var voiceVolume: Double = 1.0
    var toneSet: ToneSet = .chime
    /// Ausführliche Ansagen: Dauer, «Bereit machen» vor der nächsten Übung, «Noch 10 Sekunden».
    var voiceDetailed = true
    /// Gewählte Stimme (AVSpeechSynthesisVoice.identifier); nil = beste installierte automatisch.
    var voiceIdentifier: String?

    /// Ansagen grundsätzlich möglich (nicht «Aus»). Setzen schaltet zwischen «Immer» und «Aus».
    var voiceEnabled: Bool {
        get { voiceMode != .off }
        set { voiceMode = newValue ? .always : .off }
    }

    /// Wird für diese Schrittfolge gesprochen?
    func speaks(_ steps: [Step]) -> Bool {
        switch voiceMode {
        case .off: return false
        case .always: return true
        case .auto: return steps.contains { $0.kind == .work && $0.hasName }
        }
    }

    init() {}

    private enum CodingKeys: String, CodingKey {
        case tonesEnabled, tonesVolume, halftimeEnabled, halftimeVolume, voiceMode, voiceVolume, toneSet, voiceDetailed, voiceIdentifier
        case voiceEnabled // ältere Fassung
    }

    /// Tolerant einlesen: fehlende Felder (ältere Fassungen) bekommen den Standardwert.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SignalSettings()
        tonesEnabled = try c.decodeIfPresent(Bool.self, forKey: .tonesEnabled) ?? d.tonesEnabled
        tonesVolume = try c.decodeIfPresent(Double.self, forKey: .tonesVolume) ?? d.tonesVolume
        halftimeEnabled = try c.decodeIfPresent(Bool.self, forKey: .halftimeEnabled) ?? d.halftimeEnabled
        halftimeVolume = try c.decodeIfPresent(Double.self, forKey: .halftimeVolume) ?? d.halftimeVolume
        if let m = try c.decodeIfPresent(VoiceMode.self, forKey: .voiceMode) {
            voiceMode = m
        } else {
            // Früher: Schalter «Sprachansagen» (Standard aus) → ein = «Immer», aus = neuer Standard «Automatisch».
            voiceMode = (try c.decodeIfPresent(Bool.self, forKey: .voiceEnabled) ?? false) ? .always : .auto
        }
        voiceVolume = try c.decodeIfPresent(Double.self, forKey: .voiceVolume) ?? d.voiceVolume
        // Unbekanntes Ton-Set (von einer neueren Fassung über iCloud): Standard nehmen, den Rest behalten.
        toneSet = (try? c.decodeIfPresent(ToneSet.self, forKey: .toneSet)) ?? d.toneSet
        voiceDetailed = try c.decodeIfPresent(Bool.self, forKey: .voiceDetailed) ?? d.voiceDetailed
        voiceIdentifier = try c.decodeIfPresent(String.self, forKey: .voiceIdentifier)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(tonesEnabled, forKey: .tonesEnabled)
        try c.encode(tonesVolume, forKey: .tonesVolume)
        try c.encode(halftimeEnabled, forKey: .halftimeEnabled)
        try c.encode(halftimeVolume, forKey: .halftimeVolume)
        try c.encode(voiceMode, forKey: .voiceMode)
        try c.encode(voiceVolume, forKey: .voiceVolume)
        try c.encode(toneSet, forKey: .toneSet)
        try c.encode(voiceDetailed, forKey: .voiceDetailed)
        try c.encodeIfPresent(voiceIdentifier, forKey: .voiceIdentifier)
    }
}

enum ToneSet: String, Codable, CaseIterable, Sendable, Identifiable {
    case chime, beeps, boxingBell, softGong
    var id: String { rawValue }
}

/// Texte der Sprachansagen. Ohne Übungsnamen sagt die Stimme «Los» bzw. nur «Pause».
/// Ausführlich (`detailed`) kommt die Dauer dazu, z. B. «Kniebeugen, 45 Sekunden».
enum Announcements {
    static func text(for step: Step, next: Step?, isLastRoundStart: Bool, detailed: Bool = false) -> String? {
        var parts: [String] = []
        if isLastRoundStart { parts.append(String(localized: "Letzte Runde", comment: "Sprachansage")) }
        switch step.kind {
        case .rest:
            if detailed {
                parts.append(String(localized: "Pause, \(spoken(step.seconds))", comment: "Sprachansage Pause mit Dauer"))
            } else {
                parts.append(String(localized: "Pause", comment: "Sprachansage zu Beginn einer Pause"))
            }
            if let next, next.kind == .work, let name = next.exerciseName, next.hasName {
                parts.append(String(localized: "gleich: \(name)", comment: "Sprachansage, nächste Übung"))
            }
        case .work:
            if let name = step.exerciseName, step.hasName {
                parts.append(detailed ? String(localized: "\(name), \(spoken(step.seconds))", comment: "Übung mit Dauer") : name)
            } else if detailed {
                parts.append(String(localized: "\(spoken(step.seconds)) Arbeit, los", comment: "Arbeit ohne Namen mit Dauer"))
            } else {
                parts.append(String(localized: "Los", comment: "Sprachansage ohne Übungsnamen"))
            }
        case .prep:
            if step.isLeadIn {
                parts.append(String(localized: "Bereit machen", comment: "Sprachansage Vorlauf"))
                if detailed, let next, next.kind == .work {
                    parts.append(String(localized: "gleich: \(upcoming(next))", comment: "Vorlauf, erste Übung"))
                }
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: ". ")
    }

    /// «Bereit machen: Kniebeugen, 45 Sekunden» kurz vor Ende einer Pause.
    static func getReady(next: Step) -> String {
        String(localized: "Bereit machen: \(upcoming(next))", comment: "Sprachansage vor der nächsten Übung")
    }

    static var tenSecondsLeft: String { String(localized: "Noch 10 Sekunden", comment: "Sprachansage") }

    static var finished: String { String(localized: "Geschafft", comment: "Sprachansage am Ende") }

    private static func upcoming(_ s: Step) -> String {
        if let name = s.exerciseName, s.hasName { return String(localized: "\(name), \(spoken(s.seconds))", comment: "Übung mit Dauer") }
        return String(localized: "\(spoken(s.seconds)) Arbeit", comment: "Arbeit mit Dauer")
    }

    /// Gesprochene Dauer: «45 Sekunden», «1 Minute», «1 Minute 30».
    static func spoken(_ seconds: Int) -> String {
        let m = seconds / 60, sec = seconds % 60
        if m == 0 { return String(localized: "\(sec) Sekunden", comment: "gesprochene Dauer") }
        let minutes = m == 1 ? String(localized: "1 Minute", comment: "gesprochene Dauer") : String(localized: "\(m) Minuten", comment: "gesprochene Dauer")
        return sec == 0 ? minutes : "\(minutes) \(sec)"
    }
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
        let voice = settings.speaks(steps)
        for (i, s) in steps.enumerated() {
            let len = TimeInterval(s.seconds)
            if settings.tonesEnabled, !s.isLeadIn {
                events.append(SignalEvent(at: t, kind: .blockStart(s.kind)))
            }
            let next = i + 1 < steps.count ? steps[i + 1] : nil
            if voice,
               let text = Announcements.text(for: s, next: next, isLastRoundStart: lastRoundStarts.contains(i),
                                             detailed: settings.voiceDetailed) {
                events.append(SignalEvent(at: t, kind: .announcement(text)))
            }
            if voice, settings.voiceDetailed {
                // 6 s vor Ende einer Pause: «Bereit machen …», fertig gesprochen vor den 3-2-1-Tönen.
                if s.kind == .rest, s.seconds >= 12, let next, next.kind == .work {
                    events.append(SignalEvent(at: t + len - 6, kind: .announcement(Announcements.getReady(next: next))))
                }
                // In längeren Arbeitsblöcken: «Noch 10 Sekunden».
                if s.kind == .work, s.seconds >= 30 {
                    events.append(SignalEvent(at: t + len - 10, kind: .announcement(Announcements.tenSecondsLeft)))
                }
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
            if voice { events.append(SignalEvent(at: t, kind: .announcement(Announcements.finished))) }
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
