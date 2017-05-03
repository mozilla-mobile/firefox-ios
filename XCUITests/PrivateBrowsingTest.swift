/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url1 = "www.mozilla.org"
let url2 = "people.mozilla.org"

let url1Label = "Internet for people, not profit — Mozilla"
let url2Label = "People of Mozilla"

class PrivateBrowsingTest: BaseTestCase {

    var navigator: Navigator!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPrivateTabDoesNotTrackHistory() {
        navigator.openURL(urlString: url1)
        navigator.goto(BrowserTabMenu)
        // Go to History screen
        waitforExistence(app.toolbars.buttons["HistoryMenuToolbarItem"])
        app.toolbars.buttons["HistoryMenuToolbarItem"].tap()
        navigator.nowAt(NewTabScreen)
        waitforExistence(app.tables["History List"])

        XCTAssertTrue(app.tables["History List"].staticTexts[url1Label].exists)
        // History without counting Recently Closed and Synced devices
        let history = app.tables["History List"].cells.count - 2

        XCTAssertEqual(history, 1, "History entries in regular browsing do not match")

        // Go to Private browsing to open a website and check if it appears on History
        navigator.goto(PrivateTabTray)
        navigator.openURL(urlString: url2)
        navigator.nowAt(PrivateBrowserTab)
        waitForValueContains(app.textFields["url"], value: "people")
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.toolbars.buttons["HistoryMenuToolbarItem"])
        app.toolbars.buttons["HistoryMenuToolbarItem"].tap()

        waitforExistence(app.tables["History List"])
        XCTAssertTrue(app.tables["History List"].staticTexts[url1Label].exists)
        XCTAssertFalse(app.tables["History List"].staticTexts[url2Label].exists)

        let privateHistory = app.tables["History List"].cells.count - 2
        XCTAssertEqual(privateHistory, 1, "History entries in private browsing do not match")
    }

    func testTabCountShowsOnlyNormalOrPrivateTabCount() {
        // Open two tabs in normal browsing and check the number of tabs open
        navigator.openNewURL(urlString: url1)
        navigator.goto(TabTray)
        navigator.goto(NewTabScreen)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[url1Label])
        let numTabs = app.collectionViews.cells.count
        XCTAssertEqual(numTabs, 2, "The number of regular tabs is not correct")

        // Open one tab in private browsing and check the total number of tabs
        navigator.goto(NewPrivateTabScreen)
        navigator.openURL(urlString: url2)
        navigator.nowAt(PrivateBrowserTab)
        waitForValueContains(app.textFields["url"], value: "people")

        navigator.goto(PrivateTabTray)

        waitforExistence(app.collectionViews.cells[url2Label])
        let numPrivTabs = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabs, 1, "The number of private tabs is not correct")

        // Go back to regular mode and check the total number of tabs
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[url1Label])
        waitforNoExistence(app.collectionViews.cells[url2Label])
        let numRegularTabs = app.collectionViews.cells.count
        XCTAssertEqual(numRegularTabs, 2, "The number of regular tabs is not correct")
    }

    func testClosePrivateTabsOptionClosesPrivateTabs() {
        // Check that Close Private Tabs when closing the Private Browsing Button is off by default
        navigator.goto(SettingsScreen)
        let appsettingstableviewcontrollerTableviewTable = app.tables["AppSettingsTableViewController.tableView"]
        appsettingstableviewcontrollerTableviewTable.staticTexts["Firefox needs to reopen for this change to take effect."].swipeUp()
        let closePrivateTabsSwitch = appsettingstableviewcontrollerTableviewTable.switches["Close Private Tabs, When Leaving Private Browsing"]

        XCTAssertFalse(closePrivateTabsSwitch.isSelected)

        // Open a Private tab
        navigator.goto(PrivateTabTray)
        navigator.openURL(urlString: url1)
        navigator.nowAt(PrivateBrowserTab)
        navigator.goto(PrivateTabTray)

        // Go back to regular browser
        navigator.goto(TabTray)

        // Go back to private browsing and check that the tab has not been closed
        navigator.goto(PrivateTabTray)
        waitforExistence(app.collectionViews.cells[url1Label])
        let numPrivTabs = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabs, 1, "The number of tabs is not correct, the private tab should not have been closed")

        // Now the enable the Close Private Tabs when closing the Private Browsing Button
        navigator.goto(SettingsScreen)
        closePrivateTabsSwitch.tap()

        // Go back to regular browsing and check that the private tab has been closed and that the initial Private Browsing message appears when going back to Private Browsing
        navigator.goto(PrivateTabTray)
        navigator.goto(TabTray)
        navigator.goto(PrivateTabTray)

        waitforNoExistence(app.collectionViews.cells[url1Label])
        let numPrivTabsAfterClosing = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabsAfterClosing, 0, "The number of tabs is not correct, the private tab should have been closed")
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is not shown")
    }

    func testPrivateBrowserPanelView() {
        // If no private tabs are open, there should be a initial screen with label Private Browsing
        navigator.goto(PrivateTabTray)

        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is not shown")
        let numPrivTabsFirstTime = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabsFirstTime, 0, "The number of tabs is not correct, there should not be any private tab yet")

        // If a private tab is open Private Browsing screen is not shown anymore
        navigator.goto(NewPrivateTabScreen)

        // Go to regular browsing
        navigator.goto(TabTray)

        // Go back to private brosing
        navigator.goto(PrivateTabTray)
        XCTAssertFalse(app.staticTexts["Private Browsing"].exists, "Private Browsing screen is shown")
        let numPrivTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numPrivTabsOpen, 1, "The number of tabs is not correct, there should be one private tab")
    }
}
