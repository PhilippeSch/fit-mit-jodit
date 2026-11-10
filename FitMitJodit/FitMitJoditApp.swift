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
        let uiTesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")
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
