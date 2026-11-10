import Foundation
#if os(watchOS)
import WatchKit
#endif

/// Welche Haptik die Uhr spielt: unterschiedlich für Arbeit, Pause und die letzten 3 Sekunden.
/// Rein und testbar; die Uhr ruft `next(state:)` regelmässig auf.
final class HapticPlanner {
    enum Haptic: Equatable {
        case workStart, restStart, countdown, finished

        #if os(watchOS)
        var wk: WKHapticType {
            switch self {
            case .workStart: return .start
            case .restStart: return .stop
            case .countdown: return .click
            case .finished: return .success
            }
        }
        #endif
    }

    private var lastIndex: Int?
    private var lastCountdown: Int?
    private var finished = false

    func reset() {
        lastIndex = nil
        lastCountdown = nil
        finished = false
    }

    func next(state: RunState) -> [Haptic] {
        var out: [Haptic] = []
        if state.isFinished {
            if !finished, lastIndex != nil { out.append(.finished) }
            finished = true
            return out
        }
        if let last = lastIndex, last != state.stepIndex, let step = state.step {
            out.append(step.kind == .rest ? .restStart : .workStart)
            lastCountdown = nil
        }
        lastIndex = state.stepIndex
        if !state.isPaused, let step = state.step, step.seconds >= 4 {
            let s = state.displaySeconds
            if (1...3).contains(s), lastCountdown != s {
                out.append(.countdown)
                lastCountdown = s
            }
        }
        return out
    }
}
