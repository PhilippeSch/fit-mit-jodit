#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation

/// Live Activity: Countdown und Blockname auf Sperrbildschirm und Dynamic Island.
struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var blockName: String
        var kind: BlockKind
        /// Ende des aktuellen Blocks; das System rendert den Countdown selbst (Text(timerInterval:)).
        var blockEnd: Date
        var blockStart: Date
        var isPaused: Bool
        /// Verbleibende Sekunden, wenn pausiert.
        var pausedRemaining: Int
        var nextName: String?
        var roundText: String?
    }

    var workoutName: String
}
#endif
