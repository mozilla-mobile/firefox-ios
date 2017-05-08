/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let defaultTopSite = ["topSiteLabel": "wikipedia", "bookmarkLabel": "Wikipedia"]
let newTopSite = ["url": "www.mozilla.org", "topSiteLabel": "mozilla", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
let allDefaultTopSites = ["facebook", "youtube", "amazon", "wikipedia", "twitter"]

class ActivityStreamTest: BaseTestCase {
    var navigator: Navigator!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
        dismissFirstRunUI()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDefaultSites() {
        let app = XCUIApplication()
        let topSites = app.cells["TopSitesCell"]
        let numberOfTopSites = topSites.cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, 5, "There should be a total of 5 default Top Sites.")
    }

    func testTopSitesAdd() {
        let app = XCUIApplication()
        let topSites = app.cells["TopSitesCell"]
        let numberOfTopSites = topSites.cells.matching(identifier: "TopSite").count

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        let sitesAfter = topSites.cells.matching(identifier: "TopSite").count
        XCTAssertTrue(sitesAfter == numberOfTopSites + 1, "A new site should have been added to the topSites")
    }

    func testTopSitesRemove() {
        let app = XCUIApplication()
        let topSites = app.cells["TopSitesCell"]
        let numberOfTopSites = topSites.cells.matching(identifier: "TopSite").count

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()
        let sitesAfter = topSites.cells.matching(identifier: "TopSite").count
        XCTAssertTrue(sitesAfter == numberOfTopSites + 1, "A new site should have been added to the topSites")

        app.collectionViews.cells["TopSitesCell"].cells["example"].press(forDuration: 1) //example is the name of the domain. (example.com)
        app.tables["Context Menu"].cells["Remove"].tap()
        let sitesAfterDelete = topSites.cells.matching(identifier: "TopSite").count
        XCTAssertTrue(sitesAfterDelete == numberOfTopSites, "A site should have been deleted to the topSites")
    }

    func testTopSitesRemoveDefaultTopSite() {
        navigator.goto(NewTabScreen)
        app.collectionViews.cells["TopSitesCell"].cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Remove and check that now there should be only 4 default top sites
        selectOptionFromContextMenu (option: "Remove")
        let topSites = app.cells["TopSitesCell"]
        let numberOfTopSites = topSites.cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, 4, "A site should have been deleted to the topSites")
    }

    func testTopSitesRemoveAllDefaultTopSitesAddNewOne() {
        navigator.goto(NewTabScreen)

        // Remove all default Top Sites
        for i in allDefaultTopSites {
            app.collectionViews.cells["TopSitesCell"].cells[i].press(forDuration: 1)
            selectOptionFromContextMenu (option: "Remove")
        }

        let topSites = app.cells["TopSitesCell"]
        let numberOfTopSites = topSites.cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, 0, "All top sites should have been removed")

        navigator.nowAt(NewTabScreen)
        navigator.openURL(urlString: newTopSite["url"]!)
        app.buttons["TabToolbar.backButton"].tap()
        waitforExistence(app.collectionViews.cells["TopSitesCell"].cells[newTopSite["topSiteLabel"]!])
        let numberOfTopSitesAfter = topSites.cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSitesAfter, 1, "A new top site should appear")
    }

    func testTopSitesShiftAfterRemovingOne() {
        navigator.goto(NewTabScreen)

        // Check top site in first and second cell
        let topSiteFirstCell = app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        let topSiteSecondCell = app.collectionViews.cells.collectionViews.cells.element(boundBy: 1).label

        XCTAssertTrue(topSiteFirstCell == allDefaultTopSites[0])
        XCTAssertTrue(topSiteSecondCell == allDefaultTopSites[1])

        // Remove it
        app.collectionViews.cells["TopSitesCell"].cells[allDefaultTopSites[0]].press(forDuration: 1)
        selectOptionFromContextMenu (option: "Remove")

        // Check top site in first cell now
        let topSiteFirstCellAfter = app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        XCTAssertTrue(topSiteFirstCellAfter == allDefaultTopSites[1])
    }

    func testTopSitesOpenInNewTab() {
        let app = XCUIApplication()

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        app.collectionViews.cells["TopSitesCell"].cells["example"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Tab"].tap()
        XCTAssert(app.collectionViews.cells["TopSitesCell"].exists)
        XCTAssertFalse(app.staticTexts["Example Domain"].exists)

        app.buttons["URLBarView.tabsButton"].tap()
        app.cells["Example Domain"].tap()
        XCTAssertFalse(app.tables["Top sites"].exists)
        XCTAssert(app.staticTexts["Example Domain"].exists)
    }

    func testTopSitesOpenInNewTabDefaultTopSite() {
        navigator.goto(NewTabScreen)
        app.collectionViews.cells["TopSitesCell"].cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu (option: "Open in New Tab")

        // Check that two tabs are open and one of them is the default top site one
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells[defaultTopSite["bookmarkLabel"]!])
        let numTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 2, "New tab not open")
    }

     func testTopSitesOpenInNewPrivateTab() {
        let app = XCUIApplication()

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        app.collectionViews.cells["TopSitesCell"].cells["example"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Private Tab"].tap()

        XCTAssert(app.collectionViews.cells["TopSitesCell"].exists)
        XCTAssertFalse(app.staticTexts["Example Domain"].exists)

        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.maskButton"].tap()
        app.cells["Example Domain"].tap()

        XCTAssertFalse(app.collectionViews.cells["TopSitesCell"].exists)
        XCTAssert(app.staticTexts["Example Domain"].exists)
     }

    func testTopSitesOpenInNewPrivateTabDefaultTopSite() {
        navigator.goto(NewTabScreen)
        app.collectionViews.cells["TopSitesCell"].cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu (option: "Open in New Private Tab")

        // Check that two tabs are open and one of them is the default top site one
        navigator.goto(PrivateTabTray)
        waitforExistence(app.collectionViews.cells[defaultTopSite["bookmarkLabel"]!])
        let numTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 1, "New tab not open")
    }

    func testTopSitesBookmarkDefaultTopSite() {
        // Bookmark a default TopSite
        navigator.goto(NewTabScreen)
        app.collectionViews.cells["TopSitesCell"].cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu (option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.goto(HomePanel_Bookmarks)
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[defaultTopSite["bookmarkLabel"]!].exists)

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.goto(HomePanel_TopSites)
        app.collectionViews.cells["TopSitesCell"].cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)
        XCTAssertTrue(app.tables["Context Menu"].cells["Remove Bookmark"].exists)

        // Unbookmark it
        selectOptionFromContextMenu (option: "Remove Bookmark")
        navigator.goto(HomePanel_Bookmarks)
        XCTAssertFalse(app.tables["Bookmarks List"].staticTexts[defaultTopSite["bookmarkLabel"]!].exists)
    }

    func testTopSitesBookmarkNewTopSite () {
        // Bookmark a new TopSite
        navigator.openURL(urlString: newTopSite["url"]!)
        app.buttons["TabToolbar.backButton"].tap()
        waitforExistence(app.collectionViews.cells["TopSitesCell"].cells[newTopSite["topSiteLabel"]!])
        app.collectionViews.cells["TopSitesCell"].cells[newTopSite["topSiteLabel"]!].press(forDuration: 1)
        selectOptionFromContextMenu (option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomePanel_Bookmarks)
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[newTopSite["bookmarkLabel"]!].exists)

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.goto(HomePanel_TopSites)
        app.collectionViews.cells["TopSitesCell"].cells[newTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Unbookmark it
        selectOptionFromContextMenu (option: "Remove Bookmark")
        navigator.goto(HomePanel_Bookmarks)
        XCTAssertFalse(app.tables["Bookmarks List"].staticTexts[newTopSite["bookmarkLabel"]!].exists)
    }

    func testTopSitesShareDefaultTopSite () {
        navigator.goto(NewTabScreen)
        app.collectionViews.cells["TopSitesCell"].cells[defaultTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it
        selectOptionFromContextMenu (option: "Share")
        app.buttons["Cancel"].tap()
    }

    func testTopSitesShareNewTopSite () {
        navigator.openURL(urlString: newTopSite["url"]!)
        app.buttons["TabToolbar.backButton"].tap()
        waitforExistence(app.collectionViews.cells["TopSitesCell"].cells[newTopSite["topSiteLabel"]!])
        app.collectionViews.cells["TopSitesCell"].cells[newTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it....
        selectOptionFromContextMenu (option: "Share")
        app.buttons["Cancel"].tap()
    }

    private func selectOptionFromContextMenu (option: String) {
        XCTAssertTrue(app.tables["Context Menu"].cells[option].exists)
        app.tables["Context Menu"].cells[option].tap()
    }

    func testActivityStreamPages() {
        let app = XCUIApplication()
        let topSitesTable = app.cells["TopSitesCell"]
        let pagecontrolButton = topSitesTable.buttons["Next Page"]
        XCTAssertFalse(pagecontrolButton.exists, "The Page Control button must not exist. Only 5 elements should be on the page")

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        loadWebPage("http://mozilla.org")
        app.buttons["TabToolbar.backButton"].tap()

        loadWebPage("http://people.mozilla.org")
        app.buttons["TabToolbar.backButton"].tap()

        loadWebPage("http://yahoo.com")
        app.buttons["TabToolbar.backButton"].tap()

        XCTAssert(pagecontrolButton.exists, "The Page Control button must exist if more than 8 elements are displayed.")

        pagecontrolButton.tap()
        pagecontrolButton.tap()

        // Sleep so the pageControl animation finishes.
        sleep(2)

        app.collectionViews.cells["TopSitesCell"].cells["example"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Remove"].tap()
        XCTAssertFalse(pagecontrolButton.exists, "The Page Control button should disappear after an item is deleted.")
    }

    func testContextMenuInLandscape() {
        XCUIDevice.shared().orientation = .landscapeLeft
        let app = XCUIApplication()

        loadWebPage("http://example.com")
        app.buttons["URLBarView.backButton"].tap()
        app.collectionViews.cells["TopSitesCell"].cells["example"].press(forDuration: 1)

        let contextMenuHeight = app.tables["Context Menu"].frame.size.height
        let parentViewHeight = app.otherElements["Action Overlay"].frame.size.height

        XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)

        // Go back to portrait mode
        XCUIDevice.shared().orientation = .portrait
    }
}
