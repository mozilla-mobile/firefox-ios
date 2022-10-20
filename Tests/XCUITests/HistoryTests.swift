// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

let webpage = ["url": "www.mozilla.org", "label": "Internet for people, not profit — Mozilla", "value": "mozilla.org"]
let oldHistoryEntries: [String] = ["Internet for people, not profit — Mozilla", "Twitter", "Home - YouTube"]
let emptyRecentlyClosedMesg = "Websites you’ve visited recently will show up here."
// This is part of the info the user will see in recent closed tabs once the default visited website (https://www.mozilla.org/en-US/book/) is closed
let bookOfMozilla = ["file": "test-mozilla-book.html", "title": "The Book of Mozilla", "label": "localhost:\(serverPort)/test-fixture/test-mozilla-book.html"]

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
        // Go to History List from Top Sites and check it is empty
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells[HistoryPanelA11y.recentlyClosedCell])
        XCTAssertTrue(app.tables.cells[HistoryPanelA11y.recentlyClosedCell].staticTexts["Recently Closed"].exists)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
    }

    func testOpenSyncDevices() {
        // Firefox sync page should be available
        navigator.goto(TabTray)
        navigator.performAction(Action.ToggleSyncMode)
        waitForExistence(app.tables.cells.staticTexts["Firefox Sync"])
        XCTAssertTrue(app.tables.buttons["Sync and Save Data"].exists, "Sign in button does not appear")
    }

    func testClearHistoryFromSettings() {
        // Browse to have an item in history list
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells[HistoryPanelA11y.recentlyClosedCell])
        XCTAssertTrue(app.tables.cells.staticTexts[webpage["label"]!].exists)
        XCTAssertFalse(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)

        // Go to Clear Data
        navigator.goto(HomePanelsScreen)
        navigator.performAction(Action.AcceptClearPrivateData)

        // Back on History panel view check that there is not any item
        navigator.goto(HomePanelsScreen)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        waitForExistence(app.tables.cells[HistoryPanelA11y.recentlyClosedCell])
        XCTAssertFalse(app.tables.cells.staticTexts[webpage["label"]!].exists)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
    }

    // Smoketest
    func testClearPrivateDataButtonDisabled() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 45)
        }
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        // Clear private data from settings and confirm
        navigator.goto(ClearPrivateDataSettings)
        app.tables.cells["ClearPrivateData"].tap()
        waitForExistence(app.tables.cells["ClearPrivateData"])
        app.alerts.buttons["OK"].tap()

        // Wait for OK pop-up to disappear after confirming
        waitForNoExistence(app.alerts.buttons["OK"])

        // Try to tap on the disabled Clear Private Data button
        app.tables.cells["ClearPrivateData"].tap()

        // If the button is disabled, the confirmation pop-up should not exist
        XCTAssertEqual(app.alerts.buttons["OK"].exists, false)
    }

    func testRecentlyClosedWebsiteOpen() {
        openBookOfMozilla()

        // The tab, which is still opened, is not included in the "Recently Closed Tabs List"
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
    }

    func testRecentlyClosedWebsiteClosed() {
        openBookOfMozilla()

        closeFirstTabByX()

        // On regular mode, the closed tab is listed in "Recently Closed Tabs List"
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    func testRecentlyClosedPrivateMode() {
        openBookOfMozilla()

        closeFirstTabByX()

        // Toggle to private mode. The closed tab is listed in "Recently Closed Tabs List"
        navigator.nowAt(HomePanelsScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    func testRemoveAllTabsButton() {
        openBookOfMozilla()

        // Tap "Remove All Tabs" instead of close the tab individually
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)

        // The closed tab is *not* listed in "Recently Closed Tabs List"
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    func testClearRecentlyClosedHistory() {
        openBookOfMozilla()

        closeFirstTabByX()

        // Clear all private data via the settings
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(ClearPrivateDataSettings)
        app.tables.cells["ClearPrivateData"].tap()
        app.alerts.buttons["OK"].tap()

        // The closed tab is *not* listed in "Recently Closed Tabs List"
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    func testLongTapOptionsRecentlyClosedItem() {
        openBookOfMozilla()

        closeFirstTabByX()

        // Long tap a recently closed item launches a context menu
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.otherElements[ImageIdentifiers.newTab].exists)
        XCTAssertTrue(app.tables.otherElements[ImageIdentifiers.newPrivateTab].exists)
    }

    func testOpenInNewTabRecentlyClosedItem() {
        openBookOfMozilla()

        closeFirstTabByX()

        // Ensure the tab is closed
        navigator.goto(TabTray)
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1)
        XCTAssertFalse(app.staticTexts[bookOfMozilla["title"]!].exists)

        // Open the page on a new tab from History Recently Closed screen
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(HistoryRecentlyClosed) // Note: A new tab is open before opening the history page, so there'll be 3 tabs opened at the end.
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[ImageIdentifiers.newTab].tap()
        app.buttons["Done"].tap()

        // The page is opened on the new tab
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        XCTAssertTrue(app.staticTexts[bookOfMozilla["title"]!].exists)
        XCTAssertEqual(userState.numTabs, 3)
    }

    func testOpenInNewPrivateTabRecentlyClosedItem() {
        openBookOfMozilla()

        closeFirstTabByX()

        // Ensure the tab is closed
        navigator.goto(TabTray)
        XCTAssertEqual(userState.numTabs, 1)
        XCTAssertFalse(app.staticTexts[bookOfMozilla["title"]!].exists)

        // Open the page on a new private tab from History Recently Closed screen
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[ImageIdentifiers.newPrivateTab].tap()
        app.buttons["Done"].tap()

        // The page is opened only on the new private tab
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        XCTAssertFalse(app.staticTexts[bookOfMozilla["title"]!].exists)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        XCTAssertTrue(app.staticTexts[bookOfMozilla["title"]!].exists)
        XCTAssertEqual(userState.numTabs, 1)
    }

    func testPrivateClosedSiteDoesNotAppearOnRecentlyClosed() {
        // Open "Book of Mozilla" page in regular mode (not private mode)
        openBookOfMozilla()

        // Open the two tabs in private mode
        // It is necessary to open two sites. When one tab is closed private mode, the private mode still has something opened.
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: bookOfMozilla["file"]!))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.openNewURL(urlString: path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)

        // Close the private tab "Book of Mozilla" by tapping 'x' button
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts[webpage["label"]!])
        if isTablet {
            app.otherElements["Tabs Tray"].collectionViews.cells.element(boundBy: 0).buttons["tab close"].tap()
        } else {
            app.otherElements.cells.element(boundBy: 0).buttons["tab close"].tap()
        }

        // On private mode the "Recently Closed Tabs List" is empty
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)

        // On regular mode the "Recently Closed Tabs List" is empty, too
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    // Private function created to select desired option from the "Clear Recent History" list
    // We used this approach to avoid code duplication
    /*
    private func tapOnClearRecentHistoryOption(optionSelected: String) {
        app.sheets.buttons[optionSelected].tap()
    }
    */

    private func navigateToGoogle() {
        navigator.openURL("example.com")
        waitUntilPageLoad()
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        XCTAssertTrue(app.tables.cells.staticTexts["Example Domain"].exists)
    }

    private func openBookOfMozilla() {
        navigator.openURL(path(forTestPage: bookOfMozilla["file"]!))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
    }

    private func closeFirstTabByX() {
        waitForTabsButton()
        navigator.goto(TabTray)
        app.cells.buttons["tab close"].firstMatch.tap()
    }

    /* Disabled due to default browser onboarding card shown
    func testClearRecentHistory() {
        navigator.performAction(Action.ClearRecentHistory)
        tapOnClearRecentHistoryOption(optionSelected: "The Last Hour")
        // No data will be removed after Action.ClearRecentHistory since there is no recent history created.
        for entry in oldHistoryEntries {
            XCTAssertTrue(app.tables.cells.staticTexts[entry].exists)
        }
        // Go to 'google.com' to create a recent history entry.
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
    func testDeleteHistoryEntryByContextMenu() {
        navigateToGoogle()
        waitForExistence(app.cells.staticTexts["http://example.com/"])
        app.cells.staticTexts["http://example.com/"].firstMatch.press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.cells.otherElements["Delete from History"].tap()
        navigator.nowAt(LibraryPanel_History)
        waitForNoExistence(app.staticTexts["http://example.com"])
    }
}
