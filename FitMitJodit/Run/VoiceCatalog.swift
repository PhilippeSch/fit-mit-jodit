import AVFoundation

/// Auswahl der Sprachausgabe. Die Standardstimmen von iOS klingen robotisch; deutlich natürlicher sind die
/// «Erweitert»- und «Premium»-Stimmen, die man in den iOS-Einstellungen laden kann
/// (Bedienungshilfen › Gesprochene Inhalte › Stimmen). Die App nimmt automatisch die beste installierte Stimme.
enum VoiceCatalog {
    /// Sprache der App: Deutsch oder Englisch.
    static var appLanguage: String { Locale.current.language.languageCode?.identifier == "de" ? "de" : "en" }

    /// Installierte Stimmen der App-Sprache, beste zuerst (Premium, Erweitert, Standard; Deutschland vor Schweiz/Österreich).
    static func voices(language: String = appLanguage) -> [AVSpeechSynthesisVoice] {
        let preferredRegion = language == "de" ? "de-DE" : "en-US"
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(language) }
            .filter { !$0.voiceTraits.contains(.isNoveltyVoice) }
            .sorted { a, b in
                if rank(a.quality) != rank(b.quality) { return rank(a.quality) > rank(b.quality) }
                if (a.language == preferredRegion) != (b.language == preferredRegion) { return a.language == preferredRegion }
                return a.name < b.name
            }
    }

    static func rank(_ q: AVSpeechSynthesisVoiceQuality) -> Int {
        switch q {
        case .premium: return 3
        case .enhanced: return 2
        default: return 1
        }
    }

    static func qualityLabel(_ q: AVSpeechSynthesisVoiceQuality) -> String {
        switch q {
        case .premium: return String(localized: "Premium")
        case .enhanced: return String(localized: "Erweitert")
        default: return String(localized: "Standard")
        }
    }

    /// Gewählte Stimme oder, falls keine gewählt oder nicht mehr installiert, die beste installierte.
    static func voice(identifier: String?) -> AVSpeechSynthesisVoice? {
        if let identifier, let v = AVSpeechSynthesisVoice(identifier: identifier) { return v }
        return voices().first ?? AVSpeechSynthesisVoice(language: appLanguage == "de" ? "de-DE" : "en-US")
    }

    /// Liegt nur eine Standardstimme vor? Dann zeigt die App den Hinweis zum Laden einer besseren.
    static var onlyBasicVoices: Bool { (voices().first.map { rank($0.quality) } ?? 1) < 2 }
}
