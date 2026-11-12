import CoreGraphics
import Foundation

/// Einfügestelle in der Zeitleiste, bezogen auf die Anordnung vor dem Verschieben.
/// `inner == nil`: vor dem Eintrag `item` der obersten Ebene (`item == Anzahl` heisst ans Ende).
/// `inner != nil`: in der Runde `item`, vor deren Block `inner` (`inner == Anzahl` heisst ans Ende der Runde).
struct DropSlot: Equatable, Sendable {
    var item: Int
    var inner: Int?
}

/// Ergebnis der Suche: wohin abgelegt würde und wo der Einfügebalken steht.
struct DropTarget: Equatable, Sendable {
    var slot: DropSlot
    /// Einfügebalken im Koordinatenraum der Zeitleiste.
    var indicator: CGRect
    /// Runde, in die abgelegt würde (zum Hervorheben).
    var roundID: UUID?
}

/// Findet zu einem Punkt die nächstgelegene Einfügestelle. Jeder Punkt hat ein Ziel:
/// Man muss keine Kachel treffen, es zählt die nächste Lücke. Reine Geometrie, ohne SwiftUI, für Unit-Tests.
enum DropLocator {
    struct Entry {
        var id: UUID
        var frame: CGRect
        /// Blöcke einer Runde mit ihren Rahmen; `nil` für einen einzelnen Block.
        var blocks: [(id: UUID, frame: CGRect)]?
    }

    /// Randstreifen einer Runde, der noch als «davor» bzw. «danach» zählt.
    /// So lässt sich auch zwischen zwei Runden ablegen, die direkt untereinander stehen.
    static let roundEdge: CGFloat = 10
    static let barThickness: CGFloat = 5

    static func locate(point p: CGPoint, entries: [Entry], draggingRound: Bool) -> DropTarget? {
        guard !entries.isEmpty else { return nil }
        // 1. Ein Block über dem Inneren einer Runde landet in dieser Runde.
        if !draggingRound {
            for (i, e) in entries.enumerated() {
                guard let blocks = e.blocks, e.frame.insetBy(dx: 0, dy: roundEdge).contains(p) else { continue }
                let (index, bar) = slot(in: blocks.map(\.frame), at: p, fallback: e.frame)
                return DropTarget(slot: DropSlot(item: i, inner: index), indicator: bar, roundID: e.id)
            }
        }
        // 2. Oberste Ebene.
        let frames = entries.map(\.frame)
        let rows = rows(of: frames)
        guard let row = nearestRow(rows, to: p.y, frames: frames) else { return nil }
        // Eine Runde füllt ihre Zeile: oberhalb der Mitte davor, sonst danach, mit waagrechtem Balken.
        if row.count == 1, let i = row.first, entries[i].blocks != nil {
            let f = frames[i]
            let before = p.y < f.midY
            let y = before ? f.minY - gap(above: i, in: frames) / 2 : f.maxY + gap(below: i, in: frames) / 2
            let bar = CGRect(x: f.minX, y: y - barThickness / 2, width: f.width, height: barThickness)
            return DropTarget(slot: DropSlot(item: before ? i : i + 1), indicator: bar, roundID: nil)
        }
        let (index, bar) = slot(inRow: row, frames: frames, at: p)
        return DropTarget(slot: DropSlot(item: index), indicator: bar, roundID: nil)
    }

    // MARK: Zeilen

    /// Teilt Rahmen in Lesereihenfolge in Zeilen auf: Eine neue Zeile beginnt, wenn ein Rahmen unter der bisherigen Zeile liegt.
    static func rows(of frames: [CGRect]) -> [[Int]] {
        var out: [[Int]] = []
        var bottom = -CGFloat.infinity
        for (i, f) in frames.enumerated() {
            if out.isEmpty || f.minY >= bottom - 0.5 {
                out.append([i])
                bottom = f.maxY
            } else {
                out[out.count - 1].append(i)
                bottom = max(bottom, f.maxY)
            }
        }
        return out
    }

    private static func nearestRow(_ rows: [[Int]], to y: CGFloat, frames: [CGRect]) -> [Int]? {
        rows.min { distance(of: $0, to: y, frames: frames) < distance(of: $1, to: y, frames: frames) }
    }

    private static func distance(of row: [Int], to y: CGFloat, frames: [CGRect]) -> CGFloat {
        let minY = row.map { frames[$0].minY }.min() ?? 0, maxY = row.map { frames[$0].maxY }.max() ?? 0
        return y < minY ? minY - y : (y > maxY ? y - maxY : 0)
    }

    /// Einfügestelle in einer Zeile: vor dem ersten Rahmen, dessen Mitte rechts vom Punkt liegt, sonst hinter dem letzten.
    private static func slot(inRow row: [Int], frames: [CGRect], at p: CGPoint) -> (Int, CGRect) {
        let minY = row.map { frames[$0].minY }.min() ?? 0, maxY = row.map { frames[$0].maxY }.max() ?? 0
        func bar(_ x: CGFloat) -> CGRect { CGRect(x: x - barThickness / 2, y: minY, width: barThickness, height: maxY - minY) }
        for (n, i) in row.enumerated() where p.x < frames[i].midX {
            let x = n == 0 ? frames[i].minX - barThickness : (frames[row[n - 1]].maxX + frames[i].minX) / 2
            return (i, bar(x))
        }
        let last = row[row.count - 1]
        return (last + 1, bar(frames[last].maxX + barThickness))
    }

    /// Einfügestelle unter Geschwistern (Blöcke einer Runde): nächste Zeile, dann wie oben.
    private static func slot(in frames: [CGRect], at p: CGPoint, fallback: CGRect) -> (Int, CGRect) {
        let rows = rows(of: frames)
        guard let row = nearestRow(rows, to: p.y, frames: frames) else {
            return (0, CGRect(x: fallback.minX + 8, y: fallback.midY - 20, width: barThickness, height: 40))
        }
        return slot(inRow: row, frames: frames, at: p)
    }

    private static func gap(above i: Int, in frames: [CGRect]) -> CGFloat {
        i > 0 ? max(frames[i].minY - frames[i - 1].maxY, 4) : 12
    }

    private static func gap(below i: Int, in frames: [CGRect]) -> CGFloat {
        i + 1 < frames.count ? max(frames[i + 1].minY - frames[i].maxY, 4) : 12
    }
}
