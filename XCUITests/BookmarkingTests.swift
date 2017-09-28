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
        app.buttons["TabLocationView.pageOptionsButton"].tap()
//        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .button).element.tap()
        waitforExistence(app.tables.cells["Bookmark This Page"])
        app.tables.cells["Bookmark This Page"].tap()
        navigator.nowAt(BrowserTab)
    }
    
    private func unbookmark() {
        app.buttons["TabLocationView.pageOptionsButton"].tap()
        waitforExistence(app.tables.cells["Remove Bookmark"])
        app.cells["Remove Bookmark"].tap()
        navigator.nowAt(BrowserTab)
    }
    
    private func checkBookmarked() {
        app.buttons["TabLocationView.pageOptionsButton"].tap()
        waitforExistence(app.tables.cells["Remove Bookmark"])
        navigator.goto(BrowserTab)
    }
    
    private func checkUnbookmarked() {
        app.buttons["TabLocationView.pageOptionsButton"].tap()
        waitforExistence(app.tables.cells["Bookmark This Page"])
        navigator.goto(BrowserTab)
    }
    
    func testBookmarkingUI() {
        let url1 = "www.google.com"
        let url2 = "www.mozilla.org"
        
        // Go to a webpage, and add to bookmarks, check it's added
        navigator.openNewURL(urlString: url1)
        bookmark()
        checkBookmarked()
        
        // Load a different page on a new tab, check it's not bookmarked
        //navigator.goto(NewTabScreen)
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
