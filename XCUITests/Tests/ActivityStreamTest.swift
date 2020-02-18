/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ActivityStreamTest: BaseTestCase {

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if Constants.testWithDB.contains(key) {
            // for the current test name, add the db fixture used
            let pagesVisitedDB = Base.helper.iPad() ? LaunchArguments.LoadDatabasePrefix + Constants.pagesVisitediPad : LaunchArguments.LoadDatabasePrefix + Constants.pagesVisitediPhone
            launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, pagesVisitedDB]
        }
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // Smoketest
    func testDefaultSites() {
        // There should be 5 top sites by default
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        
        // Check their names so that test is added to Smoketest
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupTwitterCell)
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupAmazonCell)
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupWikipediaCell)
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupYoutubeCell)
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupFacebookCell)
    }

    func testTopSitesAdd() {
        navigator.goto(URLBarOpen)
        Base.helper.iPad() ? TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 12) : TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 8)
    }

    func testTopSitesRemove() {
        Base.helper.loadWebPage(Constants.urlExample)
        Base.helper.waitForTabsButton()
        Base.helper.iPad() ? TestStep.tapOnElement(UIElements.urlBarViewBackButton) : TestStep.tapOnElement(UIElements.tabToolbarBackButton)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        
        // A new site has been added to the top sites
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        // example is the name of the domain. (example.com)
        TestStep.longTapOnElement(UIElements.topSiteCellGroupExampleCell, forSeconds: 1)
        TestStep.tapOnElement(UIElements.contextMenuRemoveButton)
        
        // A top site has been removed
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
    }

    func testTopSitesRemoveDefaultTopSite() {
        TestStep.longTapOnElement(UIElements.topSiteCellGroupTopSiteLabel, forSeconds: 1)

        // Tap on Remove and check that now there should be only 4 default top sites
        TestStep.selectOptionFromContextMenu(option: "Remove")
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 4)
    }

    func testTopSitesRemoveAllDefaultTopSitesAddNewOne() {
        // Remove all default Top Sites
        TestStep.removeAllDefaultTopSites()

        let numberOfTopSites = UIElements.topSiteCells.count
        Base.helper.waitForNoExistence(UIElements.topSiteCell)
        XCTAssertEqual(numberOfTopSites, 0, "All top sites should have been removed")

        // Open a new page and wait for the completion
        navigator.nowAt(HomePanelsScreen)
        navigator.openURL(Constants.newTopSite["url"]!)
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        Base.helper.waitForExistence(UIElements.topSiteCellGroupTopSiteLabel)
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 1)
    }

    func testTopSitesRemoveAllExceptDefaultClearPrivateData() {
        navigator.goto(BrowserTab)
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        TestCheck.elementIsPresent(UIElements.mozillaCollectionCell)
        
        // A new site has been added to the top sites
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        XCTAssertFalse(Base.app.collectionViews.cells["mozilla"].exists)
    }

    func testTopSitesRemoveAllExceptPinnedClearPrivateData() {
        guard let topSiteLabel = Constants.newTopSite["topSiteLabel"] else {
            XCTFail("Could not get value for \"newTopSite[\"topSiteLabel\"]\".")
            return
        }
        
        navigator.goto(BrowserTab)
        navigator.performAction(Action.PinToTopSitesPAM)
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        TestCheck.elementIsPresent(Base.app.collectionViews.cells[topSiteLabel])
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        TestCheck.elementIsPresent(Base.app.collectionViews.cells[topSiteLabel], timeout: Constants.mediumWaitTime)
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    func testTopSitesShiftAfterRemovingOne() {
        // Check top site in first and second cell
        let topSiteFirstCell = Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        let topSiteSecondCell = Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 1).label

        XCTAssertTrue(topSiteFirstCell == Constants.allDefaultTopSites[0])
        XCTAssertTrue(topSiteSecondCell == Constants.allDefaultTopSites[1])

        // Remove facebook top sites, first cell
        Base.helper.waitForExistence(Base.app.cells["TopSitesCell"].cells.element(boundBy: 0), timeout: 3)
        TestStep.longTapOnElement(Base.app.cells["TopSitesCell"].cells.element(boundBy: 0), forSeconds: 1)
        TestStep.selectOptionFromContextMenu(option: "Remove")

        // Check top site in first cell now
        Base.helper.waitForExistence(Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 0))
        let topSiteCells = UIElements.topSiteCellGroup.cells
        let topSiteFirstCellAfter = Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        XCTAssertTrue(topSiteFirstCellAfter == topSiteCells["youtube"].label, "First top site does not match")
    }

    func testTopSitesOpenInNewTab() {
        navigator.goto(HomePanelsScreen)
        Base.helper.waitForExistence(UIElements.topSiteCellGroup.cells["apple"])
        TestStep.longTapOnElement(UIElements.topSiteCellGroup.cells["apple"], forSeconds: 1)
        Base.app.tables["Context Menu"].cells["Open in New Tab"].tap()
        TestCheck.elementIsPresent(UIElements.topSiteCellGroup)
        XCTAssertFalse(Base.app.staticTexts["apple"].waitForExistence(timeout: Constants.smallWaitTime))

        navigator.goto(TabTray)
        Base.app.collectionViews.cells["Home"].tap()
        Base.helper.waitForExistence(UIElements.topSiteCellGroup.cells["apple"])
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        Base.helper.waitForExistence(Base.app.collectionViews.cells["Apple"])
        TestCheck.elementIsPresent(Base.app.collectionViews.cells["Apple"])
    }

    // Smoketest
    func testTopSitesOpenInNewTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        TestStep.longTapOnElement(Base.app.cells["TopSitesCell"].cells.element(boundBy: 3), forSeconds: 1)
        TestStep.selectOptionFromContextMenu(option: "Open in New Tab")
        // Check that two tabs are open and one of them is the default top site one
        // Needed for BB to work after iOS 13.3 update
        sleep(1)
        Base.helper.waitForNoExistence(Base.app.tables["Context Menu"], timeoutValue: 15)
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        Base.helper.waitForExistence(Base.app.collectionViews.cells[Constants.defaultTopSite["bookmarkLabel"]!])
        let numTabsOpen = Base.app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 2, "New tab not open")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTab() {
        navigator.goto(HomePanelsScreen)
        // Long tap on apple top site, second cell
        TestStep.longTapOnElement(Base.app.cells["TopSitesCell"].cells["apple"], forSeconds: 1)
        TestStep.tapOnElement(Base.app.tables["Context Menu"].cells["Open in New Private Tab"])

        TestCheck.elementIsPresent(UIElements.topSiteCellGroup)
        XCTAssertFalse(Base.app.staticTexts["Apple"].waitForExistence(timeout: Constants.smallWaitTime))

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        Base.helper.waitForExistence(Base.app.collectionViews.cells.element(boundBy: 0))
        if !Base.app.collectionViews["Apple"].waitForExistence(timeout: Constants.smallWaitTime) {
            TestStep.tapOnElement(Base.app.collectionViews.cells.element(boundBy: 0))
            Base.helper.waitForValueContains(Base.app.textFields["url"], value: "apple")
            TestStep.tapOnElement(Base.app.buttons["Show Tabs"])
        }
        navigator.nowAt(TabTray)
        TestStep.tapOnElement(Base.app.collectionViews.cells["Apple"])

        // The website is open
        XCTAssertFalse(UIElements.topSiteCellGroup.waitForExistence(timeout: Constants.smallWaitTime))
        TestCheck.elementIsPresent(Base.app.textFields["url"])
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "apple.com")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        // Long tap on apple top site, second cell
        TestStep.longTapOnElement(Base.app.cells["TopSitesCell"].cells.element(boundBy: 3), forSeconds: 1)
        TestStep.selectOptionFromContextMenu(option: "Open in New Private Tab")

        // Check that two tabs are open and one of them is the default top site one
        // Workaroud needed after xcode 11.3 update Issue 5937
        sleep(3)
        navigator.nowAt(HomePanelsScreen)
        Base.helper.waitForTabsButton()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        Base.helper.waitForExistence(Base.app.collectionViews.cells[Constants.defaultTopSite["bookmarkLabel"]!])
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1, "New tab not open")
    }

    func testTopSitesBookmarkDefaultTopSite() {
        // Bookmark a default TopSite, Wikipedia, third top site
        TestStep.longTapOnElement(Base.app.cells["TopSitesCell"].cells.element(boundBy: 3), forSeconds: 1)
        TestStep.selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.goto(MobileBookmarks)
        TestCheck.elementIsPresent(Base.app.tables["Bookmarks List"].staticTexts[Constants.defaultTopSite["bookmarkLabel"]!])

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.performAction(Action.ExitMobileBookmarksFolder)
        navigator.nowAt(LibraryPanel_Bookmarks)
        navigator.performAction(Action.CloseBookmarkPanel)

        TestStep.longTapOnElement(Base.app.cells["TopSitesCell"].cells[Constants.defaultTopSite["topSiteLabel"]!], forSeconds: 2)
        TestCheck.elementIsPresent(Base.app.tables["Context Menu"].cells["Remove Bookmark"])

        // Unbookmark it
        TestStep.selectOptionFromContextMenu(option: "Remove Bookmark")
        navigator.goto(LibraryPanel_Bookmarks)
        XCTAssertFalse(Base.app.tables["Bookmarks List"].staticTexts[Constants.defaultTopSite["bookmarkLabel"]!].waitForExistence(timeout: Constants.smallWaitTime))
    }

    func testTopSitesBookmarkNewTopSite() {
        let topSiteCells = UIElements.topSiteCellGroup.cells
        TestStep.longTapOnElement(topSiteCells[Constants.newTopSite["topSiteLabel"]!], forSeconds: 1)
        TestStep.selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(MobileBookmarks)
        TestCheck.elementIsPresent(Base.app.tables["Bookmarks List"].staticTexts[Constants.newTopSite["bookmarkLabel"]!])

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.performAction(Action.ExitMobileBookmarksFolder)
        navigator.goto(HomePanelsScreen)
        TestStep.longTapOnElement(UIElements.topSiteCellGroup.cells[Constants.newTopSite["topSiteLabel"]!], forSeconds: 1)

        // Unbookmark it
        TestStep.selectOptionFromContextMenu(option: "Remove Bookmark")
        navigator.goto(LibraryPanel_Bookmarks)
        XCTAssertFalse(Base.app.tables["Bookmarks List"].staticTexts[Constants.newTopSite["bookmarkLabel"]!].waitForExistence(timeout: Constants.smallWaitTime))
    }

    func testTopSitesShareDefaultTopSite() {
        TestStep.longTapOnElement(UIElements.topSiteCellGroup.cells[Constants.defaultTopSite["topSiteLabel"]!], forSeconds: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it
        TestStep.selectOptionFromContextMenu(option: "Share")
        // Comenting out until share sheet can be managed with automated tests issue #5477
        //if !iPad() {
        //    Base.app.buttons["Cancel"].tap()
        //}
    }

    // Disable #5554
    /*
    func testTopSitesShareNewTopSite() {
        navigator.goto(HomePanelsScreen)
        let topSiteCells = UIElements.topSiteCellGroup.cells
        Base.helper.waitForExistence(topSiteCells[newTopSite["topSiteLabel"]!])
        topSiteCells[newTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it....
        selectOptionFromContextMenu(option: "Share")
        // Comenting out until share sheet can be managed with automated tests issue #5477
        //if !iPad() {
        //    Base.app.buttons["Cancel"].tap()
        //}
    }*/

    func testContextMenuInLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft

        TestStep.longTapOnElement(UIElements.topSiteCellGroup.cells["apple"], forSeconds: 1)

        let contextMenuHeight = Base.app.tables["Context Menu"].frame.size.height
        let parentViewHeight = Base.app.otherElements["Action Sheet"].frame.size.height

        XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)

        // Go back to portrait mode
        XCUIDevice.shared.orientation = .portrait
    }
    
}
