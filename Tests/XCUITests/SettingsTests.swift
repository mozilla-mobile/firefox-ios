// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class SettingsTests: BaseTestCase {
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2334757
    func testHelpOpensSUMOInTab() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        let settingsTableView = app.tables[AccessibilityIdentifiers.Settings.tableViewController]

        while settingsTableView.staticTexts["Help"].exists == false {
            settingsTableView.swipeUp()
        }
        let helpMenu = settingsTableView.cells["Help"]
        XCTAssertTrue(helpMenu.isEnabled)
        helpMenu.tap()

        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: "support.mozilla.org")
        mozWaitForElementToExist(app.webViews.staticTexts["Firefox for iOS Support"])

        let numTabs = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", numTabs as? String, "Sume should be open in a different tab")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2334760
    func testOpenSiriOption() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.OpenSiriFromSettings)
        mozWaitForElementToExist(app.cells["SiriSettings"], timeout: 5)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2334756
    func testCopiedLinks() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)

        // Check Offer to open copied links, when opening firefox is off
        let value = app.tables.cells.switches["Offer to Open Copied Links, When Opening Firefox"].value
        XCTAssertEqual(value as? String, "0")

        // Switch on, Offer to open copied links, when opening firefox
        app.tables.cells.switches["Offer to Open Copied Links, When Opening Firefox"].tap()

        // Check Offer to open copied links, when opening firefox is on
        let value2 = app.tables.cells.switches["Offer to Open Copied Links, When Opening Firefox"].value
        XCTAssertEqual(value2 as? String, "1")

        app.navigationBars["Settings"].buttons["Done"].tap()

        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].tap()
        let settingsmenuitemCell = app.tables.otherElements["Settings"]
        settingsmenuitemCell.tap()

        // Check Offer to open copied links, when opening firefox is on
        let value3 = app.tables.cells.switches["Offer to Open Copied Links, When Opening Firefox"].value
        XCTAssertEqual(value3 as? String, "1")
    }
}
