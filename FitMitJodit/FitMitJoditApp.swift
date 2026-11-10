import SwiftUI

@main
struct FitMitJoditApp: App {
    @State private var app = AppModel.makeDefault()
    @State private var player = AudioSignalPlayer()
    @State private var importError: String?
    @State private var showHint = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .onAppear(perform: setUp)
                .onOpenURL(perform: importFile)
                .alert(String(localized: "Import nicht möglich"), isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
                    Button("OK", role: .cancel) {}
                } message: { Text(importError ?? "") }
                .sheet(isPresented: $showHint, onDismiss: { app.store.settings.hasSeenSplitViewHint = true }) {
                    SplitViewHintSheet()
                }
        }
    }

    private func setUp() {
        guard app.signalPlayer == nil else { return }
        app.signalPlayer = player
        app.observeSession { [player] session in
            if let s = session, !s.isFinished { player.startKeepAlive() } else { player.stopKeepAlive() }
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
        if !uiTesting, !app.store.settings.hasSeenSplitViewHint, UIDevice.current.userInterfaceIdiom == .pad {
            showHint = true
        }
    }

    private func importFile(_ url: URL) {
        do {
            let w = try WorkoutFile.importWorkout(from: url)
            app.store.upsert(w)
        } catch {
            importError = String(localized: "Die Datei ist keine gültige Trainingsdatei von Fit mit Jodit.")
        }
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
