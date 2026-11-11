import Foundation

/// Training als kurzer Link für einen QR-Code: `fitmitjodit://training?d=…`.
/// Kompakt (ohne IDs und Datumsangaben), komprimiert und Base64url-kodiert. Kein Server nötig:
/// Die iPhone-Kamera öffnet den Link direkt in der App.
enum ShareCode {
    static let scheme = "fitmitjodit"
    static let host = "training"

    private struct Payload: Codable {
        var v = 1
        var n: String
        var i: [Item]
        var t: Bool?        // Schlusspause überspringen (nur wenn false)
        var l: String?      // Spotify-Link
    }
    private struct B: Codable {
        var k: String
        var s: Int
        var e: String?
    }
    private struct Item: Codable {
        var b: B?
        var r: Int?
        var bs: [B]?
    }

    enum Failure: Error { case invalid }

    static func url(for w: Workout) -> URL? {
        func b(_ x: Block) -> B { B(k: x.kind.rawValue, s: x.seconds, e: x.hasName ? x.exerciseName : nil) }
        let items: [Item] = w.items.map {
            switch $0 {
            case .block(let x): return Item(b: b(x))
            case .round(let r): return Item(r: r.repeats, bs: r.blocks.map(b))
            }
        }
        let p = Payload(n: w.name, i: items, t: w.skipTrailingRest ? nil : false, l: w.spotifyLink)
        guard let json = try? JSONEncoder().encode(p),
              let packed = try? (json as NSData).compressed(using: .zlib) as Data else { return nil }
        var c = URLComponents()
        c.scheme = scheme
        c.host = host
        c.queryItems = [URLQueryItem(name: "d", value: base64url(packed))]
        return c.url
    }

    static func handles(_ url: URL) -> Bool { url.scheme == scheme && url.host == host }

    /// Neues Training (neue ID) aus dem Link. Wirft bei beschädigten oder unplausiblen Daten.
    static func workout(from url: URL) throws -> Workout {
        guard handles(url),
              let d = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "d" })?.value,
              let packed = data(base64url: d),
              let json = try? (packed as NSData).decompressed(using: .zlib) as Data,
              json.count < 200_000,
              let p = try? JSONDecoder().decode(Payload.self, from: json),
              !p.n.trimmingCharacters(in: .whitespaces).isEmpty, p.i.count <= 500 else { throw Failure.invalid }
        func block(_ b: B) throws -> Block {
            guard let k = BlockKind(rawValue: b.k), (1...3600).contains(b.s) else { throw Failure.invalid }
            return Block(kind: k, seconds: b.s, exerciseName: b.e.map { String($0.prefix(80)) })
        }
        let items: [TimelineItem] = try p.i.map { it in
            if let b = it.b { return .block(try block(b)) }
            if let r = it.r, let bs = it.bs, (1...99).contains(r), !bs.isEmpty, bs.count <= 100 {
                return .round(Round(repeats: r, blocks: try bs.map(block)))
            }
            throw Failure.invalid
        }
        var w = Workout(name: String(p.n.prefix(80)), items: items)
        w.skipTrailingRest = p.t ?? true
        if let l = p.l, case .success = SpotifyLink.validate(l) { w.spotifyLink = l }
        return w
    }

    private static func base64url(_ d: Data) -> String {
        d.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func data(base64url s: String) -> Data? {
        var b = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while b.count % 4 != 0 { b += "=" }
        return Data(base64Encoded: b)
    }
}
