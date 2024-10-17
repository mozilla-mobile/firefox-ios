// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class HomeButtonTests: BaseTestCase {
    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306925
    func testGoHome() throws {
        if iPad() {
            waitForTabsButton()
            navigator.nowAt(NewTabScreen)
        }
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].waitAndTap()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].label, "Search")
        if iPad() {
            navigator.nowAt(NewTabScreen)
        }
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"), waitForLoading: true)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton])

        XCUIDevice.shared.orientation = .landscapeRight
        XCTAssertTrue(app.buttons["Home"].exists)
        app.buttons["Home"].tap()
        navigator.nowAt(NewTabScreen)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306883
    func testSwitchHomepageKeyboardNotRaisedUp() {
        // Open a new tab and load a web page
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()

        // Switch to Homepage by taping the home button
        app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].waitAndTap()

        validateHomePageAndKeyboardNotRaisedUp()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306881
    func testAppLaunchKeyboardNotRaisedUp() {
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        validateHomePageAndKeyboardNotRaisedUp()
    }

    private func validateHomePageAndKeyboardNotRaisedUp() {
        // The home page is loaded. The keyboard is not raised up
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        XCTAssertFalse(app.keyboards.element.isVisible(), "The keyboard is shown")
    }
}
