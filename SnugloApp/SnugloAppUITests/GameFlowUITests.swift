import XCTest

// MARK: — GameFlowUITests
// Smoke tests for in-game pause/resume and back-to-menu navigation.

final class GameFlowUITests: SnugloAppUITestsBase {

    // MARK: — Private Helpers

    /// Navigates from the main menu to the game screen via the play CTA.
    /// Fails the test immediately if any expected element is missing.
    private func launchGame(file: StaticString = #file, line: UInt = #line) {
        let playCTA = app.buttons["mainmenu.play_cta"]
        XCTAssertTrue(
            playCTA.waitForExistence(timeout: 6),
            "mainmenu.play_cta not found",
            file: file, line: line
        )
        playCTA.tap()

        XCTAssertTrue(
            app.otherElements["game.grid"].waitForExistence(timeout: 5),
            "game.grid not visible after tapping play CTA",
            file: file, line: line
        )
    }

    // MARK: — testPauseAndResume
    // Enters the game, pauses, verifies the resume button, resumes,
    // then confirms the game grid is still visible.

    func testPauseAndResume() throws {
        launchGame()

        let pauseButton = app.buttons["game.pause"]
        XCTAssertTrue(
            waitForElement(pauseButton, timeout: 3),
            "game.pause button not found in HUD"
        )
        pauseButton.tap()

        let resumeButton = app.buttons["pause.resume"]
        XCTAssertTrue(
            waitForElement(resumeButton, timeout: 3),
            "pause.resume button not found in PauseSheet"
        )
        resumeButton.tap()

        // Grid should still be visible after dismissing the pause sheet.
        XCTAssertTrue(
            waitForElement(app.otherElements["game.grid"], timeout: 3),
            "game.grid not visible after resuming from pause"
        )
    }

    // MARK: — testBackToMenu
    // Enters the game, taps the back button, and verifies that the
    // main menu play CTA reappears.

    func testBackToMenu() throws {
        launchGame()

        let backButton = app.buttons["game.back"]
        XCTAssertTrue(
            waitForElement(backButton, timeout: 3),
            "game.back button not found in HUD"
        )
        backButton.tap()

        let playCTA = app.buttons["mainmenu.play_cta"]
        XCTAssertTrue(
            waitForElement(playCTA, timeout: 5),
            "mainmenu.play_cta not visible after tapping game.back"
        )
    }
}
