// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

let defaultTopSite = ["topSiteLabel": "wikipedia", "bookmarkLabel": "Wikipedia"]
let newTopSite = ["url": "www.mozilla.org", "topSiteLabel": "mozilla", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
let allDefaultTopSites = ["facebook", "youtube", "amazon", "wikipedia", "twitter"]

class ActivityStreamTest: BaseTestCase {
    let TopSiteCellgroup = XCUIApplication().cells["TopSitesCell"]

    let testWithDB = ["testActivityStreamPages","testTopSites2Add", "testTopSites4OpenInNewTab", "testTopSitesOpenInNewPrivateTab", "testTopSitesBookmarkNewTopSite", "testTopSitesShareNewTopSite", "testContextMenuInLandscape"]

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
                launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet, LaunchArguments.LoadDatabasePrefix + pagesVisitediPad, LaunchArguments.SkipContextualHintJumpBackIn]
            } else {
                launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet, LaunchArguments.LoadDatabasePrefix + pagesVisitediPhone, LaunchArguments.SkipContextualHintJumpBackIn]
            }
        }
        launchArguments.append(LaunchArguments.SkipAddingGoogleTopSite)
        super.setUp()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    // Smoketest
    func testDefaultSites() {
        waitForExistence(TopSiteCellgroup, timeout: 10)
        // There should be 5 top sites by default
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        // Check their names so that test is added to Smoketest
        XCTAssertTrue(TopSiteCellgroup.cells["twitter"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["amazon"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["wikipedia"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["youtube"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["facebook"].exists)
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
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Remove and check that now there should be only 4 default top sites
        selectOptionFromContextMenu(option: "Remove")
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 4)
    }

    // Disabled due to issue #7611
    /*func testTopSitesRemoveAllExceptDefaultClearPrivateData() {
        navigator.goto(BrowserTab)
        waitForTabsButton()
        navigator.goto(TabTray)
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        waitForExistence(app.cells.staticTexts["mozilla"])
        XCTAssertTrue(app.cells.staticTexts["mozilla"].exists)
        // A new site has been added to the top sites
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        XCTAssertFalse(app.cells.staticTexts["mozilla"].exists)
    }*/

    func testTopSitesRemoveAllExceptPinnedClearPrivateData() {
        waitForExistence(app.cells["TopSitesCell"].cells.element(boundBy: 0), timeout: 10)
        if iPad() {
            navigator.performAction(Action.CloseURLBarOpen)
            app.textFields.element(boundBy: 0).tap()
            app.typeText("mozilla.org\n")
        } else {
            navigator.openURL("mozilla.org")
        }
        waitUntilPageLoad()
        
//        navigator.performAction(Action.PinToTopSitesPAM)
        app.buttons["TabLocationView.pageOptionsButton"].tap()
        app.cells["action_pin"].tap()
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        waitForExistence(app.collectionViews.cells[newTopSite["topSiteLabel"]!])
        XCTAssertTrue(app.collectionViews.cells[newTopSite["topSiteLabel"]!].exists)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        waitForExistence(app.collectionViews.cells[newTopSite["topSiteLabel"]!])
        XCTAssertTrue(app.collectionViews.cells[newTopSite["topSiteLabel"]!].exists)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    func testTopSitesShiftAfterRemovingOne() {
        // Check top site in first and second cell
        let topSiteFirstCell = app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        let topSiteSecondCell = app.collectionViews.cells.collectionViews.cells.element(boundBy: 1).label

        XCTAssertTrue(topSiteFirstCell == allDefaultTopSites[0])
        XCTAssertTrue(topSiteSecondCell == allDefaultTopSites[1])

        // Remove facebook top sites, first cell
        waitForExistence(app.cells["TopSitesCell"].cells.element(boundBy: 0), timeout: 3)
        app.cells["TopSitesCell"].cells.element(boundBy: 0).press(forDuration:1)
        selectOptionFromContextMenu(option: "Remove")

        // Check top site in first cell now
        waitForExistence(app.collectionViews.cells.collectionViews.cells.element(boundBy: 0))
        let topSiteCells = TopSiteCellgroup.cells
        let topSiteFirstCellAfter = app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        XCTAssertTrue(topSiteFirstCellAfter == topSiteCells["youtube"].label, "First top site does not match")
    }

    func testTopSites4OpenInNewTab() {
        navigator.goto(HomePanelsScreen)
        waitForExistence(TopSiteCellgroup.cells["apple"], timeout: 5)
        TopSiteCellgroup.cells["apple"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Tab"].tap()
        // The new tab is open but curren screen is still Homescreen
        XCTAssert(TopSiteCellgroup.exists)

        navigator.performAction(Action.CloseURLBarOpen)
        navigator.goto(TabTray)
        app.cells.staticTexts["Homepage"].firstMatch.tap()
        waitForExistence(TopSiteCellgroup.cells["apple"])
        navigator.nowAt(HomePanelsScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        if iPad() {
            waitForExistence(app.cells.staticTexts["Apple"])
            XCTAssertTrue(app.cells.staticTexts["Apple"].exists, "A new Tab has not been open")
        } else {
            waitForExistence(app.cells.staticTexts["Apple"])
            XCTAssertTrue(app.cells.staticTexts["Apple"].exists, "A new Tab has not been open")
        }
    }

    // Smoketest
    func testTopSitesOpenInNewTabDefaultTopSite() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.BottomToolbar.settingsMenuButton], timeout: 5)
        // Open one of the sites from Topsites and wait until page is loaded
        waitForExistence(app.cells["TopSitesCell"].cells.element(boundBy: 3), timeout: 3)
        app.cells["TopSitesCell"].cells.element(boundBy: 3).press(forDuration:1)
        selectOptionFromContextMenu(option: "Open in New Tab")
        // Check that two tabs are open and one of them is the default top site one
        // Needed for BB to work after iOS 13.3 update
        sleep(1)
        waitForNoExistence(app.tables["Context Menu"], timeoutValue: 15)
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        var numTabsOpen: Int
        if iPad() {
            waitForExistence(app.cells.staticTexts["Wikipedia"], timeout: 5)
            numTabsOpen = app.collectionViews.element(boundBy: 2).cells.count
        } else {
            waitForExistence(app.collectionViews.cells.staticTexts["Wikipedia"], timeout: 5)
            numTabsOpen = app.collectionViews.element(boundBy: 1).cells.count
        }
        XCTAssertEqual(numTabsOpen, 2, "New tab not open")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTab() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.BottomToolbar.settingsMenuButton], timeout: 5)
        // Long tap on apple top site, second cell
        waitForExistence(app.cells["TopSitesCell"].cells["apple"], timeout: 3)
        app.cells["TopSitesCell"].cells["apple"].press(forDuration:1)
        app.tables["Context Menu"].cells["Open in New Private Tab"].tap()

        XCTAssert(TopSiteCellgroup.exists)
        XCTAssertFalse(app.staticTexts["Apple"].exists)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        waitForExistence(app.cells.staticTexts.element(boundBy: 0))
        if !app.collectionViews["Apple"].exists {
            app.cells.staticTexts.element(boundBy: 0).tap()
            waitForValueContains(app.textFields["url"], value: "apple")
            app.buttons["Show Tabs"].tap()
        }
        navigator.nowAt(TabTray)
        waitForExistence(app.collectionViews.cells.staticTexts["Apple"], timeout: 5)
        app.cells.staticTexts["Apple"].firstMatch.tap()

        // The website is open
        XCTAssertFalse(TopSiteCellgroup.exists)
        XCTAssertTrue(app.textFields["url"].exists)
        waitForValueContains(app.textFields["url"], value: "apple.com")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTabDefaultTopSite() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.BottomToolbar.settingsMenuButton], timeout: 5)
        navigator.nowAt(NewTabScreen)
        // Open one of the sites from Topsites and wait until page is loaded
        // Long tap on apple top site, second cell
        waitForExistence(app.cells["TopSitesCell"].cells.element(boundBy: 3), timeout: 3)
        app.cells["TopSitesCell"].cells.element(boundBy: 3).press(forDuration:1)
        selectOptionFromContextMenu(option: "Open in New Private Tab")

        // Check that two tabs are open and one of them is the default top site one
        // Workaroud needed after xcode 11.3 update Issue 5937
        sleep(3)
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        waitForExistence(app.cells.staticTexts[defaultTopSite["bookmarkLabel"]!])
        var numTabsOpen = app.collectionViews.element(boundBy: 0).cells.count
        if iPad() {
            navigator.goto(TabTray)
            numTabsOpen = app.collectionViews.element(boundBy: 1).cells.count
        }
        XCTAssertEqual(numTabsOpen, 1, "New tab not open")
    }

    func testTopSites1ShareDefaultTopSite() {
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!]
            .press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it
        selectOptionFromContextMenu(option: "Share")
        // Comenting out until share sheet can be managed with automated tests issue #5477
        if !iPad() {
            waitForExistence( app.buttons["Close"], timeout: 10)
            app.buttons["Close"].tap()
        }
    }

    private func selectOptionFromContextMenu(option: String) {
        XCTAssertTrue(app.tables["Context Menu"].cells[option].exists)
        app.tables["Context Menu"].cells[option].tap()
    }

    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        waitForExistence(app.cells["TopSitesCell"])
        XCTAssertTrue(app.cells["TopSitesCell"].exists)
        let numberOfTopSites = TopSiteCellgroup.cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites, "The number of Top Sites is not correct")
    }

    func testContextMenuInLandscape() {
        // For iPhone test is failing to find top sites in landscape
        // can't scroll only to that area. Needs investigation
        if iPad() {
            XCUIDevice.shared.orientation = .landscapeLeft
            waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
            navigator.performAction(Action.CloseURLBarOpen)

            waitForExistence(TopSiteCellgroup.cells["apple"], timeout: 5)
            TopSiteCellgroup.cells["apple"].press(forDuration: 1)

            let contextMenuHeight = app.tables["Context Menu"].frame.size.height
            let parentViewHeight = app.otherElements["Action Sheet"].frame.size.height

            XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)

            // Go back to portrait mode
            XCUIDevice.shared.orientation = .portrait
        }
    }
}
