// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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
    func testAddTabFromTabTray() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 45)
        }
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
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
        waitForExistence(app.cells.staticTexts[urlLabel], timeout: 5)
    }

    func testAddTabFromContext() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
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
        waitForExistence(app.cells.staticTexts["Example Domain"])
        if !app.cells.staticTexts["IANA — IANA-managed Reserved Domains"].exists {
            navigator.goto(TabTray)
            app.cells.staticTexts["Example Domain"].firstMatch.tap()
            waitUntilPageLoad()
            navigator.nowAt(BrowserTab)
            navigator.goto(TabTray)
            waitForExistence(app.otherElements.cells.staticTexts["IANA-managed Reserved Domains"])
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

        waitForExistence(app.cells.staticTexts[urlLabel])
        app.cells.staticTexts[urlLabel].firstMatch.tap()
        let valueMozilla = app.textFields["url"].value as! String
        XCTAssertEqual(valueMozilla, urlValueLong)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)

        waitForExistence(app.cells.staticTexts[urlLabelExample])
        app.cells.staticTexts[urlLabelExample].firstMatch.tap()
        let value = app.textFields["url"].value as! String
        XCTAssertEqual(value, urlValueLongExample)
    }

    func testCloseOneTab() {
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)

        waitForExistence(app.cells.staticTexts[urlLabel])
        // Close the tab using 'x' button
        if iPad() {
            app.cells.buttons["tab close"].tap()
        } else {
            app.otherElements.cells.buttons["tab close"].tap()
        }

        // After removing only one tab it automatically goes to HomepanelView
        waitForExistence(app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        XCTAssert(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].exists)
    }

    private func openNtabsFromTabTray(numTabs: Int) {
        for _ in 1...numTabs {
            navigator.performAction(Action.OpenNewTabFromTabTray)
        }
    }

    // Smoketest
    func testCloseAllTabsUndo() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        if iPad() {
            waitForExistence(app.buttons["TopTabsViewController.tabsButton"], timeout: 10)
            app.buttons["TopTabsViewController.tabsButton"].tap()
            waitForExistence(app.buttons["newTabButtonTabTray"], timeout: 10)
            app.buttons["newTabButtonTabTray"].tap()
        } else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            waitForExistence(app.buttons["TabToolbar.tabsButton"], timeout: 5)
        }

        if iPad() {
            navigator.goto(TabTray)
        } else {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)

        waitForExistence(app.otherElements.buttons.staticTexts["Undo"])
        app.otherElements.buttons.staticTexts["Undo"].tap()

        waitForExistence(app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell], timeout: 5)
        navigator.nowAt(BrowserTab)
        if !iPad() {
            waitForExistence(app.buttons["TabToolbar.tabsButton"], timeout: 5)
        }

        if iPad() {
            navigator.goto(TabTray)
        } else {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        waitForExistence(app.cells.staticTexts[urlLabel])
    }

    func testCloseAllTabsPrivateModeUndo() {
        navigator.goto(URLBarOpen)
        navigator.back()
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()

        if iPad() {
            waitForExistence(app.buttons["TopTabsViewController.tabsButton"], timeout: 10)
            app.buttons["TopTabsViewController.tabsButton"].tap()
            waitForExistence(app.buttons["newTabButtonTabTray"], timeout: 10)
            app.buttons["newTabButtonTabTray"].tap()
        } else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            waitForExistence(app.buttons["TabToolbar.tabsButton"], timeout: 5)
        }

        navigator.goto(URLBarOpen)
        navigator.back()
        if iPad() {
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        } else {
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        }
        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        waitForExistence(app.staticTexts["Private Browsing"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
        // New behaviour on v14, there is no Undo in Private mode
        waitForExistence(app.staticTexts["Private Browsing"], timeout: 10)
    }

    func testCloseAllTabs() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        if !iPad() {
            waitForExistence(app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        if !iPad() {
            waitForExistence(app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        waitForExistence(app.cells.staticTexts["Homepage"])
    }

    func testCloseAllTabsPrivateMode() {
        // A different tab than home is open to do the proper checks
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
    }

    // Smoketest
    func testOpenNewTabLandscape() {
        navigator.performAction(Action.CloseURLBarOpen)
        XCUIDevice.shared.orientation = .landscapeLeft
        // Verify the '+' icon is shown and open a tab with it
        if iPad() {
            waitForExistence(app.buttons["TopTabsViewController.newTabButton"])
            app.buttons["TopTabsViewController.newTabButton"].tap()
        } else {
            waitForExistence(app.buttons["TabToolbar.addNewTabButton"], timeout: 15)
            app.buttons["TabToolbar.addNewTabButton"].tap()
        }
        app.typeText("google.com\n")
        waitUntilPageLoad()

        // Go back to portrait mode
        XCUIDevice.shared.orientation = .portrait
        // Verify that the '+' is not displayed
        if !iPad() {
            waitForNoExistence(app.buttons["TabToolbar.addNewTabButton"])
        }
    }

    // Smoketest
    func testLongTapTabCounter() throws {
        throw XCTSkip("This test is failing. Isabel will be looking into it")
//        if !iPad() {
//            waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
//            // Long tap on Tab Counter should show the correct options
//            navigator.performAction(Action.CloseURLBarOpen)
//            navigator.nowAt(NewTabScreen)
//            waitForExistence(app.buttons["Show Tabs"], timeout: 10)
//            app.buttons["Show Tabs"].press(forDuration: 1)
//            waitForExistence(app.cells[ImageIdentifiers.newTab])
//            XCTAssertTrue(app.cells[ImageIdentifiers.newTab].exists)
//            XCTAssertTrue(app.cells["tab_close"].exists)
//
//            // Open New Tab
//            app.cells[ImageIdentifiers.newTab].tap()
//            navigator.performAction(Action.CloseURLBarOpen)
//
//            waitForTabsButton()
//            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
//            waitForExistence(app.cells.staticTexts["Home"])
//            app.cells.staticTexts["Home"].firstMatch.tap()
//
//            // Close tab
//            navigator.nowAt(HomePanelsScreen)
//            navigator.performAction(Action.CloseURLBarOpen)
//            navigator.nowAt(NewTabScreen)
//
//            waitForExistence(app.buttons["Show Tabs"])
//            app.buttons["Show Tabs"].press(forDuration: 1)
//            waitForExistence(app.cells[ImageIdentifiers.newTab])
//            app.cells["tab_close"].tap()
//            navigator.performAction(Action.CloseURLBarOpen)
//            navigator.nowAt(NewTabScreen)
//            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
//
//            // Go to Private Mode
//            waitForExistence(app.cells.staticTexts["Home"])
//            app.cells.staticTexts["Home"].firstMatch.tap()
//            navigator.nowAt(HomePanelsScreen)
//            navigator.performAction(Action.CloseURLBarOpen)
//            navigator.nowAt(NewTabScreen)
//            waitForExistence(app.buttons["Show Tabs"])
//            app.buttons["Show Tabs"].press(forDuration: 1)
//            waitForExistence(app.cells["nav-tabcounter"])
//            app.cells["nav-tabcounter"].tap()
//            navigator.performAction(Action.CloseURLBarOpen)
//            navigator.nowAt(NewTabScreen)
//            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
//        }
    }
}

fileprivate extension BaseTestCase {
    func checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: Int) {
        navigator.goto(TabTray)
        var numTabsOpen = userState.numTabs
        if iPad() {
            numTabsOpen = app.collectionViews.firstMatch.cells.count
        }
        XCTAssertEqual(numTabsOpen, expectedNumberOfTabsOpen, "The number of tabs open is not correct")
    }

    func closeTabTrayView(goBackToBrowserTab: String) {
        app.cells.staticTexts[goBackToBrowserTab].firstMatch.tap()
        navigator.nowAt(BrowserTab)
    }
}

class TopTabsTestIphone: IphoneOnlyTestCase {

    func testCloseTabFromLongPressTabsButton() throws {
        throw XCTSkip("This test is failing. Isabel will be looking into it")
//        if skipPlatform { return }
//        navigator.goto(URLBarOpen)
//        navigator.back()
//        waitForTabsButton()
//        // This menu is available in HomeScreen or NewTabScreen, so no need to open new websites
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        navigator.performAction(Action.CloseURLBarOpen)
//        navigator.nowAt(NewTabScreen)
//        waitForTabsButton()
//        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
//        closeTabTrayView(goBackToBrowserTab: "Home")
//        navigator.performAction(Action.CloseURLBarOpen)
//        navigator.nowAt(NewTabScreen)
//        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
//        navigator.performAction(Action.CloseURLBarOpen)
//        navigator.nowAt(NewTabScreen)
//        waitForTabsButton()
//        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
//        closeTabTrayView(goBackToBrowserTab: "Home")
//        navigator.performAction(Action.CloseURLBarOpen)
//        navigator.nowAt(NewTabScreen)
//        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
//        navigator.performAction(Action.CloseURLBarOpen)
//        navigator.nowAt(NewTabScreen)
//        waitForTabsButton()
//        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
//        closeTabTrayView(goBackToBrowserTab: "Home")
    }

    // This test only runs for iPhone see bug 1409750
    func testAddTabByLongPressTabsButton() {
        if skipPlatform { return }
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.goto(URLBarOpen)
        navigator.back()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
    }

    // This test only runs for iPhone see bug 1409750
    func testAddPrivateTabByLongPressTabsButton() {
        if skipPlatform { return }
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenPrivateTabLongPressTabsButton)
        navigator.goto(URLBarOpen)
        navigator.back()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        waitForExistence(app.buttons["smallPrivateMask"])
        XCTAssertTrue(app.buttons["smallPrivateMask"].isEnabled)
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
        navigator.goto(TabTray)
        XCTAssertTrue(app.buttons["smallPrivateMask"].isEnabled)
    }
}

    // Tests to check if Tab Counter is updating correctly after opening three tabs by tapping on '+' button and closing the tabs by tapping 'x' button
class TopTabsTestIpad: IpadOnlyTestCase {

    func testUpdateTabCounter() {
        if skipPlatform { return }
        // Open three tabs by tapping on '+' button
        app.buttons["TopTabsViewController.newTabButton"].tap()
        app.buttons["TopTabsViewController.newTabButton"].tap()
        waitForExistence(app.buttons["TopTabsViewController.tabsButton"])
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("3", numTab)
        // Remove one tab by tapping on 'x' button
        app.collectionViews["Top Tabs View"].children(matching: .cell).matching(identifier: "Homepage").element(boundBy: 1).buttons["Remove page — Homepage"].tap()
        waitForExistence(app.buttons["Show Tabs"])
        let numTabAfterRemovingThirdTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTabAfterRemovingThirdTab)
        app.collectionViews["Top Tabs View"].children(matching: .cell).element(boundBy: 1).buttons["Remove page — Homepage"].tap()
        waitForExistence(app.buttons["Show Tabs"])
        let numTabAfterRemovingSecondTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("1", numTabAfterRemovingSecondTab)
    }

    func cellIsSelectedTab(index: Int, url: String, title: String) {
        XCTAssertEqual(app.collectionViews["Top Tabs View"].cells.element(boundBy: index).label, title)
        waitForValueContains(app.textFields["url"], value: url)
    }

    func testTopSitesScrollToVisible() throws {
        throw XCTSkip("Not sure about new behaviour with urlBar focused")

//        if skipPlatform { return }
//
//        // This first cell gets closed during the test
//        navigator.openURL(urlValueLong)
//
//        // Create enough tabs that tabs bar needs to scroll
//        for _ in 0..<6 {
//            navigator.createNewTab()
//        }
//
//        // This is the selected tab for the duration of this test
//        navigator.openNewURL(urlString: urlValueLongExample)
//
//        waitUntilPageLoad()
//
//        // This is the index of the last visible cell, it doesn't change during the test
//        let lastCell = app.collectionViews["Top Tabs View"].cells.count - 1
//
//        cellIsSelectedTab(index: lastCell, url: urlValueLongExample, title: urlLabelExample)
//
//        // Scroll to first tab and delete it, swipe twice to ensure we are fully scrolled.
//        app.collectionViews["Top Tabs View"].cells.element(boundBy: lastCell).swipeRight()
//        app.collectionViews["Top Tabs View"].cells.element(boundBy: lastCell).swipeRight()
//        app.collectionViews["Top Tabs View"].cells[urlLabel].buttons.element(boundBy: 0).tap()
//        // Confirm the view did not scroll to the selected cell
//        XCTAssertEqual(app.collectionViews["Top Tabs View"].cells.element(boundBy: lastCell).label, "Home")
//        // Confirm the url bar still has selected cell value
//        waitForValueContains(app.textFields["url"], value: urlValueLongExample)
    }
}
