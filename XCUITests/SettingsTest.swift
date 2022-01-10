// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

class SettingsTest: BaseTestCase {
    func testHelpOpensSUMOInTab() {
        navigator.performAction(Action.CloseURLBarOpen)
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
        waitForValueContains(app.textFields["url"], value: "support.mozilla.org")
        waitForExistence(app.webViews.staticTexts["Firefox for iOS Support"])
        
        let numTabs = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", numTabs as? String, "Sume should be open in a different tab")
    }

    func testOpenSiriOption() {
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.OpenSiriFromSettings)
        waitForExistence(app.cells["SiriSettings"], timeout: 5)
    }
    /* Disable test since the option to set Firefox is not available in this build after issue #8513 landed, issue #8627
    func testDefaultBrowser() {
        // A default browser card should be available on the home screen
        if #available(iOS 14, *) {
            waitForExistence(app.staticTexts["Set links from websites, emails, and Messages to open automatically in Firefox."], timeout: 5)
            waitForExistence(app.buttons["Learn More"], timeout: 5)
            app.buttons["Learn More"].tap()

            waitForExistence(app.buttons["Go to Settings"], timeout: 5)
            app.buttons["Go to Settings"].tap()
            // Tap on "Default Browser App" and set the browser as a default (Safari is listed first)
            waitForExistence(iOS_Settings.tables.cells.element(boundBy: 1), timeout: 5)
            iOS_Settings.tables.cells.element(boundBy: 2).tap()
            iOS_Settings.tables.staticTexts.element(boundBy: 0).tap()
            
            // Return to the browser
            app.activate()

            // Tap on "Set as Default Browser" from the in-browser settings
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
            navigator.performAction(Action.CloseURLBarOpen)
            navigator.nowAt(NewTabScreen)
            navigator.goto(SettingsScreen)
            let settingsTableView = app.tables["AppSettingsTableViewController.tableView"]
            let defaultBrowserButton = settingsTableView.cells["Set as Default Browser"]
            defaultBrowserButton.tap()

            // Verify the browser is selected as a default in iOS settings
            waitForExistence(iOS_Settings.tables.buttons.element(boundBy: 1), timeout: 5)
            iOS_Settings.tables.buttons.element(boundBy: 1).tap()
            waitForExistence(iOS_Settings.tables.cells.buttons["checkmark"])
            XCTAssertFalse(iOS_Settings.tables.cells.buttons["checkmark"].isEnabled)
        }
    }*/
}
