import XCTest

// MARK: — SettingsThemeLanguageUITests
// Verifies the runtime (restart-free) language switch: changing the language
// picker updates already-rendered localized Text in-place, with NO relaunch.

final class SettingsThemeLanguageUITests: XCTestCase {

    private var app: XCUIApplication!

    private func screenElement(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func openSettings() {
        app = XCUIApplication()
        continueAfterFailure = false
        // Force English at launch so the baseline UI is English.
        app.launchArguments = ["-UITestMode", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let gear = screenElement("button.menu.settings")
        XCTAssertTrue(gear.waitForExistence(timeout: 8), "settings gear not found")
        gear.tap()

        XCTAssertTrue(
            screenElement("screen.settings").waitForExistence(timeout: 6),
            "settings screen not reached"
        )
    }

    func test_languageSwitchesInstantly_withoutRelaunch() {
        openSettings()

        let title = screenElement("title.settings")
        XCTAssertTrue(title.waitForExistence(timeout: 4))
        // Baseline: English.
        XCTAssertEqual(title.label, "Settings", "expected English baseline title")

        // Change language → Türkçe (label is identical across locales).
        let picker = screenElement("settings.language_picker")
        XCTAssertTrue(picker.waitForExistence(timeout: 4), "language picker not found")
        picker.tap()

        let turkce = app.buttons["Türkçe"].firstMatch
        XCTAssertTrue(turkce.waitForExistence(timeout: 4), "Türkçe menu item not found")
        turkce.tap()

        // The SAME on-screen title must now be Turkish — no relaunch performed.
        let became = NSPredicate(format: "label == %@", "Ayarlar")
        expectation(for: became, evaluatedWith: title, handler: nil)
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(
                error,
                "Title did not switch to Turkish in-place — current label: \(title.label)"
            )
        }
    }

    func test_themeSwitchesToDark_inPlace() {
        openSettings()

        // Switch theme → Dark (English menu item label).
        let picker = screenElement("settings.theme_picker")
        XCTAssertTrue(picker.waitForExistence(timeout: 4), "theme picker not found")
        picker.tap()

        // Dark menu item — label is localized, so try each language variant.
        var tapped = false
        for label in ["Dark", "Koyu", "Oscuro"] {
            let item = app.buttons[label].firstMatch
            if item.waitForExistence(timeout: 2) { item.tap(); tapped = true; break }
        }
        XCTAssertTrue(tapped, "Dark theme menu item not found")

        // Give the rebuild a moment, then capture the Settings screen for visual proof.
        XCTAssertTrue(screenElement("title.settings").waitForExistence(timeout: 4))
        Thread.sleep(forTimeInterval: 1.0)

        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "settings-dark-theme"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
