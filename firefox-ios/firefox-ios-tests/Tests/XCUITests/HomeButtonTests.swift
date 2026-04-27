// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class HomeButtonTests: BaseTestCase {
    private var browserScreen: BrowserScreen!
    private var toolbarScreen: ToolbarScreen!

    override func setUp() async throws {
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
        try await super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306925
    func testGoHome() throws {
        browserScreen.navigateToURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        toolbarScreen.tapHomeButton()
        waitForTabsButton()
        if !iPad() {
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].label, "Search")
        }
        browserScreen.navigateToURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        toolbarScreen.assertNewTabButtonExists()

        XCUIDevice.shared.orientation = .landscapeRight
        toolbarScreen.tapOnNewTabButton()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306883
    func testSwitchHomepageKeyboardRaisedUp() {
        // Open a new tab and load a web page
        browserScreen.navigateToURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()

        // Switch to Homepage by taping the home button
        toolbarScreen.tapHomeButton()

        validateHomePageAndKeyboardRaisedUp(showKeyboard: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306881
    func testAppLaunchKeyboardNotRaisedUp() {
        toolbarScreen.assertSettingsButtonExists()
        validateHomePageAndKeyboardRaisedUp()
    }

    private func validateHomePageAndKeyboardRaisedUp(showKeyboard: Bool = false) {
        // The home page is loaded. The keyboard is not raised up
        waitForTabsButton()
        if !showKeyboard {
            XCTAssertFalse(app.keyboards.element.isVisible(), "The keyboard is shown")
        } else {
            XCTAssertTrue(app.keyboards.element.isVisible(), "The keyboard is not shown")
        }
    }
}
