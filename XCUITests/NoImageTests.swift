/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let NoImageButtonIdentifier = "menu-NoImageMode"
let ContextMenuIdentifier = "Context Menu"

class NoImageTests: BaseTestCase {
    private func showImages() {
        navigator.goto(BrowserTabMenu)
        app.tables[ContextMenuIdentifier].cells[NoImageButtonIdentifier].tap()
        navigator.nowAt(BrowserTab)
    }

    private func hideImages() {
        navigator.goto(BrowserTabMenu)
        app.tables.cells[NoImageButtonIdentifier].tap()
        navigator.nowAt(BrowserTab)
    }

    private func checkShowImages() {
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables.cells[NoImageButtonIdentifier])
        navigator.goto(BrowserTab)
    }

    private func checkHideImages() {
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables.cells[NoImageButtonIdentifier])
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
