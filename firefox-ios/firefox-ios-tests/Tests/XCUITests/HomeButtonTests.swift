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
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        waitUntilPageLoad()
        navigator.performAction(Action.GoToHomePage)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        if !iPad() {
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].label, "Search")
        }
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"), waitForLoading: true)
        waitUntilPageLoad()
        if iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        } else {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton])
        }

        XCUIDevice.shared.orientation = .landscapeRight
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()
        navigator.nowAt(NewTabScreen)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306883
    func testSwitchHomepageKeyboardRaisedUp() {
        // Open a new tab and load a web page
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()

        // Switch to Homepage by taping the home button
        navigator.performAction(Action.GoToHomePage)

        if iPad() {
            validateHomePageAndKeyboardRaisedUp(showKeyboard: true)
        } else {
            validateHomePageAndKeyboardRaisedUp(showKeyboard: false)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306881
    func testAppLaunchKeyboardNotRaisedUp() {
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        validateHomePageAndKeyboardRaisedUp()
    }

    private func validateHomePageAndKeyboardRaisedUp(showKeyboard: Bool = false) {
        // The home page is loaded. The keyboard is not raised up
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        if !showKeyboard {
            XCTAssertFalse(app.keyboards.element.isVisible(), "The keyboard is shown")
        } else {
            XCTAssertTrue(app.keyboards.element.isVisible(), "The keyboard is not shown")
        }
    }
}
