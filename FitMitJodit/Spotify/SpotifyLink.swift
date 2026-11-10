import SwiftUI
import UIKit

/// Verlinkung nach Spotifys Anleitung «iOS Content Linking» (developer.spotify.com/documentation/ios/tutorials/content-linking).
/// Kein SDK, keine Web API, kein Login. Nur Links.
enum SpotifyLink {
    static let contentTypes: Set<String> = ["playlist", "album", "artist", "track", "show", "episode"]
    static let appStoreURL = URL(string: "https://itunes.apple.com/app/spotify-music/id324684580?mt=8")!

    enum ValidationError: Error, Equatable {
        case empty
        case notSpotify
        case unsupportedType
        case missingID
    }

    /// Prüft einen eingefügten Link und gibt den kanonischen open.spotify.com-Link zurück.
    /// Akzeptiert open.spotify.com-Links (auch mit «intl-de»-Präfix) und spotify:-URIs.
    static func validate(_ input: String) -> Result<URL, ValidationError> {
        let s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return .failure(.empty) }
        var type = ""
        var id = ""
        if s.lowercased().hasPrefix("spotify:") {
            let parts = s.split(separator: ":").map(String.init)
            guard parts.count >= 3 else { return .failure(.missingID) }
            type = parts[1].lowercased()
            id = parts[2]
        } else {
            guard let url = URL(string: s.hasPrefix("http") ? s : "https://" + s),
                  let host = url.host?.lowercased(), host == "open.spotify.com" else { return .failure(.notSpotify) }
            var comps = url.pathComponents.filter { $0 != "/" }
            if let first = comps.first, first.lowercased().hasPrefix("intl-") { comps.removeFirst() }
            guard comps.count >= 1 else { return .failure(.unsupportedType) }
            type = comps[0].lowercased()
            guard comps.count >= 2 else { return .failure(.missingID) }
            id = comps[1]
        }
        guard contentTypes.contains(type) else { return .failure(.unsupportedType) }
        let allowed = CharacterSet.alphanumerics
        guard !id.isEmpty, id.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return .failure(.missingID) }
        return .success(URL(string: "https://open.spotify.com/\(type)/\(id)")!)
    }

    static func message(for error: ValidationError) -> String {
        switch error {
        case .empty: return String(localized: "Bitte einen Spotify-Link einfügen.")
        case .notSpotify: return String(localized: "Das ist kein Spotify-Link. Erwartet wird ein Link von open.spotify.com.")
        case .unsupportedType: return String(localized: "Dieser Spotify-Link zeigt nicht auf eine Playlist, ein Album, einen Song, eine Künstlerin oder einen Podcast.")
        case .missingID: return String(localized: "Der Link ist unvollständig. Kopiere ihn in Spotify über «Teilen» → «Link kopieren».")
        }
    }

    static var bundleID: String { Bundle.main.bundleIdentifier ?? "ch.fitmitjodit.timer" }

    /// Link zum Öffnen in der installierten Spotify-App.
    static func appLink(for canonical: URL?) -> URL {
        var c = URLComponents(string: "https://spotify.link/content_linking")!
        var items = [URLQueryItem(name: "~campaign", value: bundleID)]
        if let canonical { items.append(URLQueryItem(name: "$canonical_url", value: canonical.absoluteString)) }
        c.queryItems = items
        // `$` und `~` sind in Query-Werten erlaubt, aber die URL des Werts muss kodiert sein.
        c.percentEncodedQuery = c.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return c.url!
    }

    /// Weblink mit Kampagnen-Parameter für den Browser.
    static func webLink(for canonical: URL) -> URL {
        var c = URLComponents(url: canonical, resolvingAgainstBaseURL: false)!
        var items = c.queryItems ?? []
        items.append(URLQueryItem(name: "utm_campaign", value: bundleID))
        c.queryItems = items
        return c.url!
    }

    @MainActor
    static var isInstalled: Bool { UIApplication.shared.canOpenURL(URL(string: "spotify:")!) }

    /// Öffnet den gespeicherten Inhalt in Spotify. Ohne Link öffnet Spotify allgemein.
    @MainActor
    static func open(_ stored: String?) {
        let canonical = stored.flatMap { try? validate($0).get() }
        let target: URL
        if isInstalled {
            target = canonical.map { appLink(for: $0) } ?? URL(string: "spotify:")!
        } else if let canonical {
            target = webLink(for: canonical)
        } else {
            target = appStoreURL
        }
        UIApplication.shared.open(target)
    }
}

/// Knopf «In Spotify öffnen», nur Text, kein Logo (Spotifys Gestaltungsrichtlinien).
struct SpotifyButton: View {
    let link: String?

    var body: some View {
        Button {
            SpotifyLink.open(link)
        } label: {
            Label(String(localized: "In Spotify öffnen"), systemImage: "music.note")
        }
        .accessibilityIdentifier("openSpotify")
    }
}

struct SpotifyLinkSheet: View {
    @State private var text: String
    @State private var error: String?
    let onDone: (String?) -> Void

    init(initial: String, onDone: @escaping (String?) -> Void) {
        _text = State(initialValue: initial)
        self.onDone = onDone
    }

    var body: some View {
        Form {
            Section {
                TextField(String(localized: "https://open.spotify.com/playlist/…"), text: $text, axis: .vertical)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("spotifyField")
                if let error {
                    Text(error).foregroundStyle(.red).font(.footnote)
                        .accessibilityIdentifier("spotifyError")
                }
            } footer: {
                Text("In Spotify bei der Playlist oder dem Album «Teilen» → «Link kopieren» wählen und hier einfügen. Die App öffnet damit nur Spotify, sie steuert die Wiedergabe nicht.")
            }
            Section {
                Button(String(localized: "Sichern")) {
                    switch SpotifyLink.validate(text) {
                    case .success(let url): onDone(url.absoluteString)
                    case .failure(let e): error = SpotifyLink.message(for: e)
                    }
                }
                .accessibilityIdentifier("saveSpotify")
                if !text.isEmpty {
                    Button(String(localized: "Link entfernen"), role: .destructive) { onDone(nil) }
                }
            }
        }
        .navigationTitle(Text("Spotify-Link"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
