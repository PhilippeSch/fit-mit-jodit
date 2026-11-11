import SwiftUI
#if os(iOS)
import UIKit

extension Font.TextStyle {
    var uiStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .callout: return .callout
        case .caption: return .caption1
        case .caption2: return .caption2
        case .footnote: return .footnote
        default: return .body
        }
    }
}
#endif

/// Zentrale Farben und Schriften. Die drei Blockfarben sind fest und unabhängig von der Markenfarbe.
/// Alle drei erreichen mit weisser Schrift mindestens Kontrast 4.5:1 (WCAG AA).
enum Theme {
    /// Arbeit: Grün (#1B7F3B, Kontrast zu Weiss 5.1:1)
    static let work = Color(red: 0x1B / 255, green: 0x7F / 255, blue: 0x3B / 255)
    /// Pause: Orange (#C2410C, Kontrast zu Weiss 5.2:1)
    static let rest = Color(red: 0xC2 / 255, green: 0x41 / 255, blue: 0x0C / 255)
    /// Vorbereitung: Blau (#1D4ED8, Kontrast zu Weiss 6.7:1)
    static let prep = Color(red: 0x1D / 255, green: 0x4E / 255, blue: 0xD8 / 255)

    /// Markenfarbe für Bibliothek, Baukasten und Knöpfe. Abgeleitet aus fitmitjodit.ch (Text #404040,
    /// Akzent #7A7575): warmes Dunkelgrau #5E5858 (hell) bzw. #756D6D (dunkel; Weiss darauf ≥ 4.5:1), Asset «AccentColor».
    static let brand = Color("AccentColor")
    /// Dunkler Grund wie im App-Icon.
    static let ink = Color(red: 0x14 / 255, green: 0x16 / 255, blue: 0x1C / 255)

    static func color(for kind: BlockKind) -> Color {
        switch kind {
        case .work: return work
        case .rest: return rest
        case .prep: return prep
        }
    }

    /// Titel-Schrift wie auf fitmitjodit.ch: Raleway (SIL Open Font License, in der App gebündelt).
    /// Auf der Uhr und im Widget nicht gebündelt: dort Systemschrift.
    static func title(_ style: Font.TextStyle = .title2, weight: Font.Weight = .bold) -> Font {
        #if os(iOS)
        if UIFont(name: "Raleway", size: 12) != nil {
            return Font.custom("Raleway", size: UIFont.preferredFont(forTextStyle: style.uiStyle).pointSize, relativeTo: style).weight(weight)
        }
        #endif
        return Font.system(style, design: .default).weight(weight)
    }

    /// Schrift für den grossen Countdown: monospaced Ziffern, damit nichts springt.
    static func countdownFont(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
    }
}

extension BlockKind {
    /// Typ als Text, Farbe ist nie das einzige Merkmal.
    var label: String {
        switch self {
        case .work: return String(localized: "Arbeit", comment: "Blocktyp")
        case .rest: return String(localized: "Pause", comment: "Blocktyp")
        case .prep: return String(localized: "Vorbereitung", comment: "Blocktyp")
        }
    }

    var symbolName: String {
        switch self {
        case .work: return "figure.run"
        case .rest: return "pause.circle"
        case .prep: return "hourglass"
        }
    }
}

extension Step {
    /// Anzeigename: Übungsname oder Typ («Arbeit», «Pause», beim Vorlauf «Bereit machen»).
    var displayName: String {
        if isLeadIn { return String(localized: "Bereit machen", comment: "Vorlauf vor dem ersten Block") }
        if let n = exerciseName, hasName { return n }
        return kind.label
    }
}

extension Block {
    var displayName: String {
        if let n = exerciseName, hasName { return n }
        return kind.label
    }
}

enum DurationFormat {
    /// 45 -> «0:45», 90 -> «1:30», 3600 -> «1:00:00».
    static func clock(_ seconds: Int) -> String {
        let s = max(seconds, 0)
        if s >= 3600 { return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60) }
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// Kurzform für Kacheln: «45 s», «1 min», «1:30 min».
    static func short(_ seconds: Int) -> String {
        if seconds < 60 { return String(localized: "\(seconds) s", comment: "Sekunden kurz") }
        if seconds % 60 == 0 { return String(localized: "\(seconds / 60) min", comment: "Minuten kurz") }
        return String(localized: "\(clock(seconds)) min", comment: "Minuten und Sekunden kurz")
    }
}
