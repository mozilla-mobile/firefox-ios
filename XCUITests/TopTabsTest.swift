/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let url = "www.mozilla.org"
let urlLabel = "Internet for people, not profit — Mozilla"
let urlValue = "mozilla.org"

let urlExample = path(forTestPage: "test-example.html")
let urlLabelExample = "Example Domain"
let urlValueExample = "example"

let toastUrl = ["url": "twitter.com", "link": "About", "urlLabel": "about"]

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

    func testAddTabFromContext() {
        navigator.openURL(urlExample)
        // Initially there is only one tab open
        let tabsOpenInitially = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpenInitially as? String)

        // Open link in a different tab and switch to it
        waitforExistence(app.webViews.links.staticTexts["More information..."], timeout: 5)
        app.webViews.links.staticTexts["More information..."].press(forDuration: 5)
        app.buttons["Open in New Tab"].tap()
        waitUntilPageLoad()

        // Open tab tray to check that both tabs are there
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        waitforExistence(app.collectionViews.cells["Example Domain"])
        if !app.collectionViews.cells["IANA — IANA-managed Reserved Domains"].exists {
            navigator.goto(TabTray)
            app.collectionViews.cells["Example Domain"].tap()
            waitUntilPageLoad()
            navigator.nowAt(BrowserTab)
            navigator.goto(TabTray)
            waitforExistence(app.collectionViews.cells["IANA — IANA-managed Reserved Domains"])
        }
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

    private func openNtabsFromTabTray(numTabs: Int) {
        for _ in 1...numTabs {
            navigator.performAction(Action.OpenNewTabFromTabTray)
        }
    }

    func testCloseAllTabsUndo() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        if !iPad() {
            waitforExistence(app.buttons["TabToolbar.tabsButton"],timeout: 5)
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        app.buttons["Undo"].tap()
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        if !iPad() {
            waitforExistence(app.buttons["TabToolbar.tabsButton"], timeout: 5)
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        waitforExistence(app.collectionViews.cells[urlLabel])
    }

    func testCloseAllTabsPrivateModeUndo() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        openNtabsFromTabTray(numTabs: 1)
        waitforExistence(app.buttons["TabToolbar.tabsButton"], timeout: 3)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
        // New behaviour on v14, there is no Undo in Private mode
        waitforExistence(app.staticTexts["Private Browsing"])
    }

    func testCloseAllTabs() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            waitforExistence(app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            waitforExistence(app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        waitforNoExistence(app.collectionViews.cells[urlLabel])
    }

    func testCloseAllTabsPrivateMode() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)

        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
    }
    // This test is disabled, this option is not shown now
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

    func testLongTapTabCounter() {
        if !iPad() {
            // Long tap on Tab Counter should show the correct options
            waitforExistence(app.buttons["Show Tabs"])
            app.buttons["Show Tabs"].press(forDuration: 1)
            waitforExistence(app.cells["quick_action_new_tab"])
            XCTAssertTrue(app.cells["quick_action_new_tab"].exists)
            XCTAssertTrue(app.cells["tab_close"].exists)

            // Open New Tab
            app.cells["quick_action_new_tab"].tap()
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
            app.collectionViews.cells["home"].firstMatch.tap()

            // Close tab
            navigator.nowAt(HomePanelsScreen)
            waitforExistence(app.buttons["Show Tabs"])
            app.buttons["Show Tabs"].press(forDuration: 1)
            waitforExistence(app.cells["quick_action_new_tab"])
            app.cells["tab_close"].tap()
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)

            // Go to Private Mode
            app.collectionViews.cells["home"].firstMatch.tap()
            navigator.nowAt(HomePanelsScreen)
            waitforExistence(app.buttons["Show Tabs"])
            app.buttons["Show Tabs"].press(forDuration: 1)
            waitforExistence(app.cells["nav-tabcounter"])
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
        // This menu is available in HomeScreen or NewTabScreen, so no need to open new websites
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            waitforExistence(app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        closeTabTrayView(goBackToBrowserTab: "home")

        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            waitforExistence(app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeTabTrayView(goBackToBrowserTab: "home")

        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            waitforExistence(app.buttons["TabToolbar.tabsButton"])
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeTabTrayView(goBackToBrowserTab: "home")
    }

    // This test only runs for iPhone see bug 1409750
    func testAddTabByLongPressTabsButton() {
        if skipPlatform { return }
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
    }

    // This test only runs for iPhone see bug 1409750
    func testAddPrivateTabByLongPressTabsButton() {
        if skipPlatform { return }
        navigator.performAction(Action.OpenPrivateTabLongPressTabsButton)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        waitforExistence(app.buttons["TabTrayController.maskButton"])
        XCTAssertTrue(app.buttons["TabTrayController.maskButton"].isEnabled)
        XCTAssertTrue(userState.isPrivate)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    func testSwitchBetweenTabsToastButton() {
        if skipPlatform { return }

        navigator.openURL(toastUrl["url"]!)
        waitUntilPageLoad()

        app.webViews.links.staticTexts[toastUrl["link"]!].press(forDuration: 1)
        waitforExistence(app.sheets.buttons["Open in New Tab"])
        app.sheets.buttons["Open in New Tab"].press(forDuration: 1)
        app.buttons["Switch"].tap()

        // Check that the tab has changed
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: toastUrl["urlLabel"]!)
        XCTAssertTrue(app.staticTexts[toastUrl["link"]!].exists)
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTab)


        // Go to Private mode and do the same
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(toastUrl["url"]!)
        waitUntilPageLoad()
        app.webViews.links[toastUrl["link"]!].press(forDuration: 1)
        waitforExistence(app.sheets.buttons["Open in New Private Tab"])
        app.sheets.buttons["Open in New Private Tab"].press(forDuration: 1)
        app.buttons["Switch"].tap()

        // Check that the tab has changed
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: toastUrl["urlLabel"]!)
        XCTAssertTrue(app.staticTexts[toastUrl["link"]!].exists)
        let numPrivTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numPrivTab)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    func testSwitchBetweenTabsNoPrivatePrivateToastButton() {
        if skipPlatform { return }

        navigator.openURL(toastUrl["url"]!)
        waitUntilPageLoad()

        app.webViews.links[toastUrl["link"]!].press(forDuration: 1)
        waitforExistence(app.sheets.buttons["Open in New Tab"])
        app.sheets.buttons["Open in New Private Tab"].press(forDuration: 1)
        waitforExistence(app.buttons["Switch"], timeout: 5)
        app.buttons["Switch"].tap()

        // Check that the tab has changed to the new open one and that the user is in private mode
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: toastUrl["urlLabel"]!)
        XCTAssertTrue(app.staticTexts[toastUrl["link"]!].exists)
        navigator.goto(TabTray)
        XCTAssertTrue(app.buttons["TabTrayController.maskButton"].isEnabled)
    }
}
