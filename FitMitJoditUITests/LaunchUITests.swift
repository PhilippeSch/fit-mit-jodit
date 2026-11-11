import XCTest

final class LaunchUITests: XCTestCase {
    /// Start ohne iCloud: Bibliothek mit den sechs Vorlagen erscheint.
    func testLaunchShowsLibraryWithTemplates() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        XCTAssertTrue(app.buttons["newWorkout"].waitForExistence(timeout: 15))
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-'"))
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(rows.count, 6)
    }
}

final class WelcomeAndPromoUITests: XCTestCase {
    /// Willkommensbildschirm beim ersten Start, danach die Bibliothek; Werbung für Jodit in den Einstellungen.
    func testWelcomeThenLibraryAndPromo() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-showWelcome"]
        app.launch()
        XCTAssertTrue(app.staticTexts["welcomeTitle"].waitForExistence(timeout: 10))
        // Hinweis zur Stimme mit Probehören (Simulator: nur einfache Stimmen → Anleitung zum Laden)
        XCTAssertTrue(app.buttons["welcomeVoiceSample"].waitForExistence(timeout: 5))
        let start = app.buttons["welcomeStart"]
        var tries = 0
        while !start.isHittable && tries < 4 { app.swipeUp(); tries += 1 }
        start.tap()
        XCTAssertTrue(app.buttons["newWorkout"].waitForExistence(timeout: 10))
        app.buttons["settings"].tap()
        XCTAssertTrue(app.switches["toggleTones"].waitForExistence(timeout: 5))
        let link = app.descendants(matching: .any)["promoLink"].firstMatch
        var t = 0
        while !link.exists && t < 6 { app.swipeUp(); t += 1 }
        XCTAssertTrue(link.exists, "Werbekarte mit Link zu fitmitjodit.ch fehlt")
    }
}
