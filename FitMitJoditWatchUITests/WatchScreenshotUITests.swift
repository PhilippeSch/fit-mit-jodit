import XCTest

/// Store-Screenshots der Watch-App (Arbeit, Pause, Trainingsliste) in Deutsch und Englisch.
class WatchScreenshotUITests: XCTestCase {
    var language: String { "de" }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s); a.name = name; a.lifetime = .keepAlways; add(a)
        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else { return }
        let folder = URL(fileURLWithPath: dir).appendingPathComponent(language == "de" ? "de-DE" : "en-US")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "Watch"
        try? s.pngRepresentation.write(to: folder.appendingPathComponent("\(device)-\(name).png"))
    }

    private func launch(_ extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-AppleLanguages", "(\(language))"] + extra
        app.launch()
        return app
    }

    func testWatchScreenshots() {
        var app = launch(["-watchDemoRun"])
        XCTAssertTrue(app.staticTexts["watchCountdown"].waitForExistence(timeout: 20))
        shot(app, "01-run-work")
        app.terminate()
        app = launch(["-watchDemoRest"])
        XCTAssertTrue(app.staticTexts["watchCountdown"].waitForExistence(timeout: 20))
        shot(app, "02-run-rest")
        app.swipeUp()
        sleep(1)
        shot(app, "03-workouts")
    }
}

final class WatchScreenshotUITestsEnglish: WatchScreenshotUITests {
    override var language: String { "en" }
}
