import XCTest
@testable import FitMitJodit

final class ShareCodeTests: XCTestCase {
    func testRoundTripKeepsEverythingButIDs() throws {
        for var w in Templates.all() {
            w.skipTrailingRest = false
            w.spotifyLink = "https://open.spotify.com/playlist/37i9dQZF1DXdxcBWuJkbcy"
            let url = try XCTUnwrap(ShareCode.url(for: w))
            let back = try ShareCode.workout(from: url)
            XCTAssertNotEqual(back.id, w.id, "neues Training, keine Übernahme der ID")
            XCTAssertEqual(back.name, w.name)
            XCTAssertEqual(StepSequence.expand(back), StepSequence.expand(w))
            XCTAssertEqual(back.skipTrailingRest, false)
            XCTAssertEqual(back.spotifyLink, w.spotifyLink)
        }
    }

    /// Der QR-Code muss sich vom iPad aus der Distanz scannen lassen: Link kurz halten.
    func testLinkIsShortEnoughForQRCode() throws {
        let url = try XCTUnwrap(ShareCode.url(for: Templates.fullBody))
        XCTAssertLessThan(url.absoluteString.count, 700, url.absoluteString)
        XCTAssertNotNil(QRCode.image(for: url.absoluteString))
    }

    func testRejectsBrokenOrForeignLinks() {
        for s in ["fitmitjodit://training?d=kaputt", "fitmitjodit://training", "https://example.com/training?d=abc",
                  "fitmitjodit://anderes?d=abc"] {
            XCTAssertThrowsError(try ShareCode.workout(from: URL(string: s)!), s)
        }
    }
}
