// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

let url = "www.mozilla.org"
let urlLabel = "Internet for people, not profit — Mozilla"
let selectedTab = "Currently selected tab."
let urlValue = "mozilla.org"
let urlValueLong = "localhost"

let urlExample = path(forTestPage: "test-example.html")
let urlLabelExample = "Example Domain"
let urlValueExample = "example"
let urlValueLongExample = "localhost:\(serverPort)/test-fixture/test-example.html"

let toastUrl = ["url": "twitter.com", "link": "About", "urlLabel": "about"]

class TabsTests: BaseTestCase {
    var toolBarScreen: ToolbarScreen!
    var tabTrayScreen: TabTrayScreen!
    var browserScreen: BrowserScreen!
    var newTabsScreen: NewTabsScreen!
    var firefoxHomePageScreen: FirefoxHomePageScreen!

    // https://mozilla.testrail.io/index.php?/cases/view/2307042
    // Smoketest
    func testAddTabFromTabTray() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        // The tabs counter shows the correct number
        let tabsOpen = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual("2", tabsOpen as? String)

        // The tab tray shows the correct tabs
        if iPad() {
//            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
        } else {
            navigator.goto(TabTray)
        }
        let identifier = "\(AccessibilityIdentifiers.TabTray.tabCell)_0_1"
        mozWaitForElementToExist(app.cells[identifier])
        XCTAssertEqual(app.cells[identifier].label, "\(urlLabel). \(selectedTab)")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307042
    // Smoketest TAE
    func testAddTabFromTabTray_TAE() {
        toolBarScreen = ToolbarScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
        navigator.nowAt(NewTabScreen)
        toolBarScreen.assertTabsButtonExists()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        // The tabs counter shows the correct number
        toolBarScreen.assertTabsOpened(expectedCount: 2)

        // The tab tray shows the correct tabs
        if iPad() {
            toolBarScreen.tapOnTabsButton()
        } else {
            navigator.goto(TabTray)
        }
        tabTrayScreen.assertTabCellVisibleAndHasCorrectLabel(
            index: 1,
            urlLabel: urlLabel,
            selectedTab: selectedTab
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354300
    func testAddTabFromContext() {
        navigator.openURL(urlExample)
        // Initially there is only one tab open
        let tabsOpenInitially = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual("1", tabsOpenInitially as? String)

        // Open link in a different tab and switch to it
        mozWaitForElementToExist(app.webViews.links.staticTexts["More information..."])
        app.webViews.links.staticTexts["More information..."].press(forDuration: 5)
        app.buttons["Open in New Tab"].waitAndTap()
        waitUntilPageLoad()

        // Open tab tray to check that both tabs are there
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        let identifier = "TabDisplayView.tabCell_0_1"
        XCTAssertEqual(app.cells.matching(identifier: identifier).element.label,
                       "Example Domains")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354447
    func testSwitchBetweenTabs() {
        // Open two urls from tab tray and switch between them
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(urlExample)
        waitForTabsButton()
        navigator.goto(TabTray)

        app.cells.elementContainingText(urlLabel).waitAndTap()
        guard let valueMozilla = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].value
                as? String else {
            XCTFail("Failed to retrieve the URL value from the Mozilla browser's URL bar")
            return
        }
        XCTAssertEqual(valueMozilla, urlValueLong)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)

        app.cells.elementContainingText(urlLabelExample).waitAndTap()
        guard let value = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].value
                as? String else {
            XCTFail("Failed to retrieve the URL value from the Mozilla browser's URL bar")
            return
        }
        XCTAssertEqual(value, urlValueLong)
    }

    private func openNtabsFromTabTray(numTabs: Int) {
        for _ in 1...numTabs {
            navigator.performAction(Action.OpenNewTabFromTabTray)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306865
    // Smoketest
    func testCloseAllTabsUndo() throws {
        if !iPad() {
            let shouldSkipTest = true
            try XCTSkipIf(shouldSkipTest, "Undo toast no longer available on iPhone")
        }
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
        app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
        navigator.goto(TabTray)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        app.otherElements.buttons.staticTexts["Undo"].waitAndTap()
        mozWaitForElementToExist(
            app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        mozWaitForElementToExist(app.cells.staticTexts[urlLabel])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306865
    // Smoketest TAE
    func testCloseAllTabsUndo_TAE() throws {
        if !iPad() {
            let shouldSkipTest = true
            try XCTSkipIf(shouldSkipTest, "Undo toast no longer available on iPhone")
        }
        toolBarScreen = ToolbarScreen(app: app)
        firefoxHomePageScreen = FirefoxHomePageScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        toolBarScreen.assertTabsButtonExists()
        navigator.nowAt(BrowserTab)
        toolBarScreen.tapOnTabsButton()
        tabTrayScreen.tapOnNewTabButton()
        navigator.goto(TabTray)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        tabTrayScreen.undoRemovingAllTabs()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        tabTrayScreen.waitForTabWithLabel(urlLabel)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354473
    // Smoketest
    func testCloseAllTabsPrivateModeUndo() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()

        if iPad() {
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
            app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
        } else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        }

        if iPad() {
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        } else {
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        }
        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        mozWaitForElementToExist(app.staticTexts["Private Browsing"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354473
    // Smoketest TAE
    func testCloseAllTabsPrivateModeUndo_TAE() {
        browserScreen = BrowserScreen(app: app)
        toolBarScreen = ToolbarScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        toolBarScreen.assertTabsButtonExists()

        if iPad() {
            toolBarScreen.tapOnTabsButton()
            tabTrayScreen.tapOnNewTabButton()
        } else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            toolBarScreen.assertTabsButtonExists()
        }

        if iPad() {
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        } else {
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        }
        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        browserScreen.assertPrivateBrowsingLabelExist()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354579
    func testCloseAllTabs() {
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        // Add several tabs from tab tray menu and check that the  number is correct before closing all
        navigator.performAction(Action.OpenNewTabFromTabTray)
        if !iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        }
        navigator.nowAt(NewTabScreen)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        if !iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        }
        navigator.nowAt(NewTabScreen)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354580
    func testCloseAllTabsPrivateMode() {
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(BrowserTab)
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
        mozWaitForElementToExist(app.staticTexts["Private Browsing"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306884
    // Smoketest
    func testOpenNewTabLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // Verify the '+' icon is shown and open a tab with it
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])

        // Go back to portrait mode
        XCUIDevice.shared.orientation = .portrait
        // Verify that the '+' is displayed
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306884
    // Smoketest TAE
    func testOpenNewTabLandscape_TAE() {
        toolBarScreen = ToolbarScreen(app: app)
        XCUIDevice.shared.orientation = .landscapeLeft
        // Verify the '+' icon is shown and open a tab with it
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        toolBarScreen.assertNewTabButtonExists()

        // Go back to portrait mode
        XCUIDevice.shared.orientation = .portrait
        // Verify that the '+' is displayed
        toolBarScreen.assertNewTabButtonExists()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306838
    // Smoketest
    func testLongTapTabCounter() {
        guard !iPad() else { return }
        // Long tap on Tab Counter should show the correct options
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].press(forDuration: 1)
        waitForElementsToExist(
            [
                app.cells.buttons[StandardImageIdentifiers.Large.plus],
                app.cells.buttons[StandardImageIdentifiers.Large.cross]
            ]
        )

        // Open New Tab
        app.cells.buttons[StandardImageIdentifiers.Large.plus].waitAndTap()
        navigator.performAction(Action.CloseURLBarOpen)

        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        let identifier = "\(AccessibilityIdentifiers.TabTray.tabCell)_0_0"
        app.cells[identifier].waitAndTap()
        mozWaitForElementToExist(
            app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )

        // Close tab
        navigator.nowAt(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)

        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].press(forDuration: 1)
        mozWaitForElementToExist(app.tables.cells.buttons[StandardImageIdentifiers.Large.plus])
        app.tables.cells.buttons[StandardImageIdentifiers.Large.cross].waitAndTap()
        navigator.nowAt(NewTabScreen)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)

        // Go to Private Mode
        app.cells[identifier].waitAndTap()
        mozWaitForElementToExist(
            app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )
        navigator.nowAt(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].press(forDuration: 1)
        app.tables.cells.buttons["New Private Tab"].waitAndTap()
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)
        navigator.nowAt(NewTabScreen)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306838
    // Smoketest TAE
    func testLongTapTabCounter_TAE() {
        toolBarScreen = ToolbarScreen(app: app)
        newTabsScreen = NewTabsScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
        firefoxHomePageScreen = FirefoxHomePageScreen(app: app)
        browserScreen = BrowserScreen(app: app)

        guard !iPad() else { return }
        // Long tap on Tab Counter should show the correct options
        navigator.nowAt(NewTabScreen)
        toolBarScreen.assertTabsButtonExists()
        toolBarScreen.pressTabsButton(duration: 1)
        newTabsScreen.assertLargeAndCrossIconsExist()
        // Open New Tab
        newTabsScreen.tapOnPlusIconScreen()
        browserScreen.tapCancelButtonOnUrlWithRetry()

        toolBarScreen.assertTabsButtonExists()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        tabTrayScreen.tapTabAtIndex(index: 0)

        firefoxHomePageScreen.assertTopSitesItemCellExist()

        // Close tab
        navigator.nowAt(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)

        toolBarScreen.assertTabsButtonExists()
        toolBarScreen.pressTabsButton(duration: 1)
        mozWaitForElementToExist(app.tables.cells.buttons[StandardImageIdentifiers.Large.plus])
        newTabsScreen.tapOnCrossIconScreen()
        navigator.nowAt(NewTabScreen)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)

        // Go to Private Mode
        tabTrayScreen.tapTabAtIndex(index: 0)
        firefoxHomePageScreen.assertTopSitesItemCellExist()
        navigator.nowAt(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
        toolBarScreen.assertTabsButtonExists()
        toolBarScreen.pressTabsButton(duration: 1)
        newTabsScreen.tapNewPrivateTab()
        browserScreen.tapCancelButtonOnUrlWithRetry()
        toolBarScreen.assertTabsButtonExists()
        navigator.nowAt(NewTabScreen)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307047
    func testOpenTabsViewCurrentTabThumbnail() {
        // Open ten or more tabs
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        for _ in 1...10 {
            navigator.createNewTab()
            if app.keyboards.element.isVisible() && !iPad() {
                mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
                navigator.performAction(Action.CloseURLBarOpen)
            }
        }
        let numTab = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as? String
        XCTAssertEqual("11", numTab, "The number of counted tabs is not equal to \(String(describing: numTab))")
        // Scroll down to view all open tabs thumbnails
        navigator.goto(TabTray)
        app.swipeUp()
        if iPad() {
            let navBarTabTray = AccessibilityIdentifiers.TabTray.navBarSegmentedControl
            let navBarTabTrayButton = app.segmentedControls[navBarTabTray].buttons.firstMatch
            mozWaitForElementToExist(navBarTabTrayButton)
            let tabsOpenTabTray: String = navBarTabTrayButton.label
            XCTAssertTrue(tabsOpenTabTray.hasSuffix(numTab!))
        }
        let tabsTrayCell = app.otherElements[tabsTray].cells
        // Go to a tab that is below the fold of the scrollable “Open Tabs” view
        if !iPad() {
            tabsTrayCell.element(boundBy: 3).waitAndTap()
        } else {
            XCTAssertTrue(Int(numTab!) == 11)
            tabsTrayCell.staticTexts.element(boundBy: 6).waitAndTap()
        }
        // The current tab’s thumbnail is focused in the “Open Tabs” view
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(TabTray)
        mozWaitForElementToExist(tabsTrayCell.firstMatch)
        app.swipeUp()
        if !iPad() {
            XCTAssertEqual(tabsTrayCell.element(boundBy: 3).label, "Homepage. Currently selected tab.")
        } else {
            XCTAssertEqual(tabsTrayCell.element(boundBy: 6).label, "Homepage. Currently selected tab.")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306868
    func testTabTrayCloseMultipleTabs() throws {
        if !iPad() {
            let shouldSkipTest = true
            try XCTSkipIf(shouldSkipTest, "Undo toast no longer available on iPhone")
        }
        validateToastWhenClosingMultipleTabs()
        // Choose to undo the action
        app.buttons["Undo"].waitAndTap()
        waitUntilPageLoad()
        // Only the latest tab closed is restored
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        let tabsTrayCell = app.otherElements[tabsTray].cells
        XCTAssertEqual(tabsTrayCell.count, 2)
        mozWaitForElementToExist(app.buttons["2"])
        mozWaitForElementToExist(app.otherElements.cells.staticTexts[urlLabelExample])
        // Repeat for private browsing mode
        navigator.performAction(Action.ToggleExperimentPrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        validateToastWhenClosingMultipleTabs()
        // Choose to undo the action
        app.buttons["Undo"].waitAndTap()
        // Only the latest tab closed is restored
        mozWaitForElementToExist(app.otherElements.cells.staticTexts[urlLabelExample])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306867
    func testCloseOneTabUndo() throws {
        if !iPad() {
            let shouldSkipTest = true
            try XCTSkipIf(shouldSkipTest, "Undo toast no longer available on iPhone")
        }
        // Open a few tabs
        waitForTabsButton()
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()
        navigator.createNewTab()
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/test-example.html")
        waitUntilPageLoad()
        navigator.createNewTab()
        navigator.openURL("localhost:\(serverPort)/test-fixture/test-mozilla-org.html")
        waitUntilPageLoad()
        navigator.goto(TabTray)

        // Experiment from #25337: "Undo" button no longer available on iPhone.
        // Tap "x"
        let secondTab = app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_0_2"]
        secondTab.buttons[StandardImageIdentifiers.Large.cross].tap()
        mozWaitForElementToNotExist(secondTab)
        app.buttons["Undo"].waitAndTap()
        mozWaitForElementToExist(secondTab)

        // Long press tab. Tap "Close Tab" from the context menu
        secondTab.press(forDuration: 2)
        mozWaitForElementToExist(app.collectionViews.buttons["Close Tab"])
        app.collectionViews.buttons["Close Tab"].waitAndTap()
        mozWaitForElementToNotExist(secondTab)
        app.buttons["Undo"].waitAndTap()
        mozWaitForElementToExist(secondTab)

        // Swipe tab
        secondTab.swipeLeft()
        mozWaitForElementToNotExist(secondTab)
        app.buttons["Undo"].waitAndTap()
        mozWaitForElementToExist(secondTab)
    }

    private func validateToastWhenClosingMultipleTabs() {
        // Have multiple tabs opened in the tab tray
        navigator.nowAt(BrowserTab)
        navigator.openURL(urlExample)
        waitUntilPageLoad()
        for _ in 1...4 {
            navigator.createNewTab()
        }
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        // Close multiple tabs by pressing X button
        let closeButton = StandardImageIdentifiers.Large.cross
        for _ in 0...3 {
            app.collectionViews.cells["Homepage. Currently selected tab."].buttons[closeButton].waitAndTap()
        }
        app.collectionViews.buttons[closeButton].waitAndTap()
    }

    private func addTabsAndUndoCloseTabAction(nrOfTabs: Int) {
        for _ in 1...nrOfTabs {
            navigator.createNewTab()
        }
        let numTab = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as? String
        XCTAssertEqual("4", numTab, "The number of counted tabs is not equal to \(String(describing: numTab))")
        navigator.goto(TabTray)
        // Long press on the tab tray to open the context menu
        let tabsTrayCell = app.otherElements[tabsTray].cells
        app.otherElements[tabsTray].cells.staticTexts.element(boundBy: 3).press(forDuration: 1.6)
        // Context menu opens
        waitForElementsToExist(
            [
                app.buttons["Close Tab"]
            ]
        )
        // Choose to close the tab
        app.buttons["Close Tab"].waitAndTap()
        // A toast notification is displayed with the message "Tab Closed" and the Undo option
        waitForElementsToExist(
            [
                app.buttons["Undo"],
                app.staticTexts["Tab Closed"]
            ]
        )
        app.buttons["Undo"].waitAndTap()
        mozWaitForElementToNotExist(app.buttons["Undo"])
        mozWaitForElementToNotExist(app.staticTexts["Tab Closed"])
        // The tab closed is restored
        mozWaitForElementToExist(tabsTrayCell.element(boundBy: 3))
        XCTAssertEqual(Int(numTab!), tabsTrayCell.count)
    }
}

fileprivate extension BaseTestCase {
    func checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: Int) {
        navigator.goto(TabTray)
        if #available(iOS 16, *) {
            var numTabsOpen = userState.numTabs
            if iPad() {
                numTabsOpen = app.collectionViews.firstMatch.cells.count
            }
            XCTAssertEqual(numTabsOpen, expectedNumberOfTabsOpen, "The number of tabs open is not correct")
        } else {
            // iOS 15 does not update userState.numTabs properly
        }
    }

    func closeTabTrayView(goBackToBrowserTab: String) {
        app.cells.staticTexts[goBackToBrowserTab].firstMatch.waitAndTap()
        navigator.nowAt(BrowserTab)
    }

    func closeExperimentTabTrayView(goBackToBrowserTab: String) {
        let tabCell = app.cells.containing(NSPredicate(format: "label CONTAINS %@", goBackToBrowserTab)).firstMatch
        XCTAssertTrue(tabCell.waitForExistence(timeout: 5))
        tabCell.tap()
        navigator.nowAt(BrowserTab)
    }
}

class TabsTestsIphone: BaseTestCase {
    var toolBarScreen: ToolbarScreen!
    var tabTrayScreen: TabTrayScreen!
    var browserScreen: BrowserScreen!
    var newTabsScreen: NewTabsScreen!
    var firefoxHomePageScreen: FirefoxHomePageScreen!

    override func setUp() async throws {
        specificForPlatform = .phone
        if !iPad() {
            try await super.setUp()
        }
        toolBarScreen = ToolbarScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        newTabsScreen = NewTabsScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2355535
    // Smoketest
    func testCloseTabFromLongPressTabsButton() {
        if skipPlatform { return }
        waitForTabsButton()
        // This menu is available in HomeScreen or NewTabScreen, so no need to open new websites
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        closeExperimentTabTrayView(goBackToBrowserTab: "Homepage")
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeExperimentTabTrayView(goBackToBrowserTab: "Homepage")
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeExperimentTabTrayView(goBackToBrowserTab: "Homepage")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2355535
    // Smoketest TAE
    func testCloseTabFromLongPressTabsButton_TAE() {
        if skipPlatform { return }

        // This menu is available in HomeScreen or NewTabScreen, so no need to open new websites
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        toolBarScreen.assertTabsButtonExists()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        closeExperimentTabTrayView(goBackToBrowserTab: "Homepage")
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        toolBarScreen.assertTabsButtonExists()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeExperimentTabTrayView(goBackToBrowserTab: "Homepage")
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        toolBarScreen.assertTabsButtonExists()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeExperimentTabTrayView(goBackToBrowserTab: "Homepage")
    }

    // This test only runs for iPhone see bug 1409750
    // https://mozilla.testrail.io/index.php?/cases/view/2355536
    // Smoketest
    func testAddTabByLongPressTabsButton() {
        if skipPlatform { return }
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.nowAt(BrowserTab)
        // Adding tapping action to avoid the test to fail in bitrise
        app.buttons["Cancel"].tapIfExists()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2355536
    // Smoketest TAE
    func testAddTabByLongPressTabsButton_TAE() {
        if skipPlatform { return }
        navigator.nowAt(BrowserTab)
        toolBarScreen.assertTabsButtonExists()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.nowAt(BrowserTab)
        browserScreen.tapCancelButtonIfExist()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
    }

    // This test only runs for iPhone see bug 1409750
    // https://mozilla.testrail.io/index.php?/cases/view/2355537
    // Smoketest
    func testAddPrivateTabByLongPressTabsButton() {
        if skipPlatform { return }
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenPrivateTabLongPressTabsButton)
        navigator.nowAt(BrowserTab)
        // Adding tapping action to avoid the test to fail in bitrise
        app.buttons["Cancel"].tapIfExists()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        let privateIdentifier = "\(AccessibilityIdentifiers.TabTray.selectorCell)0"
        mozWaitForElementToExist(app.buttons[privateIdentifier])
        XCTAssertTrue(app.buttons[privateIdentifier].isEnabled)
        XCTAssertTrue(userState.isPrivate)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2355537
    // Smoketest TAE
    func testAddPrivateTabByLongPressTabsButton_TAE() {
        if skipPlatform { return }
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenPrivateTabLongPressTabsButton)
        navigator.nowAt(BrowserTab)
        // Adding tapping action to avoid the test to fail in bitrise
        browserScreen.tapCancelButtonIfExist()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        tabTrayScreen.assertTabButtonEnabled(at: 0)
        XCTAssertTrue(userState.isPrivate)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    // https://mozilla.testrail.io/index.php?/cases/view/2306861
    // Smoketest
    func testSwitchBetweenTabsToastButton() {
        if skipPlatform { return }
        navigator.openURL(urlExample)
        waitUntilPageLoad()

        app.webViews.links.firstMatch.press(forDuration: 1)
        mozWaitForElementToExist(app.buttons["Open in New Tab"])
        app.buttons["Open in New Tab"].press(forDuration: 1)
        app.buttons["Switch"].waitAndTap()

        // Check that the tab has changed
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "iana")
        mozWaitForElementToExist(app.links["RFC 2606"])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        let numTab = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as? String
        XCTAssertEqual("2", numTab)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306861
    // Smoketest TAE
    func testSwitchBetweenTabsToastButton_TAE() {
        if skipPlatform { return }
        navigator.openURL(urlExample)
        waitUntilPageLoad()

        app.webViews.links.firstMatch.press(forDuration: 1)
        newTabsScreen.pressOpenNewTabButtonExist(duration: 1, timeout: TIMEOUT)
        newTabsScreen.tapOnSwitchButton()

        // Check that the tab has changed
        waitUntilPageLoad()
        browserScreen.addressToolbarContainValue(value: "iana")
        browserScreen.assertRFCLinkExist()
        toolBarScreen.assertTabsButtonExists()
        toolBarScreen.assertTabsButtonValue(expectedCount: "2")
    }

    // This test is disabled for iPad because the toast menu is not shown there
    // https://mozilla.testrail.io/index.php?/cases/view/2306860
    // Smoketest
    func testSwitchBetweenTabsNoPrivatePrivateToastButton() {
        if skipPlatform { return }
        navigator.openURL(urlExample)
        waitUntilPageLoad()

        app.webViews.links.firstMatch.press(forDuration: 1)
        mozWaitForElementToExist(app.buttons["Open in New Tab"])
        app.buttons["Open in New Private Tab"].press(forDuration: 1)
        app.buttons["Switch"].waitAndTap()

        // Check that the tab has changed to the new open one and that the user is in private mode
        waitUntilPageLoad()
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "iana")
        navigator.goto(TabTray)
        let privateIdentifier = "\(AccessibilityIdentifiers.TabTray.selectorCell)0"
        mozWaitForElementToExist(app.buttons[privateIdentifier])
        XCTAssertTrue(app.buttons[privateIdentifier].isEnabled)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306860
    // Smoketest TAE
    func testSwitchBetweenTabsNoPrivatePrivateToastButton_TAE() {
        if skipPlatform { return }
        navigator.openURL(urlExample)
        waitUntilPageLoad()

        app.webViews.links.firstMatch.press(forDuration: 1)
        newTabsScreen.pressOpenNewPrivateTabButton(duration: 1, timeout: TIMEOUT)
        newTabsScreen.tapOnSwitchButton()

        // Check that the tab has changed to the new open one and that the user is in private mode
        waitUntilPageLoad()
        browserScreen.addressToolbarContainValue(value: "iana")
        navigator.goto(TabTray)
        tabTrayScreen.assertTabButtonEnabled(at: 0)
    }
}

// Tests to check if Tab Counter is updating correctly after opening three tabs by tapping on '+' button
// and closing the tabs by tapping 'x' button
class TabsTestsIpad: IpadOnlyTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2307023
    func testUpdateTabCounter() {
        if skipPlatform { return }
        // Open three tabs by tapping on '+' button
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        let numTab = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as? String
        XCTAssertEqual("3", numTab)
        // Remove one tab by tapping on 'x' button
        app.collectionViews["Top Tabs View"]
            .children(matching: .cell)
            .matching(identifier: "Homepage")
            .element(boundBy: 1).buttons["Remove page — Homepage"]
            .waitAndTap()
        waitForTabsButton()
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].staticTexts["3"])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].staticTexts["2"])
        let numTabAfterRemovingThirdTab = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as? String
        XCTAssertEqual("2", numTabAfterRemovingThirdTab)
        app.collectionViews["Top Tabs View"]
            .children(matching: .cell)
            .element(boundBy: 1)
            .buttons["Remove page — Homepage"]
            .waitAndTap()
        waitForTabsButton()
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].staticTexts["2"])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].staticTexts["1"])
        let numTabAfterRemovingSecondTab = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as? String
        XCTAssertEqual("1", numTabAfterRemovingSecondTab)
    }
}
