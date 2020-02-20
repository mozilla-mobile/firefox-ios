/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ReaderViewTest: BaseTestCase {
    // Smoketest
    func testLoadReaderContent() {
        userState.url = Base.helper.path(forTestPage: "test-mozilla-book.html")
        navigator.goto(BrowserTab)
        Base.app.buttons["Reader View"].tap()
        Base.app.buttons["Reload"].tap()
        // The settings of reader view are shown as well as the content of the web site
        Base.helper.waitForExistence(Base.app.buttons["Display Settings"])
        XCTAssertTrue(Base.app.webViews.staticTexts["The Book of Mozilla"].exists)
    }

    private func addContentToReaderView() {
        userState.url = Base.helper.path(forTestPage: "test-mozilla-book.html")
        navigator.goto(BrowserTab)
        Base.helper.waitUntilPageLoad()
        Base.app.buttons["Reader View"].tap()
        Base.app.buttons["Reload"].tap()
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.buttons["Add to Reading List"])
        Base.app.buttons["Add to Reading List"].tap()
    }

    private func checkReadingListNumberOfItems(items: Int) {
        Base.helper.waitForExistence(Base.app.tables["ReadingTable"])
        let list = Base.app.tables["ReadingTable"].cells.count
        XCTAssertEqual(list, items, "The number of items in the reading table is not correct")
    }

    // Smoketest
    func testAddToReadingList() {
        // Navigate to reading list
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        
        // Check that ReadingList and Bookmarks button is enabled
        XCTAssertFalse(Base.app.buttons["LibraryPanels.Bookmarks"].isSelected)
        XCTAssertTrue(Base.app.buttons["LibraryPanels.ReadingList"].isSelected)

        // Check to make sure the reading list is empty
        checkReadingListNumberOfItems(items: 0)
        
        // Add item to reading list and check that it Base.appears
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        Base.helper.waitForExistence(Base.app.buttons["LibraryPanels.ReadingList"])

        // Check that there is one item
        let savedToReadingList = Base.app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        Base.helper.waitForExistence(savedToReadingList)
        XCTAssertTrue(savedToReadingList.exists)
        checkReadingListNumberOfItems(items: 1)
    }

    func testAddToReadingListPrivateMode() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        
        // Check that ReadingList and Bookmarks button is enabled
        XCTAssertFalse(Base.app.buttons["LibraryPanels.Bookmarks"].isSelected)
        XCTAssertTrue(Base.app.buttons["LibraryPanels.ReadingList"].isSelected)
        
        // Initially reading list is empty
        checkReadingListNumberOfItems(items: 0)

        // Add item to reading list and check that it Base.appears
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        Base.helper.waitForExistence(Base.app.buttons["LibraryPanels.ReadingList"])

        // Check that there is one item
        let savedToReadingList = Base.app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        Base.helper.waitForExistence(savedToReadingList)
        XCTAssertTrue(savedToReadingList.exists)
        checkReadingListNumberOfItems(items: 1)

        // Check that it Base.appears on regular mode
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 1)
    }

    func testMarkAsReadAndUreadFromReaderView() {
        addContentToReaderView()

        // Mark the content as read, so the mark as unread buttons Base.appear
        Base.app.buttons["Mark as Read"].tap()
        Base.helper.waitForExistence(Base.app.buttons["Mark as Unread"])

        // Mark the content as unread, so the mark as read button Base.appear
        Base.app.buttons["Mark as Unread"].tap()
        Base.helper.waitForExistence(Base.app.buttons["Mark as Read"])
    }

    func testRemoveFromReadingView() {
        addContentToReaderView()
        // Once the content has been added, remove it
        Base.helper.waitForExistence(Base.app.buttons["Remove from Reading List"])
        Base.app.buttons["Remove from Reading List"].tap()

        // Check that instead of the remove icon now it is shown the add to read list
        Base.helper.waitForExistence(Base.app.buttons["Add to Reading List"])

        // Go to reader list view to check that there is not any item there
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        Base.helper.waitForExistence(Base.app.buttons["LibraryPanels.ReadingList"])
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 0)
    }

    func testMarkAsReadAndUnreadFromReadingList() {
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        Base.helper.waitForExistence(Base.app.buttons["LibraryPanels.ReadingList"])
        navigator.goto(LibraryPanel_ReadingList)

        // Check that there is one item
        let savedToReadingList = Base.app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        XCTAssertTrue(savedToReadingList.exists)

        // Mark it as read/unread
        savedToReadingList.swipeLeft()
        Base.helper.waitForExistence(Base.app.tables.cells.buttons["trailing1"].staticTexts["Mark as  Read"])
        Base.app.tables.cells.buttons["trailing1"].tap()
        savedToReadingList.swipeLeft()
        Base.helper.waitForExistence(Base.app.buttons["trailing1"].staticTexts["Mark as  Unread"])
    }

    func testRemoveFromReadingList() {
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        Base.helper.waitForExistence(Base.app.buttons["LibraryPanels.ReadingList"])
        navigator.goto(LibraryPanel_ReadingList)

        let savedToReadingList = Base.app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        savedToReadingList.swipeLeft()
        Base.helper.waitForExistence(Base.app.buttons["Remove"])

        // Remove the item from reading list
        Base.app.buttons["Remove"].tap()
        XCTAssertFalse(savedToReadingList.exists)

        // Reader list view should be empty
        checkReadingListNumberOfItems(items: 0)
    }

    func testAddToReadingListFromPageOptionsMenu() {
        // First time Reading list is empty
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 0)

        // Add item to Reading List from Page Options Menu
        userState.url = Base.helper.path(forTestPage: "test-mozilla-book.html")
        navigator.goto(BrowserTab)
        Base.helper.waitUntilPageLoad()
        navigator.browserPerformAction(.addReadingListOption)

        // Now there should be an item on the list
        navigator.nowAt(BrowserTab)
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 1)
    }

    func testOpenSavedForReadingLongPressInNewTab() {
        let numTab = Base.app.buttons["Show Tabs"].value as? String
        XCTAssertEqual(numTab, "1")

        // Add item to Reading List
        addContentToReaderView()
        navigator.goto(LibraryPanel_ReadingList)

        // Long tap on the item just saved
        let savedToReadingList = Base.app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        savedToReadingList.press(forDuration: 1)

        // Select to open in New Tab
        Base.helper.waitForExistence(Base.app.tables["Context Menu"])
        Base.app.tables.cells["quick_action_new_tab"].tap()

        // Now there should be two tabs open
        navigator.goto(HomePanelsScreen)
        let numTabAfter = Base.app.buttons["Show Tabs"].value as? String
        XCTAssertEqual(numTabAfter, "2")
    }

    func testRemoveSavedForReadingLongPress() {
        // Add item to Reading List
        addContentToReaderView()
        navigator.goto(LibraryPanel_ReadingList)

        // Long tap on the item just saved and choose remove
        let savedToReadingList = Base.app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        savedToReadingList.press(forDuration: 1)
        Base.helper.waitForExistence(Base.app.tables["Context Menu"])
        Base.app.tables.cells["action_remove"].tap()

        // Verify the item has been removed
        Base.helper.waitForNoExistence(Base.app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"])
        XCTAssertFalse(Base.app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"].exists)
    }

    // Smoketest
    func testAddToReaderListOptions() {
        addContentToReaderView()
        // Check that Settings layouts options are shown
        Base.helper.waitForExistence(Base.app.buttons["ReaderModeBarView.settingsButton"], timeout: 10)
        Base.app.buttons["ReaderModeBarView.settingsButton"].tap()
        XCTAssertTrue(Base.app.buttons["Light"].exists)
    }
}
