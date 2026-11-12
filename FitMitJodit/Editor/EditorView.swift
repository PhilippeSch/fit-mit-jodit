import SwiftUI
import UIKit

/// Baukasten: Namensfeld, Zeitleiste, Palette. Auf breiter Fläche Zeitleiste und Palette nebeneinander.
struct EditorView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var model: EditorModel
    @State private var sheet: EditorSheet?
    @State private var placedCount = 0
    @State private var drag = EditorDrag()
    /// Hinweis zum Verschieben, bis einmal ein Block gezogen wurde. Er verschwindet erst beim nächsten Öffnen
    /// des Baukastens, damit die Zeitleiste direkt nach dem ersten Ziehen nicht springt.
    @AppStorage("fmj.hint.dragMoved") private var dragHintDone = false
    @State private var showDragHint = false
    @State private var nameDraft = ""
    @FocusState private var nameFocused: Bool
    /// Breite der schmalen Bausteinspalte (eine Kachel breit), wächst mit der Schriftgrösse.
    @ScaledMetric(relativeTo: .caption) private var slimPaletteWidth: CGFloat = 124

    init(workout: Workout) {
        _model = State(initialValue: EditorModel(workout: workout))
    }

    var body: some View {
        GeometryReader { geo in
            // Bausteine rechts neben der Zeitleiste, sobald die Fläche es erlaubt: nah an der Stelle, wo gebaut wird.
            // Ab 640 pt eine breite Spalte, ab 460 pt (z. B. iPad 11 Zoll hochkant neben der Trainingsliste)
            // eine schmale Spalte mit einer Kachel pro Zeile. Darunter liegen die Bausteine unten.
            let sideBySide = hSize == .regular && geo.size.width >= 460
            let paletteWidth = geo.size.width >= 640 ? min(300, geo.size.width * 0.32) : slimPaletteWidth
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
                            .frame(width: paletteWidth)
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
        // Haptik direkt über UIKit statt `sensoryFeedback`: Dessen Anbindung stürzte auf dem iPad ab,
        // wenn sie auslöste, während die Ansicht gerade ersetzt wurde (Wechsel des Trainings).
        .onChange(of: placedCount) { _, _ in UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        .onChange(of: drag.dropCount) { _, _ in dragHintDone = true }
        .onAppear {
            model.onChange = { old, new in app.store.applyEdit(from: old, to: new) }
            nameDraft = model.workout.name
            showDragHint = !dragHintDone
        }
        .onDisappear(perform: commitName)
        .onChange(of: model.workout.name) { _, n in if !nameFocused { nameDraft = n } }
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

    private func commitName() {
        let n = nameDraft.trimmingCharacters(in: .whitespaces)
        if !n.isEmpty, n != model.workout.name { model.setName(n) } else if n.isEmpty { nameDraft = model.workout.name }
    }

    /// Die ganze Spalte scrollt (Name, Kopf, Start, Zeitleiste), damit auch lange Trainings auf kleinen
    /// Bildschirmen bearbeitbar bleiben. Die Auswahl-Leiste liegt fest am unteren Rand der Spalte.
    private var timelineColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Name als Entwurf: erst beim Abschluss übernehmen (ein Rückgängig-Schritt, ein Speichervorgang).
                TextField(String(localized: "Name des Trainings"), text: $nameDraft)
                    .focused($nameFocused)
                    .onSubmit(commitName)
                    .onChange(of: nameFocused) { _, focused in if !focused { commitName() } }
                    .font(Theme.title(.title2))
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .accessibilityIdentifier("workoutName")
                HStack(spacing: 16) {
                    Label(DurationFormat.clock(model.workout.totalSeconds), systemImage: "clock")
                        .accessibilityIdentifier("totalDuration")
                    Label(model.workout.roundCount == 1 ? String(localized: "1 Runde") : String(localized: "\(model.workout.roundCount) Runden"),
                          systemImage: "repeat")
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
                        .foregroundStyle(Theme.onBrand)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(StepSequence.expand(model.workout).isEmpty)
                .accessibilityIdentifier("start")

                TimelineStrip(model: model, drag: drag, sheet: $sheet)
                if showDragHint, model.items.count > 1 {
                    Label(String(localized: "Block halten und ziehen, um ihn zu verschieben – auch in eine Runde hinein oder heraus."),
                          systemImage: "hand.draw")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("dragHint")
                }
                Color.clear.frame(height: 12)
            }
            .padding()
            .onGeometryChange(for: [CGRect].self) { [$0.frame(in: .scrollView), $0.frame(in: .global)] } action: {
                drag.contentInScrollView = $0[0]
                drag.contentGlobal = $0[1]
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .accessibilityIdentifier("editorScroll")
        // Sichtbarer Bereich ohne Leisten (Navigationsleiste oben, Auswahl-Leiste unten) für das Nachscrollen am Rand.
        .onGeometryChange(for: CGRect.self) { g in
            let f = g.frame(in: .global), i = g.safeAreaInsets
            return CGRect(x: f.minX + i.leading, y: f.minY + i.top,
                          width: f.width - i.leading - i.trailing, height: f.height - i.top - i.bottom)
        } action: { drag.viewport = $0 }
        .modifier(DragAutoScroll(drag: drag))
        // Nur für die SwiftUI-Geste (iOS 17): Sie läuft gleichzeitig mit dem Scrollen, darum sperrt der Baukasten
        // es, solange ein Block angehoben ist. Der UIKit-Erkenner ab iOS 18 nimmt dem Scrollen den Finger selbst weg.
        .scrollDisabled(drag.isDragging && HoldToDrag.usesSwiftUIGesture)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !model.selection.isEmpty {
                SelectionBar(model: model, sheet: $sheet)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
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
    let drag: EditorDrag
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
                        BlockTile(block: b, model: model, drag: drag)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    case .round(let r):
                        RoundView(round: r, model: model, drag: drag, sheet: $sheet)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                }
            }
            .coordinateSpace(.named(EditorDrag.space))
            .onGeometryChange(for: CGPoint.self) { $0.frame(in: .global).origin } action: { drag.setStripOrigin($0) }
            .overlay(alignment: .topLeading) { DropIndicator(drag: drag) }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: model.items)
        }
    }
}

struct BlockTile: View {
    let block: Block
    @Bindable var model: EditorModel
    let drag: EditorDrag

    static func width(for seconds: Int) -> CGFloat {
        // Breite entspricht der Dauer: 5 s = 56 pt, 1 min = 132 pt, 10 min = 260 pt (gedeckelt).
        min(56 + CGFloat(seconds) * 1.27, 260)
    }

    var body: some View {
        let selected = model.selection.contains(block.id)
        let lifted = drag.isLifted(block.id)
        VStack(alignment: .leading, spacing: 2) {
            Text(DurationFormat.short(block.seconds))
                .font(.headline.monospacedDigit())
            Text(block.displayName)
                .font(.caption)
                .lineLimit(2)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(minWidth: Self.width(for: block.seconds), minHeight: 56, alignment: .leading)
        .fixedSize()
        .background(Theme.color(for: block.kind), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(selected ? Color.primary : .clear, lineWidth: 3)
                .padding(-3)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .scaleEffect(lifted ? 1.1 : (selected ? 1.04 : 1))
        .shadow(color: .black.opacity(lifted ? 0.4 : 0), radius: lifted ? 10 : 0, y: lifted ? 6 : 0)
        // Leicht durchscheinend, damit Einfügebalken und Ziel unter der angehobenen Kachel sichtbar bleiben.
        .opacity(lifted ? 0.9 : 1)
        // Antippen markiert, Halten hebt an, Ziehen verschiebt.
        .onTapGesture { model.toggleSelection(block.id) }
        .holdToDrag(.block(block.id), drag: drag, model: model) { model.toggleSelection(block.id) }
        .offset(lifted ? drag.offset : .zero)
        // Der alte Platz bleibt als gestrichelter Umriss sichtbar.
        .background {
            if lifted {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
        .reportFrame(block.id, to: drag)
        .zIndex(lifted ? 10 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(block.kind.label), \(DurationFormat.short(block.seconds))\(block.hasName ? ", " + (block.exerciseName ?? "") : "")"))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(Text("Antippen markiert den Block."))
        .accessibilityAction { model.toggleSelection(block.id) }
        .accessibilityAction(named: Text("Nach links verschieben")) { model.moveBlock(block.id, by: -1) }
        .accessibilityAction(named: Text("Nach rechts verschieben")) { model.moveBlock(block.id, by: 1) }
        .accessibilityIdentifier("tile-\(block.kind.rawValue)-\(block.seconds)")
    }
}

struct RoundView: View {
    let round: Round
    @Bindable var model: EditorModel
    let drag: EditorDrag
    @Binding var sheet: EditorSheet?

    var body: some View {
        let lifted = drag.isLifted(round.id)
        // Ein angehobener Block würde in dieser Runde landen.
        let targeted = drag.targetChanges && drag.target?.roundID == round.id
        // Ein Block aus dieser Runde ist angehoben: Die Runde muss über ihren Nachbarn liegen.
        let holdsLifted = round.blocks.contains { drag.isLifted($0.id) }
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Button {
                    sheet = .roundRepeats(round.id)
                } label: {
                    Label(String(localized: "× \(round.repeats)"), systemImage: "repeat")
                        .font(.subheadline.bold().monospacedDigit())
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Theme.brand.opacity(0.15), in: Capsule())
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Text("Runde, \(round.repeats) mal, \(DurationFormat.clock(round.secondsPerPass)) pro Runde"))
                .accessibilityHint(Text("Antippen ändert die Anzahl Durchgänge."))
                .accessibilityIdentifier("roundCounter")
                Text(String(localized: "\(DurationFormat.clock(round.secondsPerPass)) pro Runde"))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
                Menu {
                    Button { model.dissolveRound(round.id) } label: { Label("Runde auflösen", systemImage: "rectangle.split.3x1") }
                    Button { model.moveItem(round.id, by: -1) } label: { Label("Nach links", systemImage: "arrow.left") }
                    Button { model.moveItem(round.id, by: 1) } label: { Label("Nach rechts", systemImage: "arrow.right") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Text("Runde bearbeiten"))
                .accessibilityIdentifier("roundMenu")
            }
            FlowLayout(spacing: 6, lineSpacing: 8) {
                ForEach(round.blocks) { b in
                    BlockTile(block: b, model: model, drag: drag)
                }
            }
        }
        .padding(8)
        .background {
            // Die Runde lässt sich an Kopf und freier Fläche anheben. Die Geste liegt auf dem Hintergrund und nicht
            // auf dem ganzen Behälter, damit sie nicht gleichzeitig mit der Geste einer Kachel darin auslöst.
            RoundedRectangle(cornerRadius: 14)
                .fill(targeted ? AnyShapeStyle(Theme.brand.opacity(0.18)) : (lifted ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.clear)))
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .holdToDrag(.round(round.id), drag: drag, model: model)
        }
        .overlay {
            // Klammer um die Runde; durchgezogen, wenn ein Block hineinfallen würde.
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.brand, style: StrokeStyle(lineWidth: targeted ? 3 : 2, dash: targeted ? [] : [6, 4]))
                .allowsHitTesting(false)
        }
        .scaleEffect(lifted ? 1.03 : 1)
        .shadow(color: .black.opacity(lifted ? 0.4 : 0), radius: lifted ? 12 : 0, y: lifted ? 6 : 0)
        .opacity(lifted ? 0.9 : 1)
        .offset(lifted ? drag.offset : .zero)
        .background {
            if lifted {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
        .reportFrame(round.id, to: drag)
        .zIndex(lifted || holdsLifted ? 10 : 0)
        .animation(.easeOut(duration: 0.15), value: targeted)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("round")
    }
}

// MARK: - Auswahl-Leiste

struct SelectionBar: View {
    @Bindable var model: EditorModel
    @Binding var sheet: EditorSheet?
    /// Auf schmaler Breite nur Symbole (Beschriftung bleibt für VoiceOver), damit die Leiste kompakt bleibt.
    @Environment(\.horizontalSizeClass) private var hSize
    private var compact: Bool { hSize == .compact }

    var body: some View {
        // Bricht in Zeilen um, damit auf schmalen Breiten alle Aktionen sichtbar sind.
        FlowLayout(spacing: 8, lineSpacing: 8) {
            Group {
                bar(String(localized: "Übung"), "figure.strengthtraining.traditional", id: "pickExercise") { sheet = .exercise }
                bar(String(localized: "Dauer"), "timer", id: "pickDuration") { sheet = .duration }
                if model.selection.count == 1, let id = model.selection.first {
                    bar(String(localized: "Nach links"), "arrow.left", id: "selMoveLeft") { model.moveBlock(id, by: -1) }
                    bar(String(localized: "Nach rechts"), "arrow.right", id: "selMoveRight") { model.moveBlock(id, by: 1) }
                }
                bar(String(localized: "Duplizieren"), "plus.square.on.square", id: "duplicate") { model.duplicateSelection() }
                bar(String(localized: "Löschen"), "trash", id: "deleteBlocks", role: .destructive) { model.deleteSelection() }
                bar(String(localized: "mal N"), "repeat", id: "makeRound", keepTitle: true) { sheet = .repeats }
                    .disabled(!model.canMakeRound)
                bar(String(localized: "Fertig"), "checkmark", id: "deselect", keepTitle: true) { model.clearSelection() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(model.selection.count) markiert"))
    }

    @ViewBuilder
    private func bar(_ title: String, _ icon: String, id: String, role: ButtonRole? = nil, keepTitle: Bool = false,
                     action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            if compact && !keepTitle {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 28, minHeight: 28)
            } else {
                Label(title, systemImage: icon)
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(Text(title))
        .accessibilityIdentifier(id)
    }
}

// MARK: - Fliesslayout (bricht auf schmalen Breiten in Zeilen um)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    /// Volle angebotene Breite nutzen; Umbruch erst, wenn ein Element wirklich nicht mehr passt (mit Toleranz gegen Rundungsfehler).
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, widest: CGFloat = 0
        // Kinder bekommen die verfügbare Breite (Runden brechen so selbst um); Kacheln haben eine feste natürliche Grösse.
        let childProposal = ProposedViewSize(width: maxW.isFinite ? maxW : nil, height: nil)
        for v in subviews {
            let s = v.sizeThatFits(childProposal)
            if x > 0, x + s.width > maxW + 0.5 { y += lineH + lineSpacing; x = 0; lineH = 0 }
            x += s.width + spacing
            lineH = max(lineH, s.height)
            widest = max(widest, x - spacing)
        }
        let w = maxW.isFinite ? maxW : widest
        return CGSize(width: w, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        let childProposal = ProposedViewSize(width: bounds.width, height: nil)
        for v in subviews {
            let s = v.sizeThatFits(childProposal)
            if x > bounds.minX, x + s.width > bounds.maxX + 0.5 { y += lineH + lineSpacing; x = bounds.minX; lineH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: .init(s))
            x += s.width + spacing
            lineH = max(lineH, s.height)
        }
    }
}
