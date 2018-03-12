/* This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0. If a copy of the MPL was not distributed with this
 file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
class NightModeTests: BaseTestCase {

    private func nightModeOnOff() {
        navigator.goto(BrowserTabMenu)
        app.tables.cells["menu-NightMode"].tap()
        navigator.nowAt(BrowserTab)
    }

    private func checkNightModeOn() {
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables.cells["menu-NightMode"])
        XCTAssertTrue(app.tables.cells.images["enabled"].exists)
        navigator.goto(BrowserTab)
    }

    private func checkNightModeOff() {
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables.cells["menu-NightMode"])
        XCTAssertTrue(app.tables.cells.images["disabled"].exists)
        navigator.goto(BrowserTab)
    }

    func testNightModeUI() {
        let url1 = "www.google.com"

        // Go to a webpage, and select night mode on and off, check it's applied or not
        navigator.openNewURL(urlString: url1)

        //turn on the night mode
        nightModeOnOff()

        //checking night mode on or off
        checkNightModeOn()

        //turn off the night mode
        nightModeOnOff()

        //checking night mode on or off
        checkNightModeOff()
    }
}
