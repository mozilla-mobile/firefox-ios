/* This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0. If a copy of the MPL was not distributed with this
 file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
class NightModeTests: BaseTestCase {
    private func nightModeOff() {
        navigator.goto(BrowserTabMenu)
        app.tables.cells["Disable Night Mode"].tap()
        navigator.nowAt(BrowserTab)
    }

    private func nightModeOn() {
        navigator.goto(BrowserTabMenu)
        app.tables.cells["Enable Night Mode"].tap()
        navigator.nowAt(BrowserTab)
    }

    private func checkNightModeOn() {
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables.cells["Disable Night Mode"])
        navigator.goto(BrowserTab)
    }

    private func checkNightModeOff() {
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables.cells["Enable Night Mode"])
        navigator.goto(BrowserTab)
    }

    func testNightModeUI() {
        let url1 = "www.google.com"

        // Go to a webpage, and select night mode on and off, check it's applied or not
        navigator.openNewURL(urlString: url1)

        //turn on the night mode
        nightModeOn()

        //checking night mode on or off
        checkNightModeOn()

        //turn off the night mode
        nightModeOff()

        //checking night mode on or off
        checkNightModeOff()
    }
}
