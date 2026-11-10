import XCTest

final class WatchLaunchUITests: XCTestCase {
    func testWatchLaunchShowsTitle() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["watchTitle"].waitForExistence(timeout: 20))
    }
}
