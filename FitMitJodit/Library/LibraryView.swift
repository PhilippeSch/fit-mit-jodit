import SwiftUI

/// Wurzel: Bibliothek links (oder als Liste), Training rechts. Passt sich über Size Classes an.
/// Was die Wurzel im Vollbild zeigt. Eine einzige Darstellung für beides, damit sich Willkommen und Laufansicht
/// nicht gegenseitig schliessen können; ein laufendes Training hat Vorrang.
private enum RootCover: Identifiable {
    case welcome
    case run(RunSession)

    var id: String {
        switch self {
        case .welcome: return "welcome"
        case .run(let s): return "run-\(s.id)"
        }
    }
}

struct RootView: View {
    /// Willkommensbildschirm beim ersten Start (gesteuert von der App).
    @Binding var showWelcome: Bool
    var onWelcomeDone: () -> Void = {}
    @Environment(AppModel.self) private var app
    @State private var selection: UUID?
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            LibraryView(selection: $selection)
        } detail: {
            if let id = selection, app.store.workout(id: id) != nil {
                WorkoutDetailView(workoutID: id, selection: $selection)
                    .id(id)
            } else {
                ContentUnavailableView(String(localized: "Kein Training gewählt"),
                                       systemImage: "timer",
                                       description: Text("Wähle links ein Training oder lege mit + ein neues an."))
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Theme.brand)
        .onAppear {
            // Auf breiter Fläche gleich ein Training zeigen, damit der Baukasten sichtbar ist.
            if hSize == .regular, selection == nil { selection = app.store.sorted.first?.id }
        }
        .fullScreenCover(item: Binding<RootCover?>(
            get: {
                if let s = app.session { return .run(s) }
                return showWelcome ? .welcome : nil
            },
            set: { new in
                // Vom System geschlossen: die Laufansicht beendet dabei das Training (wie bisher).
                // Der Willkommensbildschirm bleibt, bis «Los geht's» getippt wird.
                if new == nil, app.session != nil { app.stop() }
            })) { cover in
            switch cover {
            case .run(let session): WidthSimulator { RunView(session: session) }
            case .welcome: WelcomeView(onDone: onWelcomeDone)
            }
        }
        .onChange(of: app.store.workouts) { PhoneConnectivity.shared.pushWorkouts() }
        // Die Rückfrage «Fernbedienung erlauben?» zeigt `RemoteLink` über der obersten Ansicht (siehe `TopAlert`).
    }
}

struct LibraryView: View {
    @Environment(AppModel.self) private var app
    @Binding var selection: UUID?
    @State private var query = ""
    @State private var renaming: Workout?
    @State private var newName = ""
    @State private var deleting: Workout?
    @State private var showSettings = false
    @State private var showRemote = false
    @State private var showHistory = false

    var body: some View {
        let items = app.store.search(query)
        List(selection: $selection) {
            ForEach(items) { w in
                NavigationLink(value: w.id) {
                    LibraryRow(workout: w)
                }
                .accessibilityIdentifier("workout-\(w.name)")
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { deleting = w } label: { Label("Löschen", systemImage: "trash") }
                    Button { app.store.duplicate(w) } label: { Label("Duplizieren", systemImage: "plus.square.on.square") }
                        .tint(.gray)
                }
                .swipeActions(edge: .leading) {
                    Button { app.store.toggleFavorite(w) } label: {
                        Label(w.isFavorite ? "Favorit entfernen" : "Favorit", systemImage: w.isFavorite ? "star.slash" : "star")
                    }
                    .tint(.yellow)
                }
                .contextMenu {
                    Button { app.start(w) } label: { Label("Starten", systemImage: "play.fill") }
                    Button { app.store.toggleFavorite(w) } label: {
                        Label(w.isFavorite ? "Favorit entfernen" : "Als Favorit markieren", systemImage: "star")
                    }
                    Button { newName = w.name; renaming = w } label: { Label("Umbenennen", systemImage: "pencil") }
                    Button { app.store.duplicate(w) } label: { Label("Duplizieren", systemImage: "plus.square.on.square") }
                    Button(role: .destructive) { deleting = w } label: { Label("Löschen", systemImage: "trash") }
                }
            }
        }
        .overlay {
            if items.isEmpty && !query.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .searchable(text: $query, prompt: Text("Trainings suchen"))
        .navigationTitle(AppInfo.displayName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let w = app.store.create(name: String(localized: "Neues Training"))
                    selection = w.id
                } label: { Label("Neues Training", systemImage: "plus") }
                .accessibilityIdentifier("newWorkout")
            }
            ToolbarItem(placement: .topBarLeading) {
                Button { showSettings = true } label: { Label("Einstellungen", systemImage: "gearshape") }
                    .accessibilityIdentifier("settings")
            }
            ToolbarItem(placement: .topBarLeading) {
                Button { showHistory = true } label: { Label("Verlauf", systemImage: "clock.arrow.circlepath") }
                    .accessibilityIdentifier("history")
            }
            if RemoteLink.shared.isConnected && !RemoteLink.shared.isPad {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showRemote = true } label: { Label("iPad steuern", systemImage: "ipad.and.iphone") }
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showRemote) { RemotePadView() }
        .sheet(isPresented: $showHistory) { HistoryView() }
        .alert("Umbenennen", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $newName)
            Button("Sichern") { if let w = renaming { app.store.rename(w, to: newName) }; renaming = nil }
            Button("Abbrechen", role: .cancel) { renaming = nil }
        }
        .confirmationDialog(Text("Training löschen?"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                            titleVisibility: .visible, presenting: deleting) { w in
            Button("Löschen", role: .destructive) {
                if selection == w.id { selection = nil }
                app.store.delete(w)
                deleting = nil
            }
            .accessibilityIdentifier("confirmDelete")
        } message: { w in
            Text("«\(w.name)» wird auf allen Geräten gelöscht.")
        }
    }
}

struct LibraryRow: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if workout.isFavorite {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                        .accessibilityLabel(Text("Favorit"))
                }
                Text(workout.name).font(Theme.title(.headline)).lineLimit(2)
                Spacer(minLength: 8)
                Text(DurationFormat.clock(workout.totalSeconds))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            TimelinePreview(workout: workout)
                .frame(height: 10)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(workout.name), \(DurationFormat.clock(workout.totalSeconds))"))
    }
}

/// Kleine farbige Vorschau der Blockfolge (Breite entspricht der Dauer).
struct TimelinePreview: View {
    let workout: Workout

    var body: some View {
        let steps = StepSequence.expand(workout)
        let total = max(steps.reduce(0) { $0 + $1.seconds }, 1)
        GeometryReader { geo in
            HStack(spacing: 1) {
                ForEach(Array(steps.enumerated()), id: \.offset) { _, s in
                    Rectangle()
                        .fill(Theme.color(for: s.kind))
                        .frame(width: max((geo.size.width - CGFloat(steps.count)) * CGFloat(s.seconds) / CGFloat(total), 1))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}
