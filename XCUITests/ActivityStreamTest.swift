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
            if iPad() {
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
        if iPad() {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 12)
        } else {
            checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 8)
        }
    }

    func testTopSitesRemove() {
        loadWebPage("http://example.com")
        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
        navigator.goto(URLBarOpen)
        // A new site has been added to the top sites
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        TopSiteCellgroup.cells["example"].press(forDuration: 1) //example is the name of the domain. (example.com)
        app.tables["Context Menu"].cells["Remove"].tap()
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
        navigator.goto(HomePanel_TopSites)
        waitforExistence(app.cells["facebook"])
        for element in allDefaultTopSites {
            TopSiteCellgroup.cells[element].press(forDuration: 1)
            selectOptionFromContextMenu(option: "Remove")
        }

        let numberOfTopSites = TopSiteCellgroup.cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, 0, "All top sites should have been removed")

        // Open a new page and wait for the completion
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText(newTopSite["url"]!)
        app.textFields["address"].typeText("\r")
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.goto(HomePanel_TopSites)

        waitforExistence(TopSiteCellgroup.cells[newTopSite["topSiteLabel"]!])
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 1)
    }

    func testTopSitesRemoveAllExceptDefaultClearPrivateData() {
        navigator.goto(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.goto(HomePanel_TopSites)
        waitforExistence(app.collectionViews.cells["mozilla"])
        XCTAssertTrue(app.collectionViews.cells["mozilla"].exists)
        // A new site has been added to the top sites
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        XCTAssertFalse(app.collectionViews.cells["mozilla"].exists)
    }

    func testTopSitesRemoveAllExceptPinnedClearPrivateData() {
        navigator.goto(BrowserTab)
        navigator.performAction(Action.PinToTopSitesPAM)
        navigator.goto(BrowserTabMenu)
        navigator.goto(HomePanel_TopSites)
        waitforExistence(app.collectionViews.cells[newTopSite["topSiteLabel"]!])
        XCTAssertTrue(app.collectionViews.cells[newTopSite["topSiteLabel"]!].exists)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        waitforExistence(app.collectionViews.cells[newTopSite["topSiteLabel"]!])
        XCTAssertTrue(app.collectionViews.cells[newTopSite["topSiteLabel"]!].exists)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    func testTopSitesShiftAfterRemovingOne() {
        // Check top site in first and second cell
        let topSiteFirstCell = app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        let topSiteSecondCell = app.collectionViews.cells.collectionViews.cells.element(boundBy: 1).label

        XCTAssertTrue(topSiteFirstCell == allDefaultTopSites[0])
        XCTAssertTrue(topSiteSecondCell == allDefaultTopSites[1])

        // Remove it
        waitforExistence(app.cells["facebook"])
        app.cells["facebook"].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Remove")

        // Check top site in first cell now
        let topSiteCells = TopSiteCellgroup.cells
        let topSiteFirstCellAfter = app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        XCTAssertTrue(topSiteFirstCellAfter == topSiteCells["youtube"].label, "First top site does not match")
    }

    func testTopSitesOpenInNewTab() {
        navigator.goto(HomePanelsScreen)
        waitforExistence(TopSiteCellgroup.cells["apple"])
        TopSiteCellgroup.cells["apple"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Tab"].tap()
        XCTAssert(TopSiteCellgroup.exists)
        XCTAssertFalse(app.staticTexts["apple"].exists)

        navigator.goto(TabTray)
        app.collectionViews.cells["home"].tap()
        waitforExistence(TopSiteCellgroup.cells["apple"])
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells["Apple"])
        XCTAssertTrue(app.collectionViews.cells["Apple"].exists, "A new Tab has not been open")
    }

    func testTopSitesOpenInNewTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        app.cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Open in New Tab")
        waitUntilPageLoad()

        // Check that two tabs are open and one of them is the default top site one
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells[defaultTopSite["bookmarkLabel"]!])
        let numTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 2, "New tab not open")
    }

    func testTopSitesOpenInNewPrivateTab() {
        navigator.goto(HomePanelsScreen)
        waitforExistence(app.cells["apple"])
        app.collectionViews.cells["TopSitesCell"].cells["apple"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Private Tab"].tap()

        XCTAssert(TopSiteCellgroup.exists)
        XCTAssertFalse(app.staticTexts["Apple"].exists)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells.element(boundBy: 0))
        if !app.collectionViews["Apple"].exists {
            app.collectionViews.cells.element(boundBy: 0).tap()
            waitForValueContains(app.textFields["url"], value: "apple")
            app.buttons["Show Tabs"].tap()
        }
        navigator.nowAt(TabTray)
        waitforExistence(app.cells["Apple"])
        app.collectionViews.cells["Apple"].tap()

        // The website is open
        XCTAssertFalse(TopSiteCellgroup.exists)
        XCTAssertTrue(app.textFields["url"].exists)
        waitForValueContains(app.textFields["url"], value: "apple.com")
    }

    func testTopSitesOpenInNewPrivateTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!]
            .press(forDuration: 1)
        selectOptionFromContextMenu(option: "Open in New Private Tab")

        // Check that two tabs are open and one of them is the default top site one
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        waitforExistence(app.collectionViews.cells[defaultTopSite["bookmarkLabel"]!])
        let numTabsOpen = userState.numTabs
        XCTAssertEqual(numTabsOpen, 1, "New tab not open")
    }

    func testTopSitesBookmarkDefaultTopSite() {
        // Bookmark a default TopSite
        app.cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.goto(HomePanel_Bookmarks)
        waitforExistence(app.tables["Bookmarks List"])
        print(app.debugDescription)
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[defaultTopSite["bookmarkLabel"]!].exists)

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.goto(HomePanel_TopSites)
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!]
            .press(forDuration: 2)
        XCTAssertTrue(app.tables["Context Menu"].cells["Remove Bookmark"].exists)

        // Unbookmark it
        selectOptionFromContextMenu(option: "Remove Bookmark")
        navigator.goto(HomePanel_Bookmarks)
        XCTAssertFalse(app.tables["Bookmarks List"].staticTexts[defaultTopSite["bookmarkLabel"]!].exists)
    }

    func testTopSitesBookmarkNewTopSite () {
        let topSiteCells = TopSiteCellgroup.cells
        waitforExistence(topSiteCells[newTopSite["topSiteLabel"]!])
        topSiteCells[newTopSite["topSiteLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(HomePanel_Bookmarks)
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[newTopSite["bookmarkLabel"]!].exists)

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.goto(HomePanel_TopSites)
        TopSiteCellgroup.cells[newTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Unbookmark it
        selectOptionFromContextMenu(option: "Remove Bookmark")
        navigator.goto(HomePanel_Bookmarks)
        XCTAssertFalse(app.tables["Bookmarks List"].staticTexts[newTopSite["bookmarkLabel"]!].exists)
    }

    func testTopSitesShareDefaultTopSite () {
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!]
            .press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it
        selectOptionFromContextMenu(option: "Share")
        if !iPad() {
            app.buttons["Cancel"].tap()
        }
    }

    func testTopSitesShareNewTopSite () {
        navigator.goto(HomePanelsScreen)
        let topSiteCells = TopSiteCellgroup.cells
        waitforExistence(topSiteCells[newTopSite["topSiteLabel"]!])
        topSiteCells[newTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it....
        selectOptionFromContextMenu(option: "Share")
        if !iPad() {
            app.buttons["Cancel"].tap()
        }
    }

    private func selectOptionFromContextMenu(option: String) {
        XCTAssertTrue(app.tables["Context Menu"].cells[option].exists)
        app.tables["Context Menu"].cells[option].tap()
    }

    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        waitforExistence(app.cells["TopSitesCell"])
        XCTAssertTrue(app.cells["TopSitesCell"].exists)
        let numberOfTopSites = TopSiteCellgroup.cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites, "The number of Top Sites is not correct")
    }

    func testOpenTopSitesFromContextMenu () {
         // Top Sites is shown by default
         waitforExistence(app.cells["TopSitesCell"])
         checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)

         // Go to a website
         navigator.openURL("example.com")
         waitUntilPageLoad()

         // Go back to Top Sites from context menu
         navigator.browserPerformAction(.openTopSitesOption)
         checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    func testActivityStreamPages() {
        let pagecontrolButton = TopSiteCellgroup.buttons["Next Page"]
        waitforExistence(pagecontrolButton)
        XCTAssert(pagecontrolButton.exists, "The Page Control button must exist")
        pagecontrolButton.tap()
        pagecontrolButton.tap()
        let topSiteCells = TopSiteCellgroup.cells
        waitforExistence(topSiteCells["example"])
        topSiteCells["example"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Remove"].tap()
        waitforNoExistence(pagecontrolButton)
        XCTAssertFalse(pagecontrolButton.exists, "The Page Control button should disappear after an item is deleted.")
    }

    func testContextMenuInLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft

        TopSiteCellgroup.cells["apple"].press(forDuration: 1)

        let contextMenuHeight = app.tables["Context Menu"].frame.size.height
        let parentViewHeight = app.otherElements["Action Sheet"].frame.size.height

        XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)

        // Go back to portrait mode
        XCUIDevice.shared.orientation = .portrait
    }
}
