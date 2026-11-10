import ActivityKit
import Foundation

/// Startet, aktualisiert und beendet die Live Activity zum laufenden Training.
/// Aktualisiert wird nur bei Blockwechsel, Pause und Sprung; den Countdown zählt das System selbst.
@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()
    private var activity: Activity<WorkoutActivityAttributes>?

    func attach(to app: AppModel) {
        app.observeSession { [weak self] session in self?.update(session) }
    }

    private func update(_ session: RunSession?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let session, !session.isFinished, let step = session.state.step else {
            end()
            return
        }
        let now = session.clock.now
        let st = session.state
        let end = session.engine.stepEndDate(at: now) ?? now.addingTimeInterval(st.remaining)
        let state = WorkoutActivityAttributes.ContentState(
            blockName: step.displayName, kind: step.kind,
            blockEnd: end, blockStart: end.addingTimeInterval(-TimeInterval(step.seconds)),
            isPaused: st.isPaused, pausedRemaining: st.displaySeconds,
            nextName: st.nextStep?.displayName, roundText: session.roundText)
        let content = ActivityContent(state: state, staleDate: end.addingTimeInterval(2))
        if let activity {
            Task { await activity.update(content) }
        } else {
            activity = try? Activity.request(attributes: WorkoutActivityAttributes(workoutName: session.workout.name),
                                             content: content, pushType: nil)
        }
    }

    private func end() {
        guard let a = activity else { return }
        activity = nil
        Task { await a.end(nil, dismissalPolicy: .immediate) }
    }
}
