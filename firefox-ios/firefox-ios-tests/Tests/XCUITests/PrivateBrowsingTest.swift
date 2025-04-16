// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let url1 = "example.com"
let url2 = path(forTestPage: "test-mozilla-org.html")
let url3 = path(forTestPage: "test-example.html")
let urlIndexedDB = path(forTestPage: "test-indexeddb-private.html")

let url1And3Label = "Example Domain"
let url2Label = "Internet for people, not profit — Mozilla"

class PrivateBrowsingTest: BaseTestCase {
    typealias HistoryPanelA11y = AccessibilityIdentifiers.LibraryPanels.HistoryPanel

    // https://mozilla.testrail.io/index.php?/cases/view/2307004
    func testPrivateTabDoesNotTrackHistory() {
        navigator.openURL(url1)
        waitForTabsButton()
        navigator.goto(BrowserTabMenu)
        // Go to History screen
        navigator.goto(LibraryPanel_History)
        waitForElementsToExist(
            [
                app.tables[HistoryPanelA11y.tableView],
                app.tables[HistoryPanelA11y.tableView].staticTexts[url1And3Label]
            ]
        )
        // History without counting Clear Recent History and Recently Closed
        let history = app.tables[HistoryPanelA11y.tableView].cells.count - 1

        XCTAssertEqual(history, 1, "History entries in regular browsing do not match")

        // Go to Private browsing to open a website and check if it appears on History
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        navigator.openURL(url2)
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "localhost")
        navigator.goto(LibraryPanel_History)
        waitForElementsToExist(
            [
            app.tables[HistoryPanelA11y.tableView],
            app.tables[HistoryPanelA11y.tableView].staticTexts[url1And3Label]
            ]
        )
        mozWaitForElementToNotExist(app.tables[HistoryPanelA11y.tableView].staticTexts[url2Label])

        // Open one tab in private browsing and check the total number of tabs
        let privateHistory = app.tables[HistoryPanelA11y.tableView].cells.count - 1
        XCTAssertEqual(privateHistory, 1, "History entries in private browsing do not match")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307005
    func testTabCountShowsOnlyNormalOrPrivateTabCount() {
        // Open two tabs in normal browsing and check the number of tabs open
        navigator.nowAt(NewTabScreen)
        navigator.openNewURL(urlString: url2)
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.otherElements["Tabs Tray"])
        XCTAssertNotNil(
            app.otherElements["Tabs Tray"].collectionViews.cells.staticTexts
                .element(boundBy: 1).label
                .range(of: url2Label)
        )
        let numTabs = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(numTabs, 2, "The number of regular tabs is not correct")

        // Open one tab in private browsing and check the total number of tabs
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        navigator.goto(URLBarOpen)
        waitUntilPageLoad()
        navigator.openURL(url3)
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForValueContains(url, value: "localhost")
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].cells.staticTexts[url1And3Label])
        let numPrivTabs = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(numPrivTabs, 1, "The number of private tabs is not correct")
        // Go back to regular mode and check the total number of tabs
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)

        mozWaitForElementToExist(app.otherElements["Tabs Tray"])
        XCTAssertNotNil(
            app.otherElements["Tabs Tray"].collectionViews.cells.staticTexts
                .element(boundBy: 1).label
                .range(of: url2Label)
        )
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].collectionViews.cells.staticTexts[url1And3Label])
        let numRegularTabs = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(numRegularTabs, 2, "The number of regular tabs is not correct")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307006
    func testClosePrivateTabsOptionClosesPrivateTabs() {
        // Check that Close Private Tabs when closing the Private Browsing Button is off by default
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        navigator.goto(SettingsScreen)

        // FXIOS-8672: "Close Private Tabs" has been removed from the settings.

        //  Open a Private tab
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(url2)
        waitUntilPageLoad()
        waitForTabsButton()

        // Go back to regular browser
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)
        app.cells.staticTexts["Homepage"].waitAndTap()
        navigator.nowAt(NewTabScreen)

        // Go back to private browsing and check that the tab has been closed
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        waitForElementsToExist(
            [
                app.otherElements["Tabs Tray"],
                app.staticTexts["Private Browsing"]
            ]
        )
        checkOpenTabsBeforeClosingPrivateMode()
    }

    /* Loads a page that checks if an db file exists already. It uses indexedDB on both the main document,
     and in a web worker. The loaded page has two staticTexts that get set when the db is correctly
     created (because the db didn't exist in the cache)
     https://bugzilla.mozilla.org/show_bug.cgi?id=1646756
     */
    // https://mozilla.testrail.io/index.php?/cases/view/2307011
    func testClearIndexedDB() {
        navigator.nowAt(NewTabScreen)

        // FXIOS-8672: "Close Private Tabs" has been removed from the settings.

        func checkIndexedDBIsCreated() {
            navigator.openURL(urlIndexedDB)
            waitUntilPageLoad()
            waitForElementsToExist(
                [
                    app.webViews.staticTexts["DB_CREATED_PAGE"],
                    app.webViews.staticTexts["DB_CREATED_WORKER"]
                ]
            )
        }

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        checkIndexedDBIsCreated()

        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)
        // FXIOS-8672: "Close Private Tabs" has been removed from the settings.
        // checkIndexedDBIsCreated()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        // FXIOS-8672: "Close Private Tabs" has been removed from the settings.
        // checkIndexedDBIsCreated()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307007
    func testPrivateBrowserPanelView() {
        navigator.nowAt(NewTabScreen)
        // If no private tabs are open, there should be a initial screen with label Private Browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        let numPrivTabsFirstTime = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(
            numPrivTabsFirstTime,
            0,
            "The number of tabs is not correct, there should not be any private tab yet"
        )

        // If a private tab is open Private Browsing screen is not shown anymore

        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        // Wait until the page loads and go to regular browser
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)

        // Go back to private browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        navigator.nowAt(TabTray)
        let numPrivTabsOpen = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(numPrivTabsOpen, 1, "The number of private tabs is not correct")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307012
    // Smoketest
    func testLongPressLinkOptionsPrivateMode() {
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        navigator.openURL(path(forTestPage: "test-example.html"))
        mozWaitForElementToExist(app.webViews.links[website_2["link"]!])
        app.webViews.links[website_2["link"]!].press(forDuration: 2)
        mozWaitForElementToExist(
            app.collectionViews.staticTexts[website_2["moreLinkLongPressUrl"]!]
        )
        mozWaitForElementToNotExist(app.buttons["Open in New Tab"])
        waitForElementsToExist(
            [
                app.buttons["Open in New Private Tab"],
                app.buttons["Copy Link"],
                app.buttons["Download Link"]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2497357
    func testAllPrivateTabsRestore() {
        // Several tabs opened in private tabs tray. Tap on the trashcan
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        for _ in 1...4 {
            navigator.createNewTab()
            if app.keyboards.element.isVisible() && !iPad() {
                mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
                navigator.performAction(Action.CloseURLBarOpen)
            }
        }
        navigator.goto(TabTray)
        var numTab = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(4, numTab, "The number of counted tabs is not equal to \(String(describing: numTab))")
        app.buttons[AccessibilityIdentifiers.TabTray.closeAllTabsButton].waitAndTap()

        // Validate Close All Tabs and Cancel options
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.deleteCloseAllButton])
        if !iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.deleteCancelButton])
        }

        // Tap on "Close All Tabs"
        app.buttons[AccessibilityIdentifiers.TabTray.deleteCloseAllButton].waitAndTap()
        if #unavailable(iOS 16) {
            // Wait for the screen to refresh first.
            mozWaitForElementToExist(
                app.staticTexts["Firefox won’t remember any of your history or cookies, but new bookmarks will be saved."])
        }
        // The private tabs are closed
        waitForElementsToExist(
            [
                app.staticTexts["Private Browsing"],
                app.otherElements["Tabs Tray"]
            ]
        )
        numTab = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(0, numTab, "The number of counted tabs is not equal to \(String(describing: numTab))")
        mozWaitForElementToExist(app.staticTexts["Private Browsing"])

        app.buttons["Undo"].waitAndTap()

        // All the private tabs are restored
        navigator.goto(TabTray)
        numTab = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(4, numTab, "The number of counted tabs is not equal to \(String(describing: numTab))")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307003
    func testHamburgerMenuNewPrivateTab() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(urlExample)
        waitUntilPageLoad()
        navigator.goto(BrowserTabMenu)
        // Validate menu option New Private Tab
        let newPrivateTab = app.staticTexts["New Private Tab"]
        mozWaitForElementToExist(newPrivateTab)
        scrollToElement(newPrivateTab)
        // Tap on "New private tab" option
        newPrivateTab.waitAndTap()
        // Tap on "New private tab" option
        navigator.nowAt(NewTabScreen)
        if #available(iOS 16, *) {
            navigator.performAction(Action.CloseURLBarOpen)
            waitForTabsButton()
            navigator.goto(TabTray)
            let numTab = app.otherElements["Tabs Tray"].cells.count
            XCTAssertEqual(2, numTab, "The number of counted tabs is not equal to \(String(describing: numTab))")
        }
    }
}

fileprivate extension BaseTestCase {
    func checkOpenTabsBeforeClosingPrivateMode() {
        let numPrivTabs = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(
            numPrivTabs,
            0,
            "The private tab should have been closed"
        )
    }

    func enableClosePrivateBrowsingOptionWhenLeaving() {
        navigator.goto(SettingsScreen)
        let settingsTableView = app.tables[AccessibilityIdentifiers.Settings.tableViewController]

        while settingsTableView.staticTexts["Close Private Tabs"].isHittable == false {
            settingsTableView.swipeUp()
        }
        let closePrivateTabsSwitch = settingsTableView.switches["ClosePrivateTabs"]
        closePrivateTabsSwitch.waitAndTap()
    }
}

class PrivateBrowsingTestIphone: IphoneOnlyTestCase {
    // This test is disabled for iPad because the toast menu is not shown there
    // https://mozilla.testrail.io/index.php?/cases/view/2307013
    // Smoketest
    func testSwitchBetweenPrivateTabsToastButton() {
        if skipPlatform { return }

        // Go to Private mode
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(urlExample)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.links.firstMatch)
        app.webViews.links.firstMatch.press(forDuration: 1)
        mozWaitForElementToExist(app.buttons["Open in New Private Tab"])
        app.buttons["Open in New Private Tab"].press(forDuration: 1)
        app.buttons["Switch"].waitAndTap()

        // Check that the tab has changed
        waitUntilPageLoad()
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "iana")
        waitForElementsToExist(
            [
                app.links["RFC 2606"],
                app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
            ]
        )
        let numPrivTab = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as? String
        XCTAssertEqual("2", numPrivTab)
    }
}

class PrivateBrowsingTestIpad: IpadOnlyTestCase {
    typealias HistoryPanelA11y = AccessibilityIdentifiers.LibraryPanels.HistoryPanel

    // This test is only enabled for iPad. Shortcut does not exists on iPhone
    // https://mozilla.testrail.io/index.php?/cases/view/2307008
    func testClosePrivateTabsOptionClosesPrivateTabsShortCutiPad() {
        if skipPlatform { return }
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(url2)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])

        // Leave PM by tapping on PM shourt cut
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateModeFromTabBarHomePanel)
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        checkOpenTabsBeforeClosingPrivateMode()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307009
    func testiPadDirectAccessPrivateMode() {
        if skipPlatform { return }
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateModeFromTabBarHomePanel)

        // A Tab opens directly in HomePanels view
        XCTAssertFalse(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is not shown")

        // Open website and check it does not appear under history once going back to regular mode
        navigator.openURL("http://example.com")
        waitUntilPageLoad()
        // This action to enable private mode is defined on HomePanel Screen that is why we need to open
        // a new tab and be sure we are on that screen to use the correct action
        navigator.goto(NewTabScreen)

        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateModeFromTabBarHomePanel)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
        // History without counting Clear Recent History, Recently Closed
        let history = app.tables[HistoryPanelA11y.tableView].cells.count - 1
        XCTAssertEqual(history, 0, "History list should be empty")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307010
    func testiPadDirectAccessPrivateModeBrowserTab() {
        if skipPlatform { return }
        navigator.openURL("www.mozilla.org")
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateModeFromTabBarBrowserTab)

        // A Tab opens directly in HomePanels view
        XCTAssertFalse(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is not shown")

        // Open website and check it does not appear under history once going back to regular mode
        navigator.openURL("http://example.com")
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateModeFromTabBarBrowserTab)
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[HistoryPanelA11y.tableView])
        // History without counting Clear Recent History, Recently Closed
        let history = app.tables[HistoryPanelA11y.tableView].cells.count - 1
        XCTAssertEqual(history, 1, "There should be one entry in History")
        let savedToHistory = app.tables[HistoryPanelA11y.tableView]
            .cells.element(boundBy: 1)
            .staticTexts.element(boundBy: 1)
        mozWaitForElementToExist(savedToHistory)
        XCTAssertNotNil(savedToHistory.label.range(of: url2Label))
    }
}
