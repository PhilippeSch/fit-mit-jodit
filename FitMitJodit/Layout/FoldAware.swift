import SwiftUI

/// Falz des iPhone Duo (aufgeklappt). Abgefragt über die reservierten Regionen vom Typ `.division`
/// (SwiftUI, ab iOS 27.1, siehe Apples Tech Talk «Prepare your app for iPhone Duo»).
/// Auf allen anderen Geräten und Systemversionen: nil, das Layout richtet sich dann nur nach der Fläche.
struct FoldInfo: Equatable {
    /// Bereich des Falzes in lokalen Koordinaten der Ansicht.
    var rect: CGRect
    /// true, wenn der Falz senkrecht verläuft (links/rechts geteilt).
    var isVertical: Bool

    /// Fläche links/oben und rechts/unten des Falzes.
    func halves(in size: CGSize) -> (first: CGRect, second: CGRect) {
        if isVertical {
            return (CGRect(x: 0, y: 0, width: max(rect.minX, 0), height: size.height),
                    CGRect(x: rect.maxX, y: 0, width: max(size.width - rect.maxX, 0), height: size.height))
        }
        return (CGRect(x: 0, y: 0, width: size.width, height: max(rect.minY, 0)),
                CGRect(x: 0, y: rect.maxY, width: size.width, height: max(size.height - rect.maxY, 0)))
    }
}

extension GeometryProxy {
    /// Aktiver Falz, der diese Ansicht schneidet, sonst nil.
    var fold: FoldInfo? {
        if #available(iOS 27.1, *) {
            let bounds = CGRect(origin: .zero, size: size)
            for r in reservedRegions(kind: .division) where r.isActive {
                let f = r.frame.intersection(bounds)
                guard !f.isNull, !f.isEmpty || f.width > 0 || f.height > 0 else { continue }
                // Nur ein Falz, der die Ansicht tatsächlich durchquert, teilt das Layout.
                let vertical = r.frame.height >= r.frame.width
                if vertical, f.minX > 40, f.maxX < size.width - 40 { return FoldInfo(rect: f, isVertical: true) }
                if !vertical, f.minY > 40, f.maxY < size.height - 40 { return FoldInfo(rect: f, isVertical: false) }
            }
        }
        return nil
    }
}
