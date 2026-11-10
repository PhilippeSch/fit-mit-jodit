import SwiftUI
import WatchKit

@main
struct FitMitJoditWatchApp: App {
    @State private var link = WatchLink.shared

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(link)
                .onAppear { link.activate() }
        }
    }
}

struct WatchRootView: View {
    @Environment(WatchLink.self) private var link

    var body: some View {
        TabView {
            WatchRunPage()
            WatchWorkoutList()
            WatchMusicPage()
        }
        .tabViewStyle(.verticalPage)
    }
}

/// Laufendes Training: Typ, Name, Countdown, nächster Block, Runde. Knöpfe steuern das iPhone bzw. iPad.
struct WatchRunPage: View {
    @Environment(WatchLink.self) private var link
    @State private var confirmStop = false

    var body: some View {
        Group {
            if let snap = link.snapshot {
                TimelineView(.periodic(from: .now, by: 0.25)) { ctx in
                    let st = snap.state(at: ctx.date)
                    let kind = st.step?.kind ?? .prep
                    VStack(spacing: 2) {
                        Text(kind.label.uppercased())
                            .font(.caption2.bold())
                        Text(st.step?.displayName ?? "")
                            .font(.headline)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .accessibilityIdentifier("watchBlockName")
                        Text(DurationFormat.clock(st.displaySeconds))
                            .font(Theme.countdownFont(size: 44))
                            .minimumScaleFactor(0.5)
                            .accessibilityIdentifier("watchCountdown")
                        HStack(spacing: 6) {
                            if let next = st.nextStep { Text("→ \(next.displayName)").lineLimit(1) }
                            if let r = snap.roundText(at: ctx.date) { Text(r) }
                        }
                        .font(.caption2)
                        .opacity(0.9)
                        HStack(spacing: 8) {
                            ctrl("backward.end.fill", String(localized: "Block zurück")) { link.send(.skipBack) }
                            ctrl(st.isPaused ? "play.fill" : "pause.fill", st.isPaused ? String(localized: "Weiter") : String(localized: "Pause")) {
                                link.send(.togglePause)
                            }
                            ctrl("forward.end.fill", String(localized: "Block vor")) { link.send(.skipForward) }
                        }
                        .padding(.top, 2)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.color(for: kind).gradient)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { confirmStop = true } label: { Image(systemName: "xmark") }
                            .accessibilityLabel(Text("Stopp"))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Text(snap.hostName).font(.caption2)
                            .accessibilityLabel(Text("Steuert \(snap.hostName)"))
                    }
                }
                .confirmationDialog(Text("Training beenden?"), isPresented: $confirmStop) {
                    Button(String(localized: "Beenden"), role: .destructive) { link.send(.stop) }
                }
            } else {
                VStack(spacing: 8) {
                    RingMarkSmall().frame(width: 54, height: 54)
                    Text("Kein Training läuft").font(.headline)
                    Text("Wische nach oben, um ein Training zu starten.")
                        .font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary)
                    statusLine
                }
                .accessibilityIdentifier("watchIdle")
            }
        }
    }

    private var statusLine: some View {
        HStack(spacing: 4) {
            Circle().fill(link.reachable ? .green : .orange).frame(width: 6, height: 6)
            Text(link.reachable ? String(localized: "Steuert \(link.targetName)") : String(localized: "iPhone nicht erreichbar"))
        }
        .font(.caption2)
        .accessibilityElement(children: .combine)
    }

    private func ctrl(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.body.bold())
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(Text(label))
    }
}

struct WatchWorkoutList: View {
    @Environment(WatchLink.self) private var link

    var body: some View {
        NavigationStack {
            List {
                if let e = link.lastError {
                    Text(e).font(.caption2).foregroundStyle(.orange)
                }
                if link.workouts.isEmpty {
                    Text("Öffne Fit mit Jodit auf dem iPhone, damit die Trainings erscheinen.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(link.workouts) { w in
                    Button {
                        link.send(.start, workoutID: w.id)
                    } label: {
                        VStack(alignment: .leading) {
                            HStack(spacing: 4) {
                                if w.isFavorite { Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption2) }
                                Text(w.name).font(.headline).lineLimit(2)
                            }
                            Text(DurationFormat.clock(w.totalSeconds)).font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("watchWorkout-\(w.name)")
                }
            }
            .navigationTitle(Text("Trainings"))
        }
    }
}

/// Musiksteuerung über die System-Ansicht: steuert, was auf dem iPhone läuft (auch Spotify).
struct WatchMusicPage: View {
    var body: some View {
        NowPlayingView()
            .accessibilityLabel(Text("Musik auf dem iPhone"))
    }
}

struct RingMarkSmall: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .trim(from: CGFloat(i) / 8 + 0.015, to: CGFloat(i + 1) / 8 - 0.015)
                    .stroke(i % 2 == 0 ? Theme.work : Theme.rest, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text(verbatim: "J").font(.system(size: 24, weight: .heavy, design: .rounded))
        }
    }
}
