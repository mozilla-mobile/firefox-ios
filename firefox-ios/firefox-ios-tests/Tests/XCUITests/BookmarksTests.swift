// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

let url_1 = "test-example.html"
let url_2 = ["url": "test-mozilla-org.html", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
let urlLabelExample_3 = "Example Domain"
let url_3 = "localhost:\(serverPort)/test-fixture/test-example.html"

class BookmarksTests: BaseTestCase {
    private func checkBookmarked() {
        navigator.goto(BrowserTabMenu)
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.bookmarkSlash])
        if iPad() {
            app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    private func undoBookmarkRemoval() {
        navigator.goto(BrowserTabMenu)
        app.otherElements[StandardImageIdentifiers.Large.bookmarkSlash].waitAndTap()
        navigator.nowAt(BrowserTab)
        app.buttons["Undo"].waitAndTap()
    }

    private func checkUnbookmarked() {
        navigator.goto(BrowserTabMenu)
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.bookmark])
        if iPad() {
            app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306905
    func testBookmarkingUI() {
        // Go to a webpage, and add to bookmarks, check it's added
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: url_1))
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        bookmark()
        waitForTabsButton()
        checkBookmarked()

        // Load a different page on a new tab, check it's not bookmarked
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: url_2["url"]!))

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        checkUnbookmarked()

        // Go back, check it's still bookmarked, check it's on bookmarks home panel
        waitForTabsButton()
        navigator.goto(TabTray)
        if iPad() {
            app.collectionViews
                .cells["Example Domain"].children(matching: .other)
                .element.children(matching: .other)
                .element.tap()
        } else {
            app.cells.staticTexts["Example Domain"].tap()
        }
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        checkBookmarked()

        // Open it, then unbookmark it, and check it's no longer on bookmarks home panel
        unbookmark()
        waitForTabsButton()
        checkUnbookmarked()
    }

    private func checkEmptyBookmarkList() {
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 0, "There should not be any entry in the bookmarks list")
    }

    private func checkItemInBookmarkList(oneItemBookmarked: Bool) {
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        let bookmarksList = app.tables["Bookmarks List"]
        let list = bookmarksList.cells.count
        if oneItemBookmarked == true {
            XCTAssertEqual(list, 2, "There should be an entry in the bookmarks list")
            waitForElementsToExist(
                [
                    bookmarksList.cells.element(
                        boundBy: 0
                    ).staticTexts["Desktop Bookmarks"],
                    bookmarksList.cells.element(
                        boundBy: 1
                    ).staticTexts[url_2["bookmarkLabel"]!]
                ]
            )
        } else {
            XCTAssertEqual(list, 3, "There should be an entry in the bookmarks list")
            waitForElementsToExist(
                [
                    bookmarksList.cells.element(
                        boundBy: 1
                    ).staticTexts[urlLabelExample_3],
                    bookmarksList.cells.element(
                        boundBy: 2
                    ).staticTexts[url_2["bookmarkLabel"]!]
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306906
    func testAccessBookmarksFromContextMenu() {
        // Add a bookmark
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        bookmark()

        // There should be a bookmark
        navigator.goto(LibraryPanel_Bookmarks)
        checkItemInBookmarkList(oneItemBookmarked: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306907
    // Smoketest
    func testBookmarksAwesomeBar() {
        XCTExpectFailure("The app was not launched", strict: false) {
            mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url], timeout: TIMEOUT_LONG)
        }
        typeOnSearchBar(text: "www.google")
        waitForElementsToExist([app.tables["SiteTable"], app.tables["SiteTable"].cells.staticTexts["www.google"]])
        urlBarAddress.typeText(".com")
        urlBarAddress.typeText("\r")
        navigator.nowAt(BrowserTab)

        // Clear text and enter new url
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "https://mozilla.org")

        // Site table exists but is empty
        mozWaitForElementToExist(app.tables["SiteTable"])
        XCTAssertEqual(app.tables["SiteTable"].cells.count, 0)
        urlBarAddress.typeText("\r")
        navigator.nowAt(BrowserTab)

        // Add page to bookmarks
        waitForTabsButton()
        sleep(2)
        bookmark()

        // Now the site should be suggested
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(BrowserTab)
        typeOnSearchBar(text: "mozilla.org")
        waitForElementsToExist([app.tables["SiteTable"], app.cells.staticTexts["mozilla.org"]])
        XCTAssertNotEqual(app.tables["SiteTable"].cells.count, 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306913
    func testAddBookmark() {
        addNewBookmark()
        // Verify that clicking on bookmark opens the website
        app.tables["Bookmarks List"].cells.element(boundBy: 1).tap()
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306914
    func testAddNewFolder() {
        navigator.goto(LibraryPanel_Bookmarks)
        navigator.nowAt(MobileBookmarks)
        navigator.performAction(Action.AddNewFolder)
        mozWaitForElementToExist(app.navigationBars["Bookmarks"])
        // XCTAssertFalse(app.buttons["Save"].isEnabled), is this a bug allowing empty folder name?
        app.tables.cells.textFields.element(boundBy: 0).tapAndTypeText("Test Folder")
        app.buttons["Save"].tap()
        app.buttons["Done"].tap()
        checkItemsInBookmarksList(items: 2)
        navigator.nowAt(MobileBookmarks)
        // Now remove the folder
        navigator.performAction(Action.RemoveItemMobileBookmarks)
        if #available (iOS 17, *) {
            mozWaitForElementToExist(app.buttons["Remove Test Folder"])
        } else {
            mozWaitForElementToExist(app.buttons["Delete Test Folder"])
        }
        navigator.performAction(Action.ConfirmRemoveItemMobileBookmarks)
        // Verify that there are only 1 cell (desktop bookmark folder)
        checkItemsInBookmarksList(items: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306915
    func testAddNewMarker() {
        navigator.goto(LibraryPanel_Bookmarks)
        navigator.nowAt(MobileBookmarks)
        navigator.performAction(Action.AddNewSeparator)
        app.buttons["Done"].tap()
        // There is one item plus the default Desktop Bookmarks folder
        checkItemsInBookmarksList(items: 2)

        // Remove it
        navigator.nowAt(MobileBookmarks)
        navigator.performAction(Action.RemoveItemMobileBookmarks)
        mozWaitForElementToExist(app.buttons["Delete"])
        navigator.performAction(Action.ConfirmRemoveItemMobileBookmarks)
        // Verify that there are only 1 cell (desktop bookmark folder)
        checkItemsInBookmarksList(items: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306916
    func testDeleteBookmarkSwiping() {
        addNewBookmark()
        // Remove by swiping
        app.tables["Bookmarks List"].staticTexts["BBC"].swipeLeft()
        app.buttons["Delete"].waitAndTap()
        // Verify that there are only 1 cell (desktop bookmark folder)
        checkItemsInBookmarksList(items: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306917
    func testDeleteBookmarkContextMenu() {
        addNewBookmark()
        // Remove by long press and select option from context menu
        app.tables.staticTexts.element(boundBy: 1).press(forDuration: 1)
        mozWaitForElementToExist(app.tables["Context Menu"])
        app.tables.otherElements["Remove Bookmark"].tap()
        // Verify that there are only 1 cell (desktop bookmark folder)
        checkItemsInBookmarksList(items: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306908
    // Smoketest
    func testUndoDeleteBookmark() {
        navigator.openURL(path(forTestPage: url_1))
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        bookmark()
        checkBookmarked()
        undoBookmarkRemoval()
        checkBookmarked()
    }

    private func addNewBookmark() {
        navigator.goto(LibraryPanel_Bookmarks)
        navigator.nowAt(MobileBookmarks)
        navigator.performAction(Action.AddNewBookmark)
        mozWaitForElementToExist(app.navigationBars["Bookmarks"])
        // Enter the bookmarks details
        app.textFields[AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.titleTextField].tapAndTypeText("BBC")
        app.textFields[AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.urlTextField].tapAndTypeText("bbc.com")
        navigator.performAction(Action.SaveCreatedBookmark)
        app.buttons["Done"].tap(force: true)
        // There is one item plus the default Desktop Bookmarks folder
        checkItemsInBookmarksList(items: 2)
    }

    private func checkItemsInBookmarksList(items: Int) {
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, items)
    }

    private func typeOnSearchBar(text: String) {
        app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].waitAndTap()
        urlBarAddress.typeText(text)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306909
    // Smoketest
    func testBookmarkLibraryAddDeleteBookmark() {
        // Verify that there are only 1 cell (desktop bookmark folder)
        XCTExpectFailure("The app was not launched", strict: false) {
            mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url], timeout: TIMEOUT_LONG)
        }
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        // There is only one row in the bookmarks panel, which is the desktop folder
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, 1)

        // Add a bookmark
        navigator.nowAt(LibraryPanel_Bookmarks)
        navigator.goto(NewTabScreen)

        navigator.openURL(url_3)
        waitForTabsButton()
        bookmark()

        // Check that it appears in Bookmarks panel
        navigator.goto(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.tables["Bookmarks List"])

        // Delete the Bookmark added, check it is removed
        app.tables["Bookmarks List"].cells.staticTexts["Example Domain"].swipeLeft()
        app.buttons["Delete"].tap()
        mozWaitForElementToNotExist(app.tables["Bookmarks List"].cells.staticTexts["Example Domain"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306910
    // Smoketest
    func testDesktopFoldersArePresent() {
        // Verify that there are only 1 cell (desktop bookmark folder)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        // There is only one folder at the root of the bookmarks
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, 1)

        // There is only three folders inside the desktop bookmarks
        app.tables["Bookmarks List"].cells.firstMatch.tap()
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, 3)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306911
    func testRecentlyBookmarked() {
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitForTabsButton()
        bookmark()
        navigator.goto(LibraryPanel_Bookmarks)
        checkItemInBookmarkList(oneItemBookmarked: true)
        navigator.nowAt(LibraryPanel_Bookmarks)
        navigator.goto(NewTabScreen)
        navigator.openURL(path(forTestPage: url_1))
        waitForTabsButton()
        bookmark()
        navigator.goto(LibraryPanel_Bookmarks)
        checkItemInBookmarkList(oneItemBookmarked: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306866
    func testEditBookmark() {
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitForTabsButton()
        bookmarkPageAndTapEdit()
        app.buttons["crossLarge"].tap()
        waitForTabsButton()
        unbookmark()
        bookmarkPageAndTapEdit()
        app.buttons["Save"].tap()
        navigator.goto(LibraryPanel_Bookmarks)
        checkItemInBookmarkList(oneItemBookmarked: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2445808
    func testLongTapRecentlySavedLink() {
        // Go to "Recently saved" section and long tap on one of the links
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitForTabsButton()
        bookmark()
        navigator.performAction(Action.GoToHomePage)
        waitForElementsToExist([app.staticTexts["Bookmarks"], app.cells["BookmarksCell"]])
        app.cells["BookmarksCell"].press(forDuration: 1.5)
        // The context menu opens, having the correct options
        let ContextMenuTable = app.tables["Context Menu"]
        waitForElementsToExist(
            [
                ContextMenuTable,
                ContextMenuTable.cells.otherElements[StandardImageIdentifiers.Large.plus],
                ContextMenuTable.cells.otherElements[StandardImageIdentifiers.Large.privateMode],
                ContextMenuTable.cells.otherElements[StandardImageIdentifiers.Large.bookmarkSlash],
                ContextMenuTable.cells.otherElements[StandardImageIdentifiers.Large.share]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307054
    func testBookmark() {
        navigator.openURL(url_3)
        waitForTabsButton()
        bookmark()
        mozWaitForElementToExist(app.staticTexts["Bookmark Added"])
        unbookmark()
        mozWaitForElementToExist(app.staticTexts["Bookmark Removed"])
    }

    private func bookmarkPageAndTapEdit() {
        bookmark()
        app.buttons["Edit"].waitAndTap()
        mozWaitForElementToExist(app.navigationBars["Edit Bookmark"])
    }
}
