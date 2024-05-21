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
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307042
    // Smoketest
    func testAddTabFromTabTray() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            mozWaitForElementToExist(app.collectionViews["FxCollectionView"], timeout: TIMEOUT)
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
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 15)
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].tap()
        } else {
            navigator.goto(TabTray)
        }
        mozWaitForElementToExist(app.cells.staticTexts[urlLabel], timeout: TIMEOUT)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2354300
    func testAddTabFromContext() {
        navigator.nowAt(NewTabScreen)
        navigator.openURL(urlExample)
        // Initially there is only one tab open
        let tabsOpenInitially = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpenInitially as? String)

        // Open link in a different tab and switch to it
        mozWaitForElementToExist(app.webViews.links.staticTexts["More information..."], timeout: 5)
        app.webViews.links.staticTexts["More information..."].press(forDuration: 5)
        app.buttons["Open in New Tab"].tap()
        waitUntilPageLoad()

        // Open tab tray to check that both tabs are there
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        mozWaitForElementToExist(app.cells.staticTexts["Example Domain"])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2354447
    func testSwitchBetweenTabs() {
        // Open two urls from tab tray and switch between them
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.openURL(urlExample)
        waitForTabsButton()
        navigator.goto(TabTray)

        mozWaitForElementToExist(app.cells.staticTexts[urlLabel])
        app.cells.staticTexts[urlLabel].firstMatch.tap()
        let valueMozilla = app.textFields["url"].value as! String
        XCTAssertEqual(valueMozilla, urlValueLong)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)

        mozWaitForElementToExist(app.cells.staticTexts[urlLabelExample])
        app.cells.staticTexts[urlLabelExample].firstMatch.tap()
        let value = app.textFields["url"].value as! String
        XCTAssertEqual(value, urlValueLongExample)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2354449
    func testCloseOneTab() {
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)

        mozWaitForElementToExist(app.cells.staticTexts[urlLabel])
        // Close the tab using 'x' button
        if iPad() {
            app.cells.buttons[StandardImageIdentifiers.Large.cross].tap()
        } else {
            app.otherElements.cells.buttons[StandardImageIdentifiers.Large.cross].tap()
        }

        // After removing only one tab it automatically goes to HomepanelView
        mozWaitForElementToExist(
            app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )
        XCTAssert(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].exists)
    }

    private func openNtabsFromTabTray(numTabs: Int) {
        for _ in 1...numTabs {
            navigator.performAction(Action.OpenNewTabFromTabTray)
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306865
    // Smoketest
    func testCloseAllTabsUndo() {
        navigator.nowAt(NewTabScreen)
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        if iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 10)
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].tap()
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: 10)
            app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].tap()
        } else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 5)
        }

        if iPad() {
            navigator.goto(TabTray)
        } else {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Disabling next steps due to https://github.com/mozilla-mobile/firefox-ios/issues/16810 crash
        // Close all tabs, undo it and check that the number of tabs is correct
//        navigator.performAction(Action.AcceptRemovingAllTabs)
//
//        mozWaitForElementToExist(app.otherElements.buttons.staticTexts["Undo"])
//        app.otherElements.buttons.staticTexts["Undo"].tap()
//
//        mozWaitForElementToExist(
//            app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell],
//            timeout: 5
//        )
//        navigator.nowAt(BrowserTab)
//        if !iPad() {
//            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 5)
//        }
//
//        if iPad() {
//            navigator.goto(TabTray)
//        } else {
//            navigator.performAction(Action.CloseURLBarOpen)
//        }
//        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
//
//        mozWaitForElementToExist(app.cells.staticTexts[urlLabel])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2354473
    // Smoketest
    func testCloseAllTabsPrivateModeUndo() {
        navigator.goto(URLBarOpen)
        mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: TIMEOUT_LONG)
        navigator.back()
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()

        if iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 10)
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].tap()
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: 10)
            app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].tap()
        } else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 5)
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
        mozWaitForElementToExist(app.staticTexts["Private Browsing"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Private Browsing"].exists, "Private welcome screen is not shown")
        // New behaviour on v14, there is no Undo in Private mode
        mozWaitForElementToExist(app.staticTexts["Private Browsing"], timeout: 10)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2354579
    func testCloseAllTabs() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        if !iPad() {
            navigator.performAction(Action.CloseURLBarOpen)
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        }
        navigator.nowAt(NewTabScreen)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Disabling next steps due to https://github.com/mozilla-mobile/firefox-ios/issues/16810 crash
        // Close all tabs and check that the number of tabs is correct
//        navigator.performAction(Action.AcceptRemovingAllTabs)
//        if !iPad() {
//            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
//        }
//        navigator.nowAt(NewTabScreen)
//        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
//        mozWaitForElementToExist(app.cells.staticTexts["Homepage"])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2354580
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
        mozWaitForElementToExist(app.staticTexts["Private Browsing"], timeout: TIMEOUT)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306884
    // Smoketest
    func testOpenNewTabLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // Verify the '+' icon is shown and open a tab with it
        if iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
            app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].tap()
        } else {
            mozWaitForElementToExist(
                app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton],
                timeout: 15
            )
            app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].tap()
        }
        app.typeText("google.com\n")
        waitUntilPageLoad()

        // Go back to portrait mode
        XCUIDevice.shared.orientation = .portrait
        // Verify that the '+' is not displayed
        if !iPad() {
            mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306838
    // Smoketest
    func testLongTapTabCounter() {
        if !iPad() {
            // Long tap on Tab Counter should show the correct options
            navigator.nowAt(NewTabScreen)
            mozWaitForElementToExist(app.buttons["Show Tabs"], timeout: 10)
            app.buttons["Show Tabs"].press(forDuration: 1)
            mozWaitForElementToExist(app.cells.otherElements[StandardImageIdentifiers.Large.plus])
            XCTAssertTrue(app.cells.otherElements[StandardImageIdentifiers.Large.plus].exists)
            XCTAssertTrue(app.cells.otherElements[StandardImageIdentifiers.Large.cross].exists)

            // Open New Tab
            app.cells.otherElements[StandardImageIdentifiers.Large.plus].tap()
            navigator.performAction(Action.CloseURLBarOpen)

            waitForTabsButton()
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
            mozWaitForElementToExist(app.cells.staticTexts["Homepage"])
            app.cells.staticTexts["Homepage"].firstMatch.tap()
            mozWaitForElementToExist(
                app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
            )

            // Close tab
            navigator.nowAt(HomePanelsScreen)
            navigator.nowAt(NewTabScreen)

            mozWaitForElementToExist(app.buttons["Show Tabs"])
            app.buttons["Show Tabs"].press(forDuration: 1)
            mozWaitForElementToExist(app.tables.cells.otherElements[StandardImageIdentifiers.Large.plus])
            app.tables.cells.otherElements[StandardImageIdentifiers.Large.cross].tap()
            navigator.nowAt(NewTabScreen)
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)

            // Go to Private Mode
            mozWaitForElementToExist(app.cells.staticTexts["Homepage"])
            app.cells.staticTexts["Homepage"].firstMatch.tap()
            mozWaitForElementToExist(
                app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
            )
            navigator.nowAt(HomePanelsScreen)
            navigator.nowAt(NewTabScreen)
            mozWaitForElementToExist(app.buttons["Show Tabs"])
            app.buttons["Show Tabs"].press(forDuration: 1)
            mozWaitForElementToExist(app.tables.cells.otherElements["Private Browsing Mode"])
            app.tables.cells.otherElements["Private Browsing Mode"].tap()
            navigator.nowAt(NewTabScreen)
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307047
    func testOpenTabsViewCurrentTabThumbnail() {
        // Open ten or more tabs
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        for _ in 1...10 {
            navigator.createNewTab()
            if app.keyboards.element.isVisible() && !iPad() {
                mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: TIMEOUT)
                navigator.performAction(Action.CloseURLBarOpen)
            }
        }
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("11", numTab, "The number of counted tabs is not equal to \(String(describing: numTab))")
        // Scroll down to view all open tabs thumbnails
        navigator.goto(TabTray)
        app.swipeUp()
        if !iPad() {
            let navBarTabTray = AccessibilityIdentifiers.TabTray.navBarSegmentedControl
            let navBarTabTrayButton = app.segmentedControls[navBarTabTray].buttons.firstMatch
            mozWaitForElementToExist(navBarTabTrayButton)
            let tabsOpenTabTray: String = navBarTabTrayButton.label
            XCTAssertTrue(tabsOpenTabTray.hasSuffix(numTab!))
        } else {
            let navBarTabTrayButton = app.segmentedControls["Open Tabs"].buttons.firstMatch
            mozWaitForElementToExist(navBarTabTrayButton)
            XCTAssertTrue(navBarTabTrayButton.label.hasSuffix(numTab!))
        }
        let tabsTrayCell = app.otherElements["Tabs Tray"].cells
        // Go to a tab that is below the fold of the scrollable “Open Tabs” view
        if !iPad() {
            tabsTrayCell.staticTexts.element(boundBy: 3).tap()
        } else {
            XCTAssertEqual(tabsTrayCell.count, Int(numTab!))
            tabsTrayCell.staticTexts.element(boundBy: 6).tap()
        }
        // The current tab’s thumbnail is focused in the “Open Tabs” view
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(TabTray)
        app.swipeDown()
        app.swipeUp()
        if !iPad() {
            XCTAssertEqual(tabsTrayCell.element(boundBy: 3).label, "Homepage. Currently selected tab.")
        } else {
            XCTAssertEqual(tabsTrayCell.element(boundBy: 6).label, "Homepage. Currently selected tab.")
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306869
    func testTabTrayContextMenuCloseTab() {
        // Have multiple tabs opened in the tab tray
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        addTabsAndUndoCloseTabAction(nrOfTabs: 3)
        // Repeat steps for private browsing mode
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        addTabsAndUndoCloseTabAction(nrOfTabs: 4)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306868
    func testTabTrayCloseMultipleTabs() {
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            validateToastWhenClosingMultipleTabs(fromIndex: 6, toIndex: 2)
        } else {
            validateToastWhenClosingMultipleTabs(fromIndex: 4, toIndex: 0)
        }
        app.collectionViews.buttons["crossLarge"].tap()
        // Choose to undo the action
        app.buttons["Undo"].tap()
        waitUntilPageLoad()
        // Only the latest tab closed is restored
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        let tabsTrayCell = app.otherElements["Tabs Tray"].cells
        if !iPad() {
            let numTab = app.buttons["Show Tabs"].value as? String
            XCTAssertEqual(Int(numTab!), tabsTrayCell.count)
        } else {
            XCTAssertEqual(tabsTrayCell.count, 2)
            XCTAssertTrue(app.buttons.elementContainingText("2").exists)
        }
        mozWaitForElementToExist(app.otherElements.cells.staticTexts[urlLabelExample])
        // Repeat for private browsing mode
        navigator.performAction(Action.TogglePrivateMode)
        validateToastWhenClosingMultipleTabs(fromIndex: 4, toIndex: 0)
        app.collectionViews.buttons["crossLarge"].tap()
        // Choose to undo the action
        app.buttons["Undo"].tap()
        // Only the latest tab closed is restored
        if !iPad() {
            let numTab = app.buttons["Show Tabs"].value as? String
            let tabsTrayCell = app.otherElements["Tabs Tray"].cells
            XCTAssertEqual(Int(numTab!), tabsTrayCell.count)
        }
        mozWaitForElementToExist(app.otherElements.cells.staticTexts[urlLabelExample])
    }

    private func validateToastWhenClosingMultipleTabs(fromIndex: Int, toIndex: Int) {
        // Have multiple tabs opened in the tab tray
        navigator.openURL(urlExample)
        waitUntilPageLoad()
        for _ in 1...4 {
            navigator.createNewTab()
            if app.keyboards.element.isVisible() && !iPad() {
                mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: TIMEOUT)
                navigator.performAction(Action.CloseURLBarOpen)
            }
        }
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        // Close multiple tabs by pressing X button
        for index in stride(from: fromIndex, to: toIndex, by: -1) {
            app.collectionViews.buttons.element(boundBy: index).tap()
            // A toast notification is displayed with the message "Tab Closed" and the Undo option
            mozWaitForElementToExist(app.buttons["Undo"])
            mozWaitForElementToExist(app.staticTexts["Tab Closed"])
        }
    }

    private func addTabsAndUndoCloseTabAction(nrOfTabs: Int) {
        for _ in 1...nrOfTabs {
            navigator.createNewTab()
            if app.keyboards.element.isVisible() && !iPad() {
                mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: TIMEOUT)
                navigator.performAction(Action.CloseURLBarOpen)
            }
        }
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("4", numTab, "The number of counted tabs is not equal to \(String(describing: numTab))")
        navigator.goto(TabTray)
        // Long press on the tab tray to open the context menu
        let tabsTrayCell = app.otherElements["Tabs Tray"].cells
        app.otherElements["Tabs Tray"].cells.staticTexts.element(boundBy: 3).press(forDuration: 1.6)
        // Context menu opens
        mozWaitForElementToExist(app.buttons["Close Tab"])
        mozWaitForElementToExist(app.buttons["Copy URL"])
        // Choose to close the tab
        app.buttons["Close Tab"].tap()
        // A toast notification is displayed with the message "Tab Closed" and the Undo option
        mozWaitForElementToExist(app.buttons["Undo"])
        mozWaitForElementToExist(app.staticTexts["Tab Closed"])
        app.buttons["Undo"].tap()
        // The tab closed is restored
        XCTAssertEqual(Int(numTab!), tabsTrayCell.count)
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
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2355535
    // Smoketest
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
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2355536
    // Smoketest
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
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2355537
    // Smoketest
    func testAddPrivateTabByLongPressTabsButton() {
        if skipPlatform { return }
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenPrivateTabLongPressTabsButton)
        navigator.goto(URLBarOpen)
        navigator.back()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        mozWaitForElementToExist(app.buttons["privateModeLarge"])
        XCTAssertTrue(app.buttons["privateModeLarge"].isEnabled)
        XCTAssertTrue(userState.isPrivate)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306861
    // Smoketest
    func testSwitchBetweenTabsToastButton() {
        if skipPlatform { return }

        navigator.openURL(urlExample)
        waitUntilPageLoad()

        app.webViews.links.firstMatch.press(forDuration: 1)
        mozWaitForElementToExist(app.buttons["Open in New Tab"])
        app.buttons["Open in New Tab"].press(forDuration: 1)
        mozWaitForElementToExist(app.buttons["Switch"])
        app.buttons["Switch"].tap()

        // Check that the tab has changed
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: "iana")
        XCTAssertTrue(app.links["RFC 2606"].exists)
        mozWaitForElementToExist(app.buttons["Show Tabs"])
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTab)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306860
    // Smoketest
    func testSwitchBetweenTabsNoPrivatePrivateToastButton() {
        if skipPlatform { return }

        navigator.openURL(urlExample)
        waitUntilPageLoad()

        app.webViews.links.firstMatch.press(forDuration: 1)
        mozWaitForElementToExist(app.buttons["Open in New Tab"], timeout: 3)
        app.buttons["Open in New Private Tab"].press(forDuration: 1)
        mozWaitForElementToExist(app.buttons["Switch"], timeout: 5)
        app.buttons["Switch"].tap()

        // Check that the tab has changed to the new open one and that the user is in private mode
        waitUntilPageLoad()
        mozWaitForElementToExist(app.textFields["url"], timeout: 5)
        mozWaitForValueContains(app.textFields["url"], value: "iana")
        navigator.goto(TabTray)
        XCTAssertTrue(app.buttons["privateModeLarge"].isEnabled)
    }
}

// Tests to check if Tab Counter is updating correctly after opening three tabs by tapping on '+' button
// and closing the tabs by tapping 'x' button
class TopTabsTestIpad: IpadOnlyTestCase {
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307023
    func testUpdateTabCounter() {
        if skipPlatform { return }
        // Open three tabs by tapping on '+' button
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].tap()
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("3", numTab)
        // Remove one tab by tapping on 'x' button
        app.collectionViews["Top Tabs View"]
            .children(matching: .cell)
            .matching(identifier: "Homepage")
            .element(boundBy: 1).buttons["Remove page — Homepage"]
            .tap()
        waitForTabsButton()
        mozWaitForElementToNotExist(app.buttons["Show Tabs"].staticTexts["3"])
        mozWaitForElementToExist(app.buttons["Show Tabs"].staticTexts["2"])
        let numTabAfterRemovingThirdTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTabAfterRemovingThirdTab)
        app.collectionViews["Top Tabs View"]
            .children(matching: .cell)
            .element(boundBy: 1)
            .buttons["Remove page — Homepage"]
            .tap()
        waitForTabsButton()
        mozWaitForElementToNotExist(app.buttons["Show Tabs"].staticTexts["2"])
        mozWaitForElementToExist(app.buttons["Show Tabs"].staticTexts["1"])
        let numTabAfterRemovingSecondTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("1", numTabAfterRemovingSecondTab)
    }
}
