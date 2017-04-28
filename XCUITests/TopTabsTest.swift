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

    func testAddTabFromSettings() {
        navigator.createNewTab()
        navigator.openURL(urlString: url)
        waitForValueContains(app.textFields["url"], value: urlValue)
        waitforExistence(app.buttons["Show Tabs"])
        let numTab = app.buttons["Show Tabs"].value

        XCTAssertEqual("2", numTab as? String)
    }

    func testAddTabFromTabTray() {
        navigator.goto(TabTray)
        navigator.openURL(urlString: url)
        waitForValueContains(app.textFields["url"], value: urlValue)
        // The tabs counter shows the correct number
        let tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", tabsOpen as? String)

        // The tab tray shows the correct tabs
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells[urlLabel])
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
        //waitforExistence(app.buttons["Switch"])
        //app.buttons["Switch"].tap(force: true)

        // Open tab tray to check that both tabs are there
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells["Example Domain"])
        waitforExistence(app.collectionViews.cells["IANA — IANA-managed Reserved Domains"])
        let numTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 2, "Tab not added from link")
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
        navigator.goto(NewTabScreen)
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells[urlLabel])

        // 'x' button to close the tab is not visible, so closing by swiping the tab
        app.collectionViews.cells[urlLabel].swipeRight()

        // After removing only one tab is visible and should be home
        let numTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 1, "After removing one tab there should remain only one")
        waitforNoExistence(app.collectionViews.cells[urlLabel])
        waitforExistence(app.collectionViews.cells["home"])
    }

    func testCloseAllTabsUndo() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(urlString: url)
        // Add several tabs and check that the number is correct
        navigator.createSeveralTabsFromTabTray (numberTabs: 3)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        let numTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 4, "The number of regular tabs is not correct")

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.closeAllTabs()
        app.buttons["Undo"].tap()
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        let numTabsAfterUndo = app.collectionViews.cells.count
        XCTAssertEqual(numTabsAfterUndo, 4, "The number of regular tabs is not correct")
    }

    func testCloseAllTabs() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(urlString: url)
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.createSeveralTabsFromTabTray (numberTabs: 3)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        let numTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 4, "The number of tabs is not correct after opening 4")

        // Close all tabs and check that the number of tabs is correct
        navigator.closeAllTabs()
        navigator.goto(TabTray)
        waitforNoExistence(app.collectionViews.cells[urlLabel])
        let numTabsAfterClosingAll = app.collectionViews.cells.count
        XCTAssertEqual(numTabsAfterClosingAll, 1, "The number of tabs is not correct after closing all")
    }
}
