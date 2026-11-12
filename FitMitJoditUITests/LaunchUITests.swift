import XCTest

final class LaunchUITests: XCTestCase {
    /// Start ohne iCloud: Bibliothek mit allen zwölf Vorlagen erscheint (Liste lädt Zeilen erst beim Scrollen).
    func testLaunchShowsLibraryWithTemplates() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        XCTAssertTrue(app.buttons["newWorkout"].waitForExistence(timeout: 15))
        let rows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-'"))
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5))
        var seen = Set<String>()
        for _ in 0..<6 {
            let before = seen.count
            seen.formUnion(rows.allElementsBoundByIndex.map(\.identifier))
            if seen.count == 12 { break }
            rows.firstMatch.swipeUp()
            if seen.count == before && before > 0 { rows.element(boundBy: max(rows.count - 1, 0)).swipeUp() }
        }
        XCTAssertEqual(seen.count, 12, "\(seen.sorted())")
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

/// Rückfragen über Vollbild-Darstellungen. Anlass (12.11.2026): Kam die Anfrage «Fernbedienung erlauben?» vom iPhone,
/// während auf dem iPad der Willkommensbildschirm stand, schloss sich dieser von selbst, die Anfrage ging verloren
/// und ein danach gestartetes Training lief ohne sichtbare Laufansicht.
final class PromptOverCoverUITests: XCTestCase {
    private func launch(_ extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-simulateInvitation", "-AppleLanguages", "(de)", "-AppleLocale", "de_CH"] + extra
        app.launch()
        return app
    }

    /// Anfrage über dem Willkommensbildschirm: Sie erscheint, und der Willkommensbildschirm bleibt bis «Los geht's».
    func testInvitationOverWelcomeKeepsWelcome() {
        let app = launch(["-showWelcome"])
        XCTAssertTrue(app.staticTexts["welcomeTitle"].waitForExistence(timeout: 10))
        let decline = app.alerts.buttons["Ablehnen"]
        XCTAssertTrue(decline.waitForExistence(timeout: 10), "Rückfrage erscheint nicht über dem Willkommensbildschirm")
        decline.tap()
        XCTAssertTrue(app.staticTexts["welcomeTitle"].waitForExistence(timeout: 5), "Willkommensbildschirm hat sich von selbst geschlossen")
        let start = app.buttons["welcomeStart"]
        var tries = 0
        while !start.isHittable && tries < 4 { app.swipeUp(); tries += 1 }
        start.tap()
        XCTAssertTrue(app.buttons["newWorkout"].waitForExistence(timeout: 10))
        // Danach lässt sich ein Training starten, und die Laufansicht ist zu sehen.
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'workout-'")).firstMatch
        if !app.buttons["start"].exists { row.tap() }
        XCTAssertTrue(app.buttons["start"].waitForExistence(timeout: 10))
        app.buttons["start"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["countdown"].waitForExistence(timeout: 10), "Training läuft, aber die Laufansicht fehlt")
    }

    /// Anfrage während eines laufenden Trainings: Sie erscheint über der Laufansicht, das Training läuft weiter.
    func testInvitationOverRunningWorkoutKeepsRunning() {
        let app = launch(["-autostart", "circuit4515"])
        let countdown = app.descendants(matching: .any)["countdown"].firstMatch
        XCTAssertTrue(countdown.waitForExistence(timeout: 10))
        let allow = app.alerts.buttons["Erlauben"]
        XCTAssertTrue(allow.waitForExistence(timeout: 10), "Rückfrage erscheint nicht über der Laufansicht")
        allow.tap()
        XCTAssertTrue(countdown.waitForExistence(timeout: 5), "Laufansicht hat sich geschlossen")
        sleep(1) // Rückfrage blendet aus
        // Die Laufansicht liegt weiter zuoberst und läuft: Die Bibliothek dahinter ist nicht erreichbar.
        XCTAssertTrue(countdown.isHittable, "Laufansicht ist nicht mehr zu sehen")
        XCTAssertFalse(app.buttons["newWorkout"].isHittable, "Training wurde beendet")
    }
}
