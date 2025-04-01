// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared

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

    // https://mozilla.testrail.io/index.php?/cases/view/2307300
    func testEmptyHistoryListFirstTime() {
        navigator.nowAt(NewTabScreen)

        // Go to History List from Top Sites and check it is empty
        navigator.goto(LibraryPanel_History)
        waitForElementsToExist(
            [
                app.tables.cells[HistoryPanelA11y.recentlyClosedCell],
                app.tables.cells[HistoryPanelA11y.recentlyClosedCell].staticTexts["Recently Closed"],
                app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307301
    func testOpenSyncDevices() {
        // Firefox sync page should be available
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.ToggleSyncMode)
        waitForElementsToExist(
            [
                app.otherElements.staticTexts["Firefox Sync"],
                app.otherElements.buttons["Sync and Save Data"]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307487
    func testClearHistoryFromSettings() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            navigator.nowAt(NewTabScreen)
            // Browse to have an item in history list
            navigator.goto(LibraryPanel_History)
            waitForElementsToExist(
                [
                    app.tables.cells[HistoryPanelA11y.recentlyClosedCell],
                    app.tables.cells.staticTexts[oldHistoryEntries[0]]
                ]
            )
            mozWaitForElementToNotExist(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg])

            // Clear all private data via the settings
            navigator.goto(HomePanelsScreen)
            navigator.nowAt(NewTabScreen)
            navigator.goto(ClearPrivateDataSettings)
            app.tables.cells["ClearPrivateData"].waitAndTap()
            app.alerts.buttons["OK"].waitAndTap()

            // Back on History panel view check that there is not any item
            navigator.goto(LibraryPanel_History)
            waitForElementsToExist(
                [
                    app.tables[HistoryPanelA11y.tableView],
                    app.tables.cells[HistoryPanelA11y.recentlyClosedCell]
                ]
            )
            mozWaitForElementToNotExist(app.tables.cells.staticTexts[oldHistoryEntries[0]])
            mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307014
    // Smoketest
    func testClearPrivateData() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        // Clear private data from settings and confirm
        navigator.goto(ClearPrivateDataSettings)
        app.tables.cells["ClearPrivateData"].waitAndTap()
        mozWaitForElementToExist(app.tables.cells["ClearPrivateData"])
        app.alerts.buttons["OK"].waitAndTap()

        // Wait for OK pop-up to disappear after confirming
        mozWaitForElementToNotExist(app.alerts.buttons["OK"])

        // Try to tap on the disabled Clear Private Data button
        app.tables.cells["ClearPrivateData"].waitAndTap()

        // If the button is disabled, the confirmation pop-up should not exist
        // Disabling assertion due to https://mozilla-hub.atlassian.net/browse/FXIOS-7494 issue
        // After this issue is clarified the assertion will be re-enabled or changed.
        // XCTAssertEqual(app.alerts.buttons["OK"].exists, false)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307357
    func testRecentlyClosedWebsiteOpen() {
        // Open "Book of Mozilla"
        openBookOfMozilla()

        // The tab, which is still opened, is not included in the "Recently Closed" list
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
        mozWaitForElementToNotExist(app.tables.cells.staticTexts[bookOfMozilla["label"]!])
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307463
    func testRecentlyClosedWebsiteClosed() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // On regular mode, the closed tab is listed in "Recently Closed" list
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForElementsToExist(
            [
                app.tables["Recently Closed Tabs List"],
                app.tables.cells.staticTexts[bookOfMozilla["label"]!]
            ]
        )

        // On private mode, the closed tab on regular mode is listed in "Recently Closed" list as well
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        closeKeyboard()
        navigator.goto(HistoryRecentlyClosed)
        waitForElementsToExist(
            [
                app.tables["Recently Closed Tabs List"],
                app.tables.cells.staticTexts[bookOfMozilla["label"]!]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307475
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
        waitForElementsToExist(
            [
                app.tables[HistoryPanelA11y.tableView],
                app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg]
            ]
        )
        mozWaitForElementToNotExist(app.tables.cells.staticTexts[bookOfMozilla["label"]!])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307479
    func testRemoveAllTabsButtonRecentlyClosedHistory() {
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
        waitForElementsToExist(
            [
                app.tables["Recently Closed Tabs List"],
                app.tables.cells.staticTexts[bookOfMozilla["label"]!]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307482
    func testClearRecentlyClosedHistory() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Once the website is visited and closed it will appear in Recently Closed Tabs list
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForElementsToExist(
            [
                app.tables["Recently Closed Tabs List"],
                app.tables.cells.staticTexts[bookOfMozilla["label"]!]
            ]
        )

        // Clear all private data via the settings
        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(ClearPrivateDataSettings)
        app.tables.cells["ClearPrivateData"].waitAndTap()
        app.alerts.buttons["OK"].waitAndTap()

        // The closed tab is *not* listed in "Recently Closed Tabs List"
        navigator.goto(LibraryPanel_History)
        waitForElementsToExist(
            [
                app.tables[HistoryPanelA11y.tableView],
                app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg]
            ]
        )
        mozWaitForElementToNotExist(app.tables.cells.staticTexts[bookOfMozilla["label"]!])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307483
    func testLongTapOptionsRecentlyClosedItem() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Long tap a recently closed item launches a context menu
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForElementsToExist(
            [
                app.tables["Recently Closed Tabs List"],
                app.tables.cells.staticTexts[bookOfMozilla["label"]!]
            ]
        )
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        waitForElementsToExist(
            [
                app.tables["Context Menu"],
                app.tables.otherElements[StandardImageIdentifiers.Large.plus],
                app.tables.otherElements[StandardImageIdentifiers.Large.privateMode]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307484
    func testOpenInNewTabRecentlyClosedItem() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Open the page on a new tab from History Recently Closed screen
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForElementsToExist(
            [
                app.tables["Recently Closed Tabs List"],
                app.tables.cells.staticTexts[bookOfMozilla["label"]!]
            ]
        )
        // userState.numTabs does not work on iOS 15
        if #available(iOS 16, *) {
            XCTAssertEqual(userState.numTabs, 1)
        }
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        mozWaitForElementToExist(app.tables["Context Menu"])
        app.tables.otherElements[StandardImageIdentifiers.Large.plus].waitAndTap()

        // The page is opened on the new tab
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        if isTablet {
            mozWaitForElementToExist(app.navigationBars.segmentedControls["navBarTabTray"])
        } else {
            mozWaitForElementToExist(app.navigationBars.staticTexts["Open Tabs"])
        }
        mozWaitForElementToExist(app.staticTexts[bookOfMozilla["title"]!])
        // userState.numTabs does not work on iOS 15
        if #available(iOS 16, *) {
            XCTAssertEqual(userState.numTabs, 2)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307485
    func testOpenInNewPrivateTabRecentlyClosedItem() {
        // Open "Book of Mozilla" and close the tab
        openBookOfMozilla()
        closeFirstTabByX()

        // Open the page on a new private tab from History Recently Closed screen
        navigator.nowAt(NewTabScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitForElementsToExist(
            [
                app.tables["Recently Closed Tabs List"],
                app.tables.cells.staticTexts[bookOfMozilla["label"]!]
            ]
        )
        app.tables.cells.staticTexts[bookOfMozilla["label"]!].press(forDuration: 1)
        mozWaitForElementToExist(app.tables["Context Menu"])
        app.tables.otherElements[StandardImageIdentifiers.Large.privateMode].waitAndTap()

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
        mozWaitForElementToExist(app.staticTexts[bookOfMozilla["title"]!])
        XCTAssertEqual(userState.numTabs, 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307486
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
        app.cells.buttons[StandardImageIdentifiers.Large.cross].firstMatch.waitAndTap()

        // On private mode, the "Recently Closed Tabs List" is empty
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(HomePanelsScreen)
        closeKeyboard()
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
        mozWaitForElementToNotExist(app.tables["Recently Closed Tabs List"])
        XCTAssertFalse(app.cells.staticTexts["Recently Closed"].isSelected)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg])
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)

        // On regular mode, the "Recently Closed Tabs List" is empty, too
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)
        navigator.goto(NewTabScreen)
        closeKeyboard()
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
        mozWaitForElementToNotExist(app.tables["Recently Closed Tabs List"])
        XCTAssertFalse(app.cells.staticTexts["Recently Closed"].isSelected)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg])
        XCTAssertFalse(app.tables.cells.staticTexts[bookOfMozilla["label"]!].exists)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307025
    // Smoke
    func testTabHistory() {
        navigator.nowAt(NewTabScreen)
        openBookOfMozilla()
        let urlBarBackButton = app.windows.otherElements.buttons[AccessibilityIdentifiers.Toolbar.backButton]
        let urlBarForwardButton = app.windows.otherElements.buttons[AccessibilityIdentifiers.Toolbar.forwardButton]
        urlBarBackButton.press(forDuration: 1)
        app.tables.staticTexts["The Book of Mozilla"].waitAndTap()
        mozWaitForElementToNotExist(app.tables.staticTexts["The Book of Mozilla"])
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        openBookOfMozilla()
        urlBarBackButton.press(forDuration: 1)
        app.tables.staticTexts["The Book of Mozilla"].waitAndTap()
        urlBarBackButton.waitAndTap()
        XCTAssertFalse(urlBarBackButton.isEnabled)
        urlBarForwardButton.press(forDuration: 1)
        app.tables.staticTexts["The Book of Mozilla"].waitAndTap()
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForValueContains(url, value: "localhost")
    }

    // Private function created to select desired option from the "Clear Recent History" list
    // We used this approach to avoid code duplication

    private func tapOnClearRecentHistoryOption(optionSelected: String) {
        app.buttons[optionSelected].waitAndTap()
    }

    private func navigateToPage() {
        navigator.openURL("example.com")
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        let cancelButton = app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton]
        mozWaitForElementToExist(cancelButton, timeout: TIMEOUT_LONG)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        waitForElementsToExist(
            [
                app.tables[HistoryPanelA11y.tableView],
                app.tables.cells.staticTexts["Example Domain"]
            ]
        )
    }

    private func openBookOfMozilla() {
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: bookOfMozilla["file"]!))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
    }

    private func closeFirstTabByX() {
        waitForTabsButton()
        navigator.goto(TabTray)
        app.cells.buttons[StandardImageIdentifiers.Large.cross].firstMatch.waitAndTap()
    }

    private func closeKeyboard() {
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306894
    // Smoke
    func testClearRecentHistory() {
        // Visit a page to create a recent history entry.
        navigateToPage()
        navigator.performAction(Action.ClearRecentHistory)
        // Recent data will be removed after calling tapOnClearRecentHistoryOption(optionSelected: "Last 24 Hours").
        // Older data will not be removed
        tapOnClearRecentHistoryOption(optionSelected: "Last 24 Hours")
        for entry in oldHistoryEntries {
            mozWaitForElementToExist(app.tables.cells.staticTexts[entry])
        }
        mozWaitForElementToNotExist(app.staticTexts["Last 24 Hours"])
        mozWaitForElementToExist(app.staticTexts["Older"])

        // Begin Test for Last 7 Days
        // Visit a page to create a recent history entry.
        navigateToPage()
        navigator.performAction(Action.ClearRecentHistory)
        // Tapping "Today and Yesterday" will remove recent data (from yesterday and today).
        // Older data will not be removed
        tapOnClearRecentHistoryOption(optionSelected: "Last 7 Days")
        for entry in oldHistoryEntries {
            XCTAssertTrue(app.tables.cells.staticTexts[entry].exists)
        }
        mozWaitForElementToNotExist(app.staticTexts["Last 7 Days"])
        mozWaitForElementToExist(app.staticTexts["Older"])

        // Begin Test for Last 4 Weeks
        // Visit a page to create a recent history entry.
        navigateToPage()
        navigator.performAction(Action.ClearRecentHistory)
        // Tapping "Today and Yesterday" will remove recent data (from yesterday and today).
        // Older data will not be removed
        tapOnClearRecentHistoryOption(optionSelected: "Last 4 Weeks")
        for entry in oldHistoryEntries {
            XCTAssertTrue(app.tables.cells.staticTexts[entry].exists)
        }
        mozWaitForElementToNotExist(app.staticTexts["Last 4 Weeks"])
        mozWaitForElementToExist(app.staticTexts["Older"])

        // Begin Test for All Time
        // Visit a page to create a recent history entry.
        navigateToPage()
        navigator.performAction(Action.ClearRecentHistory)
        // Tapping everything removes both current data and older data.
        tapOnClearRecentHistoryOption(optionSelected: "All Time")
        for entry in oldHistoryEntries {
            mozWaitForElementToNotExist(app.tables.cells.staticTexts[entry])
        }
        mozWaitForElementToNotExist(app.staticTexts["All Time"])
        mozWaitForElementToNotExist(app.staticTexts["Older"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306890
    // Smoketest
    func testDeleteHistoryEntryBySwiping() {
        navigateToPage()
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.cells.staticTexts["http://example.com/"])
        app.cells.staticTexts["http://example.com/"].firstMatch.swipeLeft()
        app.buttons["Delete"].waitAndTap()
        mozWaitForElementToNotExist(app.staticTexts["http://example.com"])
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView].staticTexts[emptyRecentlyClosedMesg])
    }
}
