/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class NoImageTests: BaseTestCase {

    var navigator: Navigator!
    var app: XCUIApplication!
    static let NoImageButtonIdentifier = "menu-NoImageMode"

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }

    override func tearDown() {
        navigator = nil
        app = nil
        super.tearDown()
    }

    private func showImages() {
        navigator.goto(BrowserTabMenu)
        app.tables.cells[NoImageTests.NoImageButtonIdentifier].tap()
        navigator.nowAt(BrowserTab)
    }

    private func hideImages() {
        navigator.goto(BrowserTabMenu)
        app.tables.cells[NoImageTests.NoImageButtonIdentifier].tap()
        navigator.nowAt(BrowserTab)
    }

    private func checkShowImages() {
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables.cells[NoImageTests.NoImageButtonIdentifier])
        navigator.goto(BrowserTab)
    }

    private func checkHideImages() {
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables.cells[NoImageTests.NoImageButtonIdentifier])
        navigator.goto(BrowserTab)
    }

    // Functionality is tested by UITests/NoImageModeTests, here only the UI is updated properly
    func testImageOnOff() {
        // Go to a webpage, and select no images or hide images, check it's hidden or not
        navigator.openNewURL(urlString: "www.google.com")
        waitUntilPageLoad()

        // Select hide images, and check the UI is updated
        hideImages()
        checkShowImages()

        // Select show images, and check the UI is updated
        showImages()
        checkHideImages()
    }
}
