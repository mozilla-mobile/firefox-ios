// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

let webpage = ["url": "www.mozilla.org", "label": "Internet for people, not profit — Mozilla", "value": "mozilla.org"]
let oldHistoryEntries: [String] = ["Internet for people, not profit — Mozilla", "Twitter", "Home - YouTube"]
// This is part of the info the user will see in recent closed tabs once the default visited website (https://www.mozilla.org/en-US/book/) is closed
let closedWebPageLabel = "localhost:\(serverPort)/test-fixture/test-mozilla-book.html"

class HistoryTests: BaseTestCase {

    typealias HistoryPanelA11y = AccessibilityIdentifiers.LibraryPanels.HistoryPanel

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
            launchArguments = [LaunchArguments.SkipIntro,
                               LaunchArguments.SkipWhatsNew,
                               LaunchArguments.SkipETPCoverSheet,
                               LaunchArguments.SkipDefaultBrowserOnboarding,
                               LaunchArguments.LoadDatabasePrefix + historyDB,
                               LaunchArguments.SkipContextualHints,
                               LaunchArguments.TurnOffTabGroupsInUserPreferences]
        }
        super.setUp()
    }

    func testEmptyHistoryListFirstTime() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        // Go to History List from Top Sites and check it is empty
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells[HistoryPanelA11y.recentlyClosedCell])
        XCTAssertTrue(app.tables.cells[HistoryPanelA11y.recentlyClosedCell].exists)
    }

    func testOpenSyncDevices() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.ToggleSyncMode)
        waitForExistence(app.tables.cells.staticTexts["Firefox Sync"])
        XCTAssertTrue(app.tables.buttons["Sign in to Sync"].exists, "Sing in button does not appear")
    }

    func testClearHistoryFromSettings() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        // Browse to have an item in history list
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells[HistoryPanelA11y.recentlyClosedCell], timeout: 5)
        XCTAssertTrue(app.tables.cells.staticTexts[webpage["label"]!].exists)

        // Go to Clear Data
        navigator.goto(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.AcceptClearPrivateData)

        // Back on History panel view check that there is not any item
        navigator.goto(HomePanelsScreen)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells[HistoryPanelA11y.recentlyClosedCell])
        XCTAssertFalse(app.tables.cells.staticTexts[webpage["label"]!].exists)
    }

    // Smoketest
    func testClearPrivateDataButtonDisabled() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 45)
        }
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 5)
        // Clear private data from settings and confirm
        navigator.goto(ClearPrivateDataSettings)
        app.tables.cells["ClearPrivateData"].tap()
        waitForExistence(app.tables.cells["ClearPrivateData"], timeout: 10)
        app.alerts.buttons["OK"].tap()

        // Wait for OK pop-up to disappear after confirming
        waitForNoExistence(app.alerts.buttons["OK"], timeoutValue: 5)

        // Try to tap on the disabled Clear Private Data button
        app.tables.cells["ClearPrivateData"].tap()

        // If the button is disabled, the confirmation pop-up should not exist
        XCTAssertEqual(app.alerts.buttons["OK"].exists, false)
    }

    func testRecentlyClosedOptionAvailable() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForNoExistence(app.tables["Recently Closed Tabs List"])

        // Go to the default web site  and check whether the option is enabled
        navigator.nowAt(LibraryPanel_History)
        navigator.goto(HomePanelsScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        // Workaround to bug 1508368
        navigator.goto(LibraryPanel_Bookmarks)
        navigator.goto(HomePanelsScreen)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
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
        navigator.performAction(Action.CloseURLBarOpen)
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
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
    }

    func testClearRecentlyClosedHistory() {
        // Open the default website
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        navigator.goto(HistoryRecentlyClosed)
        // Once the website is visited and closed it will appear in Recently Closed Tabs list
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)

        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)

        // Go to settings and clear private data
        navigator.goto(ClearPrivateDataSettings)
        app.tables.cells["ClearPrivateData"].tap()
        app.alerts.buttons["OK"].tap()

        // Back on History panel view check that there is not any item
        navigator.goto(HomePanelsScreen)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForNoExistence(app.tables["Recently Closed Tabs List"])
    }

    func testLongTapOptionsRecentlyClosedItem() {
        // Open the default website
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)

        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)
        app.tables.cells.staticTexts[closedWebPageLabel].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.otherElements[ImageIdentifiers.newTab].exists)
        XCTAssertTrue(app.tables.otherElements[ImageIdentifiers.newPrivateTab].exists)
    }

    func testOpenInNewTabRecentlyClosedItem() {
        // Open the default website
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1)
        app.tables.cells.staticTexts[closedWebPageLabel].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[ImageIdentifiers.newTab].tap()
        navigator.goto(TabTray)
        let numTabsOpen2 = userState.numTabs
        XCTAssertEqual(numTabsOpen2, 2)
    }

    func testOpenInNewPrivateTabRecentlyClosedItem() {
        // Open the default website
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)

        app.tables.cells.staticTexts[closedWebPageLabel].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[ImageIdentifiers.newPrivateTab].tap()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1)
    }

    func testPrivateClosedSiteDoesNotAppearOnRecentlyClosed() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        // Open the default website
        userState.url = path(forTestPage: "test-mozilla-book.html")
        navigator.nowAt(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(userState.url!)
        // It is necessary to open two sites so that when one is closed private mode is not closed
        navigator.openNewURL(urlString: path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts[webpage["label"]!])
        // Close tab by tapping on its 'x' button
        if isTablet {
            app.otherElements["Tabs Tray"].collectionViews.cells.element(boundBy: 0).buttons["tab close"].tap()
        } else {
            app.otherElements.cells.element(boundBy: 0).buttons["tab close"].tap()
        }

        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(HomePanelsScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        XCTAssertFalse(app.cells.staticTexts["Recently Closed"].isSelected)
        waitForNoExistence(app.tables["Recently Closed Tabs List"])

        // Now verify that on regular mode the recently closed list is empty too
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        XCTAssertFalse(app.cells.staticTexts["Recently Closed"].isSelected)
        waitForNoExistence(app.tables["Recently Closed Tabs List"])
    }

    // Private function created to select desired option from the "Clear Recent History" list
    // We used this aproch to avoid code duplication
    private func tapOnClearRecentHistoryOption(optionSelected: String) {
        app.sheets.buttons[optionSelected].tap()
    }

    private func navigateToGoogle() {
        navigator.openURL("example.com")
        waitUntilPageLoad()
        // Workaround as the item does not appear if there is only that tab open
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 15)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView], timeout: 5)
        XCTAssertTrue(app.tables.cells.staticTexts["Example Domain"].exists)
    }

    /* Disabled due to default browser onboarding card shown
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
    }*/

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
