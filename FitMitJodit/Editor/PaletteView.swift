import SwiftUI

/// Palette mit Bausteinen. Antippen hängt an, Halten ändert die Dauer, «+» legt einen eigenen an.
struct PaletteView: View {
    @Environment(AppModel.self) private var app
    @Bindable var model: EditorModel
    let axis: Axis
    @Binding var sheet: EditorSheet?
    @Binding var placedCount: Int

    var body: some View {
        let content = Group {
            Button {
                sheet = .newPaletteItem
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .frame(width: 64, height: 64)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Eigenen Baustein anlegen"))
            .accessibilityIdentifier("addPaletteItem")
            ForEach(app.store.palette) { item in
                PaletteTile(item: item) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        _ = model.append(kind: item.kind, seconds: item.seconds)
                    }
                    placedCount += 1
                } onHold: {
                    sheet = .paletteDuration(item)
                } onRemove: {
                    app.store.removePaletteItem(item)
                }
            }

        }
        VStack(alignment: .leading, spacing: 8) {
            Text("Bausteine")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            if axis == .horizontal {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) { content }.padding(.vertical, 2)
                }
            } else {
                ScrollView {
                    FlowLayout(spacing: 10, lineSpacing: 10) { content }
                }
            }
        }
        .padding()
        .background(.bar)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("palette")
    }
}

struct PaletteTile: View {
    let item: PaletteItem
    let onTap: () -> Void
    let onHold: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: item.kind.symbolName).font(.footnote)
            Text(DurationFormat.short(item.seconds)).font(.headline.monospacedDigit())
            // `.caption` statt `.caption2`: caption2 wird bei kleineren Textgrössen nicht mehr kleiner, das meldet
            // der Bedienungshilfen-Audit als «Dynamic Type teilweise nicht unterstützt».
            Text(item.kind.label).font(.caption).lineLimit(2).multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .padding(6)
        .frame(minWidth: 84, minHeight: 64)
        .fixedSize()
        .background(Theme.color(for: item.kind), in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.5, perform: onHold)
        .contextMenu {
            Button(action: onHold) { Label("Dauer ändern", systemImage: "timer") }
            Button(role: .destructive, action: onRemove) { Label("Aus Palette entfernen", systemImage: "trash") }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(item.kind.label), \(DurationFormat.short(item.seconds))"))
        .accessibilityHint(Text("Hängt den Baustein an die Zeitleiste an."))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
        .accessibilityAction(named: Text("Dauer ändern"), onHold)
        .accessibilityAction(named: Text("Aus Palette entfernen"), onRemove)
        .accessibilityIdentifier("palette-\(item.kind.rawValue)-\(item.seconds)")
    }
}

// MARK: - Blätter

struct EditorSheetView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    let sheet: EditorSheet
    @Bindable var model: EditorModel

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder private var content: some View {
        switch sheet {
        case .duration:
            DurationSheet(initial: model.selectedBlocks.first?.seconds ?? 45) { s in
                model.setDuration(s)
                dismiss()
            }
        case .exercise:
            ExercisePicker(current: model.selectedBlocks.first?.exerciseName) { name in
                model.setExerciseName(name)
                if let n = name { app.store.rememberName(n) }
                dismiss()
            }
        case .repeats:
            RepeatsSheet(initial: 4) { n in
                model.makeRound(repeats: n)
                dismiss()
            }
        case .roundRepeats(let id):
            let current: Int = {
                if case .round(let r)? = model.items.first(where: { $0.id == id }) { return r.repeats }
                return 2
            }()
            RepeatsSheet(initial: current) { n in
                model.setRepeats(n, round: id)
                dismiss()
            }
        case .newPaletteItem:
            NewPaletteItemSheet { item in
                app.store.addPaletteItem(item)
                dismiss()
            }
        case .paletteDuration(let item):
            DurationSheet(initial: item.seconds) { s in
                var p = item
                p.seconds = s
                app.store.updatePaletteItem(p)
                dismiss()
            }
        case .spotify:
            SpotifyLinkSheet(initial: model.workout.spotifyLink ?? "") { link in
                model.setSpotifyLink(link)
                dismiss()
            }
        }
    }
}

/// Rad in 5-Sekunden-Schritten von 5 s bis 10 min.
struct DurationSheet: View {
    @State var seconds: Int
    let onDone: (Int) -> Void

    init(initial: Int, onDone: @escaping (Int) -> Void) {
        _seconds = State(initialValue: min(max(initial - initial % 5, 5), 600))
        self.onDone = onDone
    }

    static let values = Array(stride(from: 5, through: 600, by: 5))

    var body: some View {
        VStack {
            Picker(String(localized: "Dauer"), selection: $seconds) {
                ForEach(Self.values, id: \.self) { v in
                    Text(DurationFormat.short(v)).tag(v)
                }
            }
            .pickerStyle(.wheel)
            .accessibilityIdentifier("durationWheel")
            Button { onDone(seconds) } label: {
                Text("Übernehmen").foregroundStyle(Theme.onBrand)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("applyDuration")
        }
        .padding()
        .navigationTitle(Text("Dauer"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RepeatsSheet: View {
    @State var repeats: Int
    let onDone: (Int) -> Void

    init(initial: Int, onDone: @escaping (Int) -> Void) {
        _repeats = State(initialValue: initial)
        self.onDone = onDone
    }

    var body: some View {
        Form {
            Stepper(value: $repeats, in: 1...99) {
                Text("\(repeats) mal").font(.title2.monospacedDigit())
            }
            .accessibilityIdentifier("repeatsStepper")
            Button(String(localized: "Übernehmen")) { onDone(repeats) }
                .accessibilityIdentifier("applyRepeats")
        }
        .navigationTitle(Text("Runde"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NewPaletteItemSheet: View {
    @State private var kind: BlockKind = .work
    @State private var seconds = 40
    let onDone: (PaletteItem) -> Void

    var body: some View {
        Form {
            Picker(String(localized: "Typ"), selection: $kind) {
                ForEach(BlockKind.allCases, id: \.self) { k in Text(k.label).tag(k) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("newKind")
            Picker(String(localized: "Dauer"), selection: $seconds) {
                ForEach(DurationSheet.values, id: \.self) { v in Text(DurationFormat.short(v)).tag(v) }
            }
            .pickerStyle(.wheel)
            .accessibilityIdentifier("newDurationWheel")
            Button(String(localized: "Hinzufügen")) { onDone(PaletteItem(kind: kind, seconds: seconds)) }
                .accessibilityIdentifier("addCustomBlock")
        }
        .navigationTitle(Text("Eigener Baustein"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Übungsliste mit Suche, eigene Namen werden gemerkt.
struct ExercisePicker: View {
    @Environment(AppModel.self) private var app
    let current: String?
    let onPick: (String?) -> Void
    @State private var query = ""

    var body: some View {
        let catalog = ExerciseCatalog.search(query).map { ExerciseCatalog.localizedName($0) }
        let own = app.store.customExerciseNames.filter { query.isEmpty || $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        List {
            if !trimmed.isEmpty && !(catalog + own).contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                Button { onPick(trimmed) } label: { Label(String(localized: "«\(trimmed)» verwenden"), systemImage: "plus.circle") }
                    .accessibilityIdentifier("useCustomName")
            }
            if current != nil {
                Button(role: .destructive) { onPick(nil) } label: { Label("Ohne Namen", systemImage: "xmark.circle") }
            }
            if !own.isEmpty {
                Section(String(localized: "Eigene")) {
                    ForEach(own, id: \.self) { n in Button(n) { onPick(n) } }
                }
            }
            Section(String(localized: "Übungen")) {
                ForEach(catalog, id: \.self) { n in
                    Button(n) { onPick(n) }
                        .accessibilityIdentifier("exercise-\(n)")
                }
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Übung suchen oder eintippen"))
        .navigationTitle(Text("Übung wählen"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
