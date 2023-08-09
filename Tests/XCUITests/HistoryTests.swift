// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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
    let historyDB = "browserYoutubeTwitterMozillaExample-places.db"

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
        navigator.nowAt(NewTabScreen)

        // Go to History List from Top Sites and check it is empty
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells[HistoryPanelA11y.recentlyClosedCell])
        XCTAssertTrue(app.tables.cells[HistoryPanelA11y.recentlyClosedCell].staticTexts["Recently Closed"].exists)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
    }

    func testOpenSyncDevices() {
        // Firefox sync page should be available
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.ToggleSyncMode)
        waitForExistence(app.tables.cells.staticTexts["Firefox Sync"])
        XCTAssertTrue(app.tables.buttons["Sync and Save Data"].exists, "Sign in button does not appear")
    }

    func testClearHistoryFromSettings() throws {
        throw XCTSkip("MTE-514 Database may not be loaded")
        /*
        navigator.nowAt(NewTabScreen)

        // Browse to have an item in history list
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells[HistoryPanelA11y.recentlyClosedCell], timeout: TIMEOUT)
        XCTAssertTrue(app.tables.cells.staticTexts[webpage["label"]!].exists)
        XCTAssertFalse(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)

        // Go to Clear Data
        navigator.goto(NewTabScreen)
        navigator.performAction(Action.AcceptClearPrivateData)

        // Back on History panel view check that there is not any item
        navigator.goto(HomePanelsScreen)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        waitForExistence(app.tables.cells[HistoryPanelA11y.recentlyClosedCell])
        XCTAssertFalse(app.tables.cells.staticTexts[webpage["label"]!].exists)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        */
    }

    // Smoketest
    func testClearPrivateDataButtonDisabled() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
        navigator.nowAt(NewTabScreen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: TIMEOUT)
        // Clear private data from settings and confirm
        navigator.goto(ClearPrivateDataSettings)
        app.tables.cells["ClearPrivateData"].tap()
        waitForExistence(app.tables.cells["ClearPrivateData"], timeout: TIMEOUT)
        app.alerts.buttons["OK"].tap()

        // Wait for OK pop-up to disappear after confirming
        waitForNoExistence(app.alerts.buttons["OK"], timeoutValue: TIMEOUT)

        // Try to tap on the disabled Clear Private Data button
        app.tables.cells["ClearPrivateData"].tap()

        // If the button is disabled, the confirmation pop-up should not exist
        XCTAssertEqual(app.alerts.buttons["OK"].exists, false)
        }
    }

    func testRecentlyClosedNoWebsiteOpen() {
        // "Recently Closed Tabs List" is empty by default
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
    }

    func testRecentlyClosedWebsiteOpen() {
        // Open "Book of Mozilla"
        openBookOfMozilla()

        // The tab, which is still opened, is not included in the "Recently Closed Tabs List"
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
    }

    func testRecentlyClosedWebsiteClosed() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // On regular mode, the closed tab is listed in "Recently Closed Tabs List"
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)

        // On private mode, the closed tab on regular mode is listed in "Recently Closed Tabs List" as well
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        closeKeyboard()
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    func testRecentlyClosedPrivateMode() {
        // Open "Book of Mozilla" on private mode and close the tab
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        openBookOfMozilla()
        closeFirstTabByX()

        // "Recently Closed Tabs List" is empty
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        closeKeyboard()
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    func testRemoveAllTabsButtonRecentlyClosedHistory() {
        // Open "Book of Mozilla"
        openBookOfMozilla()

        // Tap "Remove All Tabs" instead of close the tab individually
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)

        // The closed tab is *not* listed in "Recently Closed Tabs List" (FXIOS-5128)
        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    func testClearRecentlyClosedHistory() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Once the website is visited and closed it will appear in Recently Closed Tabs list
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)

        // Clear all private data via the settings
        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
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
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Long tap a recently closed item launches a context menu
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.plus].exists)
        XCTAssertTrue(app.tables.otherElements[ImageIdentifiers.newPrivateTab].exists)
    }

    func testOpenInNewTabRecentlyClosedItem() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Open the page on a new tab from History Recently Closed screen
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        XCTAssertEqual(userState.numTabs, 1)
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[StandardImageIdentifiers.Large.plus].tap()

        // The page is opened on the new tab
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        if isTablet {
            waitForExistence(app.navigationBars.segmentedControls["navBarTabTray"])
        } else {
            waitForExistence(app.navigationBars.staticTexts["Open Tabs"])
        }
        XCTAssertTrue(app.staticTexts[bookOfMozilla["title"]!].exists)
        XCTAssertEqual(userState.numTabs, 2)
    }

    func testOpenInNewPrivateTabRecentlyClosedItem() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Open the page on a new private tab from History Recently Closed screen
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[ImageIdentifiers.newPrivateTab].tap()

        // The page is opened only on the new private tab
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        if isTablet {
            waitForExistence(app.navigationBars.segmentedControls["navBarTabTray"])
        } else {
            waitForExistence(app.navigationBars.staticTexts["Open Tabs"])
        }
        XCTAssertFalse(app.staticTexts[bookOfMozilla["title"]!].isHittable)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        if isTablet {
            XCTAssertTrue(app.segmentedControls.buttons["Private"].isSelected)
        } else {
            waitForExistence(app.staticTexts["Private Browsing"])
        }
        XCTAssertTrue(app.staticTexts[bookOfMozilla["title"]!].exists)
        XCTAssertEqual(userState.numTabs, 1)
    }

    func testPrivateClosedSiteDoesNotAppearOnRecentlyClosed() {
        navigator.nowAt(NewTabScreen)

        // Open the two tabs in private mode
        // It is necessary to open two sites. When one tab is closed private mode, the private mode still has something opened.
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: bookOfMozilla["file"]!))
        waitUntilPageLoad()
        navigator.openNewURL(urlString: path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()

        // Close the private tab "Book of Mozilla" by tapping 'x' button
        waitForTabsButton()
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts[webpage["label"]!])
        closeFirstTabByX()

        // On private mode, the "Recently Closed Tabs List" is empty
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(HomePanelsScreen)
        closeKeyboard()
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        waitForNoExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertFalse(app.cells.staticTexts["Recently Closed"].isSelected)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)

        // On regular mode, the "Recently Closed Tabs List" is empty, too
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)
        navigator.goto(NewTabScreen)
        closeKeyboard()
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView])
        waitForNoExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertFalse(app.cells.staticTexts["Recently Closed"].isSelected)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    // Smoke & Functional
    func testTabHistory() {
        navigator.nowAt(NewTabScreen)
        openBookOfMozilla()
        let urlBarBackButton = app.windows.otherElements.buttons[AccessibilityIdentifiers.Toolbar.backButton]
        let urlBarForwardButton = app.windows.otherElements.buttons[AccessibilityIdentifiers.Toolbar.forwardButton]
        urlBarBackButton.press(forDuration: 1)
        XCTAssertTrue(app.tables.staticTexts["The Book of Mozilla"].exists)
        app.tables.staticTexts["The Book of Mozilla"].tap()
        XCTAssertFalse(app.tables.staticTexts["The Book of Mozilla"].exists)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        openBookOfMozilla()
        urlBarBackButton.press(forDuration: 1)
        XCTAssertTrue(app.tables.staticTexts["The Book of Mozilla"].exists)
        app.tables.staticTexts["The Book of Mozilla"].tap()
        urlBarBackButton.tap()
        XCTAssertFalse(urlBarBackButton.isEnabled)
        urlBarForwardButton.press(forDuration: 1)
        XCTAssertTrue(app.tables.staticTexts["The Book of Mozilla"].exists)
        app.tables.staticTexts["The Book of Mozilla"].tap()
        waitForValueContains(app.textFields["url"], value: "test-fixture/test-mozilla-book.html")
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
        // Workaround as the item does not appear if there is only that tab open
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: TIMEOUT_LONG)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[HistoryPanelA11y.tableView], timeout: TIMEOUT)
        XCTAssertTrue(app.tables.cells.staticTexts["Example Domain"].exists)
    }

    private func openBookOfMozilla() {
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: bookOfMozilla["file"]!))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
    }

    private func closeFirstTabByX() {
        // Workaround for FXIOS-5128. To be replaced by tapping "Close All Tabs"
        waitForTabsButton()
        navigator.goto(TabTray)
        if isTablet {
            app.otherElements["Tabs Tray"].collectionViews.cells.element(boundBy: 0).buttons[StandardImageIdentifiers.Large.cross].tap()
        } else {
            app.cells.buttons[StandardImageIdentifiers.Large.cross].firstMatch.tap()
            // app.otherElements.cells.element(boundBy: 0).buttons[StandardImageIdentifiers.Large.cross].tap()
        }
    }

    private func closeKeyboard() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: TIMEOUT)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
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
    func testDeleteHistoryEntryBySwiping() throws {
        if processIsTranslatedStr() == m1Rosetta {
            throw XCTSkip("Swipe gesture does not work on M1")
        } else {
            navigateToGoogle()
            navigator.goto(LibraryPanel_History)
            waitForExistence(app.cells.staticTexts["http://example.com/"], timeout: TIMEOUT)
            app.cells.staticTexts["http://example.com/"].firstMatch.swipeLeft()
            waitForExistence(app.buttons[StandardImageIdentifiers.Large.delete], timeout: TIMEOUT)
            app.buttons[StandardImageIdentifiers.Large.delete].tap()
            waitForNoExistence(app.staticTexts["http://example.com"])
        }
    }
}
