import Foundation

/// Austauschbare Uhr. In Tests wird `ManualClock` verwendet.
protocol AppClock: AnyObject, Sendable {
    var now: Date { get }
}

final class SystemClock: AppClock, @unchecked Sendable {
    static let shared = SystemClock()
    var now: Date { Date() }
}

/// Uhr für Tests: steht still, bis sie vorgestellt wird.
final class ManualClock: AppClock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    init(_ start: Date = Date(timeIntervalSinceReferenceDate: 800_000_000)) { current = start }
    var now: Date { lock.lock(); defer { lock.unlock() }; return current }
    func advance(_ seconds: TimeInterval) { lock.lock(); current += seconds; lock.unlock() }
    func set(_ date: Date) { lock.lock(); current = date; lock.unlock() }
}

/// Zustand zu einem Zeitpunkt.
struct RunState: Equatable, Sendable {
    var stepIndex: Int
    var step: Step?
    var nextStep: Step?
    /// Verbleibende Zeit im aktuellen Schritt in Sekunden.
    var remaining: TimeInterval
    var elapsedInStep: TimeInterval
    var totalElapsed: TimeInterval
    var totalDuration: TimeInterval
    var isPaused: Bool
    var isFinished: Bool

    /// Ganze Sekunden für die Anzeige (aufgerundet, 0:45 bis 0:01).
    var displaySeconds: Int { isFinished ? 0 : max(Int(ceil(remaining - 0.000_1)), 0) }
    var progress: Double { totalDuration > 0 ? min(totalElapsed / totalDuration, 1) : 0 }
}

/// Rechnet nur mit Zeitstempeln, nie mit gezählten Ticks.
/// `elapsedBase` ist die bis `anchor` verstrichene Trainingszeit; läuft der Timer, kommt `now - anchor` dazu.
struct TimerEngine: Codable, Equatable, Sendable {
    let steps: [Step]
    private(set) var elapsedBase: TimeInterval
    /// nil = pausiert.
    private(set) var anchor: Date?
    /// Startzeiten der Schritte relativ zum Trainingsbeginn.
    let starts: [TimeInterval]
    let totalDuration: TimeInterval

    init(steps: [Step], startAt date: Date) {
        self.steps = steps
        var s: [TimeInterval] = []
        var acc: TimeInterval = 0
        for step in steps {
            s.append(acc)
            acc += TimeInterval(step.seconds)
        }
        starts = s
        totalDuration = acc
        elapsedBase = 0
        anchor = date
    }

    var isPaused: Bool { anchor == nil }

    func elapsed(at date: Date) -> TimeInterval {
        let e = elapsedBase + (anchor.map { date.timeIntervalSince($0) } ?? 0)
        return min(max(e, 0), totalDuration)
    }

    func stepIndex(forElapsed e: TimeInterval) -> Int {
        guard !steps.isEmpty else { return 0 }
        // letzter Schritt, dessen Start <= e
        var lo = 0, hi = starts.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if starts[mid] <= e { lo = mid } else { hi = mid - 1 }
        }
        return lo
    }

    func state(at date: Date) -> RunState {
        let e = elapsed(at: date)
        let finished = steps.isEmpty || e >= totalDuration
        if finished {
            return RunState(stepIndex: max(steps.count - 1, 0), step: steps.last, nextStep: nil, remaining: 0,
                            elapsedInStep: TimeInterval(steps.last?.seconds ?? 0), totalElapsed: totalDuration,
                            totalDuration: totalDuration, isPaused: isPaused, isFinished: true)
        }
        let i = stepIndex(forElapsed: e)
        let inStep = e - starts[i]
        let remaining = TimeInterval(steps[i].seconds) - inStep
        return RunState(stepIndex: i, step: steps[i], nextStep: i + 1 < steps.count ? steps[i + 1] : nil,
                        remaining: remaining, elapsedInStep: inStep, totalElapsed: e,
                        totalDuration: totalDuration, isPaused: isPaused, isFinished: false)
    }

    /// Zeitpunkt, an dem der aktuelle Schritt endet (nil, wenn pausiert oder fertig).
    func stepEndDate(at date: Date) -> Date? {
        guard let anchor else { return nil }
        let st = state(at: date)
        guard !st.isFinished else { return nil }
        let endElapsed = starts[st.stepIndex] + TimeInterval(steps[st.stepIndex].seconds)
        return anchor.addingTimeInterval(endElapsed - elapsedBase)
    }

    /// Zeitpunkt, an dem das Training endet (nil, wenn pausiert).
    func endDate() -> Date? {
        guard let anchor else { return nil }
        return anchor.addingTimeInterval(totalDuration - elapsedBase)
    }

    mutating func pause(at date: Date) {
        guard anchor != nil else { return }
        elapsedBase = elapsed(at: date)
        anchor = nil
    }

    mutating func resume(at date: Date) {
        guard anchor == nil else { return }
        anchor = date
    }

    private mutating func jump(toElapsed e: TimeInterval, at date: Date) {
        elapsedBase = min(max(e, 0), totalDuration)
        if anchor != nil { anchor = date }
    }

    /// Springt an den Anfang des nächsten Schritts (oder ans Ende).
    mutating func skipForward(at date: Date) {
        let st = state(at: date)
        guard !st.isFinished else { return }
        let next = st.stepIndex + 1
        jump(toElapsed: next < starts.count ? starts[next] : totalDuration, at: date)
    }

    /// Innerhalb der ersten 2 Sekunden eines Schritts: zum vorherigen Schritt. Sonst: Schritt neu beginnen.
    mutating func skipBack(at date: Date) {
        let st = state(at: date)
        let i = st.isFinished ? max(steps.count - 1, 0) : st.stepIndex
        guard !steps.isEmpty else { return }
        if st.isFinished || st.elapsedInStep > 2 || i == 0 {
            jump(toElapsed: starts[i], at: date)
        } else {
            jump(toElapsed: starts[i - 1], at: date)
        }
    }
}
