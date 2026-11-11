import Foundation
import WatchKit

/// Hält die Uhr-App während eines Trainings aktiv, auch wenn das Handgelenk gesenkt ist
/// (Erweiterte Laufzeit, Typ «Physiotherapie», höchstens eine Stunde). Ohne sie friert watchOS die App
/// beim Senken des Arms ein, und die Haptik bei Blockwechseln bleibt aus.
/// Kein HealthKit und keine Workout-Session (SPEC 10.6 / Grenzen).
@MainActor
final class WatchRuntime: NSObject, WKExtendedRuntimeSessionDelegate {
    static let shared = WatchRuntime()
    private var session: WKExtendedRuntimeSession?
    /// Ein Training läuft, die Sitzung soll bestehen (wird beim nächsten Wechsel in den Vordergrund nachgeholt).
    private var wanted = false

    var isRunning: Bool { session?.state == .running }

    /// Starten geht nur, solange die App im Vordergrund ist.
    func begin() {
        wanted = true
        if let s = session, s.state == .running || s.state == .scheduled || s.state == .notStarted { return }
        guard WKApplication.shared().applicationState == .active else { return }
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        s.start()
        session = s
    }

    func end() {
        wanted = false
        if let s = session, s.state != .invalid { s.invalidate() }
        session = nil
    }

    /// Beim Wechsel in den Vordergrund: abgelaufene Sitzung erneuern, falls noch trainiert wird.
    func resumeIfNeeded() { if wanted { begin() } }

    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in WKInterfaceDevice.current().play(.notification) }
    }

    nonisolated func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                            didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                            error: Error?) {
        let id = ObjectIdentifier(extendedRuntimeSession)
        Task { @MainActor in
            if let s = self.session, ObjectIdentifier(s) == id { self.session = nil }
        }
    }
}
