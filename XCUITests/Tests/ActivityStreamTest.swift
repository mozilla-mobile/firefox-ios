/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let defaultTopSite = ["topSiteLabel": "wikipedia", "bookmarkLabel": "Wikipedia"]
let newTopSite = ["url": "www.mozilla.org", "topSiteLabel": "mozilla", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
let allDefaultTopSites = ["facebook", "youtube", "amazon", "wikipedia", "twitter"]

class ActivityStreamTest: BaseTestCase {
    let TopSiteCellgroup = XCUIApplication().collectionViews.cells["TopSitesCell"]

    let testWithDB = ["testActivityStreamPages","testTopSitesAdd", "testTopSitesOpenInNewTab", "testTopSitesOpenInNewPrivateTab", "testTopSitesBookmarkNewTopSite", "testTopSitesShareNewTopSite", "testContextMenuInLandscape"]

    // Using the DDDBBs created for these tests containing enough entries for the tests that used them listed above
    let pagesVisitediPad = "browserActivityStreamPagesiPad.db"
    let pagesVisitediPhone = "browserActivityStreamPagesiPhone.db"

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testWithDB.contains(key) {
            // for the current test name, add the db fixture used
            if Base.helper.iPad() {
                launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.LoadDatabasePrefix + pagesVisitediPad]
            } else {
                launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.LoadDatabasePrefix + pagesVisitediPhone]
            }
        }
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // Smoketest
    func testDefaultSites() {
        // There should be 5 top sites by default
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        // Check their names so that test is added to Smoketest
        XCTAssertTrue(TopSiteCellgroup.cells["twitter"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["amazon"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["wikipedia"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["youtube"].exists)
        XCTAssertTrue(TopSiteCellgroup.cells["facebook"].exists)
    }

    func testTopSitesAdd() {
        navigator.goto(URLBarOpen)
        if Base.helper.iPad() {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 12)
        } else {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 8)
        }
    }

    func testTopSitesRemove() {
        Base.helper.loadWebPage("http://example.com")
        Base.helper.waitForTabsButton()
        if Base.helper.iPad() {
            Base.app.buttons["URLBarView.backButton"].tap()
        } else {
            Base.app.buttons["TabToolbar.backButton"].tap()
        }
        navigator.performAction(Action.OpenNewTabFromTabTray)
        // A new site has been added to the top sites
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        TopSiteCellgroup.cells["example"].press(forDuration: 1) //example is the name of the domain. (example.com)
        Base.app.tables["Context Menu"].cells["Remove"].tap()
        // A top site has been removed
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
    }

    func testTopSitesRemoveDefaultTopSite() {
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Remove and check that now there should be only 4 default top sites
        selectOptionFromContextMenu(option: "Remove")
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 4)
    }

    func testTopSitesRemoveAllDefaultTopSitesAddNewOne() {
        // Remove all default Top Sites
        Base.helper.waitForExistence(Base.app.cells["facebook"])
        for element in allDefaultTopSites {
            TopSiteCellgroup.cells[element].press(forDuration: 1)
            selectOptionFromContextMenu(option: "Remove")
        }

        let numberOfTopSites = TopSiteCellgroup.cells.matching(identifier: "TopSite").count
        Base.helper.waitForNoExistence(TopSiteCellgroup.cells["TopSite"])
        XCTAssertEqual(numberOfTopSites, 0, "All top sites should have been removed")

        // Open a new page and wait for the completion
        navigator.nowAt(HomePanelsScreen)
        navigator.openURL(newTopSite["url"]!)
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        Base.helper.waitForExistence(TopSiteCellgroup.cells[newTopSite["topSiteLabel"]!])
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 1)
    }

    func testTopSitesRemoveAllExceptDefaultClearPrivateData() {
        navigator.goto(BrowserTab)
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        Base.helper.waitForExistence(Base.app.collectionViews.cells["mozilla"])
        XCTAssertTrue(Base.app.collectionViews.cells["mozilla"].exists)
        // A new site has been added to the top sites
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        XCTAssertFalse(Base.app.collectionViews.cells["mozilla"].exists)
    }

    func testTopSitesRemoveAllExceptPinnedClearPrivateData() {
        navigator.goto(BrowserTab)
        navigator.performAction(Action.PinToTopSitesPAM)
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        Base.helper.waitForExistence(Base.app.collectionViews.cells[newTopSite["topSiteLabel"]!])
        XCTAssertTrue(Base.app.collectionViews.cells[newTopSite["topSiteLabel"]!].exists)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        Base.helper.waitForExistence(Base.app.collectionViews.cells[newTopSite["topSiteLabel"]!])
        XCTAssertTrue(Base.app.collectionViews.cells[newTopSite["topSiteLabel"]!].exists)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    func testTopSitesShiftAfterRemovingOne() {
        // Check top site in first and second cell
        let topSiteFirstCell = Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        let topSiteSecondCell = Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 1).label

        XCTAssertTrue(topSiteFirstCell == allDefaultTopSites[0])
        XCTAssertTrue(topSiteSecondCell == allDefaultTopSites[1])

        // Remove facebook top sites, first cell
        Base.helper.waitForExistence(Base.app.cells["TopSitesCell"].cells.element(boundBy: 0), timeout: 3)
        Base.app.cells["TopSitesCell"].cells.element(boundBy: 0).press(forDuration:1)
        selectOptionFromContextMenu(option: "Remove")

        // Check top site in first cell now
        Base.helper.waitForExistence(Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 0))
        let topSiteCells = TopSiteCellgroup.cells
        let topSiteFirstCellAfter = Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        XCTAssertTrue(topSiteFirstCellAfter == topSiteCells["youtube"].label, "First top site does not match")
    }

    func testTopSitesOpenInNewTab() {
        navigator.goto(HomePanelsScreen)
        Base.helper.waitForExistence(TopSiteCellgroup.cells["apple"])
        TopSiteCellgroup.cells["apple"].press(forDuration: 1)
        Base.app.tables["Context Menu"].cells["Open in New Tab"].tap()
        XCTAssert(TopSiteCellgroup.exists)
        XCTAssertFalse(Base.app.staticTexts["apple"].exists)

        navigator.goto(TabTray)
        Base.app.collectionViews.cells["Home"].tap()
        Base.helper.waitForExistence(TopSiteCellgroup.cells["apple"])
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        Base.helper.waitForExistence(Base.app.collectionViews.cells["Apple"])
        XCTAssertTrue(Base.app.collectionViews.cells["Apple"].exists, "A new Tab has not been open")
    }

    // Smoketest
    func testTopSitesOpenInNewTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        Base.helper.waitForExistence(Base.app.cells["TopSitesCell"].cells.element(boundBy: 3), timeout: 3)
        Base.app.cells["TopSitesCell"].cells.element(boundBy: 3).press(forDuration:1)
        selectOptionFromContextMenu(option: "Open in New Tab")
        // Check that two tabs are open and one of them is the default top site one
        // Needed for BB to work after iOS 13.3 update
        sleep(1)
        Base.helper.waitForNoExistence(Base.app.tables["Context Menu"], timeoutValue: 15)
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        Base.helper.waitForExistence(Base.app.collectionViews.cells[defaultTopSite["bookmarkLabel"]!])
        let numTabsOpen = Base.app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 2, "New tab not open")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTab() {
        navigator.goto(HomePanelsScreen)
        // Long tap on apple top site, second cell
        Base.helper.waitForExistence(Base.app.cells["TopSitesCell"].cells["apple"], timeout: 3)
        Base.app.cells["TopSitesCell"].cells["apple"].press(forDuration:1)
        Base.app.tables["Context Menu"].cells["Open in New Private Tab"].tap()

        XCTAssert(TopSiteCellgroup.exists)
        XCTAssertFalse(Base.app.staticTexts["Apple"].exists)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        Base.helper.waitForExistence(Base.app.collectionViews.cells.element(boundBy: 0))
        if !Base.app.collectionViews["Apple"].exists {
            Base.app.collectionViews.cells.element(boundBy: 0).tap()
            Base.helper.waitForValueContains(Base.app.textFields["url"], value: "apple")
            Base.app.buttons["Show Tabs"].tap()
        }
        navigator.nowAt(TabTray)
        Base.helper.waitForExistence(Base.app.cells["Apple"])
        Base.app.collectionViews.cells["Apple"].tap()

        // The website is open
        XCTAssertFalse(TopSiteCellgroup.exists)
        XCTAssertTrue(Base.app.textFields["url"].exists)
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "apple.com")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        // Long tap on apple top site, second cell
        Base.helper.waitForExistence(Base.app.cells["TopSitesCell"].cells.element(boundBy: 3), timeout: 3)
        Base.app.cells["TopSitesCell"].cells.element(boundBy: 3).press(forDuration:1)
        selectOptionFromContextMenu(option: "Open in New Private Tab")

        // Check that two tabs are open and one of them is the default top site one
        // Workaroud needed after xcode 11.3 update Issue 5937
        sleep(3)
        navigator.nowAt(HomePanelsScreen)
        Base.helper.waitForTabsButton()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        Base.helper.waitForExistence(Base.app.collectionViews.cells[defaultTopSite["bookmarkLabel"]!])
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1, "New tab not open")
    }

    func testTopSitesBookmarkDefaultTopSite() {
        // Bookmark a default TopSite, Wikipedia, third top site
        Base.helper.waitForExistence(Base.app.cells["TopSitesCell"].cells.element(boundBy: 3), timeout: 3)
        Base.app.cells["TopSitesCell"].cells.element(boundBy: 3).press(forDuration:1)
        selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.goto(MobileBookmarks)
        Base.helper.waitForExistence(Base.app.tables["Bookmarks List"])
        XCTAssertTrue(Base.app.tables["Bookmarks List"].staticTexts[defaultTopSite["bookmarkLabel"]!].exists)

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.performAction(Action.ExitMobileBookmarksFolder)
        navigator.nowAt(LibraryPanel_Bookmarks)
        navigator.performAction(Action.CloseBookmarkPanel)

        Base.app.cells["TopSitesCell"].cells[defaultTopSite["topSiteLabel"]!]
            .press(forDuration: 2)
        XCTAssertTrue(Base.app.tables["Context Menu"].cells["Remove Bookmark"].exists)

        // Unbookmark it
        selectOptionFromContextMenu(option: "Remove Bookmark")
        navigator.goto(LibraryPanel_Bookmarks)
        XCTAssertFalse(Base.app.tables["Bookmarks List"].staticTexts[defaultTopSite["bookmarkLabel"]!].exists)
    }

    func testTopSitesBookmarkNewTopSite() {
        let topSiteCells = TopSiteCellgroup.cells
        Base.helper.waitForExistence(topSiteCells[newTopSite["topSiteLabel"]!])
        topSiteCells[newTopSite["topSiteLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(MobileBookmarks)
        XCTAssertTrue(Base.app.tables["Bookmarks List"].staticTexts[newTopSite["bookmarkLabel"]!].exists)

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.performAction(Action.ExitMobileBookmarksFolder)
        navigator.goto(HomePanelsScreen)
        Base.helper.waitForExistence(TopSiteCellgroup.cells[newTopSite["topSiteLabel"]!])
        TopSiteCellgroup.cells[newTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Unbookmark it
        selectOptionFromContextMenu(option: "Remove Bookmark")
        navigator.goto(LibraryPanel_Bookmarks)
        XCTAssertFalse(Base.app.tables["Bookmarks List"].staticTexts[newTopSite["bookmarkLabel"]!].exists)
    }

    func testTopSitesShareDefaultTopSite() {
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!]
            .press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it
        selectOptionFromContextMenu(option: "Share")
        // Comenting out until share sheet can be managed with automated tests issue #5477
        //if !iPad() {
        //    Base.app.buttons["Cancel"].tap()
        //}
    }

    // Disable #5554
    /*
    func testTopSitesShareNewTopSite() {
        navigator.goto(HomePanelsScreen)
        let topSiteCells = TopSiteCellgroup.cells
        Base.helper.waitForExistence(topSiteCells[newTopSite["topSiteLabel"]!])
        topSiteCells[newTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it....
        selectOptionFromContextMenu(option: "Share")
        // Comenting out until share sheet can be managed with automated tests issue #5477
        //if !iPad() {
        //    Base.app.buttons["Cancel"].tap()
        //}
    }*/

    private func selectOptionFromContextMenu(option: String) {
        XCTAssertTrue(Base.app.tables["Context Menu"].cells[option].exists)
        Base.app.tables["Context Menu"].cells[option].tap()
    }

    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        Base.helper.waitForExistence(Base.app.cells["TopSitesCell"])
        XCTAssertTrue(Base.app.cells["TopSitesCell"].exists)
        let numberOfTopSites = TopSiteCellgroup.cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites, "The number of Top Sites is not correct")
    }

    func testContextMenuInLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft

        TopSiteCellgroup.cells["apple"].press(forDuration: 1)

        let contextMenuHeight = Base.app.tables["Context Menu"].frame.size.height
        let parentViewHeight = Base.app.otherElements["Action Sheet"].frame.size.height

        XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)

        // Go back to portrait mode
        XCUIDevice.shared.orientation = .portrait
    }
}
