// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

let defaultTopSite = ["topSiteLabel": "Wikipedia", "bookmarkLabel": "Wikipedia"]
let newTopSite = [
    "url": "www.mozilla.org",
    "topSiteLabel": "Mozilla",
    "bookmarkLabel": "Internet for people, not profit — Mozilla (US)"
]
let newTopSiteiOS15 = [
    "bookmarkLabel": "Internet for people, not profit"
]
let allDefaultTopSites = ["Facebook", "YouTube", "Amazon", "Wikipedia", "X"]

class ActivityStreamTest: BaseTestCase {
    typealias TopSites = AccessibilityIdentifiers.FirefoxHomepage.TopSites
    let TopSiteCellgroup = XCUIApplication().cells[TopSites.itemCell]

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
        mozWaitForElementToExist(app.collectionViews.cells.staticTexts["X"])
        mozWaitForElementToExist(app.collectionViews.cells.staticTexts["Amazon"])
        mozWaitForElementToExist(app.collectionViews.cells.staticTexts["Wikipedia"])
        mozWaitForElementToExist(app.collectionViews.cells.staticTexts["YouTube"])
        mozWaitForElementToExist(app.collectionViews.cells.staticTexts["Facebook"])
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
        waitForExistence(app.cells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
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
            app.textFields.element(boundBy: 0).tap()
            app.typeText("mozilla.org\n")
        } else {
            navigator.openURL("mozilla.org")
        }
        waitUntilPageLoad()

        // navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.goto(TabTray)
        app.collectionViews.buttons["crossLarge"].waitAndTap()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        let topSitesCells = app.collectionViews.cells["TopSitesCell"]
        if #available(iOS 16, *) {
            waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        } else {
            waitForExistence(topSitesCells.staticTexts[newTopSiteiOS15["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        }
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        if #available(iOS 16, *) {
            topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!].press(forDuration: 1)
        } else {
            topSitesCells.staticTexts[newTopSiteiOS15["bookmarkLabel"]!].press(forDuration: 1)
        }
        selectOptionFromContextMenu(option: "Pin")
        if #available(iOS 16, *) {
            waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        } else {
            waitForExistence(topSitesCells.staticTexts[newTopSiteiOS15["bookmarkLabel"]!], timeout: TIMEOUT_LONG)
        }

        waitForExistence(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        if #available(iOS 16, *) {
            waitForExistence(topSitesCells.staticTexts[newTopSite["bookmarkLabel"]!])
        } else {
            waitForExistence(topSitesCells.staticTexts[newTopSiteiOS15["bookmarkLabel"]!])
        }
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2272514
    func testTopSitesShiftAfterRemovingOne() {
        // Check top site in first and second cell
        let allTopSites = app.collectionViews.cells.matching(identifier: "TopSitesCell")
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
        let updatedAllTopSites = app.collectionViews.cells.matching(identifier: "TopSitesCell")
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
        waitForExistence(app.collectionViews.cells.staticTexts["Wikipedia"])
        app.collectionViews.cells.staticTexts["Wikipedia"].press(forDuration: 1)
        app.tables["Context Menu"].cells.otherElements["Open in a Private Tab"].waitAndTap()

        mozWaitForElementToExist(TopSiteCellgroup)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts.element(boundBy: 0))

        navigator.nowAt(TabTray)
        waitForExistence(app.otherElements["Tabs Tray"].collectionViews.cells["Wikipedia"])
        app.otherElements["Tabs Tray"].collectionViews.cells["Wikipedia"].tap()

        // The website is open
        mozWaitForElementToNotExist(TopSiteCellgroup)
        waitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url], value: "wikipedia.org")
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
        waitForExistence(app.collectionViews["FxCollectionView"].cells
            .staticTexts[defaultTopSite["bookmarkLabel"]!])
        app.collectionViews["FxCollectionView"].cells.staticTexts[defaultTopSite["bookmarkLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Open in a Private Tab")

        // Check that two tabs are open and one of them is the default top site one
        // Workaround needed after xcode 11.3 update Issue 5937
        sleep(3)
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
        mozWaitForElementToExist(app.cells[TopSites.itemCell])
        let numberOfTopSites = app.collectionViews.cells.matching(identifier: TopSites.itemCell).count
        mozWaitForElementToExist(app.collectionViews.cells.matching(identifier: TopSites.itemCell).firstMatch)
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites, "The number of Top Sites is not correct")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2273339
    func testContextMenuInLandscape() {
        // For iPhone test is failing to find top sites in landscape
        // can't scroll only to that area. Needs investigation
        if iPad() {
            XCUIDevice.shared.orientation = .landscapeLeft
            waitForExistence(TopSiteCellgroup)
            app.collectionViews.cells.staticTexts["Wikipedia"].press(forDuration: 1)
            mozWaitForElementToExist(app.tables["Context Menu"])
            mozWaitForElementToExist(app.otherElements["Action Sheet"])

            let contextMenuHeight = app.tables["Context Menu"].frame.size.height
            let parentViewHeight = app.otherElements["Action Sheet"].frame.size.height

            XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)

            // Go back to portrait mode
            XCUIDevice.shared.orientation = .portrait
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2436086
    func testLongTapOnTopSiteOptions() {
        waitForExistence(app.cells[TopSites.itemCell])
        app.collectionViews.cells.element(boundBy: 3).press(forDuration: 1)
        // Verify options given
        let ContextMenuTable = app.tables["Context Menu"]
        mozWaitForElementToExist(ContextMenuTable)
        mozWaitForElementToExist(ContextMenuTable.cells.otherElements["pinLarge"])
        mozWaitForElementToExist(ContextMenuTable.cells.otherElements["plusLarge"])
        mozWaitForElementToExist(ContextMenuTable.cells.otherElements["privateModeLarge"])
        mozWaitForElementToExist(ContextMenuTable.cells.otherElements["crossLarge"])
    }
}
