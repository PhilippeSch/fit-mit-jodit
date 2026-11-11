import AppIntents
import Foundation

/// Ein Training für Siri und Kurzbefehle.
struct WorkoutEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("Training"))
    static let defaultQuery = WorkoutEntityQuery()

    let id: UUID
    let name: String
    let totalSeconds: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(DurationFormat.clock(totalSeconds))")
    }

    init(_ w: Workout) {
        id = w.id
        name = w.name
        totalSeconds = w.totalSeconds
    }
}

struct WorkoutEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [WorkoutEntity] {
        identifiers.compactMap { AppModel.shared.store.workout(id: $0) }.map(WorkoutEntity.init)
    }

    @MainActor
    func entities(matching string: String) async throws -> [WorkoutEntity] {
        AppModel.shared.store.search(string).map(WorkoutEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [WorkoutEntity] {
        AppModel.shared.store.sorted.map(WorkoutEntity.init)
    }
}

enum IntentFailure: Error, CustomLocalizedStringResourceConvertible {
    case workoutMissing, noRun
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .workoutMissing: return "Dieses Training gibt es nicht mehr."
        case .noRun: return "Es läuft kein Training."
        }
    }
}

/// Training starten (öffnet die App mit der Laufansicht).
struct StartWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Training starten"
    static let description = IntentDescription("Startet ein Training in Fit mit Jodit.")
    static let openAppWhenRun = true

    @Parameter(title: "Training")
    var workout: WorkoutEntity

    static var parameterSummary: some ParameterSummary { Summary("\(\.$workout) starten") }

    @MainActor
    func perform() async throws -> some IntentResult {
        let app = AppModel.shared
        guard let w = app.store.workout(id: workout.id) else { throw IntentFailure.workoutMissing }
        app.start(w)
        return .result()
    }
}

/// Pause oder weiter (funktioniert auch, ohne die App zu öffnen).
struct TogglePauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Training pausieren oder fortsetzen"
    static let description = IntentDescription("Pausiert das laufende Training oder setzt es fort.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let s = AppModel.shared.session, !s.isFinished else { throw IntentFailure.noRun }
        s.togglePause()
        return .result(dialog: s.engine.isPaused ? "Pausiert." : "Weiter geht's.")
    }
}

/// Zum nächsten Block springen.
struct SkipBlockIntent: AppIntent {
    static let title: LocalizedStringResource = "Nächster Block"
    static let description = IntentDescription("Springt im laufenden Training zum nächsten Block.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let s = AppModel.shared.session, !s.isFinished else { throw IntentFailure.noRun }
        s.skipForward()
        return .result()
    }
}

/// Training beenden.
struct StopWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Training beenden"
    static let description = IntentDescription("Beendet das laufende Training.")

    @MainActor
    func perform() async throws -> some IntentResult {
        guard AppModel.shared.session != nil else { throw IntentFailure.noRun }
        AppModel.shared.stop()
        return .result()
    }
}

/// Sätze für Siri. Jeder Satz muss den App-Namen enthalten.
struct FitMitJoditShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartWorkoutIntent(),
                    phrases: ["Starte \(\.$workout) mit \(.applicationName)",
                              "\(.applicationName) \(\.$workout) starten",
                              "Starte ein Training mit \(.applicationName)"],
                    shortTitle: "Training starten",
                    systemImageName: "figure.run")
        AppShortcut(intent: TogglePauseIntent(),
                    phrases: ["Pause in \(.applicationName)",
                              "Weiter in \(.applicationName)"],
                    shortTitle: "Pause / Weiter",
                    systemImageName: "playpause.fill")
        AppShortcut(intent: SkipBlockIntent(),
                    phrases: ["Nächster Block in \(.applicationName)"],
                    shortTitle: "Nächster Block",
                    systemImageName: "forward.end.fill")
        AppShortcut(intent: StopWorkoutIntent(),
                    phrases: ["Training beenden in \(.applicationName)"],
                    shortTitle: "Training beenden",
                    systemImageName: "stop.fill")
    }
}
