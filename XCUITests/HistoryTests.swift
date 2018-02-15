/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let webpage = ["url": "www.mozilla.org", "label": "Internet for people, not profit — Mozilla", "value": "mozilla.org"]
// This is part of the info the user will see in recent closed tabs once the default visited website (https://www.mozilla.org/en-US/book/) is closed
let closedWebPageLabel = "The Book of Mozilla"

class HistoryTests: BaseTestCase {
    func testEmptyHistoryListFirstTime() {
        // Go to History List from Top Sites and check it is empty
        navigator.goto(HomePanel_History)
        waitforExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"])
        XCTAssertTrue(app.tables.cells["HistoryPanel.recentlyClosedCell"].exists)
        XCTAssertTrue(app.tables.cells["HistoryPanel.syncedDevicesCell"].exists)
        XCTAssertFalse(app.tables.otherElements.staticTexts["Today"].exists)
    }

    func testOpenHistoryFromBrowserContextMenuOptions() {
        navigator.openURL(webpage["url"]!)
        navigator.browserPerformAction(.openHistoryOption)

        // Go to History List from Browser context menu and there should be one entry
        waitforExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"])
        XCTAssertTrue(app.tables.otherElements.staticTexts["Today"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts[webpage["label"]!].exists)
    }

    func testOpenSyncDevices() {
        navigator.goto(HomePanel_History)
        app.tables.cells["HistoryPanel.syncedDevicesCell"].tap()
        waitforExistence(app.tables.cells.staticTexts["Firefox Sync"])
        XCTAssertTrue(app.tables/*@START_MENU_TOKEN@*/.buttons["Sign in"]/*[[".cells.buttons[\"Sign in\"]",".buttons[\"Sign in\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
    }

    func testClearHistoryFromSettings() {
        // Browse to have an item in history list
        navigator.openURL(webpage["url"]!)
        navigator.goto(HomePanel_History)
        waitforExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"])
        XCTAssertTrue(app.tables.cells.staticTexts[webpage["label"]!].exists)

        // Go to Clear Data
        navigator.performAction(Action.AcceptClearPrivateData)

        // Back on History panel view check that there is not any item
        navigator.goto(HomePanel_History)
        waitforExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"])
        XCTAssertFalse(app.tables.cells.staticTexts[webpage["label"]!].exists)
    }

    func testRecentlyClosedOptionAvailable() {
        navigator.goto(HistoryRecentlyClosed)
        waitforNoExistence(app.tables["Recently Closed Tabs List"])

        // Go to the default web site  and check whether the option is enabled
        navigator.goto(BrowserTab)
        waitUntilPageLoad()
        navigator.goto(BrowserTabMenu)
        navigator.goto(HistoryRecentlyClosed)
        waitforNoExistence(app.tables["Recently Closed Tabs List"])

        // Now go back to default website close it and check whether the option is enabled
        navigator.goto(BrowserTab)
        navigator.goto(TabTray)
        navigator.closeAllTabs()
        navigator.goto(HistoryRecentlyClosed)

        // The Closed Tabs list should contain the info of the website just closed
        waitforExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)

        // This option should be enabled on private mode too
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(HistoryRecentlyClosed)
        waitforExistence(app.tables["Recently Closed Tabs List"])
    }

    func testClearRecentlyClosedHistory() {
        // Open the default website
        navigator.goto(BrowserTab)
        navigator.goto(TabTray)
        navigator.closeAllTabs()
        navigator.goto(HomePanel_History)
        navigator.goto(HistoryRecentlyClosed)
        // Once the website is visited and closed it will appear in Recently Closed Tabs list
        waitforExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)

        // Go to settings and clear private data
        navigator.performAction(Action.AcceptClearPrivateData)

        // Back on History panel view check that there is not any item
        navigator.goto(HistoryRecentlyClosed)
        waitforNoExistence(app.tables["Recently Closed Tabs List"])
    }

    func testLongTapOptionsRecentlyClosedItem() {
        // Open the default website
        navigator.goto(BrowserTab)
        navigator.goto(TabTray)
        navigator.closeAllTabs()

        navigator.goto(BrowserTabMenu)
        navigator.goto(HistoryRecentlyClosed)
        waitforExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)
        app.tables.cells.staticTexts[closedWebPageLabel].press(forDuration: 1)
        waitforExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.cells["quick_action_new_tab"].exists)
        XCTAssertTrue(app.tables.cells["quick_action_new_private_tab"].exists)
    }

    func testOpenInNewTabRecentlyClosedItem() {
        // Open the default website
        navigator.goto(BrowserTab)
        navigator.goto(TabTray)
        navigator.closeAllTabs()

        navigator.goto(HistoryRecentlyClosed)
        waitforExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1)
        app.tables.cells.staticTexts[closedWebPageLabel].press(forDuration: 1)
        waitforExistence(app.tables["Context Menu"])
        app.tables.cells["quick_action_new_tab"].tap()
        navigator.goto(TabTray)
        let numTabsOpen2 = userState.numTabs
        XCTAssertEqual(numTabsOpen2, 2)
    }

    func testOpenInNewPrivateTabRecentlyClosedItem() {
        // Open the default website
        navigator.goto(BrowserTab)
        navigator.goto(TabTray)
        navigator.closeAllTabs()
        navigator.goto(HistoryRecentlyClosed)
        waitforExistence(app.tables["Recently Closed Tabs List"])
        XCTAssertTrue(app.tables.cells.staticTexts[closedWebPageLabel].exists)

        app.tables.cells.staticTexts[closedWebPageLabel].press(forDuration: 1)
        waitforExistence(app.tables["Context Menu"])
        app.tables.cells["quick_action_new_private_tab"].tap()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1)
    }

    func testPrivateClosedSiteDoesNotAppearOnRecentlyClosed() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        // Open the default website
        navigator.goto(BrowserTab)
        // It is necessary to open two sites so that when one is closed private mode is not closed
        navigator.openNewURL(urlString: "mozilla.org")
        waitUntilPageLoad()
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells[webpage["label"]!])
        // 'x' button to close the tab is not visible, so closing by swiping the tab
        app.collectionViews.cells[webpage["label"]!].swipeRight()

        navigator.goto(HomePanelsScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitforNoExistence(app.tables["Recently Closed Tabs List"])

        // Now verify that on regular mode the recently closed list is empty too
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(HomePanelsScreen)
        navigator.goto(HistoryRecentlyClosed)
        waitforNoExistence(app.tables["Recently Closed Tabs List"])
    }
}
