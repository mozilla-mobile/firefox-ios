/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SettingsTest: BaseTestCase {
    func testHelpOpensSUMOInTab() {
        navigator.goto(SettingsScreen)
        let settingsTableView = app.tables["AppSettingsTableViewController.tableView"]

        while settingsTableView.staticTexts["Help"].exists == false {
            settingsTableView.swipeUp()
        }
        let helpMenu = settingsTableView.cells["Help"]
        XCTAssertTrue(helpMenu.isEnabled)
        helpMenu.tap()

        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(app.textFields["url"], value: "support.mozilla.org")
        if Base.helper.iPad() {
            Base.helper.waitForExistence(app.webViews.staticTexts["Firefox for iOS Support"])
        } else {
            Base.helper.waitForExistence(app.webViews.staticTexts["Firefox for iOS"])
        }
        let numTabs = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", numTabs as? String, "Sume should be open in a different tab")
    }

    func testOpenSiriOption() {
        navigator.performAction(Action.OpenSiriFromSettings)
        Base.helper.waitForExistence(app.buttons["Add to Siri"], timeout: 5)
    }
}
