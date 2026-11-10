import SwiftUI

/// Trainingsdetail mit Baukasten. Starten, Spotify, Teilen in der Leiste oben.
struct WorkoutDetailView: View {
    @Environment(AppModel.self) private var app
    let workoutID: UUID
    @Binding var selection: UUID?

    var body: some View {
        if let w = app.store.workout(id: workoutID) {
            EditorView(workout: w)
                .navigationTitle(w.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        SpotifyButton(link: w.spotifyLink)
                        ShareLink(item: WorkoutFile(workout: w),
                                  preview: SharePreview(Text(w.name), image: Image(systemName: "timer"))) {
                            Label("Exportieren", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("export")
                    }
                }
        }
    }
}
