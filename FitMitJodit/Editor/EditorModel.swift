import Foundation
import Observation

/// Logik des Baukastens: Zeitleiste, Auswahl, Runden, Rückgängig/Wiederholen.
/// Unabhängig von SwiftUI, damit sie mit Unit-Tests geprüft werden kann.
@MainActor
@Observable
final class EditorModel {
    private(set) var workout: Workout
    var selection: Set<UUID> = []
    private var undoStack: [Workout] = []
    private var redoStack: [Workout] = []
    /// Meldet (vorher, nachher), damit der Speicher nur die geänderten Felder übernimmt.
    @ObservationIgnored var onChange: ((Workout, Workout) -> Void)?

    static let minSeconds = 5
    static let maxSeconds = 600

    init(workout: Workout) { self.workout = workout }

    var items: [TimelineItem] { workout.items }
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    // MARK: Änderungen mit Verlauf

    private func mutate(_ f: (inout Workout) -> Void) {
        let before = workout
        var w = workout
        f(&w)
        guard w != before else { return }
        undoStack.append(before)
        if undoStack.count > 200 { undoStack.removeFirst() }
        redoStack.removeAll()
        workout = w
        onChange?(before, w)
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        let current = workout
        redoStack.append(current)
        workout = prev
        pruneSelection()
        onChange?(current, prev)
    }

    /// Auswahl auf Blöcke beschränken, die es noch gibt.
    private func pruneSelection() {
        selection = selection.filter { id in workout.items.contains { $0.id == id || $0.blocks.contains { $0.id == id } } }
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        let current = workout
        undoStack.append(current)
        workout = next
        pruneSelection()
        onChange?(current, next)
    }

    // MARK: Abfragen

    /// Position eines Blocks: (Index in der Zeitleiste, Index in der Runde oder nil).
    func location(of blockID: UUID) -> (item: Int, inner: Int?)? {
        for (i, item) in workout.items.enumerated() {
            switch item {
            case .block(let b) where b.id == blockID: return (i, nil)
            case .round(let r):
                if let j = r.blocks.firstIndex(where: { $0.id == blockID }) { return (i, j) }
            default: break
            }
        }
        return nil
    }

    func block(_ id: UUID) -> Block? {
        guard let loc = location(of: id) else { return nil }
        switch workout.items[loc.item] {
        case .block(let b): return b
        case .round(let r): return loc.inner.map { r.blocks[$0] }
        }
    }

    var selectedBlocks: [Block] { selection.compactMap { block($0) } }

    /// «mal N» geht, wenn alle markierten Blöcke direkt in der Zeitleiste liegen und nebeneinander stehen.
    var canMakeRound: Bool {
        let locs = selection.compactMap { location(of: $0) }
        guard locs.count == selection.count, !locs.isEmpty, locs.allSatisfy({ $0.inner == nil }) else { return false }
        let idx = locs.map(\.item).sorted()
        return idx.last! - idx.first! == idx.count - 1
    }

    // MARK: Bearbeiten

    func toggleSelection(_ id: UUID) {
        if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
    }

    func clearSelection() { selection.removeAll() }

    func setName(_ name: String) {
        mutate { w in
            w.name = name
        }
    }

    func setSkipTrailingRest(_ on: Bool) { mutate { $0.skipTrailingRest = on } }

    func setSpotifyLink(_ link: String?) { mutate { $0.spotifyLink = link } }

    /// Hängt einen Baustein ans Ende oder hinter den zuletzt markierten Block. Gibt die neue Block-ID zurück.
    @discardableResult
    func append(kind: BlockKind, seconds: Int) -> UUID {
        let b = Block(kind: kind, seconds: clamp(seconds))
        mutate { w in
            if let anchor = lastSelectedLocation(in: w) {
                if let inner = anchor.inner, case .round(var r) = w.items[anchor.item] {
                    r.blocks.insert(b, at: inner + 1)
                    w.items[anchor.item] = .round(r)
                } else {
                    w.items.insert(.block(b), at: anchor.item + 1)
                }
            } else {
                w.items.append(.block(b))
            }
        }
        // Die Auswahl wandert mit, damit mehrere Bausteine hintereinander landen.
        if !selection.isEmpty { selection = [b.id] }
        return b.id
    }

    private func lastSelectedLocation(in w: Workout) -> (item: Int, inner: Int?)? {
        guard !selection.isEmpty else { return nil }
        var best: (Int, Int?)?
        for (i, item) in w.items.enumerated() {
            switch item {
            case .block(let b) where selection.contains(b.id): best = (i, nil)
            case .round(let r):
                for (j, b) in r.blocks.enumerated() where selection.contains(b.id) { best = (i, j) }
            default: break
            }
        }
        return best.map { (item: $0.0, inner: $0.1) }
    }

    private func clamp(_ s: Int) -> Int { min(max(s, Self.minSeconds), Self.maxSeconds) }

    private func updateBlocks(_ ids: Set<UUID>, _ f: @escaping (inout Block) -> Void) {
        mutate { w in
            w.items = w.items.map { item in
                switch item {
                case .block(var b):
                    if ids.contains(b.id) { f(&b) }
                    return .block(b)
                case .round(var r):
                    r.blocks = r.blocks.map { b in var b = b; if ids.contains(b.id) { f(&b) }; return b }
                    return .round(r)
                }
            }
        }
    }

    func setDuration(_ seconds: Int, for ids: Set<UUID>? = nil) {
        let s = clamp(seconds)
        updateBlocks(ids ?? selection) { $0.seconds = s }
    }

    func setExerciseName(_ name: String?, for ids: Set<UUID>? = nil) {
        let n = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        updateBlocks(ids ?? selection) { $0.exerciseName = (n?.isEmpty ?? true) ? nil : n }
    }

    func setKind(_ kind: BlockKind, for ids: Set<UUID>? = nil) {
        updateBlocks(ids ?? selection) { $0.kind = kind }
    }

    /// Dupliziert die markierten Blöcke direkt hinter sich.
    func duplicateSelection() {
        let ids = selection
        var newIDs: Set<UUID> = []
        mutate { w in
            var out: [TimelineItem] = []
            for item in w.items {
                switch item {
                case .block(let b):
                    out.append(item)
                    if ids.contains(b.id) { let c = b.copy(); newIDs.insert(c.id); out.append(.block(c)) }
                case .round(var r):
                    var blocks: [Block] = []
                    for b in r.blocks {
                        blocks.append(b)
                        if ids.contains(b.id) { let c = b.copy(); newIDs.insert(c.id); blocks.append(c) }
                    }
                    r.blocks = blocks
                    out.append(.round(r))
                }
            }
            w.items = out
        }
        if !newIDs.isEmpty { selection = newIDs }
    }

    func deleteSelection() {
        let ids = selection
        mutate { w in
            w.items = w.items.compactMap { item in
                switch item {
                case .block(let b): return ids.contains(b.id) ? nil : item
                case .round(var r):
                    r.blocks.removeAll { ids.contains($0.id) }
                    return r.blocks.isEmpty ? nil : .round(r)
                }
            }
        }
        selection.removeAll()
    }

    /// Fasst die markierten, nebeneinander liegenden Blöcke zu einer Runde mit `repeats` Durchgängen zusammen.
    @discardableResult
    func makeRound(repeats: Int) -> UUID? {
        guard canMakeRound, repeats >= 1 else { return nil }
        let ids = selection
        let round = Round(repeats: min(repeats, 99), blocks: [])
        var roundID: UUID?
        mutate { w in
            let indices = w.items.indices.filter { if case .block(let b) = w.items[$0] { return ids.contains(b.id) }; return false }
            guard let first = indices.first else { return }
            var r = round
            r.blocks = indices.compactMap { if case .block(let b) = w.items[$0] { return b }; return nil }
            w.items.removeSubrange(first...indices.last!)
            w.items.insert(.round(r), at: first)
            roundID = r.id
        }
        selection.removeAll()
        return roundID
    }

    func setRepeats(_ n: Int, round id: UUID) {
        mutate { w in
            guard let i = w.items.firstIndex(where: { $0.id == id }), case .round(var r) = w.items[i] else { return }
            r.repeats = min(max(n, 1), 99)
            w.items[i] = .round(r)
        }
    }

    /// Löst eine Runde wieder in einzelne Blöcke auf (ein Durchgang).
    func dissolveRound(_ id: UUID) {
        mutate { w in
            guard let i = w.items.firstIndex(where: { $0.id == id }), case .round(let r) = w.items[i] else { return }
            w.items.replaceSubrange(i...i, with: r.blocks.map { .block($0) })
        }
    }

    /// Verschiebt einen Eintrag der Zeitleiste (Block oder Runde) an eine neue Position.
    func moveItem(_ id: UUID, to target: Int) {
        mutate { w in
            guard let from = w.items.firstIndex(where: { $0.id == id }) else { return }
            let item = w.items.remove(at: from)
            let t = min(max(target, 0), w.items.count)
            w.items.insert(item, at: t)
        }
    }

    /// Verschiebt einen Eintrag der Zeitleiste um eine Position.
    func moveItem(_ id: UUID, by delta: Int) {
        guard let i = workout.items.firstIndex(where: { $0.id == id }) else { return }
        let t = i + delta
        guard workout.items.indices.contains(t) else { return }
        moveItem(id, to: t)
    }

    /// Verschiebt einen Block um eine Stelle nach links (-1) oder rechts (+1), so wie man die Zeitleiste liest:
    /// Steht daneben eine Runde, wandert der Block hinein; am Rand einer Runde wandert er wieder hinaus.
    /// Damit ist jede Stelle auch ohne Ziehen erreichbar (Auswahl-Leiste, VoiceOver-Aktionen).
    func moveBlock(_ id: UUID, by delta: Int) {
        guard delta == 1 || delta == -1, let loc = location(of: id) else { return }
        if let inner = loc.inner {
            guard case .round(let r) = workout.items[loc.item] else { return }
            if r.blocks.indices.contains(inner + delta) {
                move(id, to: DropSlot(item: loc.item, inner: delta > 0 ? inner + 2 : inner - 1))
            } else {
                // Am Rand der Runde: hinaus, direkt davor bzw. dahinter.
                move(id, to: DropSlot(item: delta > 0 ? loc.item + 1 : loc.item))
            }
        } else {
            let t = loc.item + delta
            guard workout.items.indices.contains(t) else { return }
            if case .round(let r) = workout.items[t] {
                // In die Nachbarrunde hinein: von links kommend an den Anfang, von rechts kommend ans Ende.
                move(id, to: DropSlot(item: t, inner: delta > 0 ? 0 : r.blocks.count))
            } else {
                move(id, to: DropSlot(item: delta > 0 ? loc.item + 2 : loc.item - 1))
            }
        }
    }

    // MARK: Ziehen und Ablegen

    /// Legt einen Block oder eine ganze Runde an der Einfügestelle `slot` ab. Die Stelle bezieht sich auf die
    /// Anordnung vor dem Verschieben, so wie sie auf dem Bildschirm steht. Gibt zurück, ob sich etwas änderte.
    @discardableResult
    func move(_ id: UUID, to slot: DropSlot) -> Bool {
        let before = workout
        mutate { w in w = Self.moved(w, id: id, to: slot) }
        return workout != before
    }

    /// Ob das Ablegen an dieser Stelle etwas ändern würde (sonst braucht es keinen Einfügebalken).
    func wouldMove(_ id: UUID, to slot: DropSlot) -> Bool {
        Self.moved(workout, id: id, to: slot) != workout
    }

    /// Reine Umformung: das Training nach dem Verschieben. Unveränderte Rückgabe, wenn die Stelle nicht passt.
    static func moved(_ original: Workout, id: UUID, to slot: DropSlot) -> Workout {
        var w = original
        var target = slot
        // Ganze Runde: nur auf der obersten Ebene, Runden lassen sich nicht verschachteln.
        if let from = w.items.firstIndex(where: { $0.id == id }), case .round = w.items[from] {
            guard target.inner == nil else { return original }
            let item = w.items.remove(at: from)
            if target.item > from { target.item -= 1 }
            w.items.insert(item, at: min(max(target.item, 0), w.items.count))
            return w
        }
        // Block entfernen; die Einfügestelle an die neue Zählung anpassen.
        var block: Block?
        for i in w.items.indices {
            switch w.items[i] {
            case .block(let b) where b.id == id:
                block = b
                w.items.remove(at: i)
                if target.item > i { target.item -= 1 }
            case .round(var r):
                guard let j = r.blocks.firstIndex(where: { $0.id == id }) else { continue }
                block = r.blocks.remove(at: j)
                if r.blocks.isEmpty {
                    // Einziger Block der Runde: Die Runde verschwindet. In sich selbst ablegen ändert nichts.
                    if target.item == i, target.inner != nil { return original }
                    w.items.remove(at: i)
                    if target.item > i { target.item -= 1 }
                } else {
                    w.items[i] = .round(r)
                    if target.item == i, let inner = target.inner, inner > j { target.inner = inner - 1 }
                }
            default: continue
            }
            break
        }
        guard let b = block else { return original }
        if let inner = target.inner {
            guard w.items.indices.contains(target.item), case .round(var r) = w.items[target.item] else { return original }
            r.blocks.insert(b, at: min(max(inner, 0), r.blocks.count))
            w.items[target.item] = .round(r)
        } else {
            w.items.insert(.block(b), at: min(max(target.item, 0), w.items.count))
        }
        return w
    }

    /// Verschiebt einen Block (oder eine ganze Runde) vor den Block bzw. Eintrag `targetID` (Ziehen und Ablegen).
    /// Funktioniert auch aus einer Runde heraus, in eine Runde hinein und zwischen Runden. Gibt zurück, ob sich etwas änderte.
    @discardableResult
    func moveBlock(_ id: UUID, before targetID: UUID) -> Bool {
        guard id != targetID else { return false }
        // Eine ganze Runde (oder ein Block der obersten Ebene) vor einen anderen Eintrag der obersten Ebene.
        if let from = workout.items.firstIndex(where: { $0.id == id }), case .round = workout.items[from] {
            guard let to = workout.items.firstIndex(where: { $0.id == targetID || $0.blocks.contains { $0.id == targetID } }) else { return false }
            moveItem(id, to: from < to ? to - 1 : to)
            return true
        }
        guard location(of: id) != nil else { return false }
        let before = workout
        mutate { w in
            // 1. Block entfernen (leere Runde ebenfalls)
            var moved: Block?
            for i in w.items.indices {
                switch w.items[i] {
                case .block(let b) where b.id == id:
                    moved = b
                    w.items.remove(at: i)
                case .round(var r):
                    if let j = r.blocks.firstIndex(where: { $0.id == id }) {
                        moved = r.blocks.remove(at: j)
                        if r.blocks.isEmpty { w.items.remove(at: i) } else { w.items[i] = .round(r) }
                    }
                default: continue
                }
                if moved != nil { break }
            }
            guard let b = moved else { return }
            // 2. Vor dem Ziel einfügen: Eintrag der obersten Ebene oder Block in einer Runde
            if let t = w.items.firstIndex(where: { $0.id == targetID }) {
                w.items.insert(.block(b), at: t)
                return
            }
            for i in w.items.indices {
                if case .round(var r) = w.items[i], let j = r.blocks.firstIndex(where: { $0.id == targetID }) {
                    r.blocks.insert(b, at: j)
                    w.items[i] = .round(r)
                    return
                }
            }
            // Ziel nicht gefunden: Ausgangslage behalten
            w = before
        }
        return workout != before
    }
}
