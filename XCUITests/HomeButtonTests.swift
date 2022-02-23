// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

class HomeButtonTests: BaseTestCase {

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    func testGoHome() throws {
        if iPad() {
            waitForTabsButton()
            navigator.performAction(Action.CloseURLBarOpen)
            navigator.nowAt(NewTabScreen)
        }
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton], timeout: 5)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].exists)
        app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].tap()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()

        if iPad() {
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].label, "Menu")
        } else {
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].label, "Search")
        }
        if iPad() {
            navigator.nowAt(NewTabScreen)
        }
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"), waitForLoading: true)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton], timeout: 5)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].exists)

        XCUIDevice.shared.orientation = .landscapeRight
        XCTAssertTrue(app.buttons["Home"].exists)
        app.buttons["Home"].tap()
        navigator.nowAt(NewTabScreen)
    }
}
