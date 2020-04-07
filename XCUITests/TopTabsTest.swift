/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url = "www.mozilla.org"
let urlLabel = "Internet for people, not profit — Mozilla"
let urlValue = "mozilla.org"
let urlValueLong = "localhost:\(serverPort)/test-fixture/test-mozilla-org.html"

let urlExample = Base.helper.path(forTestPage: "test-example.html")
let urlLabelExample = "Example Domain"
let urlValueExample = "example"
let urlValueLongExample = "localhost:\(serverPort)/test-fixture/test-example.html"

let toastUrl = ["url": "twitter.com", "link": "About", "urlLabel": "about"]

class TopTabsTest: BaseTestCase {
    func testAddTabFromTabTray() {
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForTabsButton()
        // The tabs counter shows the correct number
        let tabsOpen = Base.app.buttons["Show Tabs"].value
        XCTAssertEqual("2", tabsOpen as? String)

        // The tab tray shows the correct tabs
        if Base.helper.iPad() {
            Base.helper.waitForExistence(Base.app.buttons["TopTabsViewController.tabsButton"], timeout: 15)
            Base.app.buttons["TopTabsViewController.tabsButton"].tap()
        } else {
            navigator.goto(TabTray)
        }
        Base.helper.waitForExistence(Base.app.collectionViews.cells[urlLabel], timeout: 5)
    }

    func testAddTabFromContext() {
        navigator.openURL(urlExample)
        // Initially there is only one tab open
        let tabsOpenInitially = Base.app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpenInitially as? String)

        // Open link in a different tab and switch to it
        Base.helper.waitForExistence(Base.app.webViews.links.staticTexts["More information..."], timeout: 5)
        Base.app.webViews.links.staticTexts["More information..."].press(forDuration: 5)
        Base.app.buttons["Open in New Tab"].tap()
        Base.helper.waitUntilPageLoad()

        // Open tab tray to check that both tabs are there
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        Base.helper.waitForExistence(Base.app.collectionViews.cells["Example Domain"])
        if !Base.app.collectionViews.cells["IANA — IANA-managed Reserved Domains"].exists {
            navigator.goto(TabTray)
            Base.app.collectionViews.cells["Example Domain"].tap()
            Base.helper.waitUntilPageLoad()
            navigator.nowAt(BrowserTab)
            navigator.goto(TabTray)
            Base.helper.waitForExistence(Base.app.collectionViews.cells["IANA — IANA-managed Reserved Domains"])
        }
    }

    func testSwitchBetweenTabs() {
        // Open two urls from tab tray and switch between them
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        navigator.openURL(urlExample)
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)

        Base.helper.waitForExistence(Base.app.collectionViews.cells[urlLabel])
        Base.app.collectionViews.cells[urlLabel].tap()
        let valueMozilla = Base.app.textFields["url"].value as! String
        XCTAssertEqual(valueMozilla, urlValueLong)

        navigator.nowAt(BrowserTab)
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)

        Base.helper.waitForExistence(Base.app.collectionViews.cells[urlLabelExample])
        Base.app.collectionViews.cells[urlLabelExample].tap()
        let value = Base.app.textFields["url"].value as! String
        XCTAssertEqual(value, urlValueLongExample)
    }

    func testCloseOneTab() {
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)

        Base.helper.waitForExistence(Base.app.collectionViews.cells[urlLabel])

        // 'x' button to close the tab is not visible, so closing by swiping the tab
        Base.app.collectionViews.cells[urlLabel].swipeRight()

        // After removing only one tab it automatically goes to HomepanelView
        Base.helper.waitForExistence(Base.app.collectionViews.cells["TopSitesCell"])
        XCTAssert(Base.app.cells["TopSitesCell"].cells["TopSite"].exists)
    }

    private func openNtabsFromTabTray(numTabs: Int) {
        for _ in 1...numTabs {
            navigator.performAction(Action.OpenNewTabFromTabTray)
        }
    }

    // Smoketest
    func testCloseAllTabsUndo() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForTabsButton()
        navigator.nowAt(BrowserTab)
        if Base.helper.iPad() {
            Base.helper.waitForExistence(Base.app.buttons["TopTabsViewController.tabsButton"], timeout: 10)
            Base.app.buttons["TopTabsViewController.tabsButton"].tap()
            Base.helper.waitForExistence(Base.app.buttons["TabTrayController.addTabButton"], timeout: 10)
            Base.app.buttons["TabTrayController.addTabButton"].tap()
        }
        else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            Base.helper.waitForExistence(Base.app.buttons["TabToolbar.tabsButton"],timeout: 5)
        }

        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        Base.app.buttons["Undo"].tap()
        Base.helper.waitForExistence(Base.app.collectionViews.cells["TopSitesCell"], timeout: 5)
        navigator.nowAt(BrowserTab)
        if !Base.helper.iPad() {
            Base.helper.waitForExistence(Base.app.buttons["TabToolbar.tabsButton"], timeout: 5)
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        Base.helper.waitForExistence(Base.app.collectionViews.cells[urlLabel])
    }

    func testCloseAllTabsPrivateModeUndo() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForTabsButton()

        if Base.helper.iPad() {
            Base.helper.waitForExistence(Base.app.buttons["TopTabsViewController.tabsButton"], timeout: 10)
            Base.app.buttons["TopTabsViewController.tabsButton"].tap()
            Base.helper.waitForExistence(Base.app.buttons["TabTrayController.addTabButton"], timeout: 10)
            Base.app.buttons["TabTrayController.addTabButton"].tap()
        }
        else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            Base.helper.waitForExistence(Base.app.buttons["TabToolbar.tabsButton"],timeout: 5)
        }

        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        Base.helper.waitForExistence(Base.app.staticTexts["Private Browsing"], timeout: 10)
        XCTAssertTrue(Base.app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
        // New behaviour on v14, there is no Undo in Private mode
        Base.helper.waitForExistence(Base.app.staticTexts["Private Browsing"], timeout:10)
    }

    func testCloseAllTabs() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForTabsButton()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        if !Base.helper.iPad() {
            Base.helper.waitForExistence(Base.app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.nowAt(NewTabScreen)
        if !Base.helper.iPad() {
            Base.helper.waitForExistence(Base.app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        Base.helper.waitForNoExistence(Base.app.collectionViews.cells[urlLabel])
    }

    func testCloseAllTabsPrivateMode() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForTabsButton()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        Base.helper.waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        XCTAssertTrue(Base.app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
    }

    // Smoketest
    func testLongTapTabCounter() {
        if !Base.helper.iPad() {
            // Long tap on Tab Counter should show the correct options
            Base.helper.waitForExistence(Base.app.buttons["Show Tabs"], timeout: 10)
            Base.app.buttons["Show Tabs"].press(forDuration: 1)
            Base.helper.waitForExistence(Base.app.cells["quick_action_new_tab"])
            XCTAssertTrue(Base.app.cells["quick_action_new_tab"].exists)
            XCTAssertTrue(Base.app.cells["tab_close"].exists)

            // Open New Tab
            Base.app.cells["quick_action_new_tab"].tap()
            Base.helper.waitForTabsButton()
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
            Base.helper.waitForExistence(Base.app.collectionViews.cells["Home"])
            Base.app.collectionViews.cells["Home"].firstMatch.tap()

            // Close tab
            navigator.nowAt(HomePanelsScreen)
            Base.helper.waitForExistence(Base.app.buttons["Show Tabs"])
            Base.app.buttons["Show Tabs"].press(forDuration: 1)
            Base.helper.waitForExistence(Base.app.cells["quick_action_new_tab"])
            Base.app.cells["tab_close"].tap()
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)

            // Go to Private Mode
            Base.helper.waitForExistence(Base.app.collectionViews.cells["Home"])
            Base.app.collectionViews.cells["Home"].firstMatch.tap()
            navigator.nowAt(HomePanelsScreen)
            Base.helper.waitForExistence(Base.app.buttons["Show Tabs"])
            Base.app.buttons["Show Tabs"].press(forDuration: 1)
            Base.helper.waitForExistence(Base.app.cells["nav-tabcounter"])
            Base.app.cells["nav-tabcounter"].tap()
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
        Base.app.collectionViews.cells[goBackToBrowserTab].firstMatch.tap()
        navigator.nowAt(BrowserTab)
    }
}

class TopTabsTestIphone: IphoneOnlyTestCase {

    func testCloseTabFromLongPressTabsButton() {
        if Base.helper.skipPlatform { return }
        Base.helper.waitForTabsButton()
        // This menu is available in HomeScreen or NewTabScreen, so no need to open new websites
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        Base.helper.waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        closeTabTrayView(goBackToBrowserTab: "Home")

        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        Base.helper.waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeTabTrayView(goBackToBrowserTab: "Home")

        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        Base.helper.waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeTabTrayView(goBackToBrowserTab: "Home")
    }

    // This test only runs for iPhone see bug 1409750
    func testAddTabByLongPressTabsButton() {
        if Base.helper.skipPlatform { return }
        Base.helper.waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
    }

    // This test only runs for iPhone see bug 1409750
    func testAddPrivateTabByLongPressTabsButton() {
        if Base.helper.skipPlatform { return }
        Base.helper.waitForTabsButton()
        navigator.performAction(Action.OpenPrivateTabLongPressTabsButton)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        Base.helper.waitForExistence(Base.app.buttons["TabTrayController.maskButton"])
        XCTAssertTrue(Base.app.buttons["TabTrayController.maskButton"].isEnabled)
        XCTAssertTrue(userState.isPrivate)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    // Smoketest
    func testSwitchBetweenTabsToastButton() {
        if Base.helper.skipPlatform { return }

        navigator.openURL(urlExample)
        Base.helper.waitUntilPageLoad()

        Base.app.webViews.links.firstMatch.press(forDuration: 1)
        Base.helper.waitForExistence(Base.app.buttons["Open in New Tab"])
        Base.app.buttons["Open in New Tab"].press(forDuration: 1)
        Base.helper.waitForExistence(Base.app.buttons["Switch"])
        Base.app.buttons["Switch"].tap()

        // Check that the tab has changed
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "iana")
        XCTAssertTrue(Base.app.links["RFC 2606"].exists)
        Base.helper.waitForExistence(Base.app.buttons["Show Tabs"])
        let numTab = Base.app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTab)


        // Go to Private mode and do the same
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(urlExample)
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.webViews.links.firstMatch)
        Base.app.webViews.links.firstMatch.press(forDuration: 1)
        Base.helper.waitForExistence(Base.app.buttons["Open in New Private Tab"])
        Base.app.buttons["Open in New Private Tab"].press(forDuration: 1)
        Base.helper.waitForExistence(Base.app.buttons["Switch"])
        Base.app.buttons["Switch"].tap()

        // Check that the tab has changed
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 5)
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "iana")
        XCTAssertTrue(Base.app.links["RFC 2606"].exists)
        Base.helper.waitForExistence(Base.app.buttons["Show Tabs"])
        let numPrivTab = Base.app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numPrivTab)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    // Smoketest
    func testSwitchBetweenTabsNoPrivatePrivateToastButton() {
        if Base.helper.skipPlatform { return }

        navigator.openURL(urlExample)
        Base.helper.waitUntilPageLoad()

        Base.app.webViews.links.firstMatch.press(forDuration: 1)
        Base.helper.waitForExistence(Base.app.buttons["Open in New Tab"], timeout: 3)
        Base.app.buttons["Open in New Private Tab"].press(forDuration: 1)
        Base.helper.waitForExistence(Base.app.buttons["Switch"], timeout: 5)
        Base.app.buttons["Switch"].tap()

        // Check that the tab has changed to the new open one and that the user is in private mode
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 5)
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "iana")
        XCTAssertTrue(Base.app.links["RFC 2606"].exists)
        navigator.goto(TabTray)
        XCTAssertTrue(Base.app.buttons["TabTrayController.maskButton"].isEnabled)
    }
}

    // Tests to check if Tab Counter is updating correctly after opening three tabs by tapping on '+' button and closing the tabs by tapping 'x' button
class TopTabsTestIpad: IpadOnlyTestCase {

    func testUpdateTabCounter(){
        if Base.helper.skipPlatform {return}
        // Open three tabs by tapping on '+' button
        Base.app.buttons["TopTabsViewController.newTabButton"].tap()
        Base.app.buttons["TopTabsViewController.newTabButton"].tap()
        Base.helper.waitForExistence(Base.app.buttons["TopTabsViewController.tabsButton"])
        let numTab = Base.app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("3", numTab)
        // Remove one tab by tapping on 'x' button
        Base.app.collectionViews["Top Tabs View"].children(matching: .cell).matching(identifier: "Home").element(boundBy: 1).buttons["Remove page — Home"].tap()
        Base.helper.waitForExistence(Base.app.buttons["Show Tabs"])
        let numTabAfterRemovingThirdTab = Base.app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTabAfterRemovingThirdTab)
        Base.app.collectionViews["Top Tabs View"].children(matching: .cell).element(boundBy: 1).buttons["Remove page — Home"].tap()
        Base.helper.waitForExistence(Base.app.buttons["Show Tabs"])
        let numTabAfterRemovingSecondTab = Base.app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("1", numTabAfterRemovingSecondTab)
    }

    func cellIsSelectedTab(index: Int, url: String, title: String) {
        XCTAssertEqual(Base.app.collectionViews["Top Tabs View"].cells.element(boundBy: index).label, title)
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: url)
    }

    func testTopSitesScrollToVisible() {
        if Base.helper.skipPlatform { return }

        // This first cell gets closed during the test
        navigator.openURL(urlValueLong)

        // Create enough tabs that tabs bar needs to scroll
        for _ in 0..<6 {
            navigator.createNewTab()
        }

        // This is the selected tab for the duration of this test
        navigator.openNewURL(urlString: urlValueLongExample)

        Base.helper.waitUntilPageLoad()

        // This is the index of the last visible cell, it doesn't change during the test
        let lastCell = Base.app.collectionViews["Top Tabs View"].cells.count - 1

        cellIsSelectedTab(index: lastCell, url: urlValueLongExample, title: urlLabelExample)

        // Scroll to first tab and delete it, swipe twice to ensure we are fully scrolled.
        Base.app.collectionViews["Top Tabs View"].cells.element(boundBy: lastCell).swipeRight()
        Base.app.collectionViews["Top Tabs View"].cells.element(boundBy: lastCell).swipeRight()
        Base.app.collectionViews["Top Tabs View"].cells[urlLabel].buttons.element(boundBy: 0).tap()
        // Confirm the view did not scroll to the selected cell
        XCTAssertEqual(Base.app.collectionViews["Top Tabs View"].cells.element(boundBy: lastCell).label, "Home")
        // Confirm the url bar still has selected cell value
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: urlValueLongExample)
    }
}
