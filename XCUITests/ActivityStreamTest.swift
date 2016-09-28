/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ActivityStreamTest: BaseTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDefaultSites() {
        let app = XCUIApplication()
        let topSites = app.tables["Top sites"].cells["TopSitesCell"]
        let numberOfTopSites = topSites.childrenMatchingType(.Other).matchingIdentifier("TopSite").count
        XCTAssertEqual(numberOfTopSites,5, "There should be a total of 5 default Top Sites.")
    }

    func testActivityStreamAdd() {
        let app = XCUIApplication()
        let topSites = app.tables["Top sites"].cells["TopSitesCell"]
        let numberOfTopSites = topSites.childrenMatchingType(.Other).matchingIdentifier("TopSite").count

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        let sitesAfter = topSites.childrenMatchingType(.Other).matchingIdentifier("TopSite").count
        XCTAssertTrue(sitesAfter == numberOfTopSites + 1, "A new site should have been added to the topSites")
    }

    func testActivityStreamDelete() {
        let app = XCUIApplication()
        let topSites = app.tables["Top sites"].cells["TopSitesCell"]
        let numberOfTopSites = topSites.childrenMatchingType(.Other).matchingIdentifier("TopSite").count

        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        let sitesAfter = topSites.childrenMatchingType(.Other).matchingIdentifier("TopSite").count
        XCTAssertTrue(sitesAfter == numberOfTopSites + 1, "A new site should have been added to the topSites")

        app.tables["Top sites"].otherElements["example"].pressForDuration(1) //example is the name of the domain. (example.com)
        app.sheets.elementBoundByIndex(0).buttons["Delete"].tap()
        let sitesAfterDelete = topSites.childrenMatchingType(.Other).matchingIdentifier("TopSite").count
        XCTAssertTrue(sitesAfterDelete == numberOfTopSites, "A site should have been deleted to the topSites")
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

        app.tables["Top sites"].otherElements["example"].pressForDuration(1)
        app.sheets.elementBoundByIndex(0).buttons["Delete"].tap()
        XCTAssertFalse(pagecontrolButton.exists, "The Page Control button should disappear after an item is deleted.")

    }
    
    
}
