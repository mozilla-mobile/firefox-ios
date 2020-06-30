/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let webpage = ["url": "www.mozilla.org", "label": "Internet for people, not profit — Mozilla", "value": "mozilla.org"]
let oldHistoryEntries: [String] = ["Internet for people, not profit — Mozilla", "Twitter", "Home - YouTube"]
// This is part of the info the user will see in recent closed tabs once the default visited website (https://www.mozilla.org/en-US/book/) is closed
let closedWebPageLabel = "localhost:\(serverPort)/test-fixture/test-mozilla-book.html"

class HistoryTests: BaseTestCase {
    let testWithDB = ["testOpenHistoryFromBrowserContextMenuOptions", "testClearHistoryFromSettings", "testClearRecentHistory"]

    // This DDBB contains those 4 websites listed in the name
    let historyDB = "browserYoutubeTwitterMozillaExample.db"
    
    let clearRecentHistoryOptions = ["The Last Hour", "Today", "Today and Yesterday", "Everything"]

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testWithDB.contains(key) {
            // for the current test name, add the db fixture used
            launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet, LaunchArguments.LoadDatabasePrefix + historyDB]
        }
        super.setUp()
    }

    func testEmptyHistoryListFirstTime() {
        // Go to History List from Top Sites and check it is empty
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"])
        XCTAssertTrue(app.tables.cells["HistoryPanel.recentlyClosedCell"].exists)
    }

    func testOpenSyncDevices() {
        navigator.goto(LibraryPanel_SyncedTabs)
        waitForExistence(app.tables.cells.staticTexts["Firefox Sync"])
        XCTAssertTrue(app.tables.buttons["Sign in to Sync"].exists, "Sing in button does not appear")
    }

    func testClearHistoryFromSettings() {
        // Browse to have an item in history list
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"], timeout: 5)
        XCTAssertTrue(app.tables.cells.staticTexts[webpage["label"]!].exists)

        // Go to Clear Data
        navigator.performAction(Action.AcceptClearPrivateData)

        // Back on History panel view check that there is not any item
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"])
        XCTAssertFalse(app.tables.cells.staticTexts[webpage["label"]!].exists)
    }

    func testClearPrivateDataButtonDisabled() {
        //Clear private data from settings and confirm
        navigator.goto(ClearPrivateDataSettings)
        app.tables.cells["ClearPrivateData"].tap()
        app.alerts.buttons["OK"].tap()
        
        //Wait for OK pop-up to disappear after confirming
        waitForNoExistence(app.alerts.buttons["OK"], timeoutValue:5)
        
        //Try to tap on the disabled Clear Private Data button
        app.tables.cells["ClearPrivateData"].tap()
        
        //If the button is disabled, the confirmation pop-up should not exist
        XCTAssertEqual(app.alerts.buttons["OK"].exists, false)
    }

    func testRecentlyClosedOptionAvailable() {
        navigator.goto(HistoryRecentlyClosed)
        waitForNoExistence(app.tables["Recently Closed Tabs List"])

        // Go to the default web site  and check whether the option is enabled
        navigator.nowAt(LibraryPanel_History)
        navigator.goto(HomePanelsScreen)
        userState.url = path(forTestPage: "test-mozilla-book.html")
        navigator.goto(BrowserTab)
        navigator.goto(BrowserTabMenu)
        // Workaround to bug 1508368
        navigator.goto(LibraryPanel_Bookmarks)
        navigator.goto(LibraryPanel_History)
        navigator.goto(HistoryRecentlyClosed)
        waitForNoExistence(app.tables["Recently Closed Tabs List"])
        navigator.nowAt(LibraryPanel_History)
        navigator.goto(HomePanelsScreen)

        // Now go back to default website close it and check whether the option is enabled
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        navigator.goto(HistoryRecentlyClosed)

        // The Closed Tabs list should contain the info of the website just closed
        waitForExistence(app.tables["Recently Closed Tabs List"], timeout: 3)
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)

        navigator.goto(HomePanelsScreen)

        // This option should be enabled on private mode too
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
    }

    func testClearRecentlyClosedHistory() {
        // Open the default website
        userState.url = path(forTestPage: "test-mozilla-book.html")
        navigator.goto(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        navigator.goto(HistoryRecentlyClosed)
        // Once the website is visited and closed it will appear in Recently Closed Tabs list
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)

        navigator.goto(HomePanelsScreen)

        // Go to settings and clear private data
        navigator.performAction(Action.AcceptClearPrivateData)

        // Back on History panel view check that there is not any item
        navigator.goto(HistoryRecentlyClosed)
        waitForNoExistence(app.tables["Recently Closed Tabs List"])
    }

    func testLongTapOptionsRecentlyClosedItem() {
        // Open the default website
        userState.url = path(forTestPage: "test-mozilla-book.html")
        navigator.goto(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)
        app.tables.cells.staticTexts[closedWebPageLabel].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.cells["quick_action_new_tab"].exists)
        XCTAssertTrue(app.tables.cells["quick_action_new_private_tab"].exists)
    }

    func testOpenInNewTabRecentlyClosedItem() {
        // Open the default website
        userState.url = path(forTestPage: "test-mozilla-book.html")
        navigator.goto(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1)
        app.tables.cells.staticTexts[closedWebPageLabel].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables.cells["quick_action_new_tab"].tap()
        navigator.goto(TabTray)
        let numTabsOpen2 = userState.numTabs
        XCTAssertEqual(numTabsOpen2, 2)
    }

    func testOpenInNewPrivateTabRecentlyClosedItem() {
        // Open the default website
        userState.url = path(forTestPage: "test-mozilla-book.html")
        navigator.goto(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)

        app.tables.cells.staticTexts[closedWebPageLabel].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables.cells["quick_action_new_private_tab"].tap()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1)
    }

    func testPrivateClosedSiteDoesNotAppearOnRecentlyClosed() {
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        // Open the default website
        userState.url = path(forTestPage: "test-mozilla-book.html")
        navigator.goto(BrowserTab)
        // It is necessary to open two sites so that when one is closed private mode is not closed
        navigator.openNewURL(urlString: path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)
        waitForExistence(app.collectionViews.cells[webpage["label"]!])
        // 'x' button to close the tab is not visible, so closing by swiping the tab
        app.collectionViews.cells[webpage["label"]!].swipeRight()

        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(HomePanelsScreen)
        navigator.goto(LibraryPanel_History)
        XCTAssertFalse(app.cells.staticTexts["Recently Closed"].isSelected)
        waitForNoExistence(app.tables["Recently Closed Tabs List"])

        // Now verify that on regular mode the recently closed list is empty too
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        XCTAssertFalse(app.cells.staticTexts["Recently Closed"].isSelected)
        waitForNoExistence(app.tables["Recently Closed Tabs List"])
    }
    
    // Private function created to select desired option from the "Clear Recent History" list
    // We used this aproch to avoid code duplication
    private func tapOnClearRecentHistoryOption(optionSelected: String) {
        app.sheets.buttons[optionSelected].tap()
    }
    
    private func navigateToGoogle(){
        navigator.openURL("example.com")
        navigator.goto(LibraryPanel_History)
        XCTAssertTrue(app.tables.cells.staticTexts["Example Domain"].exists)
    }
    
    func testClearRecentHistory() {
        navigator.performAction(Action.ClearRecentHistory)
        tapOnClearRecentHistoryOption(optionSelected: "The Last Hour")
        // No data will be removed after Action.ClearRecentHistory since there is no recent history created.
        for entry in oldHistoryEntries {
            XCTAssertTrue(app.tables.cells.staticTexts[entry].exists)
        }
        // Go to 'goolge.com' to create a recent history entry.
        navigateToGoogle()
        navigator.performAction(Action.ClearRecentHistory)
        // Recent data will be removed after calling tapOnClearRecentHistoryOption(optionSelected: "Today").
        // Older data will not be removed
        tapOnClearRecentHistoryOption(optionSelected: "Today")
        for entry in oldHistoryEntries {
            XCTAssertTrue(app.tables.cells.staticTexts[entry].exists)
        }
        XCTAssertFalse(app.tables.cells.staticTexts["Google"].exists)
        
        // Begin Test for Today and Yesterday
        // Go to 'goolge.com' to create a recent history entry.
        navigateToGoogle()
        navigator.performAction(Action.ClearRecentHistory)
        // Tapping "Today and Yesterday" will remove recent data (from yesterday and today).
        // Older data will not be removed
        tapOnClearRecentHistoryOption(optionSelected: "Today and Yesterday")
        for entry in oldHistoryEntries {
            XCTAssertTrue(app.tables.cells.staticTexts[entry].exists)
        }
        XCTAssertFalse(app.tables.cells.staticTexts["Google"].exists)
        
        // Begin Test for Everything
        // Go to 'goolge.com' to create a recent history entry.
        navigateToGoogle()
        navigator.performAction(Action.ClearRecentHistory)
        // Tapping everything removes both current data and older data.
        tapOnClearRecentHistoryOption(optionSelected: "Everything")
        for entry in oldHistoryEntries {
            waitForNoExistence(app.tables.cells.staticTexts[entry], timeoutValue: 10)

        XCTAssertFalse(app.tables.cells.staticTexts[entry].exists, "History not removed")
        }
        XCTAssertFalse(app.tables.cells.staticTexts["Google"].exists)
        
    }
    
    func testAllOptionsArePresent(){
        // Go to 'goolge.com' to create a recent history entry.
        navigateToGoogle()
        navigator.performAction(Action.ClearRecentHistory)
        for option in clearRecentHistoryOptions {
            XCTAssertTrue(app.sheets.buttons[option].exists)
        }
    }

    // Smoketest
    func testDeleteHistoryEntryBySwiping() {
        navigateToGoogle()
        navigator.goto(LibraryPanel_History)
        print(app.debugDescription)
        waitForExistence(app.cells.staticTexts["http://example.com/"], timeout: 10)
        app.cells.staticTexts["http://example.com/"].firstMatch.swipeLeft()
        waitForExistence(app.buttons["Delete"], timeout: 10)
        app.buttons["Delete"].tap()
        waitForNoExistence(app.staticTexts["http://example.com"])
    }
}
