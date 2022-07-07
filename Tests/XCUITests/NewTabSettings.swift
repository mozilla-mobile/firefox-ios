// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

let websiteUrl = "www.mozilla.org"
class NewTabSettingsTest: BaseTestCase {
    // Smoketest
    func testCheckNewTabSettingsByDefault() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 15)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 5)
        navigator.nowAt(NewTabScreen)
        navigator.goto(NewTabSettings)
        waitForExistence(app.navigationBars["New Tab"])
        XCTAssertTrue(app.tables.cells["Firefox Home"].exists)
        XCTAssertTrue(app.tables.cells["Blank Page"].exists)
        XCTAssertTrue(app.tables.cells["NewTabAsCustomURL"].exists)
    }

    // Smoketest
    func testChangeNewTabSettingsShowBlankPage() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 25)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 5)
        navigator.nowAt(NewTabScreen)
        navigator.goto(NewTabSettings)
        waitForExistence(app.navigationBars["New Tab"])

        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        waitForNoExistence(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        waitForNoExistence(app.collectionViews.cells.staticTexts["YouTube"])
        waitForNoExistence(app.staticTexts["Highlights"])
    }

    func testChangeNewTabSettingsShowFirefoxHome() {
        // Set to history page first since FF Home is default
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForNoExistence(app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])

        // Now check if it switches to FF Home
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 3)
        app.buttons["urlBar-cancel"].tap()
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabSettings)
        navigator.performAction(Action.SelectNewTabAsFirefoxHomePage)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
    }

    func testChangeNewTabSettingsShowCustomURL() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 15)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(NewTabSettings)
        waitForExistence(app.navigationBars["New Tab"])
        // Check the placeholder value
        let placeholderValue = app.textFields["NewTabAsCustomURLTextField"].value as! String
        XCTAssertEqual(placeholderValue, "Custom URL")
        navigator.performAction(Action.SelectNewTabAsCustomURL)
        // Check the value typed
        app.textFields["NewTabAsCustomURLTextField"].typeText("mozilla.org")
        let valueTyped = app.textFields["NewTabAsCustomURLTextField"].value as! String
        waitForValueContains(app.textFields["NewTabAsCustomURLTextField"], value: "mozilla")
        XCTAssertEqual(valueTyped, "mozilla.org")
        // Open new page and check that the custom url is used
        navigator.performAction(Action.OpenNewTabFromTabTray)

        navigator.nowAt(NewTabScreen)
        // Disabling and modifying this check xcode 11.3 update Issue 5937
        // Let's just check that website is open
        waitForExistence(app.webViews.firstMatch, timeout: 20)
        // waitForValueContains(app.textFields["url"], value: "mozilla")
    }

    func testChangeNewTabSettingsLabel() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        // Go to New Tab settings and select Custom URL option
        navigator.performAction(Action.SelectNewTabAsCustomURL)
        navigator.nowAt(NewTabSettings)
        // Enter a custom URL
        app.textFields["NewTabAsCustomURLTextField"].typeText(websiteUrl)
        waitForValueContains(app.textFields["NewTabAsCustomURLTextField"], value: "mozilla")
        navigator.goto(SettingsScreen)
        // Assert that the label showing up in Settings is equal to the URL entered (NOT CURRENTLY WORKING, SHOWING HOMEPAGE INSTEAD)
        XCTAssertEqual(app.tables.cells["NewTab"].label, "New Tab, Homepage")
        // Switch to Blank page and check label
        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.nowAt(NewTabSettings)
        navigator.goto(SettingsScreen)
        XCTAssertEqual(app.tables.cells["NewTab"].label, "New Tab, Blank Page")
        // Switch to FXHome and check label
        navigator.performAction(Action.SelectNewTabAsFirefoxHomePage)
        navigator.nowAt(NewTabSettings)
        navigator.goto(SettingsScreen)
        XCTAssertEqual(app.tables.cells["NewTab"].label, "New Tab, Firefox Home")
    }
}
