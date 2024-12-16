// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

class NightModeTests: BaseTestCase {
    private func checkNightModeOn() {
        navigator.goto(ToolsBrowserTabMenu)
        mozWaitForElementToExist(app.tables.cells["MainMenu.NightModeOn"])
        XCTAssertTrue(app.tables.cells["MainMenu.NightModeOn"].label == "Turn off Night Mode")
        // Turn off night mode
        app.tables.cells["MainMenu.NightModeOn"].tap()
    }

    private func checkNightModeOff() {
        navigator.goto(ToolsBrowserTabMenu)
        mozWaitForElementToExist(app.tables.cells["MainMenu.NightModeOn"])
        XCTAssertTrue(app.tables.cells["MainMenu.NightModeOn"].label == "Turn on Night Mode")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307056
    func testNightModeUI() {
        let url1 = "test-example.html"
        // Go to a webpage, and select night mode on and off, check it's applied or not
        navigator.openURL(path(forTestPage: url1))
        waitUntilPageLoad()
        // turn on the night mode
        navigator.performAction(Action.ToggleNightMode)
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        // checking night mode on or off
        checkNightModeOn()

        // checking night mode on or off
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        checkNightModeOff()
    }
}
