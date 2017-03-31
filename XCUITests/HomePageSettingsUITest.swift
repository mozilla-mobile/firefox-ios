/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let websiteUrl1 = "https://www.mozilla.org"
let websiteUrl2 = "https://developer.mozilla.org/"
let invalidUrl = "1-2-3"

class HomePageSettingsUITests: BaseTestCase {
    var navigator: Navigator!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNavigation() {
        // Check that the homepage menu exists
        navigator.goto(HomePageSettings)
        XCTAssertTrue(app.staticTexts["Homepage Settings"].exists)
    }

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
        navigator.goto(NewTabScreen)
        navigator.goto(HomePageSettings)
        let valueAfter = app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual(valueAfter as? String, websiteUrl1)

        // Check that it is actually set by opening a different website and going to Home
        navigator.goto(NewTabScreen)
        navigator.openURL(urlString: websiteUrl2)
        navigator.goto(BrowserTabMenu)

        waitforExistence(app.collectionViews.cells["Home"])
        app.collectionViews.cells["Home"].tap()
        waitForValueContains(app.textFields["url"], value: websiteUrl1)
    }

    func testTypingBadURL() {
        navigator.goto(HomePageSettings)
        // Enter an invalid Url
        enterWebPageAsHomepage(text: invalidUrl)

        // Check that it is not saved
        navigator.goto(NewTabScreen)
        navigator.goto(HomePageSettings)
        let valueAfter = app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual(valueAfter as? String, "")

        // There is no option to go to Home, instead the website open has the option to be set as HomePageSettings
        navigator.goto(NewTabScreen)
        navigator.openURL(urlString: websiteUrl1)
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.collectionViews.cells["SetHomePageMenuItem"])
        XCTAssertFalse(app.collectionViews.cells["Home"].exists)
        XCTAssertTrue(app.collectionViews.cells["SetHomePageMenuItem"].exists)
    }

    func testClipboard() {
        // Go to a website and copy the url
        navigator.openURL(urlString: websiteUrl1)
        app.textFields["url"].press(forDuration: 5)
        app.buttons["Copy Address"].tap()

        // Go to HomePage settings and paste it using the option Used Copied Link
        navigator.goto(SettingsScreen)
        navigator.goto(HomePageSettings)
        XCTAssertTrue(app.cells["Use Copied Link"].isEnabled)
        app.cells["Use Copied Link"].tap()

        // Check that the webpage has been correclty copied into the correct field
        let value = app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual(value as? String, websiteUrl1 + "/en-US/", "The webpage typed does not match with the one saved")
    }

    func testDisabledClipboard() {
        // Type an incorrect URL and copy it
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText(invalidUrl)
        app.textFields["address"].press(forDuration: 5)
        app.menuItems["Select All"].tap()
        app.menuItems["Copy"].tap()
        app.buttons["Cancel"].tap()

        // Go to HomePage settings and check that it is not possible to copy it into the set webpage field
        navigator.nowAt(BrowserTab)
        navigator.goto(HomePageSettings)
        waitforExistence(app.staticTexts["Use Copied Link"])

        // Check that nothing is copied in the Set webpage field
        app.cells["Use Copied Link"].tap()
        let value = app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual(value as? String, "", "An invalid url cannot be copied in thto the HomePageSettingsTextField")
    }
}
