import Foundation

/// Gemeinsame JSON-Kodierung. Datumswerte als ISO 8601 mit Millisekunden, damit Zeitstempel
/// zwischen iPhone, iPad und Uhr nicht auf ganze Sekunden gerundet werden.
enum FMJDateCoding {
    static func formatter() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }
}

extension JSONEncoder {
    static var fmj: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(FMJDateCoding.formatter().string(from: date))
        }
        e.outputFormatting = [.sortedKeys]
        return e
    }
}

extension JSONDecoder {
    static var fmj: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            if let date = FMJDateCoding.formatter().date(from: s) { return date }
            let plain = ISO8601DateFormatter()
            if let date = plain.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Ungültiges Datum: \(s)")
        }
        return d
    }
}
