// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

class ReaderViewTest: BaseTestCase {
    // Smoketest
    func testLoadReaderContent() {
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        navigator.goto(BrowserTab)
        waitForNoExistence(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        waitForExistence(app.buttons["Reader View"], timeout: 5)
        app.buttons["Reader View"].tap()
        // The settings of reader view are shown as well as the content of the web site
        waitForExistence(app.buttons["Display Settings"], timeout: 5)
        XCTAssertTrue(app.webViews.staticTexts["The Book of Mozilla"].exists)
    }

    // TODO: Fine better way to update screen graph when necessary
    private func updateScreenGraph() {
        navigator = createScreenGraph(for: self, with: app).navigator()
        userState = navigator.userState
    }

    private func addContentToReaderView() {
        updateScreenGraph()
        userState.url = path(forTestPage: "test-mozilla-book.html")
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        waitForExistence(app.buttons["Reader View"], timeout: 5)
        app.buttons["Reader View"].tap()
        waitUntilPageLoad()
        waitForExistence(app.buttons["Add to Reading List"])
        app.buttons["Add to Reading List"].tap()
    }

    private func checkReadingListNumberOfItems(items: Int) {
        waitForExistence(app.tables["ReadingTable"])
        let list = app.tables["ReadingTable"].cells.count
        XCTAssertEqual(list, items, "The number of items in the reading table is not correct")
    }

    // Smoketest
    func testAddToReadingList() {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 25)
        }
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        // Navigate to reading list
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check to make sure the reading list is empty
        checkReadingListNumberOfItems(items: 0)
        app.buttons["Done"].tap()
        // Add item to reading list and check that it appears
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check that there is one item
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)
        XCTAssertTrue(savedToReadingList.exists)
        checkReadingListNumberOfItems(items: 1)
    }

    func testAddToReadingListPrivateMode() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Initially reading list is empty
        checkReadingListNumberOfItems(items: 0)
        app.buttons["Done"].tap()
        // Add item to reading list and check that it appears
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check that there is one item
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)
        XCTAssertTrue(savedToReadingList.exists)
        checkReadingListNumberOfItems(items: 1)
        app.buttons["Done"].tap()
        updateScreenGraph()
        // Check that it appears on regular mode
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 1)
    }

    func testMarkAsReadAndUreadFromReaderView() {
        addContentToReaderView()

        // Mark the content as read, so the mark as unread buttons appear
        app.buttons["Mark as Read"].tap()
        waitForExistence(app.buttons["Mark as Unread"])

        // Mark the content as unread, so the mark as read button appear
        app.buttons["Mark as Unread"].tap()
        waitForExistence(app.buttons["Mark as Read"])
    }

    func testRemoveFromReadingView() {
        addContentToReaderView()
        // Once the content has been added, remove it
        waitForExistence(app.buttons["Remove from Reading List"])
        app.buttons["Remove from Reading List"].tap()

        // Check that instead of the remove icon now it is shown the add to read list
        waitForExistence(app.buttons["Add to Reading List"])

        // Go to reader list view to check that there is not any item there
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 0)
    }

    func testMarkAsReadAndUnreadFromReadingList() {
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        navigator.goto(LibraryPanel_ReadingList)

        waitForExistence(app.tables["ReadingTable"])
        // Check that there is one item
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        XCTAssertTrue(savedToReadingList.exists)

        // Mark it as read/unread
        savedToReadingList.swipeLeft()
        waitForExistence(app.tables.cells.buttons.staticTexts["Mark as  Read"], timeout: 3)
        app.tables["ReadingTable"].cells.buttons.element(boundBy: 1).tap()
        savedToReadingList.swipeLeft()
        waitForExistence(app.tables.cells.buttons.staticTexts["Mark as  Unread"])
    }

    func testRemoveFromReadingList() {
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)
        savedToReadingList.swipeLeft()
        waitForExistence(app.buttons["Remove"])

        // Remove the item from reading list
        app.buttons["Remove"].tap()
        XCTAssertFalse(savedToReadingList.exists)

        // Reader list view should be empty
        checkReadingListNumberOfItems(items: 0)
    }

    func testAddToReadingListFromBrowserTabMenu() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        // First time Reading list is empty
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 0)
        app.buttons["Done"].tap()
        // Add item to Reading List from Page Options Menu
        updateScreenGraph()
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.performAction(Action.AddToReadingListBrowserTabMenu)
        // Now there should be an item on the list
        navigator.nowAt(BrowserTab)
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 1)
    }

    func testOpenSavedForReadingLongPressInNewTab() {
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual(numTab, "1")

        // Add item to Reading List
        addContentToReaderView()
        navigator.goto(LibraryPanel_ReadingList)

        // Long tap on the item just saved
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)
        savedToReadingList.press(forDuration: 1)

        // Select to open in New Tab
        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[ImageIdentifiers.newTab].tap()
        app.buttons["Done"].tap()
        updateScreenGraph()
        // Now there should be two tabs open
        navigator.goto(HomePanelsScreen)
        let numTabAfter = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual(numTabAfter, "2")
    }

    func testRemoveSavedForReadingLongPress() {
        // Add item to Reading List
        addContentToReaderView()
        navigator.goto(LibraryPanel_ReadingList)

        // Long tap on the item just saved and choose remove
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)
        savedToReadingList.press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[ImageIdentifiers.actionRemove].tap()

        // Verify the item has been removed
        waitForNoExistence(app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"])
        XCTAssertFalse(app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"].exists)
    }

    // Smoketest
    func testAddToReaderListOptions() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 45)
        }
        addContentToReaderView()
        // Check that Settings layouts options are shown
        waitForExistence(app.buttons["ReaderModeBarView.settingsButton"], timeout: 10)
        app.buttons["ReaderModeBarView.settingsButton"].tap()
        XCTAssertTrue(app.buttons["Light"].exists)
    }
}
