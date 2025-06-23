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

class TabsTests: FeatureFlaggedTestBase {
    // https://mozilla.testrail.io/index.php?/cases/view/2307042
    // Smoketest
    func testAddTabFromTabTray_tabTrayExperimentOff() throws {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
        XCTExpectFailure("The app was not launched", strict: false) {
            mozWaitForElementToExist(app.collectionViews["FxCollectionView"])
        }
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(TabTray)
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
        mozWaitForElementToExist(app.cells.staticTexts[urlLabel])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307042
    // Smoketest
    func testAddTabFromTabTray_tabTrayExperimentOn() throws {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()
        XCTExpectFailure("The app was not launched", strict: false) {
            mozWaitForElementToExist(app.collectionViews["FxCollectionView"])
        }
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(TabTray)
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
        let identifier = "\(AccessibilityIdentifiers.TabTray.tabCell)_1_1"
        mozWaitForElementToExist(app.cells[identifier])
        XCTAssertEqual(app.cells[identifier].label, "\(urlLabel). \(selectedTab)")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354300
    func testAddTabFromContext_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
        navigator.nowAt(NewTabScreen)
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
        mozWaitForElementToExist(app.cells.staticTexts["Example Domain"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354447
    func testSwitchBetweenTabs_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
        // Open two urls from tab tray and switch between them
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.openURL(urlExample)
        waitForTabsButton()
        navigator.goto(TabTray)

        app.cells.staticTexts[urlLabel].firstMatch.waitAndTap()
        guard let valueMozilla = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].value
                as? String else {
            XCTFail("Failed to retrieve the URL value from the Mozilla browser's URL bar")
            return
        }
        XCTAssertEqual(valueMozilla, urlValueLong)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)

        app.cells.staticTexts[urlLabelExample].firstMatch.waitAndTap()
        guard let value = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].value
                as? String else {
            XCTFail("Failed to retrieve the URL value from the Mozilla browser's URL bar")
            return
        }
        XCTAssertEqual(value, urlValueLong)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354449
    func testCloseOneTab_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)

        mozWaitForElementToExist(app.cells.staticTexts[urlLabel])
        // Close the tab using 'x' button
        app.cells.buttons[StandardImageIdentifiers.Large.cross].firstMatch.waitAndTap()

        // After removing only one tab it automatically goes to HomepanelView
        mozWaitForElementToExist(
            app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )
        XCTAssert(app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].exists)
    }

    private func openNtabsFromTabTray(numTabs: Int) {
        for _ in 1...numTabs {
            navigator.performAction(Action.OpenNewTabFromTabTray)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306865
    // Smoketest
    func testCloseAllTabsUndo() {
        app.launch()
        navigator.nowAt(NewTabScreen)
        // A different tab than home is open to do the proper checks
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        if iPad() {
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
            app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
        } else {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        }

        if iPad() {
            navigator.goto(TabTray)
        } else {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)

        app.otherElements.buttons.staticTexts["Undo"].waitAndTap()

        mozWaitForElementToExist(
            app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )
        navigator.nowAt(BrowserTab)
        if !iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        }

        if iPad() {
            navigator.goto(TabTray)
        } else {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)

        mozWaitForElementToExist(app.cells.staticTexts[urlLabel])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354473
    // Smoketest
    func testCloseAllTabsPrivateModeUndo_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
        navigator.goto(URLBarOpen)
        let cancelButton = app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton]
        mozWaitForElementToExist(cancelButton, timeout: TIMEOUT_LONG)
        navigator.back()
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
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

        navigator.goto(URLBarOpen)
        navigator.back()
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
    // Smoketest
    func testCloseAllTabsPrivateModeUndo_tabTrayExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()
        navigator.goto(URLBarOpen)
        let cancelButton = app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton]
        mozWaitForElementToExist(cancelButton, timeout: TIMEOUT_LONG)
        navigator.back()
        // A different tab than home is open to do the proper checks
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
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

        navigator.goto(URLBarOpen)
        navigator.back()
        if iPad() {
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        } else {
            checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        }
        // Close all tabs, undo it and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        mozWaitForElementToExist(app.staticTexts["Private Browsing"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354579
    func testCloseAllTabs_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
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

        // Close all tabs and check that the number of tabs is correct
        navigator.performAction(Action.AcceptRemovingAllTabs)
        if !iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        }
        navigator.nowAt(NewTabScreen)
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        mozWaitForElementToExist(app.cells.staticTexts["Homepage"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2354580
    func testCloseAllTabsPrivateMode_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
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
        mozWaitForElementToExist(app.staticTexts["Private Browsing"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306884
    // Smoketest
    func testOpenNewTabLandscape() {
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        // Verify the '+' icon is shown and open a tab with it
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])

        // Go back to portrait mode
        XCUIDevice.shared.orientation = .portrait
        // Verify that the '+' is displayed
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306838
    // Smoketest
    func testLongTapTabCounter_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
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
        app.cells.staticTexts["Homepage"].firstMatch.waitAndTap()
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
        app.cells.staticTexts["Homepage"].firstMatch.waitAndTap()
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
    // Smoketest
    func testLongTapTabCounter_tabTrayExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()
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
        let identifier = "\(AccessibilityIdentifiers.TabTray.tabCell)_1_0"
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

    // https://mozilla.testrail.io/index.php?/cases/view/2307047
    func testOpenTabsViewCurrentTabThumbnail_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
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
        let navBarTabTray = AccessibilityIdentifiers.TabTray.navBarSegmentedControl
        let navBarTabTrayButton = app.segmentedControls[navBarTabTray].buttons.firstMatch
        mozWaitForElementToExist(navBarTabTrayButton)
        let tabsOpenTabTray: String = navBarTabTrayButton.label
        XCTAssertTrue(tabsOpenTabTray.hasSuffix(numTab!))
        let tabsTrayCell = app.otherElements[tabsTray].cells
        // Go to a tab that is below the fold of the scrollable “Open Tabs” view
        if !iPad() {
            tabsTrayCell.staticTexts.element(boundBy: 3).waitAndTap()
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

    // https://mozilla.testrail.io/index.php?/cases/view/2306869
    func testTabTrayContextMenuCloseTab_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
        // Have multiple tabs opened in the tab tray
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        addTabsAndUndoCloseTabAction(nrOfTabs: 3)
        // Repeat steps for private browsing mode
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        addTabsAndUndoCloseTabAction(nrOfTabs: 4)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306868
    func testTabTrayCloseMultipleTabs_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
        navigator.nowAt(NewTabScreen)
        validateToastWhenClosingMultipleTabs()
        // Choose to undo the action
        app.buttons["Undo"].waitAndTap()
        waitUntilPageLoad()
        // Only the latest tab closed is restored
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        let tabsTrayCell = app.otherElements[tabsTray].cells
        if !iPad() {
            let button = AccessibilityIdentifiers.Toolbar.tabsButton
            let numTab = app.buttons[button].value as? String
            XCTAssertEqual(numTab, "\(tabsTrayCell.count)")
        } else {
            XCTAssertEqual(tabsTrayCell.count, 2)
            XCTAssertTrue(app.buttons.elementContainingText("2").exists)
        }
        mozWaitForElementToExist(app.otherElements.cells.staticTexts[urlLabelExample])
        // Repeat for private browsing mode
        navigator.performAction(Action.TogglePrivateMode)
        validateToastWhenClosingMultipleTabs()
        // Choose to undo the action
        app.buttons["Undo"].waitAndTap()
        // Only the latest tab closed is restored
        if !iPad() {
            let tabsTrayCell = app.otherElements[tabsTray].cells
            XCTAssertEqual(1, tabsTrayCell.count)
        }
        mozWaitForElementToExist(app.otherElements.cells.staticTexts[urlLabelExample])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306867
    func testCloseOneTabUndo_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
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
        if iPad() {
            // Tap "x"
            app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"].buttons[StandardImageIdentifiers.Large.cross].tap()
            mozWaitForElementToNotExist(app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"])
            app.buttons["Undo"].waitAndTap()
            mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"])

            // Long press tab. Tap "Close Tab" from the context menu
            app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"].press(forDuration: 2)
            mozWaitForElementToExist(app.collectionViews.buttons["Close Tab"])
            app.collectionViews.buttons["Close Tab"].waitAndTap()
            mozWaitForElementToNotExist(app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"])
            app.buttons["Undo"].waitAndTap()
            mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"])

            // Swipe tab
            app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"].swipeLeft()
            mozWaitForElementToNotExist(app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"])
            app.buttons["Undo"].waitAndTap()
            mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"])
        } else {
            // Tap "x"
            app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"]
                .buttons[StandardImageIdentifiers.Large.cross].waitAndTap()
            mozWaitForElementToNotExist(app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"])

            // Long press tab. Tap "Close Tab" from the context menu
            app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_1"].press(forDuration: 2)
            mozWaitForElementToExist(app.collectionViews.buttons["Close Tab"])
            app.collectionViews.buttons["Close Tab"].waitAndTap()
            mozWaitForElementToNotExist(app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_2"])

            // Swipe tab
            app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_0"].swipeLeft()
            mozWaitForElementToNotExist(app.cells[AccessibilityIdentifiers.TabTray.tabCell+"_1_0"])
        }
    }

    private func validateToastWhenClosingMultipleTabs() {
        // Have multiple tabs opened in the tab tray
        navigator.openURL(urlExample)
        waitUntilPageLoad()
        for _ in 1...4 {
            navigator.createNewTab()
            if app.keyboards.element.isVisible() && !iPad() {
                mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
                navigator.performAction(Action.CloseURLBarOpen)
            }
        }
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        // Close multiple tabs by pressing X button
        let closeButton = StandardImageIdentifiers.Large.cross
        for _ in 0...3 {
            app.collectionViews.cells["Homepage. Currently selected tab."].buttons[closeButton].waitAndTap()
            // A toast notification is displayed with the message "Tab Closed" and the Undo option
            waitForElementsToExist(
                [
                    app.buttons["Undo"],
                    app.staticTexts["Tab Closed"]
                ]
            )
        }
        app.collectionViews.buttons[closeButton].waitAndTap()
        waitForElementsToExist(
            [
                app.buttons["Undo"],
                app.staticTexts["Tab Closed"]
            ]
        )
    }

    private func addTabsAndUndoCloseTabAction(nrOfTabs: Int) {
        for _ in 1...nrOfTabs {
            navigator.createNewTab()
            if app.keyboards.element.isVisible() && !iPad() {
                mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
                navigator.performAction(Action.CloseURLBarOpen)
            }
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

class TabsTestsIphone: FeatureFlaggedTestBase {
    override func setUp() {
        specificForPlatform = .phone
        if !iPad() {
            super.setUp()
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2355535
    // Smoketest
    func testCloseTabFromLongPressTabsButton_tabTrayExperimentOff() {
        if skipPlatform { return }
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
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

    // https://mozilla.testrail.io/index.php?/cases/view/2355535
    // Smoketest
    func testCloseTabFromLongPressTabsButton_tabTrayExperimentOn() {
        if skipPlatform { return }
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()
        navigator.goto(URLBarOpen)
        navigator.back()
        waitForTabsButton()
        // This menu is available in HomeScreen or NewTabScreen, so no need to open new websites
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
        closeExperimentTabTrayView(goBackToBrowserTab: "Homepage")
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeExperimentTabTrayView(goBackToBrowserTab: "Homepage")
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        closeExperimentTabTrayView(goBackToBrowserTab: "Homepage")
    }

    // This test only runs for iPhone see bug 1409750
    // https://mozilla.testrail.io/index.php?/cases/view/2355536
    // Smoketest
    func testAddTabByLongPressTabsButton() {
        if skipPlatform { return }
        app.launch()
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.goto(URLBarOpen)
        navigator.back()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 2)
    }

    // This test only runs for iPhone see bug 1409750
    // https://mozilla.testrail.io/index.php?/cases/view/2355537
    // Smoketest
    func testAddPrivateTabByLongPressTabsButton_tabTrayExperimentOff() {
        if skipPlatform { return }
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
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

    // This test only runs for iPhone see bug 1409750
    // https://mozilla.testrail.io/index.php?/cases/view/2355537
    // Smoketest
    func testAddPrivateTabByLongPressTabsButton_tabTrayExperimentOn() {
        if skipPlatform { return }
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenPrivateTabLongPressTabsButton)
        navigator.goto(URLBarOpen)
        navigator.back()
        checkNumberOfTabsExpectedToBeOpen(expectedNumberOfTabsOpen: 1)
        let privateIdentifier = "\(AccessibilityIdentifiers.TabTray.selectorCell)0"
        mozWaitForElementToExist(app.buttons[privateIdentifier])
        XCTAssertTrue(app.buttons[privateIdentifier].isEnabled)
        XCTAssertTrue(userState.isPrivate)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    // https://mozilla.testrail.io/index.php?/cases/view/2306861
    // Smoketest
    func testSwitchBetweenTabsToastButton() {
        if skipPlatform { return }
        app.launch()

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

    // This test is disabled for iPad because the toast menu is not shown there
    // https://mozilla.testrail.io/index.php?/cases/view/2306860
    // Smoketest
    func testSwitchBetweenTabsNoPrivatePrivateToastButton_tabTrayExperimentOff() {
        if skipPlatform { return }
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()

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
        XCTAssertTrue(app.buttons["privateModeLarge"].isEnabled)
    }

    // This test is disabled for iPad because the toast menu is not shown there
    // https://mozilla.testrail.io/index.php?/cases/view/2306860
    // Smoketest
    func testSwitchBetweenTabsNoPrivatePrivateToastButton_tabTrayExperimentOn() {
        if skipPlatform { return }
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()

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
