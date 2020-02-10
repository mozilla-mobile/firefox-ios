/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url_1 = "test-example.html"
let url_2 = ["url": "test-mozilla-org.html", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
let urlLabelExample_3 = "Example Domain"
let url_3 = "localhost:\(serverPort)/test-fixture/test-example.html"
let urlLabelExample_4 = "Example Login Page 2"
let url_4 = "test-password-2.html"

class BookmarkingTests: BaseTestCase {
    private func bookmark() {
        navigator.goto(PageOptionsMenu)
        Base.helper.waitForExistence(Base.app.tables.cells["Bookmark This Page"], timeout: 15)
        Base.app.tables.cells["Bookmark This Page"].tap()
        navigator.nowAt(BrowserTab)
    }

    private func unbookmark() {
        navigator.goto(PageOptionsMenu)
        Base.helper.waitForExistence(Base.app.tables.cells["Remove Bookmark"])
        Base.app.cells["Remove Bookmark"].tap()
        navigator.nowAt(BrowserTab)
    }

    private func checkBookmarked() {
        navigator.goto(PageOptionsMenu)
        Base.helper.waitForExistence(Base.app.tables.cells["Remove Bookmark"])
        if Base.helper.iPad() {
            Base.app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    private func checkUnbookmarked() {
        navigator.goto(PageOptionsMenu)
        Base.helper.waitForExistence(Base.app.tables.cells["Bookmark This Page"])
        if Base.helper.iPad() {
            Base.app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    func testBookmarkingUI() {
        // Go to a webpage, and add to bookmarks, check it's added
        navigator.openURL(Base.helper.path(forTestPage: url_1))
        navigator.nowAt(BrowserTab)
        Base.helper.waitForTabsButton()
        bookmark()
        Base.helper.waitForTabsButton()
        checkBookmarked()

        // Load a different page on a new tab, check it's not bookmarked
        navigator.openNewURL(urlString: Base.helper.path(forTestPage: url_2["url"]!))
        navigator.nowAt(BrowserTab)
        Base.helper.waitForTabsButton()
        checkUnbookmarked()

        // Go back, check it's still bookmarked, check it's on bookmarks home panel
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        Base.app.collectionViews.cells["Example Domain"].tap()
        navigator.nowAt(BrowserTab)
        Base.helper.waitForTabsButton()
        checkBookmarked()

        // Open it, then unbookmark it, and check it's no longer on bookmarks home panel
        unbookmark()
        Base.helper.waitForTabsButton()
        checkUnbookmarked()
    }

    private func checkEmptyBookmarkList() {
        let list = Base.app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 0, "There should not be any entry in the bookmarks list")
    }

    private func checkItemInBookmarkList() {
        Base.helper.waitForExistence(Base.app.tables["Bookmarks List"])
        let list = Base.app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 1, "There should be an entry in the bookmarks list")
        XCTAssertTrue(Base.app.tables["Bookmarks List"].staticTexts[url_2["bookmarkLabel"]!].exists)
    }

    func testAccessBookmarksFromContextMenu() {
        //Add a bookmark
        navigator.openURL(Base.helper.path(forTestPage: url_2["url"]!))
        Base.helper.waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        Base.helper.waitForExistence(Base.app.buttons["TabLocationView.pageOptionsButton"], timeout: 10)
        bookmark()

        //There should be a bookmark
        navigator.goto(MobileBookmarks)
        checkItemInBookmarkList()
    }
    
    func testRecentBookmarks() {
        // Verify that there are only 4 cells without recent bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        Base.helper.waitForNoExistence(Base.app.otherElements["RECENT BOOKMARKS"])
        XCTAssertEqual(Base.app.tables["Bookmarks List"].cells.count, 4)
        
        //Add a bookmark
        navigator.openURL(url_3)
        Base.helper.waitForTabsButton()
        bookmark()
        
        // Check if it shows in recent bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        Base.helper.waitForExistence(Base.app.otherElements["Recent Bookmarks"])
        Base.helper.waitForExistence(Base.app.staticTexts[urlLabelExample_3])
        XCTAssertEqual(Base.app.tables["Bookmarks List"].cells.count, 5)
        
        // Add another
        navigator.openURL(Base.helper.path(forTestPage: url_4))
        Base.helper.waitForTabsButton()
        bookmark()
        
        // Check if it shows in recent bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        Base.helper.waitForExistence(Base.app.otherElements["Recent Bookmarks"])
        Base.helper.waitForExistence(Base.app.staticTexts[urlLabelExample_4])
        XCTAssertEqual(Base.app.tables["Bookmarks List"].cells.count, 6)
        
        // Click a recent bookmark and make sure it navigates. Disabled because of issue 5038 not opening recent bookmarks when tapped
        Base.app.tables["Bookmarks List"].cells.element(boundBy: 5).tap()
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 6)
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: url_3)
    }

    // Smoketest
    // Disabling and modifying this check xcode 11.3 update Issue 5937
    /*
    func testBookmarksAwesomeBar() {
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "www.ebay")
        Base.helper.waitForExistence(Base.app.tables["SiteTable"])
        Base.helper.waitForExistence(Base.app.buttons["www.ebay.com"])
        XCTAssertTrue(Base.app.buttons["www.ebay.com"].exists)
        typeOnSearchBar(text: ".com")
        typeOnSearchBar(text: "\r")
        navigator.nowAt(BrowserTab)

         //Clear text and enter new url
        Base.helper.waitForTabsButton()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "http://www.olx.ro")

        // Site table existes but is empty
        Base.helper.waitForExistence(Base.app.tables["SiteTable"])
        XCTAssertEqual(Base.app.tables["SiteTable"].cells.count, 0)
        typeOnSearchBar(text: "\r")
        navigator.nowAt(BrowserTab)

        // Add page to bookmarks
        Base.helper.waitForTabsButton()
        bookmark()

        // Now the site should be suggested
        Base.helper.waitForExistence(Base.app.buttons["TabToolbar.menuButton"], timeout: 10)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "olx.ro")
        Base.helper.waitForExistence(Base.app.tables["SiteTable"])
        Base.helper.waitForExistence(Base.app.buttons["olx.ro"])
        XCTAssertNotEqual(Base.app.tables["SiteTable"].cells.count, 0)
    }*/

    func testAddBookmark() {
        addNewBookmark()
        // Verify that clicking on bookmark opens the website
        Base.app.tables["Bookmarks List"].cells.element(boundBy: 0).tap()
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 5)
    }

    func testAddNewFolder() {
        navigator.goto(MobileBookmarks)
        navigator.goto(MobileBookmarksAdd)
        navigator.performAction(Action.AddNewFolder)
        Base.helper.waitForExistence(Base.app.navigationBars["New Folder"])
        // XCTAssertFalse(Base.app.buttons["Save"].isEnabled), is this a bug allowing empty folder name?
        Base.app.tables["SiteTable"].cells.textFields.element(boundBy: 0).tap()
        Base.app.tables["SiteTable"].cells.textFields.element(boundBy: 0).typeText("Test Folder")
        Base.app.buttons["Save"].tap()
        Base.app.buttons["Done"].tap()
        checkItemsInBookmarksList(items: 1)
        navigator.nowAt(MobileBookmarks)
        // Now remove the folder
        navigator.performAction(Action.RemoveItemMobileBookmarks)
        Base.helper.waitForExistence(Base.app.buttons["Delete"])
        navigator.performAction(Action.ConfirmRemoveItemMobileBookmarks)
        checkItemsInBookmarksList(items: 0)
    }

    func testAddNewMarker() {
        navigator.goto(MobileBookmarks)
        navigator.goto(MobileBookmarksAdd)
        navigator.performAction(Action.AddNewSeparator)
        Base.app.buttons["Done"].tap()
        checkItemsInBookmarksList(items: 1)

        // Remove it
        navigator.nowAt(MobileBookmarks)
        navigator.performAction(Action.RemoveItemMobileBookmarks)
        Base.helper.waitForExistence(Base.app.buttons["Delete"])
        navigator.performAction(Action.ConfirmRemoveItemMobileBookmarks)
        checkItemsInBookmarksList(items: 0)
    }

    func testDeleteBookmarkSwiping() {
        addNewBookmark()
        // Remove by swiping
        Base.app.tables["Bookmarks List"].staticTexts["BBC"].swipeLeft()
        Base.app.buttons["Delete"].tap()
        checkItemsInBookmarksList(items: 0)
    }

    func testDeleteBookmarkContextMenu() {
        addNewBookmark()
        // Remove by long press and select option from context menu
        Base.app.tables.staticTexts.element(boundBy: 0).press(forDuration: 1)
        Base.helper.waitForExistence(Base.app.tables["Context Menu"])
        Base.app.tables["Context Menu"].cells["action_bookmark_remove"].tap()
        checkItemsInBookmarksList(items: 0)
    }

    private func addNewBookmark() {
        navigator.goto(MobileBookmarksAdd)
        navigator.performAction(Action.AddNewBookmark)
        Base.helper.waitForExistence(Base.app.navigationBars["New Bookmark"], timeout: 3)
        // Enter the bookmarks details
        Base.app.tables["SiteTable"].cells.textFields.element(boundBy: 0).tap()
        Base.app.tables["SiteTable"].cells.textFields.element(boundBy: 0).typeText("BBC")

        Base.app.tables["SiteTable"].cells.textFields["https://"].tap()
        Base.app.tables["SiteTable"].cells.textFields["https://"].typeText("bbc.com")
        navigator.performAction(Action.SaveCreatedBookmark)
        Base.app.buttons["Done"].tap()
        checkItemsInBookmarksList(items: 1)
    }

    private func checkItemsInBookmarksList(items: Int) {
        Base.helper.waitForExistence(Base.app.tables["Bookmarks List"], timeout: 3)
        XCTAssertEqual(Base.app.tables["Bookmarks List"].cells.count, items)
    }

    private func typeOnSearchBar(text: String) {
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 5)
        sleep(1)
        Base.app.textFields["address"].tap()
        Base.app.textFields["address"].typeText(text)
    }
}
