import Foundation
import Observation
import SwiftData
import UIKit

/// Gemeinsamer App-Zustand: Speicher und das laufende Training.
@MainActor
@Observable
final class AppModel {
    let store: WorkoutStore
    private(set) var session: RunSession?
    @ObservationIgnored var signalPlayer: SignalSink?
    /// Beobachter für Live Activity, Watch und iPad-Weiterleitung.
    @ObservationIgnored private var sessionObservers: [(RunSession?) -> Void] = []
    @ObservationIgnored private var ticker: Timer?

    init(store: WorkoutStore) {
        self.store = store
    }

    static func makeDefault() -> AppModel {
        let args = ProcessInfo.processInfo.arguments
        let uiTesting = args.contains("-uiTesting")
        if uiTesting, let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        let container = PersistenceFactory.makeContainer(inMemory: uiTesting)
        return AppModel(store: WorkoutStore(container: container))
    }

    func observeSession(_ f: @escaping (RunSession?) -> Void) { sessionObservers.append(f) }

    private func notifySession() { sessionObservers.forEach { $0(session) } }

    @discardableResult
    func start(_ workout: Workout) -> RunSession {
        stop()
        let s = RunSession(workout: workout, settings: store.settings)
        s.sink = signalPlayer
        s.onControlChange = { [weak self] in self?.notifySession() }
        s.onFinish = { [weak self] in self?.finished() }
        session = s
        store.markUsed(workout)
        UIApplication.shared.isIdleTimerDisabled = true
        startTicker()
        notifySession()
        return s
    }

    /// Übernimmt ein Training, das auf einem anderen Gerät läuft (Weiterleitung), ohne es neu zu starten.
    func adoptRemote(workout: Workout, engine: TimerEngine) {
        if session?.workout.id != workout.id {
            let s = RunSession(workout: workout, settings: store.settings)
            s.sink = signalPlayer
            s.onControlChange = { [weak self] in self?.notifySession() }
            session = s
        }
        session?.adopt(engine)
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
        session = nil
        UIApplication.shared.isIdleTimerDisabled = false
        notifySession()
    }

    private func finished() {
        ticker?.invalidate()
        ticker = nil
        UIApplication.shared.isIdleTimerDisabled = false
        notifySession()
    }

    private func startTicker() {
        ticker?.invalidate()
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.session?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    /// Nach Rückkehr aus dem Hintergrund sofort neu rechnen.
    func refresh() {
        session?.tick()
        if let s = session, !s.isFinished, ticker == nil { startTicker() }
    }
}
