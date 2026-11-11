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
        let store = WorkoutStore(container: container)
        if args.contains("-screenshotData") { seedScreenshotData(store) }
        return AppModel(store: store)
    }

    /// Nur für Store-Screenshots: Zirkel 45/15 mit Übungsnamen in der Gerätesprache und als Favorit.
    private static func seedScreenshotData(_ store: WorkoutStore) {
        guard var w = store.workouts.first(where: { $0.templateKey == "circuit4515" }) else { return }
        let ids = ["squats", "push_ups", "burpees"]
        let names = ids.compactMap { id in ExerciseCatalog.all.first { $0.id == id }.map { ExerciseCatalog.localizedName($0) } }
        w.items = w.items.map { item in
            guard case .round(var r) = item else { return item }
            var n = 0
            for i in r.blocks.indices where r.blocks[i].kind == .work {
                if n < names.count { r.blocks[i].exerciseName = names[n] }
                n += 1
            }
            return .round(r)
        }
        w.isFavorite = true
        store.upsert(w)
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
        // Live Activity, Uhr usw. neu abgleichen (z. B. Live Activity, die im Hintergrund nicht starten durfte).
        if session != nil { notifySession() }
        if let s = session, !s.isFinished, ticker == nil { startTicker() }
    }
}
