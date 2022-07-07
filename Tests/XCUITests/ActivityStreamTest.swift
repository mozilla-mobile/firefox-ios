// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

let defaultTopSite = ["topSiteLabel": "Wikipedia", "bookmarkLabel": "Wikipedia"]
let newTopSite = ["url": "www.mozilla.org", "topSiteLabel": "mozilla", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
let allDefaultTopSites = ["Facebook", "YouTube", "Amazon", "Wikipedia", "Twitter"]

class ActivityStreamTest: BaseTestCase {
    let TopSiteCellgroup = XCUIApplication().cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]

    let testWithDB = ["testActivityStreamPages", "testTopSites2Add", "testTopSitesOpenInNewPrivateTab", "testContextMenuInLandscape", "testTopSitesRemoveAllExceptDefaultClearPrivateData"]

    // Using the DDDBBs created for these tests containing enough entries for the tests that used them listed above
    let pagesVisitediPad = "browserActivityStreamPagesiPad.db"
    let pagesVisitediPhone = "browserActivityStreamPagesiPhone.db"

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testWithDB.contains(key) {
            // for the current test name, add the db fixture used
            if iPad() {
                launchArguments = [LaunchArguments.SkipIntro,
                                   LaunchArguments.SkipWhatsNew,
                                   LaunchArguments.SkipETPCoverSheet,
                                   LaunchArguments.LoadDatabasePrefix + pagesVisitediPad,
                                   LaunchArguments.SkipContextualHints]
            } else {
                launchArguments = [LaunchArguments.SkipIntro,
                                   LaunchArguments.SkipWhatsNew,
                                   LaunchArguments.SkipETPCoverSheet,
                                   LaunchArguments.LoadDatabasePrefix + pagesVisitediPhone,
                                   LaunchArguments.SkipContextualHints,
                                   LaunchArguments.TurnOffTabGroupsInUserPreferences]
            }
        }
        launchArguments.append(LaunchArguments.SkipAddingGoogleTopSite)
        launchArguments.append(LaunchArguments.SkipSponsoredShortcuts)
        super.setUp()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    // Smoketest
    func testDefaultSites() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(TopSiteCellgroup, timeout: 60)
        }
        XCTAssertTrue(app.collectionViews[AccessibilityIdentifiers.FirefoxHomepage.collectionView].exists)
        // There should be 5 top sites by default
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        // Check their names so that test is added to Smoketest
        XCTAssertTrue(app.collectionViews.cells.staticTexts["Twitter"].exists)
        XCTAssertTrue(app.collectionViews.cells.staticTexts["Amazon"].exists)
        XCTAssertTrue(app.collectionViews.cells.staticTexts["Wikipedia"].exists)
        XCTAssertTrue(app.collectionViews.cells.staticTexts["YouTube"].exists)
        XCTAssertTrue(app.collectionViews.cells.staticTexts["Facebook"].exists)
    }

    func testTopSites2Add() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 10)
        navigator.performAction(Action.CloseURLBarOpen)
        if iPad() {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 12)
        } else {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 8)
        }
    }

    func testTopSites3RemoveDefaultTopSite() {
        app.collectionViews.cells.staticTexts[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Remove and check that now there should be only 4 default top sites
        selectOptionFromContextMenu(option: "Remove")
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 4)
    }

    func testTopSitesRemoveAllExceptDefaultClearPrivateData() {
        waitForExistence(app.cells.staticTexts["Mozilla"], timeout: 15)
        XCTAssertTrue(app.cells.staticTexts["Mozilla"].exists)
        // A new site has been added to the top sites
        if iPad() {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 12)
        } else {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 8)
        }

        waitForExistence(app.buttons["urlBar-cancel"])
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(BrowserTab)
        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        if iPad() {
            navigator.goto(NewTabScreen)
        } else {
            navigator.goto(HomePanelsScreen)
        }
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        XCTAssertFalse(app.cells.staticTexts["Mozilla"].exists)
    }

    func testTopSitesRemoveAllExceptPinnedClearPrivateData() {
        waitForExistence(TopSiteCellgroup, timeout: 10)
        if iPad() {
            navigator.performAction(Action.CloseURLBarOpen)
            app.textFields.element(boundBy: 0).tap()
            app.typeText("mozilla.org\n")
        } else {
            navigator.openURL("mozilla.org")
        }
        waitUntilPageLoad()

        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].tap()
        app.otherElements[ImageIdentifiers.addShortcut].tap()
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        waitForExistence(app.collectionViews.cells.staticTexts[newTopSite["bookmarkLabel"]!])
        XCTAssertTrue(app.collectionViews.cells.staticTexts[newTopSite["bookmarkLabel"]!].exists)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        waitForExistence(app.collectionViews.cells.staticTexts[newTopSite["bookmarkLabel"]!])
        XCTAssertTrue(app.collectionViews.cells.staticTexts[newTopSite["bookmarkLabel"]!].exists)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    func testTopSitesShiftAfterRemovingOne() {
        // Check top site in first and second cell
        let topSiteFirstCell = app.collectionViews.cells.element(boundBy: 1).label
        let topSiteSecondCell = app.collectionViews.cells.element(boundBy: 2).label

        XCTAssertTrue(topSiteFirstCell == allDefaultTopSites[0])
        XCTAssertTrue(topSiteSecondCell == allDefaultTopSites[1])

        // Remove facebook top sites, first cell
        waitForExistence(app.collectionViews.cells.element(boundBy: 1), timeout: 3)
        app.collectionViews.cells.element(boundBy: 1).press(forDuration: 1)
        selectOptionFromContextMenu(option: "Remove")

        // Check top site in first cell now
        waitForExistence(app.collectionViews.cells.element(boundBy: 1))
        let topSiteCells = app.collectionViews.cells.staticTexts
        let topSiteFirstCellAfter = app.collectionViews.cells.element(boundBy: 1).label
        XCTAssertTrue(topSiteFirstCellAfter == topSiteCells[allDefaultTopSites[1]].label, "First top site does not match")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTab() throws {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 35)
        }
        navigator.performAction(Action.CloseURLBarOpen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 5)
        // Long tap on apple top site, second cell
        waitForExistence(app.collectionViews.cells.staticTexts["Apple"], timeout: 3)
        app.collectionViews.cells.staticTexts["Apple"].press(forDuration: 1)
        app.tables["Context Menu"].cells.otherElements["Open in a Private Tab"].tap()

        XCTAssert(TopSiteCellgroup.exists)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts.element(boundBy: 0), timeout: 10)

        navigator.nowAt(TabTray)
        if iPad() {
            waitForExistence(app.collectionViews.element(boundBy: 1).cells.staticTexts["Apple"], timeout: 15)
            app/*@START_MENU_TOKEN@*/.otherElements["Tabs Tray"].collectionViews/*[[".otherElements[\"Tabs Tray\"].collectionViews",".collectionViews"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.cells["Apple"].tap()

        } else {
            waitForExistence(app.collectionViews.cells.staticTexts["Apple"], timeout: 5)
            app.collectionViews.element(boundBy: 1).cells.staticTexts["Apple"].tap()
        }

        // The website is open
        XCTAssertFalse(TopSiteCellgroup.exists)
        XCTAssertTrue(app.textFields["url"].exists)
        waitForValueContains(app.textFields["url"], value: "apple.com")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTabDefaultTopSite() {
        XCTExpectFailure("The app was not launched", strict: false) {
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 35)
        }
        navigator.performAction(Action.CloseURLBarOpen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 5)
        navigator.nowAt(NewTabScreen)
        // Open one of the sites from Topsites and wait until page is loaded
        // Long tap on apple top site, second cell
        waitForExistence(app.collectionViews.cells.element(boundBy: 4), timeout: 3)
        app.collectionViews.cells.element(boundBy: 4).press(forDuration: 1)
        selectOptionFromContextMenu(option: "Open in a Private Tab")

        // Check that two tabs are open and one of them is the default top site one
        // Workaroud needed after xcode 11.3 update Issue 5937
        sleep(3)
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        waitForExistence(app.cells.staticTexts[defaultTopSite["bookmarkLabel"]!])
        var numTabsOpen = app.collectionViews.element(boundBy: 1).cells.count
        if iPad() {
            navigator.goto(TabTray)
            numTabsOpen = app/*@START_MENU_TOKEN@*/.otherElements["Tabs Tray"].collectionViews/*[[".otherElements[\"Tabs Tray\"].collectionViews",".collectionViews"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.cells.count
        }
        XCTAssertEqual(numTabsOpen, 1, "New tab not open")
    }

    private func selectOptionFromContextMenu(option: String) {
        XCTAssertTrue(app.tables["Context Menu"].cells.otherElements[option].exists)
        app.tables["Context Menu"].cells.otherElements[option].tap()
    }

    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        waitForExistence(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        XCTAssertTrue(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].exists)
        let numberOfTopSites = app.collectionViews.cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell).count

        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites, "The number of Top Sites is not correct")
    }

    func testContextMenuInLandscape() {
        // For iPhone test is failing to find top sites in landscape
        // can't scroll only to that area. Needs investigation
        if iPad() {
            XCUIDevice.shared.orientation = .landscapeLeft
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
            navigator.performAction(Action.CloseURLBarOpen)

            waitForExistence(TopSiteCellgroup.cells["Apple"], timeout: 5)
            TopSiteCellgroup.cells["Apple"].press(forDuration: 1)

            let contextMenuHeight = app.tables["Context Menu"].frame.size.height
            let parentViewHeight = app.otherElements["Action Sheet"].frame.size.height

            XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)

            // Go back to portrait mode
            XCUIDevice.shared.orientation = .portrait
        }
    }
}
