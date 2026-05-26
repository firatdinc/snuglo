import XCTest

// MARK: — HomeFlowUITests
// Smoke tests for the main-menu tab bar and the primary play CTA flow.
// Faz I-2: identifiers updated to match new tab spec:
//   tab.home / tab.stats / tab.shop / tab.settings
//   button.menu.continue (was mainmenu.play_cta)
//   button.menu.dailyPuzzle (was mainmenu.daily_card)

final class HomeFlowUITests: SnugloAppUITestsBase {

    // MARK: — testRootTabsExist
    // Verifies that all four bottom tab-bar buttons are accessible
    // after the splash screen auto-advances (~1.2 s skipped in UITestMode).

    func testRootTabsExist() throws {
        // UITestMode skips splash delay; tab bar should appear almost immediately.
        let homeTab = app.buttons["tab.home"]
        XCTAssertTrue(
            waitForElement(homeTab, timeout: 6),
            "tab.home not found — BottomTabBar may not have appeared after Splash"
        )

        XCTAssertTrue(
            app.buttons["tab.stats"].waitForExistence(timeout: 2),
            "tab.stats not found"
        )
        XCTAssertTrue(
            app.buttons["tab.shop"].waitForExistence(timeout: 2),
            "tab.shop not found"
        )
        XCTAssertTrue(
            app.buttons["tab.settings"].waitForExistence(timeout: 2),
            "tab.settings not found"
        )
    }

    // MARK: — testMainMenuShowsDailyPuzzle
    // Verifies that the daily puzzle card is visible on the main menu home tab.

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
