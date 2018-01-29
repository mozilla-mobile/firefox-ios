/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url = "www.mozilla.org"
let urlLabel = "Internet for people, not profit — Mozilla"
let urlValue = "mozilla.org"

let urlExample = "example.com"
let urlLabelExample = "Example Domain"
let urlValueExample = "example"

class TopTabsTest: BaseTestCase {
    func testAddTabFromSettings() {
        navigator.createNewTab()
        navigator.openURL(url)
        waitForValueContains(app.textFields["url"], value: urlValue)
        waitforExistence(app.buttons["Show Tabs"])
        let numTab = app.buttons["Show Tabs"].value as? String

        XCTAssertEqual("2", numTab)
    }

    func testAddTabFromTabTray() {
        navigator.goto(TabTray)
        navigator.openURL(url)
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
        navigator.goto(TabTray)
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, expectedNumberOfTabsOpen, "The number of tabs open is not correct")
    }

    private func closeTabTrayView(goBackToBrowserTab: String) {
        app.collectionViews.cells[goBackToBrowserTab].firstMatch.tap()
        navigator.nowAt(BrowserTab)
    }

    func testAddTabFromContext() {
        navigator.openURL(urlExample)
        // Initially there is only one tab open
        let tabsOpenInitially = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpenInitially as? String)

        // Open link in a different tab and switch to it
        waitforExistence(app.webViews.links.staticTexts["More information..."])
        app.webViews.links.staticTexts["More information..."].press(forDuration: 5)
        app.buttons["Open in New Tab"].tap()
        waitUntilPageLoad()

        // Open tab tray to check that both tabs are there
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        waitforExistence(app.collectionViews.cells["Example Domain"])
        waitforExistence(app.collectionViews.cells["IANA — IANA-managed Reserved Domains"])
    }

    // This test only runs for iPhone see bug 1409750
    func testAddTabByLongPressTabsButton() {
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
    }

    // This test only runs for iPhone see bug 1409750
    func testAddPrivateTabByLongPressTabsButton() {
        navigator.performAction(Action.OpenPrivateTabLongPressTabsButton)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        waitforExistence(app.buttons["TabTrayController.maskButton"])
        XCTAssertTrue(app.buttons["TabTrayController.maskButton"].isEnabled)
        XCTAssertTrue(userState.isPrivate)
    }

    func testSwitchBetweenTabs() {
        // Open two urls from tab tray and switch between them
        navigator.openURL(url)
        navigator.goto(TabTray)
        navigator.openURL(urlExample)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        app.collectionViews.cells[urlLabel].tap()
        waitForValueContains(app.textFields["url"], value: urlValue)

        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabelExample])
        app.collectionViews.cells[urlLabelExample].tap()
        waitForValueContains(app.textFields["url"], value: urlValueExample)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    func testSwitchBetweenTabsToastButton() {
        navigator.openURL(url)
        waitUntilPageLoad()
        app.webViews.links["Rust"].press(forDuration: 1)
        waitforExistence(app.sheets.buttons["Open in New Tab"])
        app.sheets.buttons["Open in New Tab"].press(forDuration: 1)
        waitforExistence(app.buttons["Switch"])
        app.buttons["Switch"].tap()

        // Check that the tab has changed
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "rust")
        XCTAssertTrue(app.staticTexts["Rust language"].exists)
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTab)


        // Go to Private mode and do the same
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(url)
        waitUntilPageLoad()
        app.webViews.links["Rust"].press(forDuration: 1)
        waitforExistence(app.sheets.buttons["Open in New Private Tab"])
        app.sheets.buttons["Open in New Private Tab"].press(forDuration: 1)
        waitforExistence(app.buttons["Switch"])
        app.buttons["Switch"].tap()

        // Check that the tab has changed
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "rust")
        XCTAssertTrue(app.staticTexts["Rust language"].exists)
        let numPrivTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numPrivTab)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    func testSwitchBetweenTabsNoPrivatePrivateToastButton() {
        navigator.openURL(url)
        waitUntilPageLoad()

        app.webViews.links["Rust"].press(forDuration: 1)
        waitforExistence(app.sheets.buttons["Open in New Tab"])
        app.sheets.buttons["Open in New Private Tab"].press(forDuration: 1)
        waitforExistence(app.buttons["Switch"])
        app.buttons["Switch"].tap()

        // Check that the tab has changed to the new open one and that the user is in private mode
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "rust")
        XCTAssertTrue(app.staticTexts["Rust language"].exists)
        navigator.goto(TabTray)
        XCTAssertTrue(app.buttons["TabTrayController.maskButton"].isEnabled)
    }

    func testCloseOneTab() {
        navigator.openURL(url)
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
        navigator.openURL(url)
        waitUntilPageLoad()
        navigator.createSeveralTabsFromTabTray (numberTabs: 3)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 4)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.closeAllTabs()
        app.buttons["Undo"].tap()
        navigator.nowAt(BrowserTab)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 4)
        waitforExistence(app.collectionViews.cells[urlLabel])
    }

    func testCloseAllTabsPrivateModeUndo() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(url)
        waitUntilPageLoad()
        navigator.createSeveralTabsFromTabTray (numberTabs: 3)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 4)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.closeAllTabs()
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
        app.buttons["Undo"].tap()
        navigator.nowAt(BrowserTab)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 4)
        waitforExistence(app.collectionViews.cells[urlLabel])
    }

    func testCloseAllTabs() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(url)
        waitUntilPageLoad()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.createSeveralTabsFromTabTray (numberTabs: 3)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 4)

        // Close all tabs and check that the number of tabs is correct
        navigator.closeAllTabs()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        waitforNoExistence(app.collectionViews.cells[urlLabel])
    }

    func testCloseAllTabsPrivateMode() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(url)
        waitUntilPageLoad()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.createSeveralTabsFromTabTray (numberTabs: 3)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[urlLabel])
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 4)

        // Close all tabs and check that the number of tabs is correct
        navigator.closeAllTabs()
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
    }

    func testCloseTabFromPageOptionsMenu() {
        // Open two websites so that there are two tabs open and the page options menu is available
        navigator.openURL(urlValue)
        navigator.openNewURL(urlString: urlExample)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Go back to one website so that the page options menu is available and close one tab from there
        closeTabTrayView(goBackToBrowserTab: urlLabelExample)
        navigator.performAction(Action.CloseTabFromPageOptions)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)

        // Go back to the website left open, close it and check that it has been closed
        closeTabTrayView(goBackToBrowserTab: urlLabel)
        navigator.performAction(Action.CloseTabFromPageOptions)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        waitforNoExistence(app.collectionViews.cells[urlLabel])
    }

    func testCloseTabFromLongPressTabsButton() {
        // This menu is available in HomeScreen or NewTabScreen, so no need to open new websites
        navigator.performAction(Action.OpenNewTabFromTabTray)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        closeTabTrayView(goBackToBrowserTab: "home")

        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeTabTrayView(goBackToBrowserTab: "home")

        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeTabTrayView(goBackToBrowserTab: "home")
        }
}
