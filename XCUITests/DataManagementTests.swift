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
    
    // Testing the search bar, search results and 'Show More' option.
    func testWebSiteDataOptions() {
        // Visiting some websites to create Website Data needed to reveal the "Show More" button
        let websitesList = ["www.facebook.com", "www.youtube.com", "www.twitter.com", "www.google.com", "www.facebook.com", "www.mozilla.org"]
        for website in websitesList {
            navigator.openURL(website)
        }
        navigator.goto(WebsiteDataSettings)
        navigator.performAction(Action.TapOnFilterWebsites)
        app.typeText("youtube")
        waitForExistence(app.tables["Search results"])
        let expectedSearchResults = app.tables["Search results"].cells.count
        XCTAssertEqual(expectedSearchResults, 1)
        navigator.performAction(Action.TapOnFilterWebsites)
        app.typeText("foo")
        let expectedNoSearchResults = app.tables["Search results"].cells.count
        XCTAssertEqual(expectedNoSearchResults, 0)
        app.buttons["Cancel"].tap()
        navigator.performAction(Action.ShowMoreWebsiteDataEntries)
        let expectedShowMoreWebsites = app.tables.cells.count
        XCTAssertNotEqual(expectedShowMoreWebsites, 9)
        navigator.performAction(Action.AcceptClearAllWebsiteData)
        waitForExistence(app.tables.cells["ClearAllWebsiteData"])
        let expectedWebsitesCleared = app.tables.cells.count
        XCTAssertEqual(expectedWebsitesCleared, 1)
    }
}
