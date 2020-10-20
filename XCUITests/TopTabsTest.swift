/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url = "www.mozilla.org"
let urlLabel = "Internet for people, not profit — Mozilla"
let urlValue = "mozilla.org"
let urlValueLong = "localhost:\(serverPort)/test-fixture/test-mozilla-org.html"

let urlExample = path(forTestPage: "test-example.html")
let urlLabelExample = "Example Domain"
let urlValueExample = "example"
let urlValueLongExample = "localhost:\(serverPort)/test-fixture/test-example.html"

let toastUrl = ["url": "twitter.com", "link": "About", "urlLabel": "about"]

class TopTabsTest: BaseTestCase {
    func testAddTabFromTabTray() {
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        // The tabs counter shows the correct number
        let tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", tabsOpen as? String)

        // The tab tray shows the correct tabs
        if iPad() {
            waitForExistence(app.buttons["TopTabsViewController.tabsButton"], timeout: 15)
            app.buttons["TopTabsViewController.tabsButton"].tap()
        } else {
            navigator.goto(TabTray)
        }
        waitForExistence(app.collectionViews.cells[urlLabel], timeout: 5)
    }

    func testAddTabFromContext() {
        navigator.openURL(urlExample)
        // Initially there is only one tab open
        let tabsOpenInitially = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpenInitially as? String)

        // Open link in a different tab and switch to it
        waitForExistence(app.webViews.links.staticTexts["More information..."], timeout: 5)
        app.webViews.links.staticTexts["More information..."].press(forDuration: 5)
        app.buttons["Open in New Tab"].tap()
        waitUntilPageLoad()

        // Open tab tray to check that both tabs are there
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        waitForExistence(app.collectionViews.cells["Example Domain"])
        if !app.collectionViews.cells["IANA — IANA-managed Reserved Domains"].exists {
            navigator.goto(TabTray)
            app.collectionViews.cells["Example Domain"].tap()
            waitUntilPageLoad()
            navigator.nowAt(BrowserTab)
            navigator.goto(TabTray)
            waitForExistence(app.collectionViews.cells["IANA — IANA-managed Reserved Domains"])
        }
    }

    func testSwitchBetweenTabs() {
        // Open two urls from tab tray and switch between them
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.openURL(urlExample)
        waitForTabsButton()
        navigator.goto(TabTray)

        waitForExistence(app.collectionViews.cells[urlLabel])
        app.collectionViews.cells[urlLabel].tap()
        let valueMozilla = app.textFields["url"].value as! String
        XCTAssertEqual(valueMozilla, urlValueLong)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)

        waitForExistence(app.collectionViews.cells[urlLabelExample])
        app.collectionViews.cells[urlLabelExample].tap()
        let value = app.textFields["url"].value as! String
        XCTAssertEqual(value, urlValueLongExample)
    }

    func testCloseOneTab() {
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)

        waitForExistence(app.collectionViews.cells[urlLabel])

        // 'x' button to close the tab is not visible, so closing by swiping the tab
        app.collectionViews.cells[urlLabel].swipeRight()

        // After removing only one tab it automatically goes to HomepanelView
        waitForExistence(app.collectionViews.cells["TopSitesCell"])
        XCTAssert(app.cells["TopSitesCell"].cells["TopSite"].exists)
    }

    private func openNtabsFromTabTray(numTabs: Int) {
        for _ in 1...numTabs {
            navigator.performAction(Action.OpenNewTabFromTabTray)
        }
    }

    // Smoketest
    func testCloseAllTabsUndo() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        if iPad() {
            waitForExistence(app.buttons["TopTabsViewController.tabsButton"], timeout: 10)
            app.buttons["TopTabsViewController.tabsButton"].tap()
            waitForExistence(app.buttons["TabTrayController.addTabButton"], timeout: 10)
            app.buttons["TabTrayController.addTabButton"].tap()
        }
        else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            waitForExistence(app.buttons["TabToolbar.tabsButton"],timeout: 5)
        }

        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        app.buttons["Undo"].tap()
        waitForExistence(app.collectionViews.cells["TopSitesCell"], timeout: 5)
        navigator.nowAt(BrowserTab)
        if !iPad() {
            waitForExistence(app.buttons["TabToolbar.tabsButton"], timeout: 5)
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        waitForExistence(app.collectionViews.cells[urlLabel])
    }

    func testCloseAllTabsPrivateModeUndo() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()

        if iPad() {
            waitForExistence(app.buttons["TopTabsViewController.tabsButton"], timeout: 10)
            app.buttons["TopTabsViewController.tabsButton"].tap()
            waitForExistence(app.buttons["TabTrayController.addTabButton"], timeout: 10)
            app.buttons["TabTrayController.addTabButton"].tap()
        }
        else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            waitForExistence(app.buttons["TabToolbar.tabsButton"],timeout: 5)
        }

        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        waitForExistence(app.staticTexts["Private Browsing"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
        // New behaviour on v14, there is no Undo in Private mode
        waitForExistence(app.staticTexts["Private Browsing"], timeout:10)
    }

    func testCloseAllTabs() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            waitForExistence(app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            waitForExistence(app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        waitForNoExistence(app.collectionViews.cells[urlLabel])
    }

    func testCloseAllTabsPrivateMode() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
    }

    // Smoketest
    func testLongTapTabCounter() {
        if !iPad() {
            // Long tap on Tab Counter should show the correct options
            waitForExistence(app.buttons["Show Tabs"], timeout: 10)
            app.buttons["Show Tabs"].press(forDuration: 1)
            waitForExistence(app.cells["quick_action_new_tab"])
            XCTAssertTrue(app.cells["quick_action_new_tab"].exists)
            XCTAssertTrue(app.cells["tab_close"].exists)

            // Open New Tab
            app.cells["quick_action_new_tab"].tap()
            waitForTabsButton()
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
            waitForExistence(app.collectionViews.cells["Home"])
            app.collectionViews.cells["Home"].firstMatch.tap()

            // Close tab
            navigator.nowAt(HomePanelsScreen)
            waitForExistence(app.buttons["Show Tabs"])
            app.buttons["Show Tabs"].press(forDuration: 1)
            waitForExistence(app.cells["quick_action_new_tab"])
            app.cells["tab_close"].tap()
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)

            // Go to Private Mode
            waitForExistence(app.collectionViews.cells["Home"])
            app.collectionViews.cells["Home"].firstMatch.tap()
            navigator.nowAt(HomePanelsScreen)
            waitForExistence(app.buttons["Show Tabs"])
            app.buttons["Show Tabs"].press(forDuration: 1)
            waitForExistence(app.cells["nav-tabcounter"])
            app.cells["nav-tabcounter"].tap()
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        }
    }
}

fileprivate extension BaseTestCase {
    func checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: Int) {
        navigator.goto(TabTray)
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, expectedNumberOfTabsOpen, "The number of tabs open is not correct")
    }

    func closeTabTrayView(goBackToBrowserTab: String) {
        app.collectionViews.cells[goBackToBrowserTab].firstMatch.tap()
        navigator.nowAt(BrowserTab)
    }
}

class TopTabsTestIphone: IphoneOnlyTestCase {

    func testCloseTabFromLongPressTabsButton() {
        if skipPlatform { return }
        waitForTabsButton()
        // This menu is available in HomeScreen or NewTabScreen, so no need to open new websites
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        closeTabTrayView(goBackToBrowserTab: "Home")

        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeTabTrayView(goBackToBrowserTab: "Home")

        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeTabTrayView(goBackToBrowserTab: "Home")
    }

    // This test only runs for iPhone see bug 1409750
    func testAddTabByLongPressTabsButton() {
        if skipPlatform { return }
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
    }

    // This test only runs for iPhone see bug 1409750
    func testAddPrivateTabByLongPressTabsButton() {
        if skipPlatform { return }
        waitForTabsButton()
        navigator.performAction(Action.OpenPrivateTabLongPressTabsButton)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        waitForExistence(app.buttons["TabTrayController.maskButton"])
        XCTAssertTrue(app.buttons["TabTrayController.maskButton"].isEnabled)
        XCTAssertTrue(userState.isPrivate)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    // Smoketest
    func testSwitchBetweenTabsToastButton() {
        if skipPlatform { return }

        navigator.openURL(urlExample)
        waitUntilPageLoad()

        app.webViews.links.firstMatch.press(forDuration: 1)
        waitForExistence(app.buttons["Open in New Tab"])
        app.buttons["Open in New Tab"].press(forDuration: 1)
        waitForExistence(app.buttons["Switch"])
        app.buttons["Switch"].tap()

        // Check that the tab has changed
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "iana")
        XCTAssertTrue(app.links["RFC 2606"].exists)
        waitForExistence(app.buttons["Show Tabs"])
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTab)


        // Go to Private mode and do the same
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(urlExample)
        waitUntilPageLoad()
        waitForExistence(app.webViews.links.firstMatch)
        app.webViews.links.firstMatch.press(forDuration: 1)
        waitForExistence(app.buttons["Open in New Private Tab"])
        app.buttons["Open in New Private Tab"].press(forDuration: 1)
        waitForExistence(app.buttons["Switch"])
        app.buttons["Switch"].tap()

        // Check that the tab has changed
        waitUntilPageLoad()
        waitForExistence(app.textFields["url"], timeout: 5)
        waitForValueContains(app.textFields["url"], value: "iana")
        XCTAssertTrue(app.links["RFC 2606"].exists)
        waitForExistence(app.buttons["Show Tabs"])
        let numPrivTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numPrivTab)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    // Smoketest
    func testSwitchBetweenTabsNoPrivatePrivateToastButton() {
        if skipPlatform { return }

        navigator.openURL(urlExample)
        waitUntilPageLoad()

        app.webViews.links.firstMatch.press(forDuration: 1)
        waitForExistence(app.buttons["Open in New Tab"], timeout: 3)
        app.buttons["Open in New Private Tab"].press(forDuration: 1)
        waitForExistence(app.buttons["Switch"], timeout: 5)
        app.buttons["Switch"].tap()

        // Check that the tab has changed to the new open one and that the user is in private mode
        waitUntilPageLoad()
        waitForExistence(app.textFields["url"], timeout: 5)
        waitForValueContains(app.textFields["url"], value: "iana")
        XCTAssertTrue(app.links["RFC 2606"].exists)
        navigator.goto(TabTray)
        XCTAssertTrue(app.buttons["TabTrayController.maskButton"].isEnabled)
    }
}

    // Tests to check if Tab Counter is updating correctly after opening three tabs by tapping on '+' button and closing the tabs by tapping 'x' button
class TopTabsTestIpad: IpadOnlyTestCase {

    func testUpdateTabCounter(){
        if skipPlatform {return}
        // Open three tabs by tapping on '+' button
        app.buttons["TopTabsViewController.newTabButton"].tap()
        app.buttons["TopTabsViewController.newTabButton"].tap()
        waitForExistence(app.buttons["TopTabsViewController.tabsButton"])
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("3", numTab)
        // Remove one tab by tapping on 'x' button
        app.collectionViews["Top Tabs View"].children(matching: .cell).matching(identifier: "Home").element(boundBy: 1).buttons["Remove page — Home"].tap()
        waitForExistence(app.buttons["Show Tabs"])
        let numTabAfterRemovingThirdTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTabAfterRemovingThirdTab)
        app.collectionViews["Top Tabs View"].children(matching: .cell).element(boundBy: 1).buttons["Remove page — Home"].tap()
        waitForExistence(app.buttons["Show Tabs"])
        let numTabAfterRemovingSecondTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("1", numTabAfterRemovingSecondTab)
    }

    func cellIsSelectedTab(index: Int, url: String, title: String) {
        XCTAssertEqual(app.collectionViews["Top Tabs View"].cells.element(boundBy: index).label, title)
        waitForValueContains(app.textFields["url"], value: url)
    }

    func testTopSitesScrollToVisible() {
        if skipPlatform { return }

        // This first cell gets closed during the test
        navigator.openURL(urlValueLong)

        // Create enough tabs that tabs bar needs to scroll
        for _ in 0..<6 {
            navigator.createNewTab()
        }

        // This is the selected tab for the duration of this test
        navigator.openNewURL(urlString: urlValueLongExample)

        waitUntilPageLoad()

        // This is the index of the last visible cell, it doesn't change during the test
        let lastCell = app.collectionViews["Top Tabs View"].cells.count - 1

        cellIsSelectedTab(index: lastCell, url: urlValueLongExample, title: urlLabelExample)

        // Scroll to first tab and delete it, swipe twice to ensure we are fully scrolled.
        app.collectionViews["Top Tabs View"].cells.element(boundBy: lastCell).swipeRight()
        app.collectionViews["Top Tabs View"].cells.element(boundBy: lastCell).swipeRight()
        app.collectionViews["Top Tabs View"].cells[urlLabel].buttons.element(boundBy: 0).tap()
        // Confirm the view did not scroll to the selected cell
        XCTAssertEqual(app.collectionViews["Top Tabs View"].cells.element(boundBy: lastCell).label, "Home")
        // Confirm the url bar still has selected cell value
        waitForValueContains(app.textFields["url"], value: urlValueLongExample)
    }
}
