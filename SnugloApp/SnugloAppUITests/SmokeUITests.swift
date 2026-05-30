import XCTest

// MARK: — SmokeUITests (Faz I-2 · updated Faz 2)
// 6 smoke tests that verify screen reachability via accessibility identifiers.
//
// Launch strategy:
//   Tests 1 & 2 (onboarding flow): -uitest-reset-progress  → first-launch state
//   Tests 3–6  (main-app nav):     -UITestMode              → skip splash/onboarding
//
// This mirrors HomeFlowUITests (which use -UITestMode) and avoids unreliable
// "skip onboarding during test" patterns that are sensitive to simulator timing.

final class SmokeUITests: XCTestCase {

    var app: XCUIApplication!

    // MARK: — Helpers: launch modes

    /// Launch as first-launch (onboarding visible, progress wiped).
    private func launchFirstLaunch() {
        app = XCUIApplication()
        continueAfterFailure = false
        app.launchArguments = ["-uitest-reset-progress"]
        app.launch()
    }

    /// Launch directly into the main app (onboarding + splash skipped).
    private func launchMainApp() {
        app = XCUIApplication()
        continueAfterFailure = false
        app.launchArguments = ["-UITestMode"]
        app.launch()
    }

    /// Returns an XCUIElement matching `identifier` across ALL accessibility element types.
    /// ZStack / VStack / ScrollView containers may be typed .other or .group; this query
    /// finds them regardless of type.
    private func screenElement(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
    }

    // MARK: — Test 1: splash → onboarding on first launch

    func test_splashReachesOnboarding_onFirstLaunch() {
        launchFirstLaunch()
        // PrimaryButton uses .buttonStyle(.plain) which may produce an .other accessibility
        // element type; use descendants(matching: .any) to search all types.
        let getStarted = app.descendants(matching: .any)
            .matching(identifier: "button.onboarding.getStarted")
            .firstMatch
        XCTAssertTrue(
            getStarted.waitForExistence(timeout: 15),
            "button.onboarding.getStarted not found — onboarding may not have appeared"
        )
    }

    // MARK: — Test 2: complete onboarding → main menu

    func test_completeOnboardingToMainMenu() {
        launchFirstLaunch()
        let skip = app.buttons["button.onboarding.skip"]
        if skip.waitForExistence(timeout: 12) {
            skip.tap()
        }
        // Verify main menu by finding a reliable interactive button (not a container identifier).
        let dailyPuzzle = app.buttons["button.menu.dailyPuzzle"]
        XCTAssertTrue(
            dailyPuzzle.waitForExistence(timeout: 12),
            "button.menu.dailyPuzzle not found after tapping onboarding skip — main menu did not load"
        )
    }

    // MARK: — Test 3: navigate to Shop tab

    func test_navigateToShop() {
        launchMainApp()
        app.buttons["tab.shop"].firstMatch.tap()
        XCTAssertTrue(
            screenElement("screen.shop").waitForExistence(timeout: 6),
            "screen.shop not found after tapping tab.shop"
        )
    }

    // MARK: — Test 4: navigate to Profile tab

    func test_navigateToProfile() {
        launchMainApp()
        app.buttons["tab.profile"].firstMatch.tap()
        XCTAssertTrue(
            screenElement("screen.profile").waitForExistence(timeout: 6),
            "screen.profile not found after tapping tab.profile"
        )
    }

    // MARK: — Test 5: navigate to Settings via gear icon

    func test_navigateToSettings() {
        launchMainApp()
        // Settings is no longer a tab (Faz 2: Play/Levels/Stats/Shop).
        // Access via gear icon (button.menu.settings) in the Play tab top bar.
        let settingsButton = app.buttons["button.menu.settings"]
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: 6),
            "button.menu.settings not found — main menu top bar may not have loaded"
        )
        settingsButton.tap()
        XCTAssertTrue(
            screenElement("screen.settings").waitForExistence(timeout: 6),
            "screen.settings not found after tapping button.menu.settings"
        )
    }

    // MARK: — Test 6: open daily puzzle → game screen

    func test_openDailyPuzzle() {
        launchMainApp()
        // Tap Play tab to ensure main menu is active, then open daily puzzle.
        app.buttons["tab.play"].firstMatch.tap()
        app.buttons["button.menu.dailyPuzzle"].firstMatch.tap()
        XCTAssertTrue(
            screenElement("screen.game").waitForExistence(timeout: 6),
            "screen.game not found after tapping button.menu.dailyPuzzle"
        )
    }
}
