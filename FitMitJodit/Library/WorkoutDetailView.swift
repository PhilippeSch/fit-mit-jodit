import SwiftUI

/// Trainingsdetail mit Baukasten. Starten, Spotify, Teilen in der Leiste oben.
struct WorkoutDetailView: View {
    @Environment(AppModel.self) private var app
    let workoutID: UUID
    @Binding var selection: UUID?
    @State private var showQR = false

    var body: some View {
        if let w = app.store.workout(id: workoutID) {
            EditorView(workout: w)
                .navigationTitle(w.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        SpotifyButton(link: w.spotifyLink)
                        Button { showQR = true } label: {
                            Label("QR-Code zum Teilen", systemImage: "qrcode")
                        }
                        .accessibilityIdentifier("showQR")
                        ShareLink(item: WorkoutFile(workout: w),
                                  preview: SharePreview(Text(w.name), image: Image(systemName: "timer"))) {
                            Label("Exportieren", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("export")
                    }
                }
                .sheet(isPresented: $showQR) { WorkoutQRView(workout: w) }
        }
    }
}
