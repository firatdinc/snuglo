import XCTest

// MARK: — GameFlowUITests
// Smoke tests for in-game pause/resume and back-to-menu navigation.
// Faz I-2: button.game.pause (was game.pause), button.menu.dailyPuzzle (was mainmenu.play_cta)

final class GameFlowUITests: SnugloAppUITestsBase {

    // MARK: — Private Helpers

    /// Navigates from the main menu to the game screen via the daily puzzle card.
    /// Fails the test immediately if any expected element is missing.
    private func launchGame(file: StaticString = #file, line: UInt = #line) {
        let dailyCard = app.buttons["button.menu.dailyPuzzle"]
        XCTAssertTrue(
            dailyCard.waitForExistence(timeout: 6),
            "button.menu.dailyPuzzle not found",
            file: file, line: line
        )
        dailyCard.tap()

        XCTAssertTrue(
            app.otherElements["game.grid"].waitForExistence(timeout: 5),
            "game.grid not visible after tapping daily puzzle card",
            file: file, line: line
        )
    }

    // MARK: — testPauseAndResume
    // Enters the game, pauses, verifies the resume button, resumes,
    // then confirms the game grid is still visible.

    func testPauseAndResume() throws {
        launchGame()

        let pauseButton = app.buttons["button.game.pause"]
        XCTAssertTrue(
            waitForElement(pauseButton, timeout: 3),
            "button.game.pause not found in HUD"
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
    // main menu daily puzzle card reappears.

    func testBackToMenu() throws {
        launchGame()

        let backButton = app.buttons["game.back"]
        XCTAssertTrue(
            waitForElement(backButton, timeout: 3),
            "game.back not found in HUD"
        )
        backButton.tap()

        let dailyCard = app.buttons["button.menu.dailyPuzzle"]
        XCTAssertTrue(
            waitForElement(dailyCard, timeout: 5),
            "button.menu.dailyPuzzle not visible after tapping game.back"
        )
    }
}
