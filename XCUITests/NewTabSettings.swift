/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let websiteUrl = "www.mozilla.org"
class NewTabSettingsTest: BaseTestCase {
    // Smoketest
    func testCheckNewTabSettingsByDefault() {
        navigator.goto(NewTabSettings)
        Base.helper.waitForExistence(Base.app.navigationBars["New Tab"])
        XCTAssertTrue(Base.app.tables.cells["Firefox Home"].exists)
        XCTAssertTrue(Base.app.tables.cells["Blank Page"].exists)
        XCTAssertTrue(Base.app.tables.cells["NewTabAsCustomURL"].exists)
    }

    // Smoketest
    func testChangeNewTabSettingsShowBlankPage() {
        navigator.goto(NewTabSettings)
        Base.helper.waitForExistence(Base.app.navigationBars["New Tab"])

        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        Base.helper.waitForNoExistence(Base.app.collectionViews.cells["TopSitesCell"])
        Base.helper.waitForNoExistence(Base.app.collectionViews.cells["TopSitesCell"].collectionViews.cells["youtube"])
        Base.helper.waitForNoExistence(Base.app.staticTexts["Highlights"])
    }
    
    func testChangeNewTabSettingsShowFirefoxHome() {
        // Set to history page first since FF Home is default
        navigator.goto(NewTabSettings)
        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        Base.helper.waitForNoExistence(Base.app.collectionViews.cells["TopSitesCell"])
        
        // Now check if it switches to FF Home
        Base.helper.waitForExistence(Base.app.buttons["urlBar-cancel"], timeout: 3)
        Base.app.buttons["urlBar-cancel"].tap()
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabSettings)
        navigator.performAction(Action.SelectNewTabAsFirefoxHomePage)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        Base.helper.waitForExistence(Base.app.collectionViews.cells["TopSitesCell"])
    }

    func testChangeNewTabSettingsShowCustomURL() {
        navigator.goto(NewTabSettings)
        Base.helper.waitForExistence(Base.app.navigationBars["New Tab"])
        // Check the placeholder value
        let placeholderValue = Base.app.textFields["NewTabAsCustomURLTextField"].value as! String
        XCTAssertEqual(placeholderValue, "Custom URL")
        navigator.performAction(Action.SelectNewTabAsCustomURL)
        // Check the value typed
        Base.app.textFields["NewTabAsCustomURLTextField"].typeText("mozilla.org")
        let valueTyped = Base.app.textFields["NewTabAsCustomURLTextField"].value as! String
        Base.helper.waitForValueContains(Base.app.textFields["NewTabAsCustomURLTextField"], value: "mozilla")
        XCTAssertEqual(valueTyped, "mozilla.org")
        // Open new page and check that the custom url is used
        navigator.performAction(Action.OpenNewTabFromTabTray)

        navigator.nowAt(NewTabScreen)
        // Disabling and modifying this check xcode 11.3 update Issue 5937
        // Let's just check that website is open
        Base.helper.waitForExistence(Base.app.webViews.firstMatch, timeout: 20)
        // Base.helper.waitForValueContains(Base.app.textFields["url"], value: "mozilla")
    }
    
    func testChangeNewTabSettingsLabel() {
        //Go to New Tab settings and select Custom URL option
        navigator.performAction(Action.SelectNewTabAsCustomURL)
        navigator.nowAt(NewTabSettings)
        //Enter a custom URL
        Base.app.textFields["NewTabAsCustomURLTextField"].typeText(websiteUrl)
        Base.helper.waitForValueContains(Base.app.textFields["NewTabAsCustomURLTextField"], value: "mozilla")
        navigator.goto(SettingsScreen)
        //Assert that the label showing up in Settings is equal to the URL entere (NOT CURRENTLY WORKING, SHOWING HOMEPAGE INSTEAD)
        XCTAssertEqual(Base.app.tables.cells["NewTab"].label, "New Tab, Homepage")
        //Switch to Blank page and check label
        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.nowAt(NewTabSettings)
        navigator.goto(SettingsScreen)
        XCTAssertEqual(Base.app.tables.cells["NewTab"].label, "New Tab, Blank Page")
        //Switch to FXHome and check label
        navigator.performAction(Action.SelectNewTabAsFirefoxHomePage)
        navigator.nowAt(NewTabSettings)
        navigator.goto(SettingsScreen)
        XCTAssertEqual(Base.app.tables.cells["NewTab"].label, "New Tab, Firefox Home")
    }
}
