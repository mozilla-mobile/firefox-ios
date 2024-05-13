// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

let webpage = [
    "url": "www.mozilla.org",
    "label": "Internet for people, not profit — Mozilla",
    "value": "mozilla.org"
]
let oldHistoryEntries: [String] = [
    "Internet for people, not profit — Mozilla (US)",
    "Explore / Twitter",
    "Home - YouTube"
]
let emptyRecentlyClosedMesg = "Websites you’ve visited recently will show up here."
// This is part of the info the user will see in recent closed tabs once the default
// visited website (https://www.mozilla.org/en-US/book/) is closed
let bookOfMozilla = [
    "file": "test-mozilla-book.html",
    "title": "The Book of Mozilla",
    "label": "localhost:\(serverPort)/test-fixture/test-mozilla-book.html"
]

class HistoryTests: BaseTestCase {
    typealias HistoryPanelA11y = AccessibilityIdentifiers.LibraryPanels.HistoryPanel

    let testWithDB = [
        "testOpenHistoryFromBrowserContextMenuOptions",
        "testClearHistoryFromSettings",
        "testClearRecentHistory"
    ]

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
                               LaunchArguments.DisableAnimations]
        }
        super.setUp()
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307300
    func testEmptyHistoryListFirstTime() {
        navigator.nowAt(NewTabScreen)

        // Go to History List from Top Sites and check it is empty
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables.cells[HistoryPanelA11y.recentlyClosedCell])
        XCTAssertTrue(app.tables.cells[HistoryPanelA11y.recentlyClosedCell].staticTexts["Recently Closed"].exists)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307301
    func testOpenSyncDevices() {
        // Firefox sync page should be available
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.ToggleSyncMode)
        mozWaitForElementToExist(app.otherElements.staticTexts["Firefox Sync"])
        XCTAssertTrue(app.otherElements.buttons["Sync and Save Data"].exists, "Sign in button does not appear")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307487
    func testClearHistoryFromSettings() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            navigator.nowAt(NewTabScreen)
            // Browse to have an item in history list
            navigator.goto(LibraryPanel_History)
            mozWaitForElementToExist(app.tables.cells[HistoryPanelA11y.recentlyClosedCell], timeout: TIMEOUT)
            XCTAssertTrue(app.tables.cells.staticTexts[oldHistoryEntries[0]].exists)
            XCTAssertFalse(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)

            // Clear all private data via the settings
            navigator.goto(HomePanelsScreen)
            navigator.nowAt(NewTabScreen)
            navigator.goto(ClearPrivateDataSettings)
            app.tables.cells["ClearPrivateData"].tap()
            app.alerts.buttons["OK"].tap()

            // Back on History panel view check that there is not any item
            navigator.goto(LibraryPanel_History)
            mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
            mozWaitForElementToExist(app.tables.cells[HistoryPanelA11y.recentlyClosedCell])
            XCTAssertFalse(app.tables.cells.staticTexts[oldHistoryEntries[0]].exists)
            XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307014
    // Smoketest
    func testClearPrivateData() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: TIMEOUT)
        // Clear private data from settings and confirm
        navigator.goto(ClearPrivateDataSettings)
        app.tables.cells["ClearPrivateData"].tap()
        mozWaitForElementToExist(app.tables.cells["ClearPrivateData"], timeout: TIMEOUT)
        app.alerts.buttons["OK"].tap()

        // Wait for OK pop-up to disappear after confirming
        mozWaitForElementToNotExist(app.alerts.buttons["OK"], timeout: TIMEOUT)

        // Try to tap on the disabled Clear Private Data button
        app.tables.cells["ClearPrivateData"].tap()

        // If the button is disabled, the confirmation pop-up should not exist
        // Disabling assertion due to https://mozilla-hub.atlassian.net/browse/FXIOS-7494 issue
        // After this issue is clarified the assertion will be re-enabled or changed.
        // XCTAssertEqual(app.alerts.buttons["OK"].exists, false)
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307357
    func testRecentlyClosedWebsiteOpen() {
        // Open "Book of Mozilla"
        openBookOfMozilla()

        // The tab, which is still opened, is not included in the "Recently Closed" list
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307463
    func testRecentlyClosedWebsiteClosed() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // On regular mode, the closed tab is listed in "Recently Closed" list
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        mozWaitForElementToExist(app.tables["Recently Closed Tabs List"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)

        // On private mode, the closed tab on regular mode is listed in "Recently Closed" list as well
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        closeKeyboard()
        navigator.goto(HistoryRecentlyClosed)
        mozWaitForElementToExist(app.tables["Recently Closed Tabs List"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307475
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
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307479
    // Disabling test due to https://github.com/mozilla-mobile/firefox-ios/issues/16810 crash
 /*   func testRemoveAllTabsButtonRecentlyClosedHistory() {
        // Open "Book of Mozilla"
        openBookOfMozilla()

        // Tap "Remove All Tabs" instead of close the tab individually
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.AcceptRemovingAllTabs)

        // The closed tab is listed in "Recently Closed" list
        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        navigator.goto(HistoryRecentlyClosed)
        mozWaitForElementToExist(app.tables["Recently Closed Tabs List"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }
*/
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307482
    func testClearRecentlyClosedHistory() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Once the website is visited and closed it will appear in Recently Closed Tabs list
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        mozWaitForElementToExist(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)

        // Clear all private data via the settings
        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(ClearPrivateDataSettings)
        app.tables.cells["ClearPrivateData"].tap()
        app.alerts.buttons["OK"].tap()

        // The closed tab is *not* listed in "Recently Closed Tabs List"
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307483
    func testLongTapOptionsRecentlyClosedItem() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Long tap a recently closed item launches a context menu
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        mozWaitForElementToExist(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        mozWaitForElementToExist(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.plus].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.privateMode].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307484
    func testOpenInNewTabRecentlyClosedItem() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Open the page on a new tab from History Recently Closed screen
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        mozWaitForElementToExist(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        XCTAssertEqual(userState.numTabs, 1)
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        mozWaitForElementToExist(app.tables["Context Menu"])
        app.tables.otherElements[StandardImageIdentifiers.Large.plus].tap()

        // The page is opened on the new tab
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        if isTablet {
            mozWaitForElementToExist(app.navigationBars.segmentedControls["navBarTabTray"])
        } else {
            mozWaitForElementToExist(app.navigationBars.staticTexts["Open Tabs"])
        }
        XCTAssertTrue(app.staticTexts[bookOfMozilla["title"]!].exists)
        XCTAssertEqual(userState.numTabs, 2)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307485
    func testOpenInNewPrivateTabRecentlyClosedItem() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Open the page on a new private tab from History Recently Closed screen
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        mozWaitForElementToExist(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        mozWaitForElementToExist(app.tables["Context Menu"])
        app.tables.otherElements[StandardImageIdentifiers.Large.privateMode].tap()

        // The page is opened only on the new private tab
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        if isTablet {
            mozWaitForElementToExist(app.navigationBars.segmentedControls["navBarTabTray"])
        } else {
            mozWaitForElementToExist(app.navigationBars.staticTexts["Open Tabs"])
        }
        XCTAssertFalse(app.staticTexts[bookOfMozilla["title"]!].isHittable)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        if isTablet {
            XCTAssertTrue(app.segmentedControls.buttons["Private"].isSelected)
        } else {
            mozWaitForElementToExist(app.staticTexts["Private Browsing"])
        }
        XCTAssertTrue(app.staticTexts[bookOfMozilla["title"]!].exists)
        XCTAssertEqual(userState.numTabs, 1)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307486
    func testPrivateClosedSiteDoesNotAppearOnRecentlyClosed() {
        navigator.nowAt(NewTabScreen)

        // Open the two tabs in private mode. It is necessary to open two sites.
        // When one tab is closed private mode, the private mode still has something opened.
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: bookOfMozilla["file"]!))
        waitUntilPageLoad()
        navigator.openNewURL(urlString: path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()

        // Close the private tab "Book of Mozilla" by tapping 'x' button
        waitForTabsButton()
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.cells.staticTexts[webpage["label"]!])
        app.cells.buttons[StandardImageIdentifiers.Large.cross].firstMatch.tap()

        // On private mode, the "Recently Closed Tabs List" is empty
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(HomePanelsScreen)
        closeKeyboard()
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
        mozWaitForElementToNotExist(app.tables["Recently Closed Tabs List"])
        XCTAssertFalse(app.cells.staticTexts["Recently Closed"].isSelected)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)

        // On regular mode, the "Recently Closed Tabs List" is empty, too
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)
        navigator.goto(NewTabScreen)
        closeKeyboard()
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
        mozWaitForElementToNotExist(app.tables["Recently Closed Tabs List"])
        XCTAssertFalse(app.cells.staticTexts["Recently Closed"].isSelected)
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307025
    // Smoke
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
        mozWaitForValueContains(app.textFields["url"], value: "test-fixture/test-mozilla-book.html")
    }

    // Private function created to select desired option from the "Clear Recent History" list
    // We used this approach to avoid code duplication

    private func tapOnClearRecentHistoryOption(optionSelected: String) {
        app.buttons[optionSelected].tap()
    }

    private func navigateToPage() {
        navigator.openURL("example.com")
        waitUntilPageLoad()
        // Workaround as the item does not appear if there is only that tab open
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: TIMEOUT_LONG)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView], timeout: TIMEOUT)
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
            app.otherElements["Tabs Tray"]
                .collectionViews
                .cells
                .element(boundBy: 0)
                .buttons[StandardImageIdentifiers.Large.cross]
                .tap()
        } else {
            app.cells.buttons[StandardImageIdentifiers.Large.cross].firstMatch.tap()
            // app.otherElements.cells.element(boundBy: 0).buttons[StandardImageIdentifiers.Large.cross].tap()
        }
    }

    private func closeKeyboard() {
        mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: TIMEOUT)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306894
    // Smoke
    func testClearRecentHistory() {
        // Visit a page to create a recent history entry.
        navigateToPage()
        navigator.performAction(Action.ClearRecentHistory)
        // Recent data will be removed after calling tapOnClearRecentHistoryOption(optionSelected: "Today").
        // Older data will not be removed
        tapOnClearRecentHistoryOption(optionSelected: "Today")
        for entry in oldHistoryEntries {
            XCTAssertTrue(app.tables.cells.staticTexts[entry].exists)
        }
        XCTAssertFalse(app.staticTexts["Today"].exists)
        XCTAssertTrue(app.staticTexts["Older"].exists)

        // Begin Test for Today and Yesterday
        // Visit a page to create a recent history entry.
        navigateToPage()
        navigator.performAction(Action.ClearRecentHistory)
        // Tapping "Today and Yesterday" will remove recent data (from yesterday and today).
        // Older data will not be removed
        tapOnClearRecentHistoryOption(optionSelected: "Today and Yesterday")
        for entry in oldHistoryEntries {
            XCTAssertTrue(app.tables.cells.staticTexts[entry].exists)
        }
        XCTAssertFalse(app.staticTexts["Today"].exists)
        XCTAssertTrue(app.staticTexts["Older"].exists)

        // Begin Test for Everything
        // Visit a page to create a recent history entry.
        navigateToPage()
        navigator.performAction(Action.ClearRecentHistory)
        // Tapping everything removes both current data and older data.
        tapOnClearRecentHistoryOption(optionSelected: "Everything")
        for entry in oldHistoryEntries {
            mozWaitForElementToNotExist(app.tables.cells.staticTexts[entry])

        XCTAssertFalse(app.tables.cells.staticTexts[entry].exists, "History not removed")
        }
        XCTAssertFalse(app.staticTexts["Today"].exists)
        XCTAssertFalse(app.staticTexts["Older"].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306890
    // Smoketest
    func testDeleteHistoryEntryBySwiping() {
        navigateToPage()
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.cells.staticTexts["http://example.com/"], timeout: TIMEOUT)
        navigateToPage()
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.cells.staticTexts["http://example.com/"], timeout: TIMEOUT)
        app.cells.staticTexts["http://example.com/"].firstMatch.swipeLeft()
        mozWaitForElementToExist(app.buttons["Delete"], timeout: TIMEOUT)
        app.buttons["Delete"].tap()
        mozWaitForElementToNotExist(app.staticTexts["http://example.com"])
        XCTAssertTrue(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg].exists)
    }
}
