import Foundation
import MultipeerConnectivity
import Observation
import UIKit

/// Weiterleitung zwischen iPhone und iPad im lokalen Netz (nur Apple-Frameworks, verschlüsselt).
/// Das iPad schickt seinen Trainingszustand, das iPhone schickt Befehle der Uhr (oder eigene) zurück.
/// Kopplung: Die erste Verbindung muss auf dem Gerät, das eingeladen wird, bestätigt werden; danach automatisch.
@MainActor
@Observable
final class RemoteLink: NSObject {
    static let shared = RemoteLink()
    static let serviceType = "fmj-remote"

    /// Zustand des Trainings auf dem verbundenen Gerät (auf dem iPhone: das iPad).
    private(set) var remoteSnapshot: RemoteSnapshot?
    private(set) var connectedPeers: [String] = []
    /// Anfrage zur Bestätigung (Name des anderen Geräts).
    var pendingInvitation: String?
    @ObservationIgnored private var pendingHandler: ((Bool, MCSession?) -> Void)?
    var onSnapshotChange: ((RemoteSnapshot?) -> Void)?
    /// Stellt die Rückfrage dar: in der App über der obersten sichtbaren Ansicht (siehe `TopAlert`), in Tests ersetzbar.
    @ObservationIgnored var presentInvitation: (String) -> Void = { RemoteLink.showInvitationPrompt($0) }

    static func showInvitationPrompt(_ name: String) {
        TopAlert.present(
            title: String(localized: "Fernbedienung erlauben?"),
            message: String(localized: "«\(name)» möchte Trainings auf diesem Gerät steuern (für die Apple Watch). Nur im lokalen Netz, keine Daten verlassen die Geräte."),
            actions: [
                .init(title: String(localized: "Ablehnen"), style: .cancel) { RemoteLink.shared.answerInvitation(false) },
                .init(title: String(localized: "Erlauben")) { RemoteLink.shared.answerInvitation(true) },
            ])
    }

    @ObservationIgnored private let peerID: MCPeerID
    @ObservationIgnored private var session: MCSession!
    @ObservationIgnored private var advertiser: MCNearbyServiceAdvertiser!
    @ObservationIgnored private var browser: MCNearbyServiceBrowser!
    @ObservationIgnored private weak var app: AppModel?
    @ObservationIgnored private var started = false

    private static let trustedKey = "fmj.remote.trustedPeers"
    private var trusted: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: Self.trustedKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: Self.trustedKey) }
    }

    var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    var isConnected: Bool { !connectedPeers.isEmpty }
    var peerName: String? { connectedPeers.first }

    override init() {
        let name = UIDevice.current.userInterfaceIdiom == .pad ? String(localized: "iPad") : String(localized: "iPhone")
        peerID = MCPeerID(displayName: "\(name) · \(UIDevice.current.name.prefix(20))")
        super.init()
    }

    func attach(to app: AppModel) {
        self.app = app
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") { return }
        app.observeSession { [weak self] _ in self?.broadcastState() }
        start()
    }

    func start() {
        guard !started else { return }
        started = true
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        let info = ["role": isPad ? "pad" : "phone"]
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: info, serviceType: Self.serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        // Das iPhone sucht nach iPads, das iPad wartet auf Einladungen.
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser.delegate = self
        if !isPad { browser.startBrowsingForPeers() }
    }

    func answerInvitation(_ accept: Bool) {
        if accept, let name = pendingInvitation { trusted.insert(name) }
        pendingHandler?(accept, accept ? session : nil)
        pendingHandler = nil
        pendingInvitation = nil
    }

    // MARK: Senden

    /// Auf dem Gerät mit laufendem Training: Zustand an alle verbundenen Geräte.
    func broadcastState() {
        guard let session, !session.connectedPeers.isEmpty else { return }
        send(.snapshot(currentLocalSnapshot()))
    }

    func currentLocalSnapshot() -> RemoteSnapshot? {
        guard let s = app?.session, !s.isFinished else { return nil }
        return RemoteSnapshot(workoutID: s.workout.id, workoutName: s.workout.name, engine: s.engine,
                              hostName: isPad ? String(localized: "iPad") : String(localized: "iPhone"), hostIsPad: isPad)
    }

    func sendStart(_ w: Workout) { send(.startWorkout(w)) }

    func sendCommand(_ c: RemoteCommand, workoutID: UUID? = nil) {
        send(.command(c, workoutID: workoutID))
    }

    func sendWorkouts(_ list: [WorkoutSummary]) { send(.workouts(list)) }

    private func send(_ m: RemoteMessage) {
        guard let session, !session.connectedPeers.isEmpty else { return }
        try? session.send(m.encoded(), toPeers: session.connectedPeers, with: .reliable)
    }

    // MARK: Empfangen

    private func handle(_ m: RemoteMessage) {
        switch m {
        case .snapshot(let snap):
            remoteSnapshot = snap
            onSnapshotChange?(snap)
        case .command(let c, let id):
            guard let app else { return }
            RemoteCommandHandler.apply(c, workoutID: id, to: app)
            broadcastState()
        case .startWorkout(let w):
            guard let app else { return }
            // Bekanntes Training lokal nehmen (aktuelle Fassung), sonst das mitgeschickte.
            app.start(app.store.workout(id: w.id) ?? w)
            broadcastState()
        case .workouts, .target:
            break
        }
    }
}

/// Wendet einen Befehl auf das lokal laufende Training an (iPad über Weiterleitung, iPhone direkt von der Uhr).
@MainActor
enum RemoteCommandHandler {
    static func apply(_ c: RemoteCommand, workoutID: UUID?, to app: AppModel) {
        switch c {
        case .togglePause: app.session?.togglePause()
        case .skipForward: app.session?.skipForward()
        case .skipBack: app.session?.skipBack()
        case .stop: app.stop()
        case .start:
            if let id = workoutID, let w = app.store.workout(id: id) { app.start(w) }
        case .requestState: break
        }
    }
}

extension RemoteLink: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let names = session.connectedPeers.map(\.displayName)
        Task { @MainActor in
            self.connectedPeers = names
            if state == .connected { self.broadcastState() }
            if names.isEmpty { self.remoteSnapshot = nil; self.onSnapshotChange?(nil) }
            PhoneConnectivity.shared.pushTarget()
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let m = RemoteMessage.decode(data) else { return }
        Task { @MainActor in self.handle(m) }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension RemoteLink: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let name = peerID.displayName
        Task { @MainActor in
            if self.trusted.contains(name) {
                invitationHandler(true, self.session)
            } else {
                self.pendingHandler = invitationHandler
                self.pendingInvitation = name
                self.presentInvitation(name)
            }
        }
    }
}

extension RemoteLink: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard info?["role"] == "pad" else { return }
        Task { @MainActor in
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 20)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
