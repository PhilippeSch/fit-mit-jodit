import SwiftUI

/// Baukasten: Namensfeld, Zeitleiste, Palette. Auf breiter Fläche Zeitleiste und Palette nebeneinander.
struct EditorView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var model: EditorModel
    @State private var sheet: EditorSheet?
    @State private var placedCount = 0

    init(workout: Workout) {
        _model = State(initialValue: EditorModel(workout: workout))
    }

    var body: some View {
        GeometryReader { geo in
            let sideBySide = hSize == .regular && geo.size.width >= 640
            Group {
                if let fold = geo.fold, fold.isVertical {
                    // iPhone Duo aufgeklappt: Zeitleiste links, Palette rechts, der Falz liegt zwischen beiden.
                    HStack(alignment: .top, spacing: fold.rect.width) {
                        timelineColumn
                            .frame(width: fold.rect.minX)
                        PaletteView(model: model, axis: .vertical, sheet: $sheet, placedCount: $placedCount)
                            .frame(width: max(geo.size.width - fold.rect.maxX, 0))
                    }
                } else if sideBySide {
                    HStack(alignment: .top, spacing: 0) {
                        timelineColumn
                        Divider()
                        PaletteView(model: model, axis: .vertical, sheet: $sheet, placedCount: $placedCount)
                            .frame(width: min(300, geo.size.width * 0.32))
                    }
                } else {
                    VStack(spacing: 0) {
                        timelineColumn
                        Divider()
                        PaletteView(model: model, axis: .horizontal, sheet: $sheet, placedCount: $placedCount)
                    }
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: placedCount)
        .onAppear { model.onChange = { app.store.upsert($0) } }
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button { model.undo() } label: { Label("Rückgängig", systemImage: "arrow.uturn.backward") }
                    .disabled(!model.canUndo)
                    .keyboardShortcut("z", modifiers: .command)
                    .accessibilityIdentifier("undo")
                Button { model.redo() } label: { Label("Wiederholen", systemImage: "arrow.uturn.forward") }
                    .disabled(!model.canRedo)
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .accessibilityIdentifier("redo")
                Toggle(isOn: Binding(get: { model.workout.skipTrailingRest }, set: { model.setSkipTrailingRest($0) })) {
                    Label("Pause am Ende überspringen", systemImage: "forward.end")
                }
                Button { sheet = .spotify } label: { Label("Spotify-Link", systemImage: "music.note") }
                    .accessibilityIdentifier("spotifyLinkEdit")
            }
        }
        .sheet(item: $sheet) { s in
            EditorSheetView(sheet: s, model: model)
        }
    }

    private var timelineColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(String(localized: "Name des Trainings"), text: Binding(get: { model.workout.name }, set: { model.setName($0) }))
                .font(Theme.title(.title2))
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .accessibilityIdentifier("workoutName")
            HStack(spacing: 16) {
                Label(DurationFormat.clock(model.workout.totalSeconds), systemImage: "clock")
                    .accessibilityIdentifier("totalDuration")
                Label(String(localized: "\(model.workout.roundCount) Runden"), systemImage: "repeat")
                Spacer()
            }
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)
            // Starten gross und immer sichtbar, auch bei einem Drittel der Breite.
            Button {
                app.start(model.workout)
            } label: {
                Label(String(localized: "Starten"), systemImage: "play.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(StepSequence.expand(model.workout).isEmpty)
            .accessibilityIdentifier("start")

            ScrollView {
                TimelineStrip(model: model, sheet: $sheet)
                    .padding(.bottom, 12)
            }
            .scrollDismissesKeyboard(.immediately)

            if !model.selection.isEmpty {
                SelectionBar(model: model, sheet: $sheet)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.selection.isEmpty)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

enum EditorSheet: Identifiable, Hashable {
    case duration
    case exercise
    case repeats
    case roundRepeats(UUID)
    case newPaletteItem
    case paletteDuration(PaletteItem)
    case spotify

    var id: String {
        switch self {
        case .duration: return "duration"
        case .exercise: return "exercise"
        case .repeats: return "repeats"
        case .roundRepeats(let id): return "round-\(id)"
        case .newPaletteItem: return "newPalette"
        case .paletteDuration(let p): return "palette-\(p.id)"
        case .spotify: return "spotify"
        }
    }
}

// MARK: - Zeitleiste

struct TimelineStrip: View {
    @Bindable var model: EditorModel
    @Binding var sheet: EditorSheet?

    var body: some View {
        if model.items.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up").font(.largeTitle).foregroundStyle(.secondary)
                Text("Tippe unten auf einen Baustein, um ihn anzuhängen.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .accessibilityIdentifier("emptyTimeline")
        } else {
            FlowLayout(spacing: 8, lineSpacing: 12) {
                ForEach(model.items) { item in
                    switch item {
                    case .block(let b):
                        BlockTile(block: b, model: model)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    case .round(let r):
                        RoundView(round: r, model: model, sheet: $sheet)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: model.items)
        }
    }
}

struct BlockTile: View {
    let block: Block
    @Bindable var model: EditorModel

    static func width(for seconds: Int) -> CGFloat {
        // Breite entspricht der Dauer: 5 s = 56 pt, 1 min = 132 pt, 10 min = 260 pt (gedeckelt).
        min(56 + CGFloat(seconds) * 1.27, 260)
    }

    var body: some View {
        let selected = model.selection.contains(block.id)
        Button {
            model.toggleSelection(block.id)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(DurationFormat.short(block.seconds))
                    .font(.headline.monospacedDigit())
                Text(block.displayName)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .frame(width: Self.width(for: block.seconds), height: 56, alignment: .leading)
            .background(Theme.color(for: block.kind), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(selected ? Color.primary : .clear, lineWidth: 3)
                    .padding(-3)
            }
            .scaleEffect(selected ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .draggable(block.id.uuidString)
        .dropDestination(for: String.self) { ids, _ in
            guard let s = ids.first, let id = UUID(uuidString: s) else { return false }
            model.moveBlock(id, before: block.id)
            return true
        }
        .accessibilityLabel(Text("\(block.kind.label), \(DurationFormat.short(block.seconds))\(block.hasName ? ", " + (block.exerciseName ?? "") : "")"))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint(Text("Antippen markiert den Block."))
        .accessibilityAction(named: Text("Nach links verschieben")) { model.moveBlock(block.id, by: -1) }
        .accessibilityAction(named: Text("Nach rechts verschieben")) { model.moveBlock(block.id, by: 1) }
        .accessibilityIdentifier("tile-\(block.kind.rawValue)-\(block.seconds)")
        .contextMenu {
            Button { model.moveBlock(block.id, by: -1) } label: { Label("Nach links", systemImage: "arrow.left") }
            Button { model.moveBlock(block.id, by: 1) } label: { Label("Nach rechts", systemImage: "arrow.right") }
        }
    }
}

struct RoundView: View {
    let round: Round
    @Bindable var model: EditorModel
    @Binding var sheet: EditorSheet?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Button {
                    sheet = .roundRepeats(round.id)
                } label: {
                    Label(String(localized: "× \(round.repeats)"), systemImage: "repeat")
                        .font(.subheadline.bold().monospacedDigit())
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Theme.brand.opacity(0.15), in: Capsule())
                }
                .accessibilityLabel(Text("Runde, \(round.repeats) mal"))
                .accessibilityHint(Text("Antippen ändert die Anzahl Durchgänge."))
                .accessibilityIdentifier("roundCounter")
                Text(String(localized: "\(DurationFormat.clock(round.secondsPerPass)) pro Runde"))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Menu {
                    Button { model.dissolveRound(round.id) } label: { Label("Runde auflösen", systemImage: "rectangle.split.3x1") }
                    Button { model.moveItem(round.id, by: -1) } label: { Label("Nach links", systemImage: "arrow.left") }
                    Button { model.moveItem(round.id, by: 1) } label: { Label("Nach rechts", systemImage: "arrow.right") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(Text("Runde bearbeiten"))
                .accessibilityIdentifier("roundMenu")
            }
            FlowLayout(spacing: 6, lineSpacing: 8) {
                ForEach(round.blocks) { b in
                    BlockTile(block: b, model: model)
                }
            }
        }
        .padding(8)
        .overlay {
            // Klammer um die Runde
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.brand, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
        }
        .draggable(round.id.uuidString)
        .dropDestination(for: String.self) { ids, _ in
            guard let s = ids.first, let id = UUID(uuidString: s) else { return false }
            if let to = model.items.firstIndex(where: { $0.id == round.id }), model.location(of: id)?.inner == nil || model.items.contains(where: { $0.id == id }) {
                let from = model.items.firstIndex(where: { $0.id == id }) ?? to
                model.moveItem(id, to: from < to ? to - 1 : to)
                return true
            }
            return false
        }
    }
}

// MARK: - Auswahl-Leiste

struct SelectionBar: View {
    @Bindable var model: EditorModel
    @Binding var sheet: EditorSheet?

    var body: some View {
        // Bricht in Zeilen um, damit auf schmalen Breiten alle Aktionen sichtbar sind.
        FlowLayout(spacing: 8, lineSpacing: 8) {
            Group {
                bar(String(localized: "Übung"), "figure.strengthtraining.traditional", id: "pickExercise") { sheet = .exercise }
                bar(String(localized: "Dauer"), "timer", id: "pickDuration") { sheet = .duration }
                bar(String(localized: "Duplizieren"), "plus.square.on.square", id: "duplicate") { model.duplicateSelection() }
                bar(String(localized: "Löschen"), "trash", id: "deleteBlocks", role: .destructive) { model.deleteSelection() }
                bar(String(localized: "mal N"), "repeat", id: "makeRound") { sheet = .repeats }
                    .disabled(!model.canMakeRound)
                bar(String(localized: "Fertig"), "checkmark", id: "deselect") { model.clearSelection() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(model.selection.count) markiert"))
    }

    private func bar(_ title: String, _ icon: String, id: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            Label(title, systemImage: icon)
                .labelStyle(.titleAndIcon)
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier(id)
    }
}

// MARK: - Fliesslayout (bricht auf schmalen Breiten in Zeilen um)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, widest: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.init(width: maxW, height: nil))
            if x > 0, x + s.width > maxW { y += lineH + lineSpacing; x = 0; lineH = 0 }
            x += s.width + spacing
            lineH = max(lineH, s.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, maxW), height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.init(width: bounds.width, height: nil))
            if x > bounds.minX, x + s.width > bounds.maxX { y += lineH + lineSpacing; x = bounds.minX; lineH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: .init(s))
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
    }
}
