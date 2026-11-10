import XCTest

final class LaunchUITests: XCTestCase {
    func testLaunchShowsTitle() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["appTitle"].waitForExistence(timeout: 10))
    }
}
