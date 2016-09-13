/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ResetOptionsTest: BaseTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testResetLaunchOptions() {
        let app = XCUIApplication()
        let topSites = app.tables["Top sites"].cells["TopSitesCell"]
        let numberOfTopSites = topSites.childrenMatchingType(.Other).matchingIdentifier("TopSite").count
        // Vist a webpage to add it to TopSites
        loadWebPage("http://example.com")
        app.buttons["TabToolbar.backButton"].tap()

        // I need to sleep before terminating to make sure the page loads and the domain is added to the topSites
        sleep(2)
        restart(app, reset: false)

        // Now check to make sure app was not reset
        XCTAssertTrue(topSites.childrenMatchingType(.Other).matchingIdentifier("TopSite").count == numberOfTopSites + 1, "A new site should have been added to the topSites")

        // Check to make sure topSites reset
        restart(app, reset: true)
        XCTAssertTrue(topSites.childrenMatchingType(.Other).matchingIdentifier("TopSite").count == numberOfTopSites, "Only the default topSites should exist")
    }


}


