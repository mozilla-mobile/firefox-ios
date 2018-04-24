/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url_1 = "www.google.com"
let url_2 = ["url": "www.mozilla.org", "bookmarkLabel": "Internet for people, not profit — Mozilla"]

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
        navigator.createNewTab()
        loadWebPage(url_1)
        navigator.nowAt(BrowserTab)
        bookmark()
        checkBookmarked()

        // Load a different page on a new tab, check it's not bookmarked
        navigator.createNewTab()
        loadWebPage(url_2["url"]!)
        navigator.nowAt(BrowserTab)
        checkUnbookmarked()

        // Go back, check it's still bookmarked, check it's on bookmarks home panel
        navigator.goto(TabTray)
        app.collectionViews.cells["Google"].tap()
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
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 1, "There should be an entry in the bookmarks list")
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[url_2["bookmarkLabel"]!].exists)
    }

    func testAccessBookmarksFromContextMenu() {
        //First time there is not any bookmark
        navigator.browserPerformAction(.openBookMarksOption)
        checkEmptyBookmarkList()
        navigator.nowAt(BrowserTab)

        //Add a bookmark
        navigator.createNewTab()
        loadWebPage(url_2["url"]!)
        navigator.nowAt(BrowserTab)
        bookmark()

        //There should be a bookmark
        navigator.browserPerformAction(.openBookMarksOption)
        checkItemInBookmarkList()
    }
}
