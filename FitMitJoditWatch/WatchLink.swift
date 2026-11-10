import Foundation
import Observation
import WatchConnectivity
import WatchKit

/// Verbindung Uhr → iPhone. Die Uhr rechnet den Countdown aus dem empfangenen Zustand selbst
/// und meldet Blockwechsel mit Haptik.
@MainActor
@Observable
final class WatchLink: NSObject {
    static let shared = WatchLink()

    private(set) var snapshot: RemoteSnapshot?
    private(set) var workouts: [WorkoutSummary] = []
    private(set) var targetName: String = String(localized: "iPhone")
    private(set) var reachable = false
    var lastError: String?

    @ObservationIgnored private var hapticTask: Task<Void, Never>?
    @ObservationIgnored let haptics = HapticPlanner()

    func activate() {
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            let de = Locale.current.language.languageCode?.identifier == "de"
            workouts = [WorkoutSummary(id: UUID(), name: de ? "Zirkel 45/15" : "Circuit 45/15", totalSeconds: 840, isFavorite: true),
                        WorkoutSummary(id: UUID(), name: "Tabata", totalSeconds: 230, isFavorite: false),
                        WorkoutSummary(id: UUID(), name: de ? "Kraft" : "Strength", totalSeconds: 1170, isFavorite: false)]
            // Für Screenshots: laufendes Beispieltraining (Arbeit oder Pause).
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-watchDemoRun") || args.contains("-watchDemoRest") {
                let names = de ? ["Kniebeugen", "Liegestütze", "Burpees"] : ["Squats", "Push-ups", "Burpees"]
                var steps: [Step] = []
                for r in 1...4 {
                    for (i, n) in names.enumerated() {
                        steps.append(Step(kind: .work, seconds: 45, exerciseName: n, round: r, roundCount: 4))
                        steps.append(Step(kind: .rest, seconds: i < 2 ? 15 : 60, round: r, roundCount: 4))
                    }
                }
                let offset: TimeInterval = args.contains("-watchDemoRest") ? 45 + 3 : 13
                let engine = TimerEngine(steps: steps, startAt: Date().addingTimeInterval(-offset))
                snapshot = RemoteSnapshot(workoutID: UUID(), workoutName: workouts[0].name, engine: engine,
                                          hostName: "iPad", hostIsPad: true)
            }
            return
        }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ c: RemoteCommand, workoutID: UUID? = nil) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isReachable else {
            lastError = String(localized: "iPhone nicht erreichbar. Ist die App auf dem iPhone geöffnet?")
            return
        }
        lastError = nil
        let payload = [RemoteMessage.key: RemoteMessage.command(c, workoutID: workoutID).encoded()]
        WCSession.default.sendMessage(payload, replyHandler: nil) { [weak self] _ in
            Task { @MainActor in self?.lastError = String(localized: "Befehl kam nicht an. Bitte nochmals versuchen.") }
        }
    }

    private func apply(_ m: RemoteMessage) {
        switch m {
        case .snapshot(let s):
            snapshot = s
            if s == nil { stopHaptics() } else { startHaptics() }
        case .workouts(let list):
            workouts = list
        case .target(let name, _):
            targetName = name
        case .command:
            break
        }
    }

    /// Prüft fünfmal pro Sekunde, ob ein Blockwechsel oder die letzten Sekunden anstehen.
    private func startHaptics() {
        guard hapticTask == nil else { return }
        hapticTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let snap = self.snapshot else { break }
                let st = snap.state(at: Date())
                for h in self.haptics.next(state: st) { WKInterfaceDevice.current().play(h.wk) }
                if st.isFinished { break }
                try? await Task.sleep(for: .milliseconds(200))
            }
            self?.hapticTask = nil
        }
    }

    private func stopHaptics() {
        hapticTask?.cancel()
        hapticTask = nil
        haptics.reset()
    }
}

extension WatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let ctx = session.receivedApplicationContext
        Task { @MainActor in
            self.reachable = session.isReachable
            if let data = ctx[RemoteMessage.key] as? Data, let m = RemoteMessage.decode(data) { self.apply(m) }
            self.send(.requestState)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let data = message[RemoteMessage.key] as? Data, let m = RemoteMessage.decode(data) else { return }
        Task { @MainActor in self.apply(m) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext[RemoteMessage.key] as? Data, let m = RemoteMessage.decode(data) else { return }
        Task { @MainActor in self.apply(m) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let r = session.isReachable
        Task { @MainActor in
            self.reachable = r
            if r { self.send(.requestState) }
        }
    }
}
