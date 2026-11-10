import XCTest
@testable import FitMitJodit

final class SmokeTests: XCTestCase {
    func testAppName() {
        XCTAssertEqual(AppInfo.displayName, "Fit mit Jodit")
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, "Fit mit Jodit")
    }
}
