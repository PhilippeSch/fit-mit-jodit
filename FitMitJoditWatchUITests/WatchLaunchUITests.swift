import XCTest

/// Watch-App ohne iPhone: Ruhezustand und Trainingsliste mit Testdaten.
final class WatchLaunchUITests: XCTestCase {
    func testIdleAndWorkoutList() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        XCTAssertTrue(app.otherElements["watchIdle"].waitForExistence(timeout: 20) || app.staticTexts["Kein Training läuft"].exists
                      || app.staticTexts["No workout running"].exists)
        app.swipeUp()
        XCTAssertTrue(app.buttons["watchWorkout-Zirkel 45/15"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["watchWorkout-Tabata"].exists)
    }
}
