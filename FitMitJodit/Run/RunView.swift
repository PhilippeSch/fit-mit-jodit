import SwiftUI

/// Laufansicht. Liest sich aus 5 m, passt sich jeder Fenstergrösse an (Drittel bis Vollbild).
struct RunView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.scenePhase) private var scenePhase
    let session: RunSession
    @State private var controlsVisible = false
    @State private var hideTask: Task<Void, Never>?
    @State private var confirmStop = false
    /// Sperre gegen versehentliches Tippen (Uhr und Fernbedienung steuern weiter).
    @State private var locked = false
    @State private var lockHintVisible = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    var body: some View {
        let st = session.state
        let kind = st.step?.kind ?? .prep
        ZStack {
            (session.isFinished ? Theme.ink : Theme.color(for: kind))
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: kind)
            if session.isFinished {
                FinishedView(session: session)
            } else {
                GeometryReader { geo in
                    if let fold = geo.fold {
                        // iPhone Duo aufgeklappt: nichts Wichtiges auf dem Falz.
                        // Links/oben Blockname und Info, rechts/unten Countdown und Knöpfe.
                        let halves = fold.halves(in: geo.size)
                        ZStack(alignment: .topLeading) {
                            RunContent(session: session, size: halves.first.size, part: .info)
                                .frame(width: halves.first.width, height: halves.first.height)
                                .offset(x: halves.first.minX, y: halves.first.minY)
                            RunContent(session: session, size: halves.second.size, part: .countdown)
                                .frame(width: halves.second.width, height: halves.second.height)
                                .offset(x: halves.second.minX, y: halves.second.minY)
                            if !locked && (controlsVisible || st.isPaused || voiceOver) {
                                RunControls(session: session, confirmStop: $confirmStop, onInteract: showControls, onLock: lock)
                                    .frame(width: halves.second.width, height: halves.second.height)
                                    .offset(x: halves.second.minX, y: halves.second.minY)
                                    .transition(.opacity)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { showControls() }
                    } else {
                        ZStack {
                            RunContent(session: session, size: geo.size, part: .all)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .contentShape(Rectangle())
                                .onTapGesture { showControls() }
                            if !locked && (controlsVisible || st.isPaused || voiceOver) {
                                RunControls(session: session, confirmStop: $confirmStop, onInteract: showControls, onLock: lock)
                                    .transition(.opacity)
                            }
                        }
                    }
                }
                if locked && (lockHintVisible || voiceOver) {
                    UnlockBadge(onUnlock: unlock, onPressing: { pressing in
                        // Während des Drückens nicht ausblenden, danach wieder 3 s stehen lassen.
                        if pressing { hideTask?.cancel() } else if locked { showLockHint() }
                    })
                        .transition(.opacity)
                }
            }
        }
        .foregroundStyle(.white)
        .statusBarHidden(!controlsVisible)
        .persistentSystemOverlays(.hidden)
        .animation(.easeInOut(duration: 0.2), value: controlsVisible)
        .animation(.easeInOut(duration: 0.2), value: lockHintVisible)
        .confirmationDialog(Text("Training beenden?"), isPresented: $confirmStop, titleVisibility: .visible) {
            Button("Beenden", role: .destructive) { app.stop() }
                .accessibilityIdentifier("confirmStop")
            Button("Weiter trainieren", role: .cancel) {}
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { app.refresh() }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("runView")
    }

    private func lock() {
        locked = true
        controlsVisible = false
        hideTask?.cancel()
        showLockHint()
    }

    private func unlock() {
        locked = false
        lockHintVisible = false
        showControls()
    }

    private func showLockHint() {
        lockHintVisible = true
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled { lockHintVisible = false }
        }
    }

    private func showControls() {
        if locked { showLockHint(); return }
        controlsVisible = true
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { controlsVisible = false }
        }
    }
}

private struct RunContent: View {
    enum Part { case all, info, countdown }
    let session: RunSession
    let size: CGSize
    var part: Part = .all

    var body: some View {
        let st = session.state
        let step = st.step
        // Countdown so gross wie möglich: begrenzt durch Breite (4 Zeichen) und Höhe.
        let digits = DurationFormat.clock(st.displaySeconds)
        let byWidth = size.width / (CGFloat(max(digits.count, 4)) * 0.62)
        let byHeight = size.height * (part == .countdown ? 0.6 : 0.48)
        let fontSize = max(min(byWidth, byHeight), 48)
        let compact = size.width < 420
        VStack(spacing: compact ? 6 : 12) {
            Spacer(minLength: 0)
            if part != .countdown {
            Text(title(step))
                .font(.system(size: max(fontSize * 0.2, 24), weight: .heavy, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("runTitle")
            if let step, step.kind == .rest, let next = st.nextStep, next.hasName, let name = next.exerciseName {
                Text("Gleich: \(name)")
                    .font(.system(size: max(fontSize * 0.12, 18), weight: .semibold, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            }
            if part != .info {
            Text(digits)
                .font(Theme.countdownFont(size: fontSize))
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .contentTransition(.numericText(countsDown: true))
                .accessibilityIdentifier("countdown")
                .accessibilityLabel(Text("\(st.displaySeconds) Sekunden"))
            if st.isPaused {
                Text("Pausiert").font(.title.bold())
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    .background(.black.opacity(0.25), in: Capsule())
                    .accessibilityIdentifier("pausedBadge")
            }
            }
            if part != .countdown {
            VStack(spacing: 4) {
                if let next = st.nextStep, !(step?.kind == .rest && next.hasName) {
                    Text("Danach: \(next.displayName) · \(DurationFormat.short(next.seconds))")
                        .font(.system(size: max(fontSize * 0.09, 16), weight: .medium))
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .accessibilityIdentifier("nextBlock")
                }
                if let r = session.roundText {
                    Text(r)
                        .font(.system(size: max(fontSize * 0.09, 16), weight: .medium).monospacedDigit())
                        .accessibilityIdentifier("roundText")
                }
            }
            .opacity(0.92)
            }
            Spacer(minLength: 0)
            if part != .info {
            ProgressView(value: st.progress)
                .tint(.white)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.horizontal, compact ? 16 : 40)
                .padding(.bottom, compact ? 12 : 24)
                .accessibilityLabel(Text("Gesamtfortschritt"))
                .accessibilityValue(Text("\(Int(st.progress * 100)) Prozent"))
            }
        }
        .padding(.horizontal, compact ? 8 : 24)
    }

    private func title(_ step: Step?) -> String {
        guard let step else { return "" }
        if step.isLeadIn { return step.displayName }
        if step.kind == .rest { return BlockKind.rest.label }
        return step.displayName
    }
}

private struct RunControls: View {
    let session: RunSession
    @Binding var confirmStop: Bool
    let onInteract: () -> Void
    let onLock: () -> Void

    var body: some View {
        VStack {
            HStack(spacing: 20) {
                Button { confirmStop = true; onInteract() } label: {
                    Label("Stopp", systemImage: "xmark")
                }
                .accessibilityIdentifier("stop")
                Button { onLock() } label: {
                    Label("Sperren", systemImage: "lock.fill")
                }
                .accessibilityHint(Text("Verhindert versehentliches Tippen. Die Uhr steuert weiter."))
                .accessibilityIdentifier("lock")
                Spacer()
                SpotifyButton(link: session.workout.spotifyLink)
            }
            .font(.title3.bold())
            .padding()
            Spacer()
            HStack(spacing: 36) {
                control("backward.end.fill", String(localized: "Block zurück"), id: "skipBack") { session.skipBack() }
                control(session.state.isPaused ? "play.fill" : "pause.fill",
                        session.state.isPaused ? String(localized: "Weiter") : String(localized: "Pause"), id: "pauseResume", big: true) {
                    session.togglePause()
                }
                control("forward.end.fill", String(localized: "Block vor"), id: "skipForward") { session.skipForward() }
            }
            .padding(.bottom, 48)
        }
        .buttonStyle(.plain)
        .background(.black.opacity(0.2))
    }

    private func control(_ icon: String, _ label: String, id: String, big: Bool = false, action: @escaping () -> Void) -> some View {
        Button { action(); onInteract() } label: {
            Image(systemName: icon)
                .font(.system(size: big ? 44 : 30, weight: .bold))
                .frame(width: big ? 96 : 72, height: big ? 96 : 72)
                .background(.black.opacity(0.3), in: Circle())
        }
        .accessibilityLabel(Text(label))
        .accessibilityIdentifier(id)
    }
}

/// Hinweis bei gesperrtem Bildschirm: Entsperren nur mit langem Drücken.
private struct UnlockBadge: View {
    let onUnlock: () -> Void
    let onPressing: (Bool) -> Void
    @State private var pressing = false

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: pressing ? "lock.open.fill" : "lock.fill")
                    .font(.title2.bold())
                Text("Zum Entsperren gedrückt halten")
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.black.opacity(pressing ? 0.6 : 0.4), in: Capsule())
            .scaleEffect(pressing ? 1.08 : 1)
            .animation(.easeInOut(duration: 0.2), value: pressing)
            .onLongPressGesture(minimumDuration: 0.8, perform: onUnlock, onPressingChanged: { pressing = $0; onPressing($0) })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Entsperren"))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onUnlock() }
            .accessibilityIdentifier("unlock")
            .padding(.top, 24)
            Spacer()
        }
    }
}

private struct FinishedView: View {
    @Environment(AppModel.self) private var app
    let session: RunSession

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                RingMark()
                    .frame(width: 120, height: 120)
                    .accessibilityHidden(true)
                Text("Geschafft").font(Theme.title(.largeTitle, weight: .heavy)).scaleEffect(1.4)
                    .accessibilityIdentifier("finishedTitle")
                Text("Gesamtzeit \(session.totalTimeText)").font(.title2.monospacedDigit())
                HStack(spacing: 16) {
                    Button { app.start(session.workout) } label: { Label("Nochmals", systemImage: "arrow.counterclockwise") }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("again")
                    Button { app.stop() } label: { Label("Fertig", systemImage: "checkmark") }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("done")
                }
                .font(.title3.bold())
                .tint(.white)
                // Werbung für Jodits Trainings mit direktem Link zur Website.
                JoditPromoCard()
                    .frame(maxWidth: 520)
                    .environment(\.colorScheme, .light)
            }
            .padding()
            .padding(.top, 40)
            .frame(maxWidth: .infinity)
        }
    }
}

/// Ringmotiv aus dem App-Icon: grüne und orange Segmente.
struct RingMark: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .trim(from: CGFloat(i) / 8 + 0.01, to: CGFloat(i + 1) / 8 - 0.01)
                    .stroke(i % 2 == 0 ? Theme.work : Theme.rest, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text(verbatim: "J").font(.system(size: 54, weight: .heavy, design: .rounded))
        }
    }
}
