/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class NewTabSettingsTest: BaseTestCase {
    // Smoketest
    func testCheckNewTabSettingsByDefault() {
        navigator.goto(NewTabSettings)
        waitForExistence(app.navigationBars["New Tab"])
        XCTAssertTrue(app.tables.cells["Firefox Home"].exists)
        XCTAssertTrue(app.tables.cells["Blank Page"].exists)
        XCTAssertTrue(app.tables.cells["Bookmarks"].exists)
        XCTAssertTrue(app.tables.cells["History"].exists)
        XCTAssertTrue(app.tables.cells["NewTabAsCustomURL"].exists)
        //XCTAssertTrue(app.tables.switches["ASPocketStoriesVisible"].isEnabled)
    }

    // Smoketest
    func testChangeNewTabSettingsShowBlankPage() {
        navigator.goto(NewTabSettings)
        waitForExistence(app.navigationBars["New Tab"])

        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        waitForNoExistence(app.collectionViews.cells["TopSitesCell"])
        waitForNoExistence(app.collectionViews.cells["TopSitesCell"].collectionViews.cells["youtube"])
        waitForNoExistence(app.staticTexts["Highlights"])
    }

    // Smoketest
    func testChangeNewTabSettingsShowYourBookmarks() {
        navigator.goto(NewTabSettings)
        waitForExistence(app.navigationBars["New Tab"])
        // Show Bookmarks panel without bookmarks
        navigator.performAction(Action.SelectNewTabAsBookmarksPage)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.otherElements.images["emptyBookmarks"])

        // Add one bookmark and check the new tab screen
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        navigator.performAction(Action.Bookmark)
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.tables["Bookmarks List"].cells.staticTexts["The Book of Mozilla"])
        waitForNoExistence(app.staticTexts["Highlights"])
    }

    // Smoketest
    func testChangeNewTabSettingsShowYourHistory() {
        navigator.goto(NewTabSettings)
        waitForExistence(app.navigationBars["New Tab"])
        // Show History Panel without history
        navigator.performAction(Action.SelectNewTabAsHistoryPage)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForNoExistence(app.tables.otherElements.staticTexts["Today"])

        // Add one history item and check the new tab screen
        navigator.openURL("example.com")
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.tables["History List"].cells.staticTexts["Example Domain"])
    }

    func testChangeNewTabSettingsShowCustomURL() {
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
        waitForExistence(app.textFields["url"])
        waitForValueContains(app.textFields["url"], value: "mozilla")
    }
}
