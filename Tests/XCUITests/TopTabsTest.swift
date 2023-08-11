// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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
            waitForExistence(app.collectionViews["FxCollectionView"], timeout: TIMEOUT)
        }
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
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 15)
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].tap()
        } else {
            navigator.goto(TabTray)
        }
        waitForExistence(app.cells.staticTexts[urlLabel], timeout: TIMEOUT)
    }

    func testAddTabFromContext() {
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
        if !app.cells.staticTexts["Example Domains"].exists {
            navigator.goto(TabTray)
            app.cells.staticTexts["Examples Domain"].firstMatch.tap()
            waitUntilPageLoad()
            navigator.nowAt(BrowserTab)
            navigator.goto(TabTray)
            waitForExistence(app.otherElements.cells.staticTexts["Examples Domains"])
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
            app.cells.buttons[StandardImageIdentifiers.Large.cross].tap()
        } else {
            app.otherElements.cells.buttons[StandardImageIdentifiers.Large.cross].tap()
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
        navigator.nowAt(NewTabScreen)
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        if iPad() {
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 10)
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].tap()
            waitForExistence(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: 10)
            app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].tap()
        } else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 5)
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
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 5)
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
        waitForExistence(app.buttons["urlBar-cancel"], timeout: TIMEOUT_LONG)
        navigator.back()
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()

        if iPad() {
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 10)
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].tap()
            waitForExistence(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: 10)
            app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].tap()
        } else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 5)
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
        if !iPad() {
            navigator.performAction(Action.CloseURLBarOpen)
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        }
        navigator.nowAt(NewTabScreen)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        if !iPad() {
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        }
        navigator.nowAt(NewTabScreen)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        waitForExistence(app.cells.staticTexts["Homepage"])
    }

    func testCloseAllTabsPrivateMode() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        if !iPad() {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        waitForExistence(app.staticTexts["Private Browsing"], timeout: TIMEOUT)
    }

    // Smoketest
    func testOpenNewTabLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // Verify the '+' icon is shown and open a tab with it
        if iPad() {
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
            app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].tap()
        } else {
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton], timeout: 15)
            app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].tap()
        }
        app.typeText("google.com\n")
        waitUntilPageLoad()

        // Go back to portrait mode
        XCUIDevice.shared.orientation = .portrait
        // Verify that the '+' is not displayed
        if !iPad() {
            waitForNoExistence(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        }
    }

    // Smoketest
    func testLongTapTabCounter() {
        if !iPad() {
            // Long tap on Tab Counter should show the correct options
            navigator.nowAt(NewTabScreen)
            waitForExistence(app.buttons["Show Tabs"], timeout: 10)
            app.buttons["Show Tabs"].press(forDuration: 1)
            waitForExistence(app.cells.otherElements[StandardImageIdentifiers.Large.plus])
            XCTAssertTrue(app.cells.otherElements[StandardImageIdentifiers.Large.plus].exists)
            XCTAssertTrue(app.cells.otherElements[StandardImageIdentifiers.Large.cross].exists)

            // Open New Tab
            app.cells.otherElements[StandardImageIdentifiers.Large.plus].tap()
            navigator.performAction(Action.CloseURLBarOpen)

            waitForTabsButton()
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
            waitForExistence(app.cells.staticTexts["Homepage"])
            app.cells.staticTexts["Homepage"].firstMatch.tap()
            waitForExistence(app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])

            // Close tab
            navigator.nowAt(HomePanelsScreen)
            navigator.nowAt(NewTabScreen)

            waitForExistence(app.buttons["Show Tabs"])
            app.buttons["Show Tabs"].press(forDuration: 1)
            waitForExistence(app.tables.cells.otherElements[StandardImageIdentifiers.Large.plus])
            app.tables.cells.otherElements[StandardImageIdentifiers.Large.cross].tap()
            navigator.nowAt(NewTabScreen)
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)

            // Go to Private Mode
            waitForExistence(app.cells.staticTexts["Homepage"])
            app.cells.staticTexts["Homepage"].firstMatch.tap()
            waitForExistence(app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
            navigator.nowAt(HomePanelsScreen)
            navigator.nowAt(NewTabScreen)
            waitForExistence(app.buttons["Show Tabs"])
            app.buttons["Show Tabs"].press(forDuration: 1)
            waitForExistence(app.tables.cells.otherElements["Private Browsing Mode"])
            app.tables.cells.otherElements["Private Browsing Mode"].tap()
            navigator.nowAt(NewTabScreen)
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        }
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
    func testCloseTabFromLongPressTabsButton() {
        if skipPlatform { return }
        navigator.goto(URLBarOpen)
        navigator.back()
        waitForTabsButton()
        // This menu is available in HomeScreen or NewTabScreen, so no need to open new websites
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        closeTabTrayView(goBackToBrowserTab: "Homepage")
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeTabTrayView(goBackToBrowserTab: "Homepage")
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeTabTrayView(goBackToBrowserTab: "Homepage")
    }

    // This test only runs for iPhone see bug 1409750
    func testAddTabByLongPressTabsButton() {
        if skipPlatform { return }
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
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].tap()
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].tap()
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("3", numTab)
        // Remove one tab by tapping on 'x' button
        app.collectionViews["Top Tabs View"].children(matching: .cell).matching(identifier: "Homepage").element(boundBy: 1).buttons["Remove page — Homepage"].tap()
        waitForTabsButton()
        waitForNoExistence(app.buttons["Show Tabs"].staticTexts["3"])
        waitForExistence(app.buttons["Show Tabs"].staticTexts["2"])
        let numTabAfterRemovingThirdTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTabAfterRemovingThirdTab)
        app.collectionViews["Top Tabs View"].children(matching: .cell).element(boundBy: 1).buttons["Remove page — Homepage"].tap()
        waitForTabsButton()
        waitForNoExistence(app.buttons["Show Tabs"].staticTexts["2"])
        waitForExistence(app.buttons["Show Tabs"].staticTexts["1"])
        let numTabAfterRemovingSecondTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("1", numTabAfterRemovingSecondTab)
    }
}
