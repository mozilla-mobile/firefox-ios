/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let websiteUrl1 = "www.mozilla.org"
let websiteUrl2 = "developer.mozilla.org"
let invalidUrl = "1-2-3"

class HomePageSettingsUITests: BaseTestCase {
    private func enterWebPageAsHomepage(text: String) {
        app.textFields["HomePageSettingTextField"].tap()
        app.textFields["HomePageSettingTextField"].typeText(text)
        let value = app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual(value as? String, text, "The webpage typed does not match with the one saved")
    }

    func testTyping() {
        navigator.goto(HomePageSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: websiteUrl1)

        // Check if it is saved going back and then again to home settings menu
        navigator.goto(HomePageSettings)
        let valueAfter = app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual(valueAfter as? String, websiteUrl1)

        // Check that it is actually set by opening a different website and going to Home
        navigator.openURL(websiteUrl2)
        navigator.goto(BrowserTabMenu)

        //Now check open home page should load the previously saved home page
        let homePageMenuItem = app.tables["Context Menu"].cells["Open Homepage"]
        waitForExistence(homePageMenuItem)
        homePageMenuItem.tap()
        waitForValueContains(app.textFields["url"], value: websiteUrl1)
    }

    func testTypingBadURL() {
        waitForExistence(app.buttons["TabToolbar.menuButton"], timeout: 5)
        navigator.goto(HomePageSettings)
        // Enter an invalid Url
        enterWebPageAsHomepage(text: invalidUrl)
        navigator.goto(SettingsScreen)
        // Check that it is not saved
        navigator.goto(HomePageSettings)
        waitForExistence(app.textFields["HomePageSettingTextField"])
        let valueAfter = app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual("Enter a webpage", valueAfter as! String)

        // There is no option to go to Home, instead the website open has the option to be set as HomePageSettings
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForExistence(app.buttons["TabToolbar.menuButton"], timeout: 5)
        navigator.goto(BrowserTabMenu)
        let homePageMenuItem = app.tables["Context Menu"].cells["Open Homepage"]
        XCTAssertFalse(homePageMenuItem.exists)
    }

    func testClipboard() {
        // Go to a website and copy the url
        navigator.openURL(websiteUrl1)
        app.textFields["url"].press(forDuration: 5)
        waitForExistence(app.tables["Context Menu"])
        app.tables["Context Menu"].cells["menu-Copy-Link"].tap()
        // Go to HomePage settings and paste it using the option Used Copied Link
        navigator.goto(HomePageSettings)
        XCTAssertTrue(app.cells["Use Copied Link"].isEnabled)
        app.cells["Use Copied Link"].tap()

        // Check that the webpage has been correclty copied into the correct field
        let value = app.textFields["HomePageSettingTextField"].value as! String

        if ((value == "https://\(websiteUrl1)/en-US/")) {
            XCTAssertEqual(value, "https://\(websiteUrl1)/en-US/",
                "The webpage typed does not match with the one saved")
        } else {
            XCTAssertTrue(value.contains("https://\(websiteUrl1)/en-US/?v="), "The webpage typed does not match with the one saved")
        }
    }

    func testDisabledClipboard() {
        // Type an incorrect URL and copy it
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText(invalidUrl)
        app.textFields["address"].press(forDuration: 5)
        app.menuItems["Select All"].tap()
        app.menuItems["Copy"].tap()
        waitForExistence(app.buttons["goBack"])
        app.buttons["goBack"].tap()

        // Go to HomePage settings and check that it is not possible to copy it into the set webpage field
        navigator.nowAt(BrowserTab)
        navigator.goto(HomePageSettings)
        waitForExistence(app.staticTexts["Use Copied Link"])

        // Check that nothing is copied in the Set webpage field
        app.cells["Use Copied Link"].tap()
        let value = app.textFields["HomePageSettingTextField"].value

        XCTAssertEqual("Enter a webpage", value as! String)
    }
}
