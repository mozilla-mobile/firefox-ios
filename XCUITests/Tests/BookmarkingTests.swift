/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class BookmarkingTests: BaseTestCase {
    
    func testBookmarkingUI() {
        // Go to a webpage, and add to bookmarks, check it's added
        navigator.openURL(Base.helper.path(forTestPage: Constants.url_1))
        navigator.nowAt(BrowserTab)
        Base.helper.waitForTabsButton()
        TestStep.bookmark()
        Base.helper.waitForTabsButton()
        TestCheck.checkBookmarked()

        // Load a different page on a new tab, check it's not bookmarked
        navigator.openNewURL(urlString: Base.helper.path(forTestPage: Constants.url_2["url"] ?? "no url!"))
        navigator.nowAt(BrowserTab)
        Base.helper.waitForTabsButton()
        TestCheck.checkUnbookmarked()

        // Go back, check it's still bookmarked, check it's on bookmarks home panel
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        TestStep.tapOnElement(Base.app.collectionViews.cells["Example Domain"])
        navigator.nowAt(BrowserTab)
        Base.helper.waitForTabsButton()
        TestCheck.checkBookmarked()

        // Open it, then unbookmark it, and check it's no longer on bookmarks home panel
        TestStep.unbookmark()
        Base.helper.waitForTabsButton()
        TestCheck.checkUnbookmarked()
    }

    func testAccessBookmarksFromContextMenu() {
        //Add a bookmark
        navigator.openURL(Base.helper.path(forTestPage: Constants.url_2["url"] ?? "no url!"))
        Base.helper.waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        Base.helper.waitForExistence(Base.app.buttons["TabLocationView.pageOptionsButton"], timeout: 10)
        TestStep.bookmark()

        //There should be a bookmark
        navigator.goto(MobileBookmarks)
        TestCheck.checkItemInBookmarkList()
    }
    
    func testRecentBookmarks() {
        // Verify that there are only 4 cells without recent bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        Base.helper.waitForNoExistence(Base.app.otherElements["RECENT BOOKMARKS"])
        XCTAssertEqual(Base.app.tables["Bookmarks List"].cells.count, 4)
        
        //Add a bookmark
        navigator.openURL(Constants.url_3)
        Base.helper.waitForTabsButton()
        TestStep.bookmark()
        
        // Check if it shows in recent bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        Base.helper.waitForExistence(Base.app.otherElements["Recent Bookmarks"])
        Base.helper.waitForExistence(Base.app.staticTexts[Constants.urlLabelExample_3])
        XCTAssertEqual(Base.app.tables["Bookmarks List"].cells.count, 5)
        
        // Add another
        navigator.openURL(Base.helper.path(forTestPage: Constants.url_4))
        Base.helper.waitForTabsButton()
        TestStep.bookmark()
        
        // Check if it shows in recent bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        Base.helper.waitForExistence(Base.app.otherElements["Recent Bookmarks"])
        Base.helper.waitForExistence(Base.app.staticTexts[Constants.urlLabelExample_4])
        XCTAssertEqual(Base.app.tables["Bookmarks List"].cells.count, 6)
        
        // Click a recent bookmark and make sure it navigates. Disabled because of issue 5038 not opening recent bookmarks when tapped
        Base.app.tables["Bookmarks List"].cells.element(boundBy: 5).tap()
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 6)
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: Constants.url_3)
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
        TestStep.addNewBookmark()
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
        TestCheck.checkItemsInBookmarksList(items: 1)
        navigator.nowAt(MobileBookmarks)
        // Now remove the folder
        navigator.performAction(Action.RemoveItemMobileBookmarks)
        Base.helper.waitForExistence(Base.app.buttons["Delete"])
        navigator.performAction(Action.ConfirmRemoveItemMobileBookmarks)
        TestCheck.checkItemsInBookmarksList(items: 0)
    }

    func testAddNewMarker() {
        navigator.goto(MobileBookmarks)
        navigator.goto(MobileBookmarksAdd)
        navigator.performAction(Action.AddNewSeparator)
        Base.app.buttons["Done"].tap()
        TestCheck.checkItemsInBookmarksList(items: 1)

        // Remove it
        navigator.nowAt(MobileBookmarks)
        navigator.performAction(Action.RemoveItemMobileBookmarks)
        Base.helper.waitForExistence(Base.app.buttons["Delete"])
        navigator.performAction(Action.ConfirmRemoveItemMobileBookmarks)
        TestCheck.checkItemsInBookmarksList(items: 0)
    }

    func testDeleteBookmarkSwiping() {
        TestStep.addNewBookmark()
        // Remove by swiping
        Base.app.tables["Bookmarks List"].staticTexts["BBC"].swipeLeft()
        Base.app.buttons["Delete"].tap()
        TestCheck.checkItemsInBookmarksList(items: 0)
    }

    func testDeleteBookmarkContextMenu() {
        TestStep.addNewBookmark()
        // Remove by long press and select option from context menu
        Base.app.tables.staticTexts.element(boundBy: 0).press(forDuration: 1)
        Base.helper.waitForExistence(Base.app.tables["Context Menu"])
        Base.app.tables["Context Menu"].cells["action_bookmark_remove"].tap()
        TestCheck.checkItemsInBookmarksList(items: 0)
    }
    
}
