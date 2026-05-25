import XCTest

// MARK: — HomeFlowUITests
// Smoke tests for the main-menu tab bar and the primary play CTA flow.
// All identifiers use the convention established in Faz I-2 (see CHANGELOG).

final class HomeFlowUITests: SnugloAppUITestsBase {

    // MARK: — testRootTabsExist
    // Verifies that all four bottom tab-bar buttons are accessible
    // after the splash screen auto-advances (~1.2 s).

    func testRootTabsExist() throws {
        // Splash auto-advances in 1.2 s — give the tab bar up to 6 s to appear.
        let homeTab = app.buttons["tab.home"]
        XCTAssertTrue(
            waitForElement(homeTab, timeout: 6),
            "tab.home not found — BottomTabBar may not have appeared after Splash"
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

    // MARK: — testMainMenuShowsPlayCTA
    // Verifies that the primary play/continue CTA is visible on the main menu.

    func testMainMenuShowsPlayCTA() throws {
        let playCTA = app.buttons["mainmenu.play_cta"]
        XCTAssertTrue(
            waitForElement(playCTA, timeout: 6),
            "mainmenu.play_cta not found — Continue card may not have rendered"
        )
    }

    // MARK: — testTapPlayLaunchesGame
    // Taps the play CTA and verifies the game grid appears within 5 s.

    func testTapPlayLaunchesGame() throws {
        let playCTA = app.buttons["mainmenu.play_cta"]
        XCTAssertTrue(
            waitForElement(playCTA, timeout: 6),
            "mainmenu.play_cta not found before tap"
        )
        playCTA.tap()

        let grid = app.otherElements["game.grid"]
        XCTAssertTrue(
            waitForElement(grid, timeout: 5),
            "game.grid did not appear within 5 s after tapping mainmenu.play_cta"
        )
    }
}
