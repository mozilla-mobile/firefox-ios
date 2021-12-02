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
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        waitForExistence(app.buttons["TabToolbar.homeButton"], timeout: 5)
        XCTAssertTrue(app.buttons["TabToolbar.homeButton"].exists)
        app.buttons["TabToolbar.homeButton"].tap()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()

        XCTAssertEqual(app.buttons["TabToolbar.homeButton"].label, "Search")
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"), waitForLoading: true)
        waitForExistence(app.buttons["TabToolbar.homeButton"], timeout: 5)
        XCTAssertTrue(app.buttons["TabToolbar.homeButton"].exists)

        XCUIDevice.shared.orientation = .landscapeRight
        // TabToolbar.homeButton is 'masked' as 'Reload' for some reason
        // Issue: https://github.com/mozilla-mobile/firefox-ios/issues/9083
        XCTAssertTrue(app.buttons["Reload"].exists)
        app.buttons["Reload"].tap()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
    }
}
