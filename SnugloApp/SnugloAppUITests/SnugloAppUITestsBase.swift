import XCTest

// MARK: — SnugloAppUITestsBase
// Base class for all XCUITest smoke tests.
// Launches the app with the -UITestMode argument so the app can optionally
// set up isolated state (e.g. in-memory UserDefaults). If the app does not
// handle the flag it is ignored; smoke tests remain green.

class SnugloAppUITestsBase: XCTestCase {

    // MARK: — Properties

    var app: XCUIApplication!

    // MARK: — Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["-UITestMode"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // MARK: — Helpers

    /// Wait for an element to exist within the given timeout.
    /// Returns `true` if the element appeared, `false` on timeout.
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }
}
