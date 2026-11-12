import SwiftUI

@main
struct FitMitJoditApp: App {
    @State private var app = AppModel.shared
    @State private var player = AudioSignalPlayer()
    @State private var showWelcome = false
    /// Pro Gerät einmal (nicht über iCloud, darum UserDefaults statt AppSettings).
    @AppStorage("fmj.welcomeSeen.v1") private var welcomeSeen = false

    var body: some Scene {
        WindowGroup {
            RootView(showWelcome: $showWelcome) {
                welcomeSeen = true
                app.store.settings.hasSeenSplitViewHint = true
                showWelcome = false
            }
            .environment(app)
            .onAppear(perform: setUp)
            .onOpenURL(perform: importFile)
        }
    }

    private func setUp() {
        guard app.signalPlayer == nil else { return }
        app.signalPlayer = player
        // Stimmenliste im Hintergrund laden (blockiert sonst beim ersten Zugriff den Haupt-Thread).
        VoiceLibrary.shared.reload()
        app.observeSession { [player] session in
            if let s = session {
                // Beim Abschluss Schlusston und «Geschafft» ausklingen lassen, nicht hart abwürgen.
                if s.isFinished { player.finishKeepAlive() } else { player.startKeepAlive() }
            } else {
                player.stopKeepAlive()
            }
        }
        LiveActivityController.shared.attach(to: app)
        PhoneConnectivity.shared.attach(to: app)
        RemoteLink.shared.attach(to: app)
        let args = ProcessInfo.processInfo.arguments
        let uiTesting = args.contains("-uiTesting")
        // Nur für Tests und Screenshots: Vorlage direkt starten, z. B. `-autostart circuit4515`.
        if uiTesting, let i = args.firstIndex(of: "-autostart"), i + 1 < args.count,
           let w = app.store.workouts.first(where: { $0.templateKey == args[i + 1] }) {
            app.start(w)
        }
        // Training fortsetzen, falls iOS die App während eines Trainings beendet hat.
        if !uiTesting || args.contains("-restoreRun") { app.restoreRunIfNeeded() }
        // Nur für UI-Tests: die Rückfrage der Fernbedienung nachstellen (sonst braucht es ein zweites Gerät im Netz).
        if uiTesting, args.contains("-simulateInvitation") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { RemoteLink.showInvitationPrompt("iPhone · Test") }
        }
        // Willkommen beim ersten Start (enthält auf dem iPad den Hinweis zu Spotify daneben).
        if (!uiTesting && !welcomeSeen) || args.contains("-showWelcome") {
            showWelcome = true
        }
    }

    /// Rückfragen und Meldungen zum Import über der obersten Ansicht (siehe `TopAlert`): Sie können auch kommen,
    /// während der Willkommensbildschirm oder ein Training im Vollbild steht.
    private func importFile(_ url: URL) {
        if ShareCode.handles(url) {
            do {
                let w = try ShareCode.workout(from: url)
                TopAlert.present(
                    title: String(localized: "Training übernehmen?"),
                    message: String(localized: "«\(w.name)», \(DurationFormat.clock(w.totalSeconds))"),
                    actions: [
                        .init(title: String(localized: "Abbrechen"), style: .cancel),
                        .init(title: String(localized: "Übernehmen")) { [app] in app.store.upsert(w) },
                    ])
            } catch {
                importFailed(String(localized: "Der QR-Code enthält kein gültiges Training."))
            }
            return
        }
        do {
            let w = try WorkoutFile.importWorkout(from: url)
            app.store.upsert(w)
        } catch {
            importFailed(String(localized: "Die Datei ist keine gültige Trainingsdatei von Fit mit Jodit."))
        }
    }

    private func importFailed(_ message: String) {
        TopAlert.present(title: String(localized: "Import nicht möglich"), message: message,
                         actions: [.init(title: String(localized: "OK"), style: .cancel)])
    }
}

/// Für UI-Tests und Screenshots: `-runWidthFraction 0.33` zeigt die App nur auf einem Teil der Breite,
/// daneben eine leere Fläche als Platz für eine Musik-App (wie im geteilten Bildschirm). Ohne Argument: volle Fläche.
struct WidthSimulator<Content: View>: View {
    @ViewBuilder var content: Content
    private var fraction: CGFloat? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-runWidthFraction"), i + 1 < args.count, let f = Double(args[i + 1]), f > 0, f < 1 else { return nil }
        return CGFloat(f)
    }

    var body: some View {
        if let fraction {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    content
                        .frame(width: geo.size.width * fraction)
                        .clipped()
                        .environment(\.horizontalSizeClass, geo.size.width * fraction < 500 ? .compact : .regular)
                    Rectangle().fill(Color(white: 0.12))
                        .overlay(Image(systemName: "music.note.list").font(.system(size: 80)).foregroundStyle(.gray))
                        .accessibilityHidden(true)
                }
            }
            .ignoresSafeArea()
        } else {
            content
        }
    }
}
