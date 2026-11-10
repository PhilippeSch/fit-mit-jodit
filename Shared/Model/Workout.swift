import Foundation

/// Art eines Blocks. Die Farbe ist fest (siehe Theme), der Typ steht immer auch als Text da.
enum BlockKind: String, Codable, CaseIterable, Sendable, Hashable {
    case work
    case rest
    case prep
}

/// Ein einzelner Zeitabschnitt.
struct Block: Codable, Hashable, Identifiable, Sendable {
    var id: UUID = UUID()
    var kind: BlockKind
    /// Dauer in ganzen Sekunden (5 s bis 10 min im Baukasten).
    var seconds: Int
    /// Freiwilliger Übungsname. Leer oder nil heisst: Anzeige «Arbeit»/«Pause».
    var exerciseName: String?

    init(id: UUID = UUID(), kind: BlockKind, seconds: Int, exerciseName: String? = nil) {
        self.id = id
        self.kind = kind
        self.seconds = seconds
        self.exerciseName = exerciseName
    }

    var hasName: Bool { !(exerciseName ?? "").trimmingCharacters(in: .whitespaces).isEmpty }

    /// Kopie mit neuer ID (für Duplizieren und beim Auflösen von Runden).
    func copy() -> Block { Block(kind: kind, seconds: seconds, exerciseName: exerciseName) }
}

/// Mehrere nebeneinander liegende Blöcke, die N-mal wiederholt werden. Keine Runden in Runden.
struct Round: Codable, Hashable, Identifiable, Sendable {
    var id: UUID = UUID()
    var repeats: Int
    var blocks: [Block]

    var secondsPerPass: Int { blocks.reduce(0) { $0 + $1.seconds } }
}

/// Eintrag der Zeitleiste: ein Block oder eine Runde.
enum TimelineItem: Codable, Hashable, Identifiable, Sendable {
    case block(Block)
    case round(Round)

    var id: UUID {
        switch self {
        case .block(let b): return b.id
        case .round(let r): return r.id
        }
    }

    var totalSeconds: Int {
        switch self {
        case .block(let b): return b.seconds
        case .round(let r): return r.secondsPerPass * max(r.repeats, 0)
        }
    }

    var blocks: [Block] {
        switch self {
        case .block(let b): return [b]
        case .round(let r): return r.blocks
        }
    }
}

/// Ein Training, wie es gespeichert, synchronisiert und exportiert wird.
struct Workout: Codable, Hashable, Identifiable, Sendable {
    var id: UUID = UUID()
    var name: String
    var items: [TimelineItem]
    var spotifyLink: String?
    var isFavorite: Bool = false
    var lastUsed: Date?
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    /// Eine Pause ganz am Ende wird beim Ablauf übersprungen (Standard: ja).
    var skipTrailingRest: Bool = true
    /// Vorlagen sind mitgelieferte Trainings, die sich kopieren und ändern lassen.
    var templateKey: String?

    init(id: UUID = UUID(), name: String, items: [TimelineItem], spotifyLink: String? = nil,
         isFavorite: Bool = false, lastUsed: Date? = nil, createdAt: Date = Date(), modifiedAt: Date = Date(),
         skipTrailingRest: Bool = true, templateKey: String? = nil) {
        self.id = id
        self.name = name
        self.items = items
        self.spotifyLink = spotifyLink
        self.isFavorite = isFavorite
        self.lastUsed = lastUsed
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.skipTrailingRest = skipTrailingRest
        self.templateKey = templateKey
    }

    /// Gesamtdauer, wie sie ablaufen wird (ohne Vorlauf, mit übersprungener Schlusspause).
    var totalSeconds: Int { StepSequence.expand(self).reduce(0) { $0 + $1.seconds } }

    /// Anzahl Runden für die Anzeige im Baukasten: grösste Wiederholungszahl, mindestens 1.
    var roundCount: Int {
        let r = items.compactMap { item -> Int? in
            if case .round(let r) = item { return r.repeats }
            return nil
        }
        return r.max() ?? 1
    }

    /// Kopie mit neuen IDs (Duplizieren, Vorlage übernehmen, Import).
    func duplicated(name: String? = nil) -> Workout {
        var w = self
        w.id = UUID()
        w.name = name ?? self.name
        w.isFavorite = false
        w.lastUsed = nil
        w.createdAt = Date()
        w.modifiedAt = Date()
        w.templateKey = nil
        w.items = items.map { item in
            switch item {
            case .block(let b): return .block(b.copy())
            case .round(let r): return .round(Round(repeats: r.repeats, blocks: r.blocks.map { $0.copy() }))
            }
        }
        return w
    }
}

/// Ein Schritt der aufgelösten, linearen Abfolge.
struct Step: Hashable, Sendable, Codable {
    var kind: BlockKind
    var seconds: Int
    var exerciseName: String?
    /// 1-basierte Runde innerhalb der Runde, zu der der Schritt gehört (nil ausserhalb von Runden).
    var round: Int?
    var roundCount: Int?
    /// true für den Vorlauf vor dem ersten Block.
    var isLeadIn: Bool = false

    var hasName: Bool { !(exerciseName ?? "").trimmingCharacters(in: .whitespaces).isEmpty }
}

enum StepSequence {
    /// Löst Runden in eine lineare Folge auf und lässt eine Pause ganz am Ende weg, falls gewünscht.
    static func expand(_ workout: Workout) -> [Step] {
        expand(items: workout.items, skipTrailingRest: workout.skipTrailingRest)
    }

    static func expand(items: [TimelineItem], skipTrailingRest: Bool) -> [Step] {
        var steps: [Step] = []
        for item in items {
            switch item {
            case .block(let b):
                guard b.seconds > 0 else { continue }
                steps.append(Step(kind: b.kind, seconds: b.seconds, exerciseName: b.exerciseName))
            case .round(let r):
                guard r.repeats > 0 else { continue }
                for pass in 1...r.repeats {
                    for b in r.blocks where b.seconds > 0 {
                        steps.append(Step(kind: b.kind, seconds: b.seconds, exerciseName: b.exerciseName,
                                          round: pass, roundCount: r.repeats))
                    }
                }
            }
        }
        if skipTrailingRest {
            while let last = steps.last, last.kind == .rest, steps.count > 1 {
                steps.removeLast()
            }
        }
        return steps
    }

    /// Folge mit Vorlauf («Bereit machen», blau) vor dem ersten Block.
    static func withLeadIn(_ steps: [Step], leadInSeconds: Int) -> [Step] {
        guard leadInSeconds > 0, !steps.isEmpty else { return steps }
        return [Step(kind: .prep, seconds: leadInSeconds, exerciseName: nil, isLeadIn: true)] + steps
    }
}
