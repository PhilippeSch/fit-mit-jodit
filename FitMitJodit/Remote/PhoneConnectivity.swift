import Foundation
import WatchConnectivity

/// Verbindung iPhone ↔ Apple Watch. Die Uhr steuert das Training auf dem iPhone direkt oder,
/// wenn das iPhone mit einem iPad verbunden ist, über die Weiterleitung das Training auf dem iPad.
@MainActor
final class PhoneConnectivity: NSObject {
    static let shared = PhoneConnectivity()
    private weak var app: AppModel?
    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    func attach(to app: AppModel) {
        self.app = app
        guard let session, !ProcessInfo.processInfo.arguments.contains("-uiTesting") else { return }
        session.delegate = self
        session.activate()
        app.observeSession { [weak self] _ in self?.pushState() }
        RemoteLink.shared.onSnapshotChange = { [weak self] _ in self?.pushState() }
    }

    /// Welches Gerät die Uhr steuert: das iPad, wenn eines verbunden ist und dort ein Training läuft, sonst das iPhone.
    private var forwardsToPad: Bool {
        guard let app else { return false }
        let link = RemoteLink.shared
        return !link.isPad && link.isConnected && (link.remoteSnapshot != nil || app.session == nil)
    }

    /// Aktueller Zustand für die Uhr.
    private func currentSnapshot() -> RemoteSnapshot? {
        if forwardsToPad, let snap = RemoteLink.shared.remoteSnapshot { return snap }
        return RemoteLink.shared.currentLocalSnapshot()
    }

    func pushState() {
        guard let session, session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        let msg = RemoteMessage.snapshot(currentSnapshot())
        send(msg)
        pushTarget()
    }

    func pushTarget() {
        guard let session, session.activationState == .activated, session.isWatchAppInstalled else { return }
        let link = RemoteLink.shared
        let name = forwardsToPad ? (link.peerName ?? String(localized: "iPad")) : String(localized: "iPhone")
        send(.target(name: name, connected: true))
    }

    func pushWorkouts() {
        guard let app, let session, session.activationState == .activated, session.isWatchAppInstalled else { return }
        let list = app.store.sorted.map { WorkoutSummary(id: $0.id, name: $0.name, totalSeconds: $0.totalSeconds, isFavorite: $0.isFavorite) }
        lastWorkouts = RemoteMessage.workouts(list).encoded()
        writeContext()
    }

    private func send(_ m: RemoteMessage) {
        guard let session else { return }
        let payload = [RemoteMessage.key: m.encoded()]
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else if case .snapshot = m {
            lastSnapshot = m.encoded()
            writeContext()
        }
    }

    /// Letzter Stand für den Application Context (immer beide Teile schreiben, der Kontext ersetzt sich als Ganzes).
    private var lastWorkouts: Data?
    private var lastSnapshot: Data?

    private func writeContext() {
        guard let session, session.activationState == .activated else { return }
        var ctx: [String: Any] = [:]
        if let w = lastWorkouts { ctx[RemoteMessage.contextWorkoutsKey] = w }
        if let s = lastSnapshot { ctx[RemoteMessage.contextSnapshotKey] = s }
        try? session.updateApplicationContext(ctx)
    }

    private func handle(_ m: RemoteMessage) {
        guard let app else { return }
        guard case .command(let c, let id) = m else { return }
        if c == .requestState {
            pushWorkouts()
            pushState()
            return
        }
        if forwardsToPad {
            // «Start» mit vollständigem Training schicken: die Vorlagen-/Trainings-ID kennt das iPad evtl. nicht.
            if c == .start, let id, let w = app.store.workout(id: id) {
                RemoteLink.shared.sendStart(w)
            } else {
                RemoteLink.shared.sendCommand(c, workoutID: id)
            }
        } else {
            RemoteCommandHandler.apply(c, workoutID: id, to: app)
        }
        pushState()
    }
}

extension PhoneConnectivity: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.pushWorkouts()
            self.pushState()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let data = message[RemoteMessage.key] as? Data, let m = RemoteMessage.decode(data) else { return }
        Task { @MainActor in self.handle(m) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.pushState() }
    }
}
