/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url1 = "example.com"
let url2 = path(forTestPage: "test-mozilla-org.html")
let url3 = path(forTestPage: "test-example.html")
let urlIndexedDB = path(forTestPage: "test-indexeddb-private.html")

let url1And3Label = "Example Domain"
let url2Label = "Internet for people, not profit — Mozilla"

class PrivateBrowsingTest: BaseTestCase {
    func testPrivateTabDoesNotTrackHistory() {
        navigator.openURL(url1)
        waitForTabsButton()
        navigator.goto(BrowserTabMenu)
        // Go to History screen
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables["History List"])

        XCTAssertTrue(app.tables["History List"].staticTexts[url1And3Label].exists)
        // History without counting Clear Recent History and Recently Closed
        let history = app.tables["History List"].cells.count - 2

        XCTAssertEqual(history, 1, "History entries in regular browsing do not match")

        // Go to Private browsing to open a website and check if it appears on History
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        navigator.openURL(url2)
        waitForValueContains(app.textFields["url"], value: "mozilla")
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables["History List"])
        XCTAssertTrue(app.tables["History List"].staticTexts[url1And3Label].exists)
        XCTAssertFalse(app.tables["History List"].staticTexts[url2Label].exists)

        // Open one tab in private browsing and check the total number of tabs
        let privateHistory = app.tables["History List"].cells.count - 2
        XCTAssertEqual(privateHistory, 1, "History entries in private browsing do not match")
    }

    func testTabCountShowsOnlyNormalOrPrivateTabCount() {
        // Open two tabs in normal browsing and check the number of tabs open
        navigator.openNewURL(urlString: url2)
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)

        waitForExistence(app.collectionViews.cells[url2Label])
        let numTabs = userState.numTabs
        XCTAssertEqual(numTabs, 2, "The number of regular tabs is not correct")

        // Open one tab in private browsing and check the total number of tabs
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        navigator.goto(URLBarOpen)
        waitUntilPageLoad()
        navigator.openURL(url3)
        waitForValueContains(app.textFields["url"], value: "test-example")
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(TabTray)
        print(app.debugDescription)
        waitForExistence(app.collectionViews.cells[url1And3Label])
        let numPrivTabs = userState.numTabs
        XCTAssertEqual(numPrivTabs, 1, "The number of private tabs is not correct")

        // Go back to regular mode and check the total number of tabs
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)

        waitForExistence(app.collectionViews.cells[url2Label])
        waitForNoExistence(app.collectionViews.cells[url1And3Label])
        let numRegularTabs = userState.numTabs
        XCTAssertEqual(numRegularTabs, 2, "The number of regular tabs is not correct")
    }

    func testClosePrivateTabsOptionClosesPrivateTabs() {
        // Check that Close Private Tabs when closing the Private Browsing Button is off by default
        waitForExistence(app.buttons["TabToolbar.menuButton"], timeout: 5)
        navigator.goto(SettingsScreen)
        let settingsTableView = app.tables["AppSettingsTableViewController.tableView"]

        while settingsTableView.staticTexts["Close Private Tabs"].exists == false {
            settingsTableView.swipeUp()
        }

        let closePrivateTabsSwitch = settingsTableView.switches["settings.closePrivateTabs"]
        XCTAssertFalse(closePrivateTabsSwitch.isSelected)

        //  Open a Private tab
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(url2)
        waitForTabsButton()

        // Go back to regular browser
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)

        // Go back to private browsing and check that the tab has not been closed
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        waitForExistence(app.collectionViews.cells[url2Label], timeout: 5)
        checkOpenTabsBeforeClosingPrivateMode()

        // Now the enable the Close Private Tabs when closing the Private Browsing Button
        app.collectionViews.cells[url2Label].tap()
        waitForTabsButton()
        waitForExistence(app.buttons["TabToolbar.menuButton"], timeout: 10)
        navigator.nowAt(BrowserTab)
        navigator.goto(SettingsScreen)
        closePrivateTabsSwitch.tap()
        navigator.goto(BrowserTab)
        waitForTabsButton()

        // Go back to regular browsing and check that the private tab has been closed and that the initial Private Browsing message appears when going back to Private Browsing
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        waitForNoExistence(app.collectionViews.cells[url2Label])
        checkOpenTabsAfterClosingPrivateMode()
    }

    func testClosePrivateTabsOptionClosesPrivateTabsDirectlyFromTabTray() {
        // See scenario described in bug 1434545 for more info about this scenario
        enableClosePrivateBrowsingOptionWhenLeaving()
        navigator.openURL(url3)
        waitUntilPageLoad()
        app.webViews.links.staticTexts["More information..."].press(forDuration: 3)
        app.buttons["Open in New Private Tab"].tap()
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        // Check there is one tab
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        checkOpenTabsBeforeClosingPrivateMode()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        checkOpenTabsAfterClosingPrivateMode()
    }

    /* Loads a page that checks if an db file exists already. It uses indexedDB on both the main document, and in a web worker.
     The loaded page has two staticTexts that get set when the db is correctly created (because the db didn't exist in the cache)
     https://bugzilla.mozilla.org/show_bug.cgi?id=1646756
     */
    func testClearIndexedDB() {
        enableClosePrivateBrowsingOptionWhenLeaving()

        func checkIndexedDBIsCreated() {
            navigator.openURL(urlIndexedDB)
            waitUntilPageLoad()
            XCTAssertTrue(app.webViews.staticTexts["DB_CREATED_PAGE"].exists)
            XCTAssertTrue(app.webViews.staticTexts["DB_CREATED_WORKER"].exists)
        }
        
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        checkIndexedDBIsCreated()

        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        checkIndexedDBIsCreated()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        checkIndexedDBIsCreated()
    }

    func testPrivateBrowserPanelView() {
        // If no private tabs are open, there should be a initial screen with label Private Browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is not shown")
        let numPrivTabsFirstTime = userState.numTabs
        XCTAssertEqual(numPrivTabsFirstTime, 0, "The number of tabs is not correct, there should not be any private tab yet")

        // If a private tab is open Private Browsing screen is not shown anymore
        navigator.goto(BrowserTab)

        //Wait until the page loads and go to regular browser
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)

        // Go back to private browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        waitForNoExistence(app.staticTexts["Private Browsing"])
        XCTAssertFalse(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is shown")
        navigator.nowAt(TabTray)
        let numPrivTabsOpen = userState.numTabs
        XCTAssertEqual(numPrivTabsOpen, 1, "The number of tabs is not correct, there should be one private tab")
    }
}

fileprivate extension BaseTestCase {
    func checkOpenTabsBeforeClosingPrivateMode() {
        let numPrivTabs = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabs, 1, "The number of tabs is not correct, the private tab should not have been closed")
    }

    func checkOpenTabsAfterClosingPrivateMode() {
        let numPrivTabsAfterClosing = userState.numTabs
        XCTAssertEqual(numPrivTabsAfterClosing, 0, "The number of tabs is not correct, the private tab should have been closed")
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is not shown")
    }

    func enableClosePrivateBrowsingOptionWhenLeaving() {
        navigator.goto(SettingsScreen)
        let settingsTableView = app.tables["AppSettingsTableViewController.tableView"]

        while settingsTableView.staticTexts["Close Private Tabs"].exists == false {
            settingsTableView.swipeUp()
        }
        let closePrivateTabsSwitch = settingsTableView.switches["settings.closePrivateTabs"]
        closePrivateTabsSwitch.tap()
    }
}

class PrivateBrowsingTestIpad: IpadOnlyTestCase {
    // This test is only enabled for iPad. Shortcut does not exists on iPhone
    func testClosePrivateTabsOptionClosesPrivateTabsShortCutiPad() {
        if skipPlatform { return }
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(url2)
        waitForExistence(app.buttons["TabToolbar.menuButton"], timeout: 5)
        enableClosePrivateBrowsingOptionWhenLeaving()
        // Leave PM by tapping on PM shourt cut
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateModeFromTabBarHomePanel)
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        checkOpenTabsAfterClosingPrivateMode()
    }

    func testiPadDirectAccessPrivateMode() {
        if skipPlatform { return }
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateModeFromTabBarHomePanel)

        // A Tab opens directly in HomePanels view
        XCTAssertFalse(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is not shown")

        // Open website and check it does not appear under history once going back to regular mode
        navigator.openURL("http://example.com")
        waitUntilPageLoad()
        // This action to enable private mode is defined on HomePanel Screen that is why we need to open a new tab and be sure we are on that screen to use the correct action
        navigator.goto(NewTabScreen)
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateModeFromTabBarHomePanel)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables["History List"])
        // History without counting Clear Recent History, Recently Closed
        let history = app.tables["History List"].cells.count - 2
        XCTAssertEqual(history, 0, "History list should be empty")
    }

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
        waitForExistence(app.tables["History List"])
        // History without counting Clear Recent History, Recently Closed
        let history = app.tables["History List"].cells.count - 2
        XCTAssertEqual(history, 1, "There should be one entry in History")
        let savedToHistory = app.tables["History List"].cells.staticTexts[url1And3Label]
        waitForExistence(savedToHistory)
        XCTAssertTrue(savedToHistory.exists)
    }
}
