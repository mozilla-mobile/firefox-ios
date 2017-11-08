/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url = "www.mozilla.org"
let urlLabel = "Internet for people, not profit — Mozilla"
let urlValue = "mozilla.org"

let urlYah = "www.yahoo.com"
let urlLabelYah = "Yahoo"
let urlValueYah = "yahoo"

let urlExample = "example.com"

class TopTabsTest: BaseTestCase {
    func testAddTabFromSettings() {
        navigator.createNewTab()
        navigator.openURL(urlString: url)
        waitForValueContains(app.textFields["url"], value: urlValue)
        waitforExistence(app.buttons["Show Tabs"])
        let numTab = app.buttons["Show Tabs"].value as? String

        XCTAssertEqual("2", numTab)
    }

    func testAddTabFromTabTray() {
        navigator.goto(TabTray)
        navigator.openURL(urlString: url)
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: urlValue)
        // The tabs counter shows the correct number
        let tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", tabsOpen as? String)

        // The tab tray shows the correct tabs
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells[urlLabel])
    }

    private func checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: Int) {
        let numTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, UInt(expectedNumberOfTabsOpen), "The number of tabs open is not correct")
    }

    func testAddTabFromContext() {
        navigator.openURL(urlString: urlExample)
        // Initially there is only one tab open
        let tabsOpenInitially = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpenInitially as? String)

        // Open link in a different tab and switch to it
        waitforExistence(app.webViews.links.staticTexts["More information..."])
        app.webViews.links.staticTexts["More information..."].press(forDuration: 5)
        app.buttons["Open in New Tab"].tap()
        waitUntilPageLoad()

        // Open tab tray to check that both tabs are there
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells["Example Domain"])
        waitforExistence(app.collectionViews.cells["IANA — IANA-managed Reserved Domains"])

        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
    }

    // This test only runs for iPhone see bug 1409750
    func testAddTabByLongPressTabsButton() {
        navigator.goto(BrowserTab)
        app.buttons["TabToolbar.tabsButton"].press(forDuration: 1)

        waitforExistence(app.buttons["New Tab"])
        app.buttons["New Tab"].tap()
        navigator.goto(TabTray)

        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
    }

    // This test only runs for iPhone see bug 1409750
    func testAddPrivateTabByLongPressTabsButton() {
        navigator.goto(BrowserTab)
        app.buttons["TabToolbar.tabsButton"].press(forDuration: 1)

        waitforExistence(app.buttons["New Private Tab"])
        app.buttons["New Private Tab"].tap()
        navigator.goto(TabTray)

        waitforExistence(app.buttons["TabTrayController.maskButton"])
        XCTAssertTrue(app.buttons["TabTrayController.maskButton"].isEnabled)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
    }

    func testSwitchBetweenTabs() {
        // Open two urls from tab tray and switch between them
        navigator.openURL(urlString: url)
        navigator.goto(TabTray)
        navigator.openURL(urlString: urlYah)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        app.collectionViews.cells[urlLabel].tap()
        waitForValueContains(app.textFields["url"], value: urlValue)

        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabelYah])
        app.collectionViews.cells[urlLabelYah].tap()
        waitForValueContains(app.textFields["url"], value: urlValueYah)
    }

    func testCloseOneTab() {
        navigator.openURL(urlString: url)
        waitUntilPageLoad()
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])

        // 'x' button to close the tab is not visible, so closing by swiping the tab
        app.collectionViews.cells[urlLabel].swipeRight()

        // After removing only one tab it automatically goes to HomepanelView
        waitforExistence(app.collectionViews.cells["TopSitesCell"])
        XCTAssert(app.buttons["HomePanels.TopSites"].exists)
    }

    func testCloseAllTabsUndo() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(urlString: url)
        waitUntilPageLoad()
        navigator.createSeveralTabsFromTabTray (numberTabs: 3)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 4)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.closeAllTabs()
        app.buttons["Undo"].tap()
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 4)
    }

    func testCloseAllTabs() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(urlString: url)
        waitUntilPageLoad()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.createSeveralTabsFromTabTray (numberTabs: 3)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 4)

        // Close all tabs and check that the number of tabs is correct
        navigator.closeAllTabs()
        navigator.goto(TabTray)

        waitforNoExistence(app.collectionViews.cells[urlLabel])
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
    }
}
