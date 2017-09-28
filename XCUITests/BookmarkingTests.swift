/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class BookmarkingTests: BaseTestCase {
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
    
    private func bookmark() {
        navigator.goto(ShareMenu)
        waitforExistence(app.tables.cells["Add Bookmark"])
        app.tables.cells["Add Bookmark"].tap()
        navigator.nowAt(BrowserTab)
    }
    
    private func unbookmark() {
        navigator.goto(ShareMenu)
        waitforExistence(app.tables.cells["Remove Bookmark"])
        app.tables.cells["Remove Bookmark"].tap()
        navigator.nowAt(BrowserTab)
    }
    
    private func checkBookmarked() {
        navigator.goto(ShareMenu)
        waitforExistence(app.tables.cells["Remove Bookmark"])
        app.buttons["Close"].tap()
        navigator.nowAt(BrowserTab)
    }
    
    private func checkUnbookmarked() {
        navigator.goto(ShareMenu)
        waitforExistence(app.tables.cells["Add Bookmark"])
        app.buttons["Close"].tap()
        navigator.nowAt(BrowserTab)
    }
    
    func testBookmarkingUI() {
        let url1 = "www.google.com"
        let url2 = "www.mozilla.org"
        
        // Go to a webpage, and add to bookmarks, check it's added
        navigator.openNewURL(urlString: url1)
        bookmark()
        checkBookmarked()
        
        // Load a different page on a new tab, check it's not bookmarked
        navigator.createNewTab()
        navigator.openNewURL(urlString: url2)
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
}
