import SwiftUI
import UIKit

/// Halten und Ziehen im Baukasten. Ersetzt das System-Drag-and-drop, bei dem nur genau getroffene Kacheln
/// als Ziel galten: Hier hat jeder Punkt der Zeitleiste ein Ziel, nämlich die nächstgelegene Lücke.
/// Ein Balken zeigt, wo der Block landet; eine Runde leuchtet auf, wenn der Block in sie hineinfällt.
@MainActor
@Observable
final class EditorDrag {
    static let space = "timeline"
    /// Haltedauer bis zum Anheben: kurz genug für flüssiges Arbeiten, lang genug, um Scrollen und Tippen zu unterscheiden.
    static let holdDuration = 0.25
    /// Unterhalb dieser Strecke gilt Anheben und Loslassen als Antippen.
    static let tapSlop: CGFloat = 6

    enum Payload: Equatable {
        case block(UUID)
        case round(UUID)

        var id: UUID {
            switch self {
            case .block(let id), .round(let id): return id
            }
        }

        var isRound: Bool {
            if case .round = self { return true }
            return false
        }
    }

    enum Outcome { case moved, unchanged, tap }

    private(set) var payload: Payload?
    private(set) var target: DropTarget?
    /// Ob das Ablegen am Ziel etwas ändert. Nur dann erscheint der Einfügebalken.
    private(set) var targetChanges = false
    /// Versatz der angehobenen Kachel gegenüber ihrem Platz in der Zeitleiste.
    private(set) var offset: CGSize = .zero
    /// Zählt erfolgreiche Verschiebungen (blendet den Hinweis im Baukasten aus).
    private(set) var dropCount = 0

    /// Rahmen aller Kacheln und Runden im Koordinatenraum der Zeitleiste.
    @ObservationIgnored var frames: [UUID: CGRect] = [:]
    /// Sichtbarer Bereich der Scroll-Ansicht in globalen Koordinaten (für das Nachscrollen am Rand).
    @ObservationIgnored var viewport: CGRect = .zero
    /// Rahmen des ganzen Scroll-Inhalts: im Raum der Scroll-Ansicht (daraus die Scroll-Position) und global.
    @ObservationIgnored var contentInScrollView: CGRect = .zero
    @ObservationIgnored var contentGlobal: CGRect = .zero
    @ObservationIgnored private var stripOrigin: CGPoint = .zero
    @ObservationIgnored private var originAtLift: CGPoint = .zero
    @ObservationIgnored private var translation: CGSize = .zero
    @ObservationIgnored private var finger: CGPoint?
    @ObservationIgnored private weak var model: EditorModel?

    var isDragging: Bool { payload != nil }

    func isLifted(_ id: UUID) -> Bool { payload?.id == id }

    /// Kachel anheben (nach dem Halten, noch ohne Bewegung).
    func begin(_ p: Payload, model: EditorModel) {
        guard payload == nil, frames[p.id] != nil else { return }
        self.model = model
        payload = p
        originAtLift = stripOrigin
        translation = .zero
        finger = nil
        target = nil
        targetChanges = false
        offset = .zero
        // Haptik direkt über UIKit: Die SwiftUI-Anbindung (`sensoryFeedback`) stürzte auf dem iPad ab,
        // wenn sie auslöste, während ihre Ansicht gerade ersetzt wurde.
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Finger bewegt sich (globale Koordinaten).
    func update(_ p: Payload, model: EditorModel, location: CGPoint, translation: CGSize) {
        if payload == nil { begin(p, model: model) }
        guard payload == p else { return }
        self.translation = translation
        finger = location
        refresh()
    }

    /// Die Zeitleiste hat sich unter dem Finger verschoben (Scrollen): Ziel neu bestimmen.
    func setStripOrigin(_ origin: CGPoint) {
        guard origin != stripOrigin else { return }
        stripOrigin = origin
        if payload != nil { refresh() }
    }

    private func refresh() {
        // Der Finger wandert um `translation`, die Zeitleiste scrollt um (stripOrigin − originAtLift) darunter weg.
        offset = CGSize(width: translation.width + originAtLift.x - stripOrigin.x,
                        height: translation.height + originAtLift.y - stripOrigin.y)
        guard let payload, let finger, let model else { return }
        let point = CGPoint(x: finger.x - stripOrigin.x, y: finger.y - stripOrigin.y)
        var entries: [DropLocator.Entry] = []
        for item in model.items {
            guard let frame = frames[item.id] else { setTarget(nil, model: model); return }
            switch item {
            case .block:
                entries.append(.init(id: item.id, frame: frame, blocks: nil))
            case .round(let r):
                var blocks: [(id: UUID, frame: CGRect)] = []
                for b in r.blocks {
                    guard let f = frames[b.id] else { setTarget(nil, model: model); return }
                    blocks.append((b.id, f))
                }
                entries.append(.init(id: item.id, frame: frame, blocks: blocks))
            }
        }
        setTarget(DropLocator.locate(point: point, entries: entries, draggingRound: payload.isRound), model: model)
    }

    private func setTarget(_ t: DropTarget?, model: EditorModel) {
        guard t != target else { return }
        // Feines Ticken, sobald die Einfügestelle wechselt.
        if t?.slot != target?.slot, t != nil { UISelectionFeedbackGenerator().selectionChanged() }
        target = t
        if let t, let payload {
            targetChanges = model.wouldMove(payload.id, to: t.slot)
        } else {
            targetChanges = false
        }
    }

    /// Finger losgelassen: ablegen. Ohne nennenswerte Bewegung zählt es als Antippen.
    func end(_ p: Payload) -> Outcome {
        guard payload == p else { return .unchanged }
        defer { reset() }
        if finger == nil || hypot(translation.width, translation.height) < Self.tapSlop { return .tap }
        guard let target, let model, model.move(p.id, to: target.slot) else { return .unchanged }
        dropCount += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        return .moved
    }

    /// Geste abgebrochen (z. B. durch das System): alles zurück an den Platz.
    func cancel(_ p: Payload) {
        if payload == p { reset() }
    }

    private func reset() {
        payload = nil
        target = nil
        targetChanges = false
        offset = .zero
        translation = .zero
        finger = nil
    }

    /// Geschwindigkeit fürs Nachscrollen in Punkten pro Sekunde: negativ nach oben, positiv nach unten, 0 in der Mitte.
    var edgeScrollSpeed: CGFloat {
        guard payload != nil, let finger, viewport.height > 0 else { return 0 }
        let zone: CGFloat = min(72, viewport.height / 4), top: CGFloat = 520
        if finger.y < viewport.minY + zone {
            return -top * min((viewport.minY + zone - finger.y) / zone, 1)
        }
        if finger.y > viewport.maxY - zone {
            return top * min((finger.y - (viewport.maxY - zone)) / zone, 1)
        }
        return 0
    }

    /// Nächste Scroll-Position fürs Nachscrollen, oder nil, wenn nichts zu tun ist (Finger nicht am Rand, Ende erreicht).
    func autoScrollTarget(step: Double) -> CGFloat? {
        let speed = edgeScrollSpeed
        guard speed != 0 else { return nil }
        var delta = speed * step
        if delta > 0 {
            // Nach unten nur, solange Inhalt unter dem sichtbaren Bereich liegt.
            delta = min(delta, contentGlobal.maxY - viewport.maxY)
            guard delta > 0.1 else { return nil }
        } else {
            delta = max(delta, contentGlobal.minY - viewport.minY)
            guard delta < -0.1 else { return nil }
        }
        // Scroll-Position = wie weit der Inhalt in der Scroll-Ansicht nach oben geschoben ist.
        return -contentInScrollView.minY + delta
    }
}

// MARK: - Geste

/// Halten hebt an, Ziehen verschiebt, Loslassen legt ab. Antippen bleibt beim Aufrufer (`onTapGesture`).
///
/// Ab iOS 18 über einen UIKit-Erkenner (`UILongPressGestureRecognizer`), so wie Listen und Raster von UIKit
/// selbst umsortieren: Er verträgt sich mit dem Scrollen. Wischen scrollt, erst Halten hebt an, und danach
/// gehört der Finger dem Block. Eine SwiftUI-Geste an derselben Stelle blockierte das Scrollen, sobald der
/// Finger auf einer Kachel startete. Davor (iOS 17) die SwiftUI-Geste, dort stört sie das Scrollen nicht.
struct HoldToDrag: ViewModifier {
    let payload: EditorDrag.Payload
    let drag: EditorDrag
    let model: EditorModel
    /// Lange gedrückt und ohne Bewegung losgelassen: wie Antippen behandeln (ab iOS 18; davor meldet es `onTapGesture` selbst).
    var onTap: (() -> Void)?

    static let settle = Animation.spring(response: 0.32, dampingFraction: 0.8)

    static var usesSwiftUIGesture: Bool {
        if #available(iOS 18.0, *) { return false }
        return true
    }

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.gesture(HoldDragRecognizer(payload: payload, drag: drag, model: model, onTap: onTap))
        } else {
            content.modifier(LegacyHoldToDrag(payload: payload, drag: drag, model: model))
        }
    }
}

@available(iOS 18.0, *)
private struct HoldDragRecognizer: UIGestureRecognizerRepresentable {
    let payload: EditorDrag.Payload
    let drag: EditorDrag
    let model: EditorModel
    let onTap: (() -> Void)?

    final class Coordinator {
        var start: CGPoint = .zero
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let r = UILongPressGestureRecognizer()
        r.minimumPressDuration = EditorDrag.holdDuration
        r.allowableMovement = 10
        return r
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        let point = context.converter.location(in: .global)
        switch recognizer.state {
        case .began:
            context.coordinator.start = point
            withAnimation(HoldToDrag.settle) { drag.begin(payload, model: model) }
        case .changed:
            let start = context.coordinator.start
            drag.update(payload, model: model, location: point,
                        translation: CGSize(width: point.x - start.x, height: point.y - start.y))
        case .ended:
            let outcome = withAnimation(HoldToDrag.settle) { drag.end(payload) }
            if outcome == .tap { onTap?() }
        case .cancelled, .failed:
            withAnimation(HoldToDrag.settle) { drag.cancel(payload) }
        default:
            break
        }
    }
}

/// SwiftUI-Fassung für iOS 17.
private struct LegacyHoldToDrag: ViewModifier {
    let payload: EditorDrag.Payload
    let drag: EditorDrag
    let model: EditorModel
    @GestureState private var pressing = false

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                LongPressGesture(minimumDuration: EditorDrag.holdDuration, maximumDistance: 10)
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
                    .updating($pressing) { value, state, _ in
                        if case .second = value { state = true }
                    }
                    .onChanged { value in
                        guard case .second(true, let d) = value else { return }
                        if let d {
                            drag.update(payload, model: model, location: d.location, translation: d.translation)
                        } else {
                            withAnimation(HoldToDrag.settle) { drag.begin(payload, model: model) }
                        }
                    }
                    .onEnded { value in
                        guard case .second = value else { return }
                        _ = withAnimation(HoldToDrag.settle) { drag.end(payload) }
                    }
            )
            .onChange(of: pressing) { _, now in
                // Abbruch ohne `onEnded` (System unterbricht die Geste): Kachel zurücklegen.
                guard !now else { return }
                DispatchQueue.main.async {
                    withAnimation(HoldToDrag.settle) { drag.cancel(payload) }
                }
            }
    }
}

extension View {
    func holdToDrag(_ payload: EditorDrag.Payload, drag: EditorDrag, model: EditorModel, onTap: (() -> Void)? = nil) -> some View {
        modifier(HoldToDrag(payload: payload, drag: drag, model: model, onTap: onTap))
    }

    /// Meldet den Rahmen im Koordinatenraum der Zeitleiste. Aussen an einem `offset` anbringen,
    /// damit der Platz in der Zeitleiste gemeldet wird und nicht die angehobene Kachel.
    func reportFrame(_ id: UUID, to drag: EditorDrag) -> some View {
        onGeometryChange(for: CGRect.self) { $0.frame(in: .named(EditorDrag.space)) } action: { drag.frames[id] = $0 }
    }
}

// MARK: - Einfügebalken

struct DropIndicator: View {
    let drag: EditorDrag

    var body: some View {
        if drag.isDragging, drag.targetChanges, let bar = drag.target?.indicator {
            Capsule()
                .fill(Theme.brand)
                .frame(width: bar.width, height: bar.height)
                .shadow(color: Theme.brand.opacity(0.6), radius: 4)
                .offset(x: bar.minX, y: bar.minY)
                .animation(.snappy(duration: 0.12), value: bar)
                .transition(.opacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Nachscrollen am Rand

/// Scrollt die Zeitleiste, solange eine angehobene Kachel am oberen oder unteren Rand gehalten wird.
/// Braucht die steuerbare Scroll-Position (ab iOS 18); davor bleibt die Ansicht stehen.
struct DragAutoScroll: ViewModifier {
    let drag: EditorDrag

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.modifier(Scroller(drag: drag))
        } else {
            content
        }
    }

    @available(iOS 18.0, *)
    private struct Scroller: ViewModifier {
        let drag: EditorDrag
        @State private var position = ScrollPosition()

        func body(content: Content) -> some View {
            content
                .scrollPosition($position)
                .task(id: drag.isDragging) {
                    guard drag.isDragging else { return }
                    let step = 1.0 / 60
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(step))
                        if let y = drag.autoScrollTarget(step: step) { position.scrollTo(y: y) }
                    }
                }
        }
    }
}
