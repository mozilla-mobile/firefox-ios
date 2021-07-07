/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class WebsiteMemoryTest: BaseTestCase {
    func testGoogleTextField() throws {
        throw XCTSkip("This test needs to be updated or removed")
        let app = XCUIApplication()
        var googleSearchField: XCUIElement = app.webViews.otherElements["Search"]

        // Enter 'google' on the search field to go to google site
        loadWebPage("google.com")

        if app.webViews.otherElements["Search"].exists {
            // Do nothing, it's the initially expected type
        } else if  app.webViews.searchFields["Search"].exists {
            // Set field type of searchField
            googleSearchField = app.webViews.searchFields["Search"]
        } else {
            // Fail, the field is not found
            XCTAssertTrue(false, "Search field type not found")
        }

        // type 'mozilla' (typing doesn't work cleanly with UIWebview, so had to paste from clipboard)
        UIPasteboard.general.string = "mozilla"
        googleSearchField.tap()
        googleSearchField.press(forDuration: 1.5)
        waitForExistence(app.menuItems["Paste"])
        app.menuItems["Paste"].tap()
        app.keyboards.buttons["Search"].tap()
        // wait for mozilla link to appear
        waitForExistence(app.links["Mozilla"].staticTexts["Mozilla"])

        // revisit google site
        app.buttons["URLBar.deleteButton"].tap()
        // Disabling this check since BB seem to intermittently miss this popup which disappears after 1~2 seconds
        // The popup is also checked in PastenGOTest
        //waitForExistence(app.staticTexts["Your browsing history has been erased."])
        checkForHomeScreen()
        loadWebPage("google.com")
        waitForExistence(googleSearchField)
        googleSearchField.tap()

        // check the world 'mozilla' does not appear in the list of autocomplete
        waitForNoExistence(app.webViews.textFields["mozilla"])
        waitForNoExistence(app.webViews.searchFields["mozilla"])
    }
}
