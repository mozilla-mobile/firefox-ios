/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class DataManagementTests: BaseTestCase {

    func testWebSiteDataEnterFirstTime() {
        navigator.performAction(Action.AcceptClearAllWebsiteData)
        let expectedWebsiteDataEntries2 = app.tables.cells.count
        XCTAssertEqual(expectedWebsiteDataEntries2, 1)
        navigator.openURL("example.com")
        navigator.goto(WebsiteDataSettings)
        let expectedWebsiteDataEntries3 = app.tables.cells.count
        XCTAssertEqual(expectedWebsiteDataEntries3, 2)
    }
    /* Disabled failing on BR
    // Testing the search bar, search results and 'Show More' option.
    func testWebSiteDataOptions() {
        // Visiting some websites to create Website Data needed to reveal the "Show More" button
        let websitesList = ["example.com", path(forTestPage: "test-mozilla-org.html"), path(forTestPage: "test-mozilla-book.html"), "youtube.com", "www.google.com", "bing.com"]
        for website in websitesList {
            navigator.openURL(website)
            waitUntilPageLoad()
        }
        navigator.goto(WebsiteDataSettings)
        waitForExistence(app.tables.otherElements["Website Data"], timeout: 3)
        app.tables.otherElements["Website Data"].swipeDown()
        waitForExistence(app.searchFields["Filter Sites"], timeout: 3)
        navigator.performAction(Action.TapOnFilterWebsites)
        app.typeText("bing")
        waitForExistence(app.tables["Search results"])
        let expectedSearchResults = app.tables["Search results"].cells.count
        XCTAssertEqual(expectedSearchResults, 1)
        navigator.performAction(Action.TapOnFilterWebsites)
        app.typeText("foo")
        let expectedNoSearchResults = app.tables["Search results"].cells.count
        XCTAssertEqual(expectedNoSearchResults, 0)
        app.buttons["Cancel"].tap()
        waitForExistence(app.tables.cells["ShowMoreWebsiteData"], timeout: 3)
        navigator.performAction(Action.ShowMoreWebsiteDataEntries)
        let expectedShowMoreWebsites = app.tables.cells.count
        XCTAssertNotEqual(expectedShowMoreWebsites, 9)
        navigator.performAction(Action.AcceptClearAllWebsiteData)
        waitForExistence(app.tables.cells["ClearAllWebsiteData"])
        let expectedWebsitesCleared = app.tables.cells.count
        XCTAssertEqual(expectedWebsitesCleared, 1)
    }*/
}
