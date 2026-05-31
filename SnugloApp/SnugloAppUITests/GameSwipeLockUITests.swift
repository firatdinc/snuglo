import XCTest

// MARK: — GameSwipeLockUITests
// Verifies the game can't be swiped away (tab carousel + nav edge), and captures
// the modern quit dialog.

final class GameSwipeLockUITests: XCTestCase {

    private func launchIntoGame() -> XCUIApplication {
        let app = XCUIApplication()
        continueAfterFailure = true
        app.launchArguments = ["-UITestMode", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        app.buttons["tab.play"].firstMatch.tap()
        let daily = app.descendants(matching: .any).matching(identifier: "button.menu.dailyPuzzle").firstMatch
        XCTAssertTrue(daily.waitForExistence(timeout: 8))
        daily.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "screen.game").firstMatch.waitForExistence(timeout: 12))
        return app
    }

    private func inGame(_ app: XCUIApplication) -> Bool {
        app.descendants(matching: .any).matching(identifier: "screen.game").firstMatch.exists
    }

    func test_swipesDoNotLeaveGame() {
        let app = launchIntoGame()
        let mid = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
        let left = app.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.42))
        let right = app.coordinate(withNormalizedOffset: CGVector(dx: 0.96, dy: 0.42))
        let edge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.42))

        mid.press(forDuration: 0.05, thenDragTo: left)
        XCTAssertTrue(inGame(app), "centre swipe-left left the game")

        mid.press(forDuration: 0.05, thenDragTo: right)
        XCTAssertTrue(inGame(app), "centre swipe-right left the game")

        edge.press(forDuration: 0.05, thenDragTo: right)
        XCTAssertTrue(inGame(app), "edge swipe-back left the game")
    }

    func test_backButtonShowsModalAndQuits() {
        let app = launchIntoGame()
        app.descendants(matching: .any).matching(identifier: "game.back").firstMatch.tap()

        let confirm = app.descendants(matching: .any).matching(identifier: "dialog.confirm").firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 4), "modern quit dialog did not appear")

        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = "quit-dialog"
        att.lifetime = .keepAlways
        add(att)

        // Cancel keeps us in the game.
        app.descendants(matching: .any).matching(identifier: "dialog.cancel").firstMatch.tap()
        XCTAssertTrue(inGame(app), "cancel should keep the game")

        // Confirm quits back to the menu.
        app.descendants(matching: .any).matching(identifier: "game.back").firstMatch.tap()
        app.descendants(matching: .any).matching(identifier: "dialog.confirm").firstMatch.tap()
        XCTAssertTrue(
            app.descendants(matching: .any).matching(identifier: "button.menu.dailyPuzzle").firstMatch.waitForExistence(timeout: 6),
            "confirm should return to the main menu"
        )
    }
}
