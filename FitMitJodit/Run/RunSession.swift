import Foundation
import Observation

/// Empfänger für Töne und Ansagen (AudioSignalPlayer in der App, Aufzeichnung in Tests).
@MainActor
protocol SignalSink: AnyObject {
    func play(_ kind: SignalKind, settings: SignalSettings)
}

/// Ein laufendes Training. Rechnet über `TimerEngine` mit Zeitstempeln; `tick()` aktualisiert nur die Anzeige
/// und löst fällige Signale aus.
@MainActor
@Observable
final class RunSession: Identifiable {
    let id = UUID()
    let workout: Workout
    let settings: AppSettings
    private(set) var engine: TimerEngine
    private(set) var state: RunState
    let startedAt: Date

    @ObservationIgnored let clock: AppClock
    @ObservationIgnored private var events: [SignalEvent]
    @ObservationIgnored private var lastElapsed: TimeInterval = -0.001
    @ObservationIgnored weak var sink: SignalSink?
    /// Wird bei jeder Zustandsänderung durch Bedienung aufgerufen (Watch, Live Activity, iPad-Weiterleitung).
    @ObservationIgnored var onControlChange: (() -> Void)?
    @ObservationIgnored var onFinish: (() -> Void)?
    @ObservationIgnored private var lastStepIndex = -1

    init(workout: Workout, settings: AppSettings, clock: AppClock = SystemClock.shared) {
        self.workout = workout
        self.settings = settings
        self.clock = clock
        let steps = StepSequence.withLeadIn(StepSequence.expand(workout), leadInSeconds: min(max(settings.leadInSeconds, 0), 30))
        let now = clock.now
        startedAt = now
        let e = TimerEngine(steps: steps, startAt: now)
        engine = e
        state = e.state(at: now)
        events = SignalPlanner.plan(steps: steps, settings: settings.signals)
    }

    /// Übernimmt einen Zustand von aussen (Weiterleitung vom iPad, Wiederaufnahme).
    func adopt(_ newEngine: TimerEngine) {
        engine = newEngine
        resyncSignals()
        tick()
    }

    var steps: [Step] { engine.steps }
    var isFinished: Bool { state.isFinished }

    /// Runde x von y des aktuellen Schritts (nil ausserhalb von Runden).
    var roundText: String? {
        guard let s = state.step, let r = s.round, let n = s.roundCount else { return nil }
        return String(localized: "Runde \(r) von \(n)")
    }

    func tick() {
        let now = clock.now
        let new = engine.state(at: now)
        let e = engine.elapsed(at: now)
        if !engine.isPaused || e != lastElapsed {
            for ev in SignalPlanner.due(events, from: lastElapsed, to: e) { sink?.play(ev.kind, settings: settings.signals) }
            lastElapsed = e
        }
        let changed = new.stepIndex != lastStepIndex || new.isFinished != state.isFinished
        if new != state { state = new }
        if changed {
            lastStepIndex = new.stepIndex
            onControlChange?()
            if new.isFinished { onFinish?() }
        }
    }

    func togglePause() { engine.isPaused ? resume() : pause() }

    func pause() {
        engine.pause(at: clock.now)
        tick()
        onControlChange?()
    }

    func resume() {
        engine.resume(at: clock.now)
        tick()
        onControlChange?()
    }

    func skipForward() {
        engine.skipForward(at: clock.now)
        resyncSignals()
        tick()
        onControlChange?()
    }

    func skipBack() {
        engine.skipBack(at: clock.now)
        resyncSignals()
        tick()
        onControlChange?()
    }

    /// Nach einem Sprung: Startsignal des neuen Schritts erlauben, Übersprungenes nicht nachholen.
    private func resyncSignals() {
        lastElapsed = engine.elapsed(at: clock.now) - 0.001
    }

    /// Verstrichene Trainingszeit für das Abschlussbild.
    var totalTimeText: String { DurationFormat.clock(Int(state.totalDuration.rounded())) }
}
