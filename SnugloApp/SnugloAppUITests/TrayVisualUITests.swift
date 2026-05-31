import XCTest

// MARK: — TrayVisualUITests
// Captures the in-game piece tray so the single-row / no-overflow layout can be
// inspected visually.

final class TrayVisualUITests: XCTestCase {

    func test_captureGameTray() {
        let app = XCUIApplication()
        continueAfterFailure = false
        app.launchArguments = ["-UITestMode", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.buttons["tab.play"].firstMatch.tap()

        let daily = app.descendants(matching: .any)
            .matching(identifier: "button.menu.dailyPuzzle").firstMatch
        XCTAssertTrue(daily.waitForExistence(timeout: 8), "daily puzzle button not found")
        daily.tap()

        let game = app.descendants(matching: .any)
            .matching(identifier: "screen.game").firstMatch
        XCTAssertTrue(game.waitForExistence(timeout: 12), "game screen not reached")
        Thread.sleep(forTimeInterval: 1.5)

        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = "game-tray"
        att.lifetime = .keepAlways
        add(att)
    }
}
