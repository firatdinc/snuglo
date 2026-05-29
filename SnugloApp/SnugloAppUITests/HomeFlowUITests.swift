import XCTest

// MARK: — HomeFlowUITests
// Smoke tests for the main-menu tab bar and the primary play CTA flow.
// Faz 2: identifiers updated to match Vibrant Play tab spec:
//   tab.play / tab.levels / tab.stats / tab.shop
//   button.menu.continue (unchanged)
//   button.menu.dailyPuzzle (unchanged)

final class HomeFlowUITests: SnugloAppUITestsBase {

    // MARK: — testRootTabsExist
    // Verifies that all four bottom tab-bar buttons are accessible
    // after the splash screen auto-advances (~1.2 s skipped in UITestMode).

    func testRootTabsExist() throws {
        // UITestMode skips splash delay; tab bar should appear almost immediately.
        let playTab = app.buttons["tab.play"]
        XCTAssertTrue(
            waitForElement(playTab, timeout: 6),
            "tab.play not found — BottomTabBar may not have appeared after Splash"
        )

        XCTAssertTrue(
            app.buttons["tab.levels"].waitForExistence(timeout: 2),
            "tab.levels not found"
        )
        XCTAssertTrue(
            app.buttons["tab.stats"].waitForExistence(timeout: 2),
            "tab.stats not found"
        )
        XCTAssertTrue(
            app.buttons["tab.shop"].waitForExistence(timeout: 2),
            "tab.shop not found"
        )
    }

    // MARK: — testMainMenuShowsDailyPuzzle
    // Verifies that the daily puzzle card is visible on the main menu play tab.

    func testMainMenuShowsDailyPuzzle() throws {
        let dailyCard = app.buttons["button.menu.dailyPuzzle"]
        XCTAssertTrue(
            waitForElement(dailyCard, timeout: 6),
            "button.menu.dailyPuzzle not found — daily puzzle card may not have rendered"
        )
    }

    // MARK: — testTapDailyPuzzleLaunchesGame
    // Taps the daily puzzle card and verifies the game grid appears within 5 s.

    func testTapDailyPuzzleLaunchesGame() throws {
        let dailyCard = app.buttons["button.menu.dailyPuzzle"]
        XCTAssertTrue(
            waitForElement(dailyCard, timeout: 6),
            "button.menu.dailyPuzzle not found before tap"
        )
        dailyCard.tap()

        let grid = app.otherElements["game.grid"]
        XCTAssertTrue(
            waitForElement(grid, timeout: 5),
            "game.grid did not appear within 5 s after tapping button.menu.dailyPuzzle"
        )
    }
}
