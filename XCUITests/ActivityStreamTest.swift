/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ActivityStreamTest: BaseTestCase {

    override func setUp() {
        
        super.setUp()
        dismissFirstRunUI()  //should be deprecated
    }

    override func tearDown() {
        super.tearDown()
    }

    // Tests disabled till bug 1352959 https://bugzilla.mozilla.org/show_bug.cgi?id=1352959 is fixed
    /*
    func testDefaultSites() {
        let app = XCUIApplication()
        let topSites = app.tables["Top sites"].cells["TopSitesCell"]
        let numberOfTopSites = topSites.children(matching: .other).matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, 5, "There should be a total of 5 default Top Sites.")
    }

    func testTopSitesAdd() {
        let app = XCUIApplication()
        let topSites = app.tables["Top sites"].cells["TopSitesCell"]
        let numberOfTopSites = topSites.children(matching: .other).matching(identifier: "TopSite").count

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        let sitesAfter = topSites.children(matching: .other).matching(identifier: "TopSite").count
        XCTAssertTrue(sitesAfter == numberOfTopSites + 1, "A new site should have been added to the topSites")
    }

    func testTopSitesRemove() {
        let app = XCUIApplication()
        let topSites = app.tables["Top sites"].cells["TopSitesCell"]
        let numberOfTopSites = topSites.children(matching: .other).matching(identifier: "TopSite").count

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        let sitesAfter = topSites.children(matching: .other).matching(identifier: "TopSite").count
        XCTAssertTrue(sitesAfter == numberOfTopSites + 1, "A new site should have been added to the topSites")

        app.tables["Top sites"].otherElements["example"].press(forDuration: 1) //example is the name of the domain. (example.com)
        app.tables["Context Menu"].cells["Remove"].tap()
        
        let sitesAfterDelete = topSites.children(matching: .other).matching(identifier: "TopSite").count
        XCTAssertTrue(sitesAfterDelete == numberOfTopSites, "A site should have been deleted to the topSites")
    }

    func testTopSitesOpenInNewTab() {
        let app = XCUIApplication()

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        app.tables["Top sites"].otherElements["example"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Tab"].tap()
        
        XCTAssert(app.tables["Top sites"].exists)
        XCTAssertFalse(app.staticTexts["Example Domain"].exists)
        
        app.buttons["URLBarView.tabsButton"].tap()
        app.cells["Example Domain"].tap()
        
        XCTAssertFalse(app.tables["Top sites"].exists)
        XCTAssert(app.staticTexts["Example Domain"].exists)
    }

    func testTopSitesOpenInNewPrivateTab() {
        let app = XCUIApplication()
        
        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()
        
        app.tables["Top sites"].otherElements["example"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Open in New Private Tab"].tap()
        
        XCTAssert(app.tables["Top sites"].exists)
        XCTAssertFalse(app.staticTexts["example"].exists)
        
        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.maskButton"].tap()
        app.cells["Example Domain"].tap()
        
        XCTAssertFalse(app.tables["Top sites"].exists)
        XCTAssert(app.staticTexts["Example Domain"].exists)
    }

    func testActivityStreamPages() {
        let app = XCUIApplication()
        let topSitesTable = app.tables["Top sites"]
        let pagecontrolButton = topSitesTable.buttons["pageControl"]
        XCTAssertFalse(pagecontrolButton.exists, "The Page Control button must not exist. Only 5 elements should be on the page")

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        loadWebPage("http://mozilla.org")
        app.buttons["TabToolbar.backButton"].tap()

        XCTAssert(pagecontrolButton.exists, "The Page Control button must exist if more than 6 elements are displayed.")
        pagecontrolButton.tap()
        pagecontrolButton.tap()

        // Sleep so the pageControl animation finishes.
        sleep(2)

        app.tables["Top sites"].otherElements["example"].press(forDuration: 1)
        app.tables["Context Menu"].cells["Remove"].tap()
        XCTAssertFalse(pagecontrolButton.exists, "The Page Control button should disappear after an item is deleted.")

    }
    
    func testContextMenuInLandscape() {
        XCUIDevice.shared().orientation = .landscapeLeft
        let app = XCUIApplication()

        loadWebPage("http://example.com")
        app.buttons["URLBarView.backButton"].tap()
        app.tables["Top sites"].otherElements["example"].press(forDuration: 1)

        let contextMenuHeight = app.tables["Context Menu"].frame.size.height
        let parentViewHeight = app.otherElements["Action Overlay"].frame.size.height

        XCTAssertLessThanOrEqual(contextMenuHeight, parentViewHeight)
    }
*/
}
