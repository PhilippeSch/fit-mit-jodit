import AVFoundation
import Observation

/// Installierte Stimmen des Geräts, im Hintergrund geladen.
///
/// `AVSpeechSynthesisVoice.speechVoices()` fragt einen Systemdienst ab und kann beim ersten Aufruf lange blockieren
/// (im Simulator viele Sekunden, auf Geräten spürbar). Früher lief der Aufruf auf dem Haupt-Thread, bei jedem
/// Aufbau der Stimmen-Karte und vor jeder Ansage: Die App reagierte beim ersten Start so lange nicht. Jetzt lädt
/// die App die Liste beim Start und nach Änderungen im Hintergrund und arbeitet sonst mit dem geladenen Stand.
@MainActor
@Observable
final class VoiceLibrary {
    static let shared = VoiceLibrary()

    private(set) var all: [AVSpeechSynthesisVoice] = []
    /// false, solange noch nie geladen wurde. Ansichten zeigen dann noch keinen Hinweis zur Stimme.
    private(set) var isLoaded = false
    @ObservationIgnored private var loading = false
    @ObservationIgnored private var reloadRequested = false

    /// Liste (neu) laden. Mehrfache Aufrufe während des Ladens werden zu einem weiteren Durchgang zusammengefasst.
    func reload() {
        if loading {
            reloadRequested = true
            return
        }
        loading = true
        Task.detached(priority: .userInitiated) {
            let voices = VoiceList(AVSpeechSynthesisVoice.speechVoices())
            await MainActor.run {
                self.all = voices.items
                self.isLoaded = true
                self.loading = false
                if self.reloadRequested {
                    self.reloadRequested = false
                    self.reload()
                }
            }
        }
    }
}

/// Trägt die geladene Liste vom Hintergrund auf den Haupt-Thread (die Stimmen-Objekte sind unveränderlich).
private struct VoiceList: @unchecked Sendable {
    let items: [AVSpeechSynthesisVoice]
    init(_ items: [AVSpeechSynthesisVoice]) { self.items = items }
}

/// Auswahl der Sprachausgabe. Die Standardstimmen von iOS klingen robotisch; deutlich natürlicher sind die
/// «Erweitert»- und «Premium»-Stimmen, die man in den iOS-Einstellungen laden kann
/// (Bedienungshilfen › Gesprochene Inhalte › Stimmen). Die App nimmt automatisch die beste installierte Stimme.
@MainActor
enum VoiceCatalog {
    /// Sprache der App: Deutsch oder Englisch.
    nonisolated static var appLanguage: String { Locale.current.language.languageCode?.identifier == "de" ? "de" : "en" }

    /// Installierte Stimmen der App-Sprache, beste zuerst (Premium, Erweitert, Standard; Deutschland vor Schweiz/Österreich).
    /// Leer, solange die Liste noch lädt.
    static func voices(language: String = appLanguage) -> [AVSpeechSynthesisVoice] {
        sorted(VoiceLibrary.shared.all, language: language)
    }

    /// Filtern und ordnen, getrennt vom Laden (für Tests).
    nonisolated static func sorted(_ all: [AVSpeechSynthesisVoice], language: String) -> [AVSpeechSynthesisVoice] {
        let preferredRegion = language == "de" ? "de-DE" : "en-US"
        return all
            .filter { $0.language.hasPrefix(language) }
            .filter { !$0.voiceTraits.contains(.isNoveltyVoice) }
            .sorted { a, b in
                if rank(a.quality) != rank(b.quality) { return rank(a.quality) > rank(b.quality) }
                if (a.language == preferredRegion) != (b.language == preferredRegion) { return a.language == preferredRegion }
                return a.name < b.name
            }
    }

    nonisolated static func rank(_ q: AVSpeechSynthesisVoiceQuality) -> Int {
        switch q {
        case .premium: return 3
        case .enhanced: return 2
        default: return 1
        }
    }

    nonisolated static func qualityLabel(_ q: AVSpeechSynthesisVoiceQuality) -> String {
        switch q {
        case .premium: return String(localized: "Premium")
        case .enhanced: return String(localized: "Erweitert")
        default: return String(localized: "Standard")
        }
    }

    /// Gewählte Stimme oder, falls keine gewählt oder nicht mehr installiert, die beste installierte.
    /// Solange die Liste noch lädt: nil, dann spricht iOS mit seiner Standardstimme (kein blockierender Aufruf).
    static func voice(identifier: String?) -> AVSpeechSynthesisVoice? {
        let library = VoiceLibrary.shared
        guard library.isLoaded else { return nil }
        if let identifier, let v = library.all.first(where: { $0.identifier == identifier }) { return v }
        return voices().first
    }

    /// Liegt nur eine Standardstimme vor? Dann zeigt die App den Hinweis zum Laden einer besseren.
    static var onlyBasicVoices: Bool {
        VoiceLibrary.shared.isLoaded && (voices().first.map { rank($0.quality) } ?? 1) < 2
    }
}
