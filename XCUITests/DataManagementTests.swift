/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class DataManagementTests: BaseTestCase {

    func testWebSiteDataEnterFirstTime() {
        navigator.performAction(Action.AcceptClearAllWebsiteData)
        let expectedWebsiteDataEntries2 = Base.app.tables.cells.count
        XCTAssertEqual(expectedWebsiteDataEntries2, 1)
        navigator.openURL("example.com")
        navigator.goto(WebsiteDataSettings)
        let expectedWebsiteDataEntries3 = Base.app.tables.cells.count
        XCTAssertEqual(expectedWebsiteDataEntries3, 2)
    }
    
    // Testing the search bar, search results and 'Show More' option.
    func testWebSiteDataOptions() {
        // Visiting some websites to create Website Data needed to reveal the "Show More" button
        let websitesList = ["example.com", Base.helper.path(forTestPage: "test-mozilla-org.html"), Base.helper.path(forTestPage: "test-mozilla-book.html"), "youtube.com", "www.google.com", "bing.com"]
        for website in websitesList {
            navigator.openURL(website)
        }
        navigator.goto(WebsiteDataSettings)
        Base.helper.waitForExistence(Base.app.searchFields["Filter Sites"])
        navigator.performAction(Action.TapOnFilterWebsites)
        Base.app.typeText("bing")
        Base.helper.waitForExistence(Base.app.tables["Search results"])
        let expectedSearchResults = Base.app.tables["Search results"].cells.count
        XCTAssertEqual(expectedSearchResults, 1)
        navigator.performAction(Action.TapOnFilterWebsites)
        Base.app.typeText("foo")
        let expectedNoSearchResults = Base.app.tables["Search results"].cells.count
        XCTAssertEqual(expectedNoSearchResults, 0)
        Base.app.buttons["Cancel"].tap()
        navigator.performAction(Action.ShowMoreWebsiteDataEntries)
        let expectedShowMoreWebsites = Base.app.tables.cells.count
        XCTAssertNotEqual(expectedShowMoreWebsites, 9)
        navigator.performAction(Action.AcceptClearAllWebsiteData)
        Base.helper.waitForExistence(Base.app.tables.cells["ClearAllWebsiteData"])
        let expectedWebsitesCleared = Base.app.tables.cells.count
        XCTAssertEqual(expectedWebsitesCleared, 1)
    }
}
