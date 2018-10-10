/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url_1 = "test-example.html"
let url_2 = ["url": "test-mozilla-org.html", "bookmarkLabel": "Internet for people, not profit — Mozilla"]

class BookmarkingTests: BaseTestCase {
    private func bookmark() {
        navigator.goto(PageOptionsMenu)
        waitforExistence(app.tables.cells["Bookmark This Page"])
        app.tables.cells["Bookmark This Page"].tap()
        navigator.nowAt(BrowserTab)
    }

    private func unbookmark() {
        navigator.goto(PageOptionsMenu)
        waitforExistence(app.tables.cells["Remove Bookmark"])
        app.cells["Remove Bookmark"].tap()
        navigator.nowAt(BrowserTab)
    }

    private func checkBookmarked() {
        navigator.goto(PageOptionsMenu)
        waitforExistence(app.tables.cells["Remove Bookmark"])
        if iPad() {
            app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    private func checkUnbookmarked() {
        navigator.goto(PageOptionsMenu)
        waitforExistence(app.tables.cells["Bookmark This Page"])
        if iPad() {
            app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    func testBookmarkingUI() {
        // Go to a webpage, and add to bookmarks, check it's added
        navigator.openURL(path(forTestPage: url_1))
        navigator.nowAt(BrowserTab)
        bookmark()
        checkBookmarked()

        // Load a different page on a new tab, check it's not bookmarked
        navigator.openNewURL(urlString: path(forTestPage: url_2["url"]!))
        navigator.nowAt(BrowserTab)
        checkUnbookmarked()

        // Go back, check it's still bookmarked, check it's on bookmarks home panel
        navigator.goto(TabTray)
        app.collectionViews.cells["Example Domain"].tap()
        navigator.nowAt(BrowserTab)
        checkBookmarked()

        // Open it, then unbookmark it, and check it's no longer on bookmarks home panel
        unbookmark()
        checkUnbookmarked()
    }

    private func checkEmptyBookmarkList() {
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 0, "There should not be any entry in the bookmarks list")
    }

    private func checkItemInBookmarkList() {
        waitforExistence(app.tables["Bookmarks List"])
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 1, "There should be an entry in the bookmarks list")
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[url_2["bookmarkLabel"]!].exists)
    }

    func testAccessBookmarksFromContextMenu() {
        //Add a bookmark
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        waitforExistence(app.buttons["TabLocationView.pageOptionsButton"])
        bookmark()

        //There should be a bookmark
        navigator.browserPerformAction(.openBookMarksOption)
        checkItemInBookmarkList()
    }

    // Smoketest
    func testBookmarksAwesomeBar() {
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "www.ebay")
        waitforExistence(app.tables["SiteTable"])
        waitforExistence(app.buttons["www.ebay.com"])
        XCTAssertTrue(app.buttons["www.ebay.com"].exists)
        typeOnSearchBar(text: ".com")
        typeOnSearchBar(text: "\r")
        navigator.nowAt(BrowserTab)

         //Clear text and enter new url
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "http://www.olx.ro")

        // Site table existes but is empty
        waitforExistence(app.tables["SiteTable"])
        XCTAssertEqual(app.tables["SiteTable"].cells.count, 0)
        typeOnSearchBar(text: "\r")
        navigator.nowAt(BrowserTab)

        // Add page to bookmarks
        navigator.nowAt(BrowserTab)
        bookmark()

        // Now the site should be suggested
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "olx.ro")
        waitforExistence(app.tables["SiteTable"])
        waitforExistence(app.buttons["olx.ro"])
        XCTAssertNotEqual(app.tables["SiteTable"].cells.count, 0)
    }

    private func typeOnSearchBar(text: String) {
        waitforExistence(app.textFields["address"])
        app.textFields["address"].typeText(text)
    }
}
