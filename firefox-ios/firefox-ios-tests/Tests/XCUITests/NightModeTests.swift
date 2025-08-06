// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
class NightModeTests: BaseTestCase {
    var nightModeOnCell: XCUIElement {
        app.tables.cells["MainMenu.NightModeOn"]
    }

    private func checkNightModeOn() {
        mozWaitForElementToExist(nightModeOnCell)
        XCTAssertTrue(nightModeOnCell.label == "Website Dark Mode")
        if !iPad() {
            mozWaitForElementToExist(app.tables.staticTexts["On"])
        } else {
            mozWaitForElementToExist(app.tables.staticTexts.matching(identifier: "On").element(boundBy: 1))
        }
        // Turn off night mode
        nightModeOnCell.waitAndTap()
    }

    private func checkNightModeOff() {
        mozWaitForElementToExist(nightModeOnCell)
        XCTAssertTrue(nightModeOnCell.label == "Website Dark Mode")
        if !iPad() {
            mozWaitForElementToExist(app.tables.staticTexts.matching(identifier: "Off").element(boundBy: 1))
        } else {
            mozWaitForElementToExist(app.tables.staticTexts["Off"])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307056
    func testNightModeUI() {
        let url1 = "test-example.html"
        // Go to a webpage, and select night mode on and off, check it's applied or not
        navigator.openURL(path(forTestPage: url1))
        waitUntilPageLoad()
        // turn on the night mode
        navigator.goto(BrowserTabMenuMore)
        navigator.performAction(Action.ToggleNightMode)
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenuMore)
        // checking night mode on or off
        checkNightModeOn()

        // checking night mode on or off
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenuMore)
        checkNightModeOff()
    }
}
