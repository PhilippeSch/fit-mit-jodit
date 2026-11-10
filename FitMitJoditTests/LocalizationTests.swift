import XCTest
@testable import FitMitJodit

/// Schlägt fehl, wenn ein Text nur in einer Sprache vorhanden ist.
final class LocalizationTests: XCTestCase {
    private func table(_ lang: String) -> [String: String]? {
        let bundle = Bundle(for: AppModel.self)
        guard let path = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: lang)
            ?? bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: "\(lang).lproj") else { return nil }
        return NSDictionary(contentsOfFile: path) as? [String: String]
    }

    /// Jeder Schlüssel des Katalogs hat eine englische Fassung (Deutsch ist die Ausgangssprache).
    func testEveryStringHasEnglishTranslation() throws {
        let url = try XCTUnwrap(Bundle(for: AppModel.self).url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: "en"),
                                "Keine englische Lokalisierung im App-Bundle")
        let en = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String])
        XCTAssertGreaterThan(en.count, 100)
        // Der Katalog im Quellcode ist massgebend: jeder Schlüssel braucht eine übersetzte en-Fassung.
        let catalogURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Shared/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(json["strings"] as? [String: Any])
        var missing: [String] = []
        for (key, value) in strings {
            let entry = value as? [String: Any]
            if (entry?["shouldTranslate"] as? Bool) == false { continue }
            let loc = entry?["localizations"] as? [String: Any]
            let unit = (loc?["en"] as? [String: Any])?["stringUnit"] as? [String: Any]
            let state = unit?["state"] as? String
            let text = unit?["value"] as? String ?? ""
            let hasVariations = (loc?["en"] as? [String: Any])?["variations"] != nil
            if !(hasVariations || (state == "translated" && !text.isEmpty)) { missing.append(key) }
        }
        XCTAssertTrue(missing.isEmpty, "Nur auf Deutsch: \(missing.sorted())")
    }

    func testBlockLabelsDifferPerLanguage() throws {
        let en = try XCTUnwrap(table("en"))
        XCTAssertEqual(en["Arbeit"], "Work")
        XCTAssertEqual(en["Pause"], "Rest")
        XCTAssertNotNil(en["Bereit machen"])
    }
}
