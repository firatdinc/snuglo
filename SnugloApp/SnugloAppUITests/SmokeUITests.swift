import XCTest

// MARK: — SmokeUITests (Faz I-2 · updated Faz 2)
// 6 smoke tests that verify screen reachability via accessibility identifiers.
// Launched with -uitest-reset-progress so every run starts from first-launch state.
// Faz 2 changes:
//   tab.home → tab.play
//   test_navigateToSettings → uses button.menu.settings (gear icon in top bar)

final class SmokeUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uitest-reset-progress"]
        app.launch()
    }

    // MARK: — Test 1: splash → onboarding on first launch

    func test_splashReachesOnboarding_onFirstLaunch() {
        // First launch: progress reset → onboarding shown after ~1.2 s splash
        let getStarted = app.buttons["button.onboarding.getStarted"]
        XCTAssertTrue(
            getStarted.waitForExistence(timeout: 5),
            "button.onboarding.getStarted not found — onboarding may not have appeared"
        )
    }

    // MARK: — Test 2: complete onboarding → main menu

    func test_completeOnboardingToMainMenu() {
        let getStarted = app.buttons["button.onboarding.getStarted"]
        if getStarted.waitForExistence(timeout: 5) {
            getStarted.tap()
        }
        let mainMenu = app.otherElements["screen.mainMenu"]
        XCTAssertTrue(
            mainMenu.waitForExistence(timeout: 4),
            "screen.mainMenu not found after tapping onboarding getStarted"
        )
    }

    // MARK: — Test 3: navigate to Shop tab

    func test_navigateToShop() {
        skipOnboardingIfPresent()
        app.buttons["tab.shop"].firstMatch.tap()
        let shopScreen = app.otherElements["screen.shop"]
        XCTAssertTrue(
            shopScreen.waitForExistence(timeout: 3),
            "screen.shop not found after tapping tab.shop"
        )
    }

    // MARK: — Test 4: navigate to Profile tab

    func test_navigateToProfile() {
        skipOnboardingIfPresent()
        app.buttons["tab.profile"].firstMatch.tap()
        let profile = app.otherElements["screen.profile"]
        XCTAssertTrue(
            profile.waitForExistence(timeout: 3),
            "screen.profile not found after tapping tab.profile"
        )
    }

    // MARK: — Test 5: navigate to Settings via gear icon

    func test_navigateToSettings() {
        skipOnboardingIfPresent()
        // Settings is no longer a tab (Faz 2: Play/Levels/Stats/Shop).
        // Access via gear icon (button.menu.settings) in the Play tab top bar.
        app.buttons["button.menu.settings"].firstMatch.tap()
        let settings = app.otherElements["screen.settings"]
        XCTAssertTrue(
            settings.waitForExistence(timeout: 3),
            "screen.settings not found after tapping button.menu.settings"
        )
    }

    // MARK: — Test 6: open daily puzzle → game screen

    func test_openDailyPuzzle() {
        skipOnboardingIfPresent()
        // Ensure play tab is active (daily puzzle card lives on the play tab)
        app.buttons["tab.play"].firstMatch.tap()
        app.buttons["button.menu.dailyPuzzle"].firstMatch.tap()
        let game = app.otherElements["screen.game"]
        XCTAssertTrue(
            game.waitForExistence(timeout: 5),
            "screen.game not found after tapping button.menu.dailyPuzzle"
        )
    }

    // MARK: — Helpers

    /// Taps getStarted if onboarding is shown; navigates to main menu.
    private func skipOnboardingIfPresent() {
        let getStarted = app.buttons["button.onboarding.getStarted"]
        if getStarted.waitForExistence(timeout: 4) {
            getStarted.tap()
        }
        // Wait for main menu to settle before each test
        _ = app.otherElements["screen.mainMenu"].waitForExistence(timeout: 3)
    }
}
