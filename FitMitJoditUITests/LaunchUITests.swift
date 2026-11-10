import XCTest

final class LaunchUITests: XCTestCase {
    /// Start ohne iCloud: Bibliothek mit den vier Vorlagen erscheint.
    func testLaunchShowsLibraryWithTemplates() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        XCTAssertTrue(app.buttons["newWorkout"].waitForExistence(timeout: 15))
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-'"))
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(rows.count, 4)
    }
}
