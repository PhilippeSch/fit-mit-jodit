import XCTest

/// Laufansicht bei einem Drittel, der Hälfte und voller Breite (neben Platz für eine Musik-App),
/// dazu die Store-Screenshots. Screenshots werden nur gespeichert, wenn `SCREENSHOT_DIR` gesetzt ist
/// (xcodebuild: `TEST_RUNNER_SCREENSHOT_DIR=…`).
class ScreenshotAndWidthUITests: XCTestCase {
    var language: String { "de" }
    private var locale: String { language == "de" ? "de-DE" : "en-US" }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-screenshotData", "-AppleLanguages", "(\(language))",
                               "-AppleLocale", language == "de" ? "de_CH" : "en_US"] + extra
        app.launch()
        return app
    }

    private func startCircuit(_ app: XCUIApplication) {
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-Zirkel' OR identifier BEGINSWITH 'workout-Circuit'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.textFields["workoutName"].waitForExistence(timeout: 10))
        let start = app.buttons["start"]
        let ok = expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: start)
        wait(for: [ok], timeout: 5)
        start.tap()
        XCTAssertTrue(app.staticTexts["countdown"].waitForExistence(timeout: 10))
    }

    private func skip(_ app: XCUIApplication, times: Int) {
        for _ in 0..<times {
            if !app.buttons["skipForward"].exists { app.staticTexts["countdown"].tap() }
            XCTAssertTrue(app.buttons["skipForward"].waitForExistence(timeout: 5))
            app.buttons["skipForward"].tap()
        }
    }

    private func save(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else { return }
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "Device"
        let folder = URL(fileURLWithPath: dir).appendingPathComponent(locale)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? shot.pngRepresentation.write(to: folder.appendingPathComponent("\(device)-\(name).png"))
    }

    /// Countdown bleibt bei jeder Breite sichtbar, vollständig und gross genug.
    func testRunViewReadableAtThirdHalfAndFullWidth() {
        for fraction in ["0.33", "0.5", nil] as [String?] {
            let app = launch(["-autostart", "circuit4515"] + (fraction.map { ["-runWidthFraction", $0] } ?? []))
            XCTAssertTrue(app.staticTexts["countdown"].waitForExistence(timeout: 10))
            let countdown = app.staticTexts["countdown"]
            let window = app.windows.firstMatch.frame
            let available = window.width * CGFloat(Double(fraction ?? "1") ?? 1)
            XCTAssertTrue(countdown.exists, "Countdown fehlt bei \(fraction ?? "1")")
            XCTAssertGreaterThanOrEqual(countdown.frame.minX, -1, "Countdown links abgeschnitten bei \(fraction ?? "1")")
            XCTAssertLessThanOrEqual(countdown.frame.maxX, available + 1, "Countdown ragt über die Breite \(fraction ?? "1")")
            XCTAssertGreaterThan(countdown.frame.height, 60, "Countdown zu klein bei \(fraction ?? "1")")
            XCTAssertTrue(app.staticTexts["runTitle"].exists)
            app.terminate()
        }
    }

    func testStoreScreenshots() {
        let app = launch()
        if UIDevice.current.userInterfaceIdiom == .pad { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.buttons["newWorkout"].waitForExistence(timeout: 10))
        sleep(1)
        save("01-library")
        startOrOpenEditor(app)
        save("02-editor")
        let start = app.buttons["start"]
        start.tap()
        XCTAssertTrue(app.staticTexts["countdown"].waitForExistence(timeout: 10))
        skip(app, times: 1) // Vorlauf → Arbeit (Kniebeugen)
        sleep(5) // Knöpfe blenden sich aus
        save("03-run-work")
        skip(app, times: 1) // → Pause, «Gleich: Liegestütze»
        sleep(5)
        save("04-run-rest")
        app.terminate()
        if UIDevice.current.userInterfaceIdiom == .pad {
            let narrow = launch(["-runWidthFraction", "0.4", "-autostart", "circuit4515"])
            XCTAssertTrue(narrow.staticTexts["countdown"].waitForExistence(timeout: 10))
            skip(narrow, times: 1)
            sleep(5)
            save("05-run-narrow")
            narrow.terminate()
            // Querformat
            let land = launch()
            XCUIDevice.shared.orientation = .landscapeLeft
            sleep(2)
            startOrOpenEditor(land)
            save("06-landscape-editor")
            land.buttons["start"].tap()
            XCTAssertTrue(land.staticTexts["countdown"].waitForExistence(timeout: 10))
            skip(land, times: 1)
            sleep(5)
            save("07-landscape-run")
            XCUIDevice.shared.orientation = .portrait
        }
    }

    private func startOrOpenEditor(_ app: XCUIApplication) {
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-Zirkel' OR identifier BEGINSWITH 'workout-Circuit'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.textFields["workoutName"].waitForExistence(timeout: 10))
        let start = app.buttons["start"]
        let ok = expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: start)
        wait(for: [ok], timeout: 5)
        sleep(1)
    }
}

final class ScreenshotAndWidthUITestsEnglish: ScreenshotAndWidthUITests {
    override var language: String { "en" }
}
