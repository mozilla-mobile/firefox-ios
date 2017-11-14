/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let defaultTopSite = ["topSiteLabel": "wikipedia", "bookmarkLabel": "Wikipedia"]
let newTopSite = ["url": "www.mozilla.org", "topSiteLabel": "mozilla", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
let allDefaultTopSites = ["facebook", "youtube", "amazon", "wikipedia", "twitter"]

class ActivityStreamTest: BaseTestCase {
    let TopSiteCellgroup = XCUIApplication().collectionViews.cells["TopSitesCell"]

    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDefaultSites() {
        // There should be 5 top sites by default
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
    }

    func testTopSitesAdd() {
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)

        loadWebPage("http://example.com")
        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
        navigator.goto(URLBarOpen)
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
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
        for i in allDefaultTopSites {
            TopSiteCellgroup.cells[i].press(forDuration: 1)
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

        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
        waitforExistence(TopSiteCellgroup.cells[newTopSite["topSiteLabel"]!])
        checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 1)
    }

    func testTopSitesShiftAfterRemovingOne() {

        // Check top site in first and second cell
        let topSiteFirstCell = app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        let topSiteSecondCell = app.collectionViews.cells.collectionViews.cells.element(boundBy: 1).label

        XCTAssertTrue(topSiteFirstCell == allDefaultTopSites[0])
        XCTAssertTrue(topSiteSecondCell == allDefaultTopSites[1])

        // Remove it
        let topSiteCells = TopSiteCellgroup.cells
        topSiteCells[allDefaultTopSites[0]].press(forDuration: 1)
        selectOptionFromContextMenu(option: "Remove")

        // Check top site in first cell now
        let topSiteFirstCellAfter = app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        XCTAssertTrue(topSiteFirstCellAfter == allDefaultTopSites[1])
    }

    func testTopSitesOpenInNewTab() {
        loadWebPage("http://example.com")
        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
        navigator.goto(URLBarOpen)
        TopSiteCellgroup.cells["example"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Tab"].tap()
        XCTAssert(TopSiteCellgroup.exists)
        XCTAssertFalse(app.staticTexts["example"].exists)

        //URLBarview goBack button
        let goBackButton = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .button).element(boundBy: 0)
        goBackButton.tap()

        if iPad() {
            app.buttons["TopTabsViewController.tabsButton"].tap()
        } else {
            app.buttons["TabToolbar.tabsButton"].tap()
        }

        app.cells.element(boundBy: 0).tap() //"Example Domain"
        XCTAssertFalse(app.tables["Top sites"].exists)

        let staticTextsQuery = self.app.staticTexts.matching(identifier: "Example Domain")
        if staticTextsQuery.count > 0 {
            let firstText = staticTextsQuery.element(boundBy: 0)
            XCTAssert(firstText.exists)
        }
    }

    func testTopSitesOpenInNewTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!]
            .press(forDuration: 1)
        selectOptionFromContextMenu(option: "Open in New Tab")
        waitUntilPageLoad()

        // Check that two tabs are open and one of them is the default top site one
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells[defaultTopSite["bookmarkLabel"]!])
        let numTabsOpen = app.collectionViews.cells.count
        XCTAssertEqual(numTabsOpen, 2, "New tab not open")
    }

    func testTopSitesOpenInNewPrivateTab() {
        loadWebPage("http://example.com")
        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
        navigator.goto(URLBarOpen)
        app.collectionViews.cells["TopSitesCell"].cells["example"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Private Tab"].tap()

        XCTAssert(TopSiteCellgroup.exists)
        XCTAssertFalse(app.staticTexts["example"].exists)

        //URLBarview goBack button
        let goBackButton = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .button).element(boundBy: 0)
        goBackButton.tap()
        if iPad() {
            app.buttons["TopTabsViewController.tabsButton"].tap()
        } else {
            app.buttons["TabToolbar.tabsButton"].tap()
        }

        app.buttons["TabTrayController.maskButton"].tap()
        app.cells["Example Domain"].tap()

        XCTAssertFalse(TopSiteCellgroup.exists)
        XCTAssert(app.staticTexts["Example Domain"].exists)
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
        TopSiteCellgroup.cells[defaultTopSite["topSiteLabel"]!]
            .press(forDuration: 1)
        selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.goto(HomePanel_Bookmarks)
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
        // Bookmark a new TopSite
        navigator.openURL(urlString: newTopSite["url"]!)
        waitUntilPageLoad()
        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
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
        navigator.openURL(urlString: newTopSite["url"]!)
        waitUntilPageLoad()
        navigator.goto(TabTray)
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
        XCTAssertEqual(numberOfTopSites, UInt(numberOfExpectedTopSites), "The number of Top Sites is not correct")
    }

    func testOpenTopSitesFromContextMenu () {
         // Top Sites is shown by default
         waitforExistence(app.cells["TopSitesCell"])
         checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)

         // Go to a website
         navigator.openURL(urlString: newTopSite["url"]!)
         waitUntilPageLoad()

         // Go back to Top Sites from context menu
         navigator.browserPerformAction(.openTopSitesOption)
         checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    func testActivityStreamPages() {
        let pagecontrolButton = TopSiteCellgroup.buttons["Next Page"]
        XCTAssertFalse(pagecontrolButton.exists, "The Page Control button must not exist. Only 5 elements should be on the page")

        navigator.openURL(urlString: "http://example.com")
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "example.com")
        navigator.openURL(urlString: "http://mozilla.org")
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "mozilla.org")
        navigator.openURL(urlString: "http://apple.com")
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "apple.com")
        navigator.openURL(urlString: "http://slack.com")
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "slack.com")

        if iPad() {
            // Test timeout on BB when loading these pages
            navigator.openURL(urlString: "http://cvs.com")
            waitUntilPageLoad()
            waitForValueContains(app.textFields["url"], value: "cvs.com")
            navigator.openURL(urlString: "http://linkedin.com")
            waitUntilPageLoad()
            waitForValueContains(app.textFields["url"], value: "linkedin.com")
            navigator.openURL(urlString: "http://zara.com")
            waitUntilPageLoad()
            waitForValueContains(app.textFields["url"], value: "zara.com")
            navigator.openURL(urlString: "http://twitter.com")
            waitUntilPageLoad()
            waitForValueContains(app.textFields["url"], value: "twitter.com")
            navigator.openURL(urlString: "http://instagram.com")
            waitUntilPageLoad()
            waitForValueContains(app.textFields["url"], value: "instagram.com")
        }
        navigator.goto(URLBarOpen)
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
        XCUIDevice.shared().orientation = .landscapeLeft

        navigator.openURL(urlString: "http://example.com")
        waitUntilPageLoad()
        if app.buttons["URLBarView.backButton"].isEnabled {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.textFields["url"].tap()
        }
        TopSiteCellgroup.cells["example"].press(forDuration: 1)

        let contextMenuHeight = app.tables["Context Menu"].frame.size.height
        let parentViewHeight = app.otherElements["Action Sheet"].frame.size.height

        XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)

        // Go back to portrait mode
        XCUIDevice.shared().orientation = .portrait
    }
}
