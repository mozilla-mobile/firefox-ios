/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class TrackingProtectionSettings: BaseTestCase {

    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    func testInactiveSettings() {

        // Go to in-app settings
        waitforHittable(element: app.buttons["Settings"])
        app.buttons["Settings"].tap()
        waitforExistence(element: app.tables.switches["BlockerToggle.BlockAnalytics"])

        // Disable 'block analytic trackers'
        app.tables.switches["BlockerToggle.BlockAnalytics"].tap()
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockAnalytics"].value as! String, "0")

        // Exit in-app settings
        app.navigationBars["Settings"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()

        // Visit https://www.mozilla.org
        loadWebPage("mozilla.org")

        // Check the correct site is reached
        waitForWebPageLoad()

        // Check for the presence of the shield
        // Currently, Mozilla has one (1) analytical tracker that is un-blocked
        XCTAssertEqual(app.staticTexts["TrackingProtectionBadge.counterLabel"].label, "0")

        // Open the tracking protection sidebar
        waitforHittable(element: app.otherElements["URLBar.trackingProtectionIcon"])
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the sidebar to open
        waitforExistence(element: app.staticTexts["Tracking Protection"])

        // Check for the existence of one (1) analytical tracker on Mozilla
        let counters = app.staticTexts.matching(identifier: "TrackingProtectionBreakdownItem.counterLabel")

        XCTAssertEqual(counters.element(boundBy: 0).label, "0") // Ad Trackers
        XCTAssertEqual(counters.element(boundBy: 1).label, "0") // Analytical trackers
        XCTAssertEqual(counters.element(boundBy: 2).label, "0") // Social trackers
        XCTAssertEqual(counters.element(boundBy: 3).label, "0") // Content trackers

        // Close the sidebar
        waitforHittable(element: app.buttons["TrackingProtectionView.closeButton"])
        app.buttons["TrackingProtectionView.closeButton"].tap()

        // Erase the history
        waitforHittable(element: app.buttons["ERASE"])
        app.buttons["ERASE"].tap()

        // Reset in-app settings (work-around until issue: #731)
        waitforHittable(element: app.buttons["Settings"])
        app.buttons["Settings"].tap()
        waitforExistence(element: app.tables.switches["BlockerToggle.BlockAnalytics"])

        // Re-enable 'block analytic trackers'
        app.tables.switches["BlockerToggle.BlockAnalytics"].tap()
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockAnalytics"].value as! String, "1")
    }

}
