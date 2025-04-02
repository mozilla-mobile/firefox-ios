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

class ActivityStreamTest: BaseTestCase {
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
    }
    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2273342
    // Smoketest
    func testDefaultSites() throws {
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

    // https://mozilla.testrail.io/index.php?/cases/view/2272218
    func testTopSites2Add() {
        if iPad() {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 12)
        } else {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 8)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2272219
    func testTopSitesRemoveAllExceptDefaultClearPrivateData() {
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
            navigator.goto(HomePanelsScreen)
        }
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        mozWaitForElementToNotExist(app.cells.staticTexts[newTopSite["bookmarkLabel"]!])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2272220
    func testTopSitesRemoveAllExceptPinnedClearPrivateData() {
        waitForExistence(TopSiteCellgroup)
        if iPad() {
            app.textFields.element(boundBy: 0).waitAndTap()
            app.typeText("mozilla.org\n")
        } else {
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
        waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
        topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Pin")
        waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!])
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2272514
    func testTopSitesShiftAfterRemovingOne() {
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
    func testTopSitesOpenInNewPrivateTab() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(TopSiteCellgroup, timeout: TIMEOUT_LONG)
        }
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        // Long tap on Wikipedia top site
        waitForExistence(app.collectionViews.links.staticTexts["Wikipedia"])
        app.collectionViews.links.staticTexts["Wikipedia"].press(forDuration: 1)
        app.tables["Context Menu"].cells.otherElements["Open in a Private Tab"].waitAndTap()
        mozWaitForElementToExist(TopSiteCellgroup)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts.element(boundBy: 0))
        navigator.nowAt(TabTray)
        app.otherElements["Tabs Tray"].collectionViews.cells["Wikipedia"].waitAndTap()
        // The website is open
        mozWaitForElementToNotExist(TopSiteCellgroup)
        waitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                             value: "wikipedia.org")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTabDefaultTopSite() {
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
            numTabsOpen = app.otherElements["Tabs Tray"].collectionViews.cells.count
            waitForExistence(app.otherElements["Tabs Tray"].collectionViews.cells.firstMatch)
        } else {
            waitForExistence(app.collectionViews.element(boundBy: 1).cells.firstMatch)
        }
        XCTAssertEqual(numTabsOpen, 1, "New tab not open")
    }

    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        mozWaitForElementToExist(app.links[TopSites.itemCell])
        let numberOfTopSites = app.collectionViews.links.matching(identifier: TopSites.itemCell).count
        mozWaitForElementToExist(app.collectionViews.links.matching(identifier: TopSites.itemCell).firstMatch)
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites, "The number of Top Sites is not correct")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2273339
    func testContextMenuInLandscape() {
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
        waitForExistence(app.links[TopSites.itemCell])
        app.collectionViews.links.element(boundBy: 3).press(forDuration: 1)
        // Verify options given
        let ContextMenuTable = app.tables["Context Menu"]
        waitForElementsToExist(
            [
                ContextMenuTable,
                ContextMenuTable.cells.otherElements["pinLarge"],
                ContextMenuTable.cells.otherElements["plusLarge"],
                ContextMenuTable.cells.otherElements["privateModeLarge"],
                ContextMenuTable.cells.otherElements["crossLarge"]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2855325
    func testSiteCanBeAddedToShortcuts() {
        addWebsiteToShortcut(website: url_3)
        let itemCell = app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        let cell = itemCell.staticTexts["Example Domain"]
        mozWaitForElementToExist(cell)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2861436
    func testShortcutsToggle() {
        //  Go to customize homepage
        navigator.goto(HomeSettings)
        navigator.performAction(Action.SelectShortcuts)
        let shortCutSwitch = app.switches["TopSitesUserPrefsKey"]
        mozWaitForElementToExist(shortCutSwitch)
        let shortCutValue = shortCutSwitch.value!
        // Shortcuts toggle is enabled by default
        XCTAssertEqual(shortCutValue as? String, "1", "The shortcut switch is not on")
        // Access a couple of websites and add them to shortcuts
        navigator.nowAt(Shortcuts)
        navigator.goto(HomeSettings)
        navigator.nowAt(HomeSettings)
        navigator.goto(NewTabScreen)
        addWebsiteToShortcut(website: url_3)
        addWebsiteToShortcut(website: path(forTestPage: url_2["url"]!))
        // The shortcuts are displayed on homepage
        let itemCell = app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        let firstWebsite = itemCell.staticTexts["Example Domain"]
        let secondWebsite = itemCell.staticTexts["Internet for people, not profit — Mozilla"]
        mozWaitForElementToExist(firstWebsite)
        mozWaitForElementToExist(secondWebsite)
        // Go to customize homepage and disable shortcuts toggle
        navigator.goto(HomeSettings)
        navigator.performAction(Action.SelectShortcuts)
        shortCutSwitch.waitAndTap()
        navigator.nowAt(Shortcuts)
        navigator.goto(HomeSettings)
        navigator.nowAt(HomeSettings)
        navigator.goto(BrowserTab)
        // The shortcuts are not displayed anymore on homepage
        mozWaitForElementToNotExist(itemCell)
        mozWaitForElementToNotExist(firstWebsite)
        mozWaitForElementToNotExist(secondWebsite)
    }

    private func addWebsiteToShortcut(website: String) {
        navigator.openURL(website)
        waitUntilPageLoad()
        navigator.goto(BrowserTabMenu)
        navigator.goto(SaveBrowserTabMenu)
        navigator.performAction(Action.PinToTopSitesPAM)
        navigator.performAction(Action.GoToHomePage)
    }
}
