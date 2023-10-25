// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class DefaultBrowserTests: BaseTestCase {
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306804
    /* Disable test since the option to set Firefox is not available in this build after issue #8513 landed, issue #8627
    func testSetFirefoxDefaultBrowserFromHomeScreenBanner() {
        // A default browser card should be available on the home screen
        mozWaitForElementToExist(app.staticTexts["Set links from websites, emails, and Messages to open automatically in Firefox."], timeout: 5)
        mozWaitForElementToExist(app.buttons["Learn More"], timeout: 5)
        app.buttons["Learn More"].tap()

        mozWaitForElementToExist(app.buttons["Go to Settings"], timeout: 5)
        app.buttons["Go to Settings"].tap()
        // Tap on "Default Browser App" and set the browser as a default (Safari is listed first)
        mozWaitForElementToExist(iOS_Settings.tables.cells.element(boundBy: 1), timeout: 5)
        iOS_Settings.tables.cells.element(boundBy: 2).tap()
        iOS_Settings.tables.staticTexts.element(boundBy: 0).tap()
        
        // Return to the browser
        app.activate()

        // Tap on "Set as Default Browser" from the in-browser settings
        mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        let settingsTableView = app.tables[AccessibilityIdentifiers.Settings.tableViewController]
        let defaultBrowserButton = settingsTableView.cells["Set as Default Browser"]
        defaultBrowserButton.tap()

        // Verify the browser is selected as a default in iOS settings
        mozWaitForElementToExist(iOS_Settings.tables.buttons.element(boundBy: 1), timeout: 5)
        iOS_Settings.tables.buttons.element(boundBy: 1).tap()
        mozWaitForElementToExist(iOS_Settings.tables.cells.buttons["checkmark"])
        XCTAssertFalse(iOS_Settings.tables.cells.buttons["checkmark"].isEnabled)
    }*/
}
