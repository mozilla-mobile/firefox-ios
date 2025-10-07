// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared

let defaultTopSite = ["topSiteLabel": "Wikipedia", "bookmarkLabel": "Wikipedia"]
let newTopSite = [
    "url": "www.mozilla.org",
    "topSiteLabel": "Mozilla",
    "bookmarkLabel": "Mozilla - Internet for people, not profit (US)"
]
let allDefaultTopSites = ["Facebook", "YouTube", "Amazon", "Wikipedia", "X"]
let tabsTray = AccessibilityIdentifiers.TabTray.tabsTray

class ActivityStreamTest: FeatureFlaggedTestBase {
    private var topSites: TopSitesScreen!
    private var contextMenu: ContextMenuScreen!
    private var tabTray: TabTrayScreen!
    private var browser: BrowserScreen!
    private var toolbar: ToolbarScreen!

    typealias TopSites = AccessibilityIdentifiers.FirefoxHomepage.TopSites
    let TopSiteCellgroup = XCUIApplication().links[TopSites.itemCell]
    let testWithDB = ["testTopSites2Add", "testTopSitesRemoveAllExceptDefaultClearPrivateData"]
    // Using the DDDBBs created for these tests containing enough entries for the tests that used them listed above
    let pagesVisited = "browserActivityStreamPages-places.db"
    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testWithDB.contains(key) {
            launchArguments = [LaunchArguments.SkipIntro,
                               LaunchArguments.SkipWhatsNew,
                               LaunchArguments.SkipETPCoverSheet,
                               LaunchArguments.LoadDatabasePrefix + pagesVisited,
                               LaunchArguments.SkipContextualHints,
                               LaunchArguments.DisableAnimations]
        }
        launchArguments.append(LaunchArguments.SkipAddingGoogleTopSite)
        launchArguments.append(LaunchArguments.SkipSponsoredShortcuts)
        super.setUp()
        topSites = TopSitesScreen(app: app)
        contextMenu = ContextMenuScreen(app: app)
        tabTray = TabTrayScreen(app: app)
        browser = BrowserScreen(app: app)
        toolbar = ToolbarScreen(app: app)
    }
    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2273342
    // Smoketest
    func testDefaultSites() throws {
        app.launch()
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(TopSiteCellgroup, timeout: TIMEOUT_LONG)
        }
        mozWaitForElementToExist(app.collectionViews[AccessibilityIdentifiers.FirefoxHomepage.collectionView])
        // There should be 5 top sites by default
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        // Check their names so that test is added to Smoketest
        waitForElementsToExist(
            [
                app.collectionViews.links.staticTexts["X"],
                app.collectionViews.links.staticTexts["Amazon"],
                app.collectionViews.links.staticTexts["Wikipedia"],
                app.collectionViews.links.staticTexts["YouTube"],
                app.collectionViews.links.staticTexts["Facebook"]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2273342
    // Smoketest TAE
    func testDefaultSites_TAE() throws {
        app.launch()

        XCTExpectFailure("The app was not launched", strict: false) {
            topSites.assertVisible()
        }

        topSites.assertVisible()
        topSites.assertTopSitesCount(5)
        topSites.assertDefaultTopSites()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2272218
    func testTopSites2Add() {
        app.launch()
        if iPad() {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 12)
        } else {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 8)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2272219
    func testTopSitesRemoveAllExceptDefaultClearPrivateData() {
        app.launch()
        waitForExistence(app.links.staticTexts["Internet for people, not profit — Mozilla (US)"], timeout: TIMEOUT_LONG)
        // A new site has been added to the top sites
        if iPad() {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 12)
        } else {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 8)
        }
        navigator.nowAt(BrowserTab)
        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        if iPad() {
            navigator.goto(NewTabScreen)
        } else {
            navigator.nowAt(ClearPrivateDataSettings)
            navigator.goto(BrowserTab)
        }
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        mozWaitForElementToNotExist(app.cells.staticTexts[newTopSite["bookmarkLabel"]!])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2272220
    func testTopSitesRemoveAllExceptPinnedClearPrivateData_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()

        waitForExistence(TopSiteCellgroup)
        if iPad() {
            app.textFields.element(boundBy: 0).waitAndTap()
            app.typeText("mozilla.org\n")
        } else {
            navigator.nowAt(HomePanelsScreen)
            navigator.goto(URLBarOpen)
            navigator.openURL("mozilla.org")
        }
        waitUntilPageLoad()
        // navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.goto(TabTray)
        app.cells.buttons[StandardImageIdentifiers.Large.cross].firstMatch.waitAndTap()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        let topSitesCells = app.collectionViews.links["TopSitesCell"]
        if #available(iOS 16, *) {
            waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        } else {
            waitForExistence(topSitesCells.staticTexts["Mozilla — Internet for people, not profit"], timeout: TIMEOUT_LONG)
        }
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
        if #available(iOS 16, *) {
            topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!].press(forDuration: 1)
        } else {
            topSitesCells.staticTexts["Mozilla — Internet for people, not profit"].press(forDuration: 1)
        }
        selectOptionFromContextMenu(option: "Pin")
        if #available(iOS 16, *) {
            waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        } else {
            waitForExistence(topSitesCells.staticTexts["Mozilla — Internet for people, not profit"], timeout: TIMEOUT_LONG)
        }
        waitForExistence(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        if #available(iOS 16, *) {
            waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        } else {
            waitForExistence(topSitesCells.staticTexts["Mozilla — Internet for people, not profit"], timeout: TIMEOUT_LONG)
        }
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2272220
    func testTopSitesRemoveAllExceptPinnedClearPrivateData_tabTrayExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()

        waitForExistence(TopSiteCellgroup)
        if iPad() {
            app.textFields.element(boundBy: 0).waitAndTap()
            app.typeText("mozilla.org\n")
        } else {
            navigator.nowAt(HomePanelsScreen)
            navigator.goto(URLBarOpen)
            navigator.openURL("mozilla.org")
        }
        waitUntilPageLoad()
        // navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.goto(TabTray)
        if iPad() {
            app.cells.buttons[StandardImageIdentifiers.Large.cross].firstMatch.waitAndTap()
        } else {
            app.cells.buttons[AccessibilityIdentifiers.TabTray.closeButton].firstMatch.waitAndTap()
        }
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        let topSitesCells = app.collectionViews.links["TopSitesCell"]
        if #available(iOS 16, *) {
            waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        } else {
            waitForExistence(topSitesCells.staticTexts["Mozilla — Internet for people, not profit"], timeout: TIMEOUT_LONG)
        }
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
        if #available(iOS 16, *) {
            topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!].press(forDuration: 1)
        } else {
            topSitesCells.staticTexts["Mozilla — Internet for people, not profit"].press(forDuration: 1)
        }

        selectOptionFromContextMenu(option: "Pin")
        if #available(iOS 16, *) {
            waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        } else {
            waitForExistence(topSitesCells.staticTexts["Mozilla — Internet for people, not profit"], timeout: TIMEOUT_LONG)
        }
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        if #available(iOS 16, *) {
            waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        } else {
            waitForExistence(topSitesCells.staticTexts["Mozilla — Internet for people, not profit"], timeout: TIMEOUT_LONG)
        }
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2272514
    func testTopSitesShiftAfterRemovingOne() {
        app.launch()
        // Check top site in first and second cell
        let allTopSites = app.collectionViews.links.matching(identifier: "TopSitesCell")
        let topSiteFirstCell = allTopSites.element(boundBy: 0).label
        let topSiteSecondCell = allTopSites.element(boundBy: 1).label
        mozWaitForElementToExist(allTopSites.firstMatch)
        XCTAssertTrue(topSiteFirstCell == allDefaultTopSites[0])
        XCTAssertTrue(topSiteSecondCell == allDefaultTopSites[1])
        // Remove facebook top sites, first cell
        waitForExistence(allTopSites.element(boundBy: 0))
        allTopSites.element(boundBy: 0).press(forDuration: 1)
        selectOptionFromContextMenu(option: "Remove")
        if #unavailable(iOS 16) {
            mozWaitForElementToNotExist(app.staticTexts[topSiteFirstCell])
        }
        mozWaitForElementToExist(allTopSites.staticTexts[topSiteSecondCell])
        mozWaitForElementToNotExist(allTopSites.staticTexts[topSiteFirstCell])
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 4)
        // Check top site in first cell now
        let updatedAllTopSites = app.collectionViews.links.matching(identifier: "TopSitesCell")
        waitForExistence(updatedAllTopSites.element(boundBy: 0))
        let topSiteCells = updatedAllTopSites.staticTexts
        let topSiteFirstCellAfter = updatedAllTopSites.element(boundBy: 0).label
        mozWaitForElementToExist(updatedAllTopSites.element(boundBy: 0))
        XCTAssertTrue(
            topSiteFirstCellAfter == topSiteCells[allDefaultTopSites[1]].label,
            "First top site does not match"
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2273338
    // Smoketest
    func testTopSitesOpenInNewPrivateTab_tabTrayExperimentOff_swipingTabsExperimentOff() throws {
        addLaunchArgument(jsonFileName: "swipingTabsOff", featureName: "toolbar-refactor-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(TopSiteCellgroup, timeout: TIMEOUT_LONG)
        }
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        // Long tap on Wikipedia top site
        waitForExistence(app.collectionViews.links.staticTexts["Wikipedia"])
        app.collectionViews.links.staticTexts["Wikipedia"].press(forDuration: 1)
        app.tables["Context Menu"].cells.buttons["Open in a Private Tab"].waitAndTap()
        mozWaitForElementToExist(TopSiteCellgroup)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts.element(boundBy: 0))
        navigator.nowAt(TabTray)
        app.otherElements[tabsTray].collectionViews.cells["Wikipedia"].waitAndTap()
        // The website is open
        mozWaitForElementToNotExist(TopSiteCellgroup)
        waitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                             value: "wikipedia.org")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2273338
    // Smoketest TAE
    func testTopSitesOpenInNewPrivateTab_tabTrayExperimentOff_swipingTabsExperimentOff_TAE() throws {
        addLaunchArgument(jsonFileName: "swipingTabsOff", featureName: "toolbar-refactor-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()

        XCTExpectFailure("The app was not launched", strict: false) {
            topSites.assertVisible()
        }

        // Wait the Toolbar loading
        toolbar.assertSettingsButtonExists()

        // Long tap en Wikipedia
        topSites.longPressOnSite(named: "Wikipedia")

        // Context menu → Open in Private Tab
        contextMenu.openInPrivateTab()

        topSites.assertVisible()

        // Activate private mode
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)

        // Validate the first cell and open Wikipedia
        tabTray.assertFirstCellVisible()
        navigator.nowAt(TabTray)
        tabTray.tapOnCell(named: "Wikipedia")

        topSites.assertNotVisibleTopSites()
        browser.assertAddressBarContains(value: "wikipedia.org")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2273338
    // Smoketest
    func testTopSitesOpenInNewPrivateTab_tabTrayToolbarOnHomepageOff() throws {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "toolbar-refactor-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        addLaunchArgument(jsonFileName: "homepageSearchBarOff", featureName: "homepage-redesign-feature")
        addLaunchArgument(jsonFileName: "storiesRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(TopSiteCellgroup, timeout: TIMEOUT_LONG)
        }
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        // Long tap on Wikipedia top site
        waitForExistence(app.collectionViews.links.staticTexts["Wikipedia"])
        app.collectionViews.links.staticTexts["Wikipedia"].press(forDuration: 1)
        app.tables["Context Menu"].cells.buttons["Open in a Private Tab"].waitAndTap()
        mozWaitForElementToExist(TopSiteCellgroup)
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts.element(boundBy: 0))
        navigator.nowAt(TabTray)
        XCTAssertFalse(
            app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].isHittable,
            "TopSitesCell should not be visible or interactable on the current screen"
        )
        app.otherElements[tabsTray].collectionViews.cells["Wikipedia"].waitAndTap()
        // The website is open
        waitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                             value: "wikipedia.org")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2273338
    // Smoketest TAE
    func testTopSitesOpenInNewPrivateTab_tabTrayToolbarOnHomepageOff_TAE() throws {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "toolbar-refactor-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        addLaunchArgument(jsonFileName: "homepageSearchBarOff", featureName: "homepage-redesign-feature")
        addLaunchArgument(jsonFileName: "storiesRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()

        // Assert that the Top Sites are visible upon launch
        XCTExpectFailure("The app was not launched", strict: false) {
            topSites.assertVisible()
        }

        // Wait for the toolbar to exist, which includes the settings menu button
        toolbar.assertSettingsButtonExists()

        // Long press on the Wikipedia top site using the screen object
        topSites.longPressOnSite(named: "Wikipedia")

        // Open the private tab using the context menu screen object
        contextMenu.openInPrivateTab()

        // Assert the homepage is visible again after the context menu action
        topSites.assertVisible()

        // Toggle private mode and navigate to the Tab Tray
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.goto(TabTray)

        // Assert that the first cell in the Tab Tray is visible and that the navigator is now at the Tab Tray
        tabTray.assertFirstCellVisible()
        navigator.nowAt(TabTray)

        // Use the new method from the TopSitesScreen object to check the hittable status
        topSites.assertNotHittable()

        // Tap on the Wikipedia cell in the Tab Tray and ensure the website is open
        tabTray.tapOnCell(named: "Wikipedia")

        // Use the new BrowserScreen to validate the URL in the address bar
        browser.assertAddressBarContains(value: "wikipedia.org")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTabDefaultTopSite_tabTrayExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()

        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(TopSiteCellgroup, timeout: TIMEOUT_LONG)
        }
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        navigator.nowAt(NewTabScreen)
        // Open one of the sites from Topsites and wait until page is loaded
        // Long tap on apple top site, second cell
        mozWaitForElementToExist(app.collectionViews["FxCollectionView"].links[defaultTopSite["bookmarkLabel"]!])
        app.collectionViews["FxCollectionView"].links[defaultTopSite["bookmarkLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Open in a Private Tab")
        // Check that two tabs are open and one of them is the default top site one
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        waitForExistence(app.staticTexts[defaultTopSite["bookmarkLabel"]!])
        if iPad() {
            navigator.goto(TabTray)
        }
        waitForExistence(app.otherElements[tabsTray].collectionViews.cells.firstMatch)
        let numTabsOpen = app.otherElements[tabsTray].collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 1, "New tab not open")
    }

    // SmokeTest TAE
    func testTopSitesOpenInNewPrivateTabDefaultTopSite_tabTrayExperimentOn_TAE() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()

        XCTExpectFailure("The app was not launched", strict: false) {
            topSites.assertVisible()
        }

        toolbar.assertSettingsButtonExists()
        navigator.nowAt(NewTabScreen)

        // Long tap on the default Top Site
        let siteName = defaultTopSite["bookmarkLabel"]!
        topSites.longPressOnSite(named: siteName)

        contextMenu.openInPrivateTab()

        navigator.nowAt(HomePanelsScreen)
        BaseTestCase().waitForTabsButton()

        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)

        tabTray.assertCellExists(named: siteName)

        if iPad() {
            navigator.goto(TabTray)
        }

        tabTray.assertFirstCellVisible()

        tabTray.assertTabCount(1)
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTabDefaultTopSite_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()

        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(TopSiteCellgroup, timeout: TIMEOUT_LONG)
        }
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        navigator.nowAt(NewTabScreen)
        // Open one of the sites from Topsites and wait until page is loaded
        // Long tap on apple top site, second cell
        mozWaitForElementToExist(app.collectionViews["FxCollectionView"].links[defaultTopSite["bookmarkLabel"]!])
        app.collectionViews["FxCollectionView"].links[defaultTopSite["bookmarkLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Open in a Private Tab")
        // Check that two tabs are open and one of them is the default top site one
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        waitForExistence(app.cells.staticTexts[defaultTopSite["bookmarkLabel"]!])
        var numTabsOpen = app.collectionViews.element(boundBy: 1).cells.count
        if iPad() {
            navigator.goto(TabTray)
            numTabsOpen = app.otherElements[tabsTray].collectionViews.cells.count
            waitForExistence(app.otherElements[tabsTray].collectionViews.cells.firstMatch)
        } else {
            waitForExistence(app.collectionViews.element(boundBy: 1).cells.firstMatch)
        }
        XCTAssertEqual(numTabsOpen, 1, "New tab not open")
    }

    // SmokeTest TAE
    func testTopSitesOpenInNewPrivateTabDefaultTopSite_tabTrayExperimentOff_TAE() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()

        XCTExpectFailure("The app was not launched", strict: false) {
            topSites.assertVisible()
        }

        toolbar.assertSettingsButtonExists()
        navigator.nowAt(NewTabScreen)

        // Long-press a default top site using the screen object
        let siteName = defaultTopSite["bookmarkLabel"]!
        topSites.longPressOnSite(named: siteName)

        // Select the context menu option
        contextMenu.openInPrivateTab()

        navigator.nowAt(HomePanelsScreen)
        BaseTestCase().waitForTabsButton()

        // Toggle private mode
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        // Assert that the new tab exists in the tab tray
        tabTray.assertCellExists(named: siteName)

        if iPad() {
            navigator.goto(TabTray)
            tabTray.assertFirstCellVisible()
            tabTray.assertTabCount(1)
        } else {
            // Assert the number of open tabs on iPhone, assuming a different tab UI
            tabTray.assertiPhoneTabCount(1)
        }
    }

    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        mozWaitForElementToExist(app.links[TopSites.itemCell])
        let numberOfTopSites = app.collectionViews.links.matching(identifier: TopSites.itemCell).count
        mozWaitForElementToExist(app.collectionViews.links.matching(identifier: TopSites.itemCell).firstMatch)
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites, "The number of Top Sites is not correct")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2273339
    func testContextMenuInLandscape() {
        app.launch()
        // For iPhone test is failing to find top sites in landscape
        // can't scroll only to that area. Needs investigation
        if iPad() {
            XCUIDevice.shared.orientation = .landscapeLeft
            waitForExistence(TopSiteCellgroup)
            app.collectionViews.links.staticTexts["Wikipedia"].press(forDuration: 1)
            waitForElementsToExist(
                [
                    app.tables["Context Menu"],
                    app.otherElements["Action Sheet"]
                ]
            )
            let contextMenuHeight = app.tables["Context Menu"].frame.size.height
            let parentViewHeight = app.otherElements["Action Sheet"].frame.size.height
            XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)
            // Go back to portrait mode
            XCUIDevice.shared.orientation = .portrait
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2436086
    func testLongTapOnTopSiteOptions() {
        app.launch()
        waitForExistence(app.links[TopSites.itemCell])
        app.collectionViews.links.element(boundBy: 3).press(forDuration: 1)
        // Verify options given
        let contextMenuTable = app.tables["Context Menu"]
        waitForElementsToExist(
            [
                contextMenuTable,
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.pin],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.plus],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.privateMode],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.cross]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2855325
    func testSiteCanBeAddedToShortcuts() {
        app.launch()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        addWebsiteToShortcut(website: url_3)
        let itemCell = app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        let cell = itemCell.staticTexts["Example Domain"]
        mozWaitForElementToExist(cell)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2861436
    func testShortcutsToggle() {
        app.launch()
        XCTExpectFailure("The app was not launched", strict: false) {
            mozWaitForElementToExist(TopSiteCellgroup, timeout: TIMEOUT_LONG)
        }
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        //  Go to customize homepage
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        navigator.performAction(Action.SelectShortcuts)
        let shortCutSwitch = app.switches["TopSitesUserPrefsKey"]
        mozWaitForElementToExist(shortCutSwitch)
        // Shortcuts toggle is enabled by default
        XCTAssertEqual(shortCutSwitch.value as? String, "1", "The shortcut switch is not on")
        // Access a couple of websites and add them to shortcuts
        navigator.nowAt(Shortcuts)
        navigator.goto(HomeSettings)
        navigator.nowAt(HomeSettings)
        navigator.goto(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        addWebsiteToShortcut(website: url_3)
        addWebsiteToShortcut(website: path(forTestPage: url_2["url"]!))
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()

        // Verify shortcuts are displayed on the homepage
        let itemCell = app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        let firstWebsite = itemCell.staticTexts["Example Domain"]
        let secondWebsite = itemCell.staticTexts["Internet for people, not profit — Mozilla"]
        mozWaitForElementToExist(firstWebsite)
        mozWaitForElementToExist(secondWebsite)

        // Disable shortcuts toggle
        navigator.goto(HomeSettings)
        navigator.performAction(Action.SelectShortcuts)
        shortCutSwitch.waitAndTap()

        // Verify shortcuts are not displayed on the homepage
        navigator.nowAt(Shortcuts)
        navigator.goto(HomeSettings)
        navigator.nowAt(HomeSettings)
        navigator.goto(BrowserTab)
        mozWaitForElementToNotExist(itemCell)
        mozWaitForElementToNotExist(firstWebsite)
        mozWaitForElementToNotExist(secondWebsite)
    }

    private func addWebsiteToShortcut(website: String) {
        navigator.openURL(website)
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        // navigator.goto(SaveBrowserTabMenu)
        navigator.performAction(Action.PinToTopSitesPAM)
        navigator.performAction(Action.GoToHomePage)
    }
}
