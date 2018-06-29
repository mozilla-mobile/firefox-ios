/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class TrackingProtectionSidebar: BaseTestCase {

    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    func testActiveProtectionSidebar() {

        // Visit https://www.mozilla.org
        loadWebPage("mozilla.org")

        // Check the correct site is reached
        waitForWebPageLoad()

        // Check for the presence of the shield
        // Currently, Mozilla has one (1) analytical tracker
        XCTAssertEqual(app.staticTexts["TrackingProtectionBadge.counterLabel"].label, "1")

        // Open the tracking protection sidebar
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the sidebar to open
        waitforExistence(element: app.staticTexts["Tracking Protection"])

        // Check for the tracker count in the sidebar
        var counters = app.staticTexts.matching(identifier: "TrackingProtectionBreakdownItem.counterLabel")

        // Check for the existence of one (1) analytical tracker on Mozilla
        XCTAssertEqual(counters.element(boundBy: 0).label, "0") // Ad Trackers
        XCTAssertEqual(counters.element(boundBy: 1).label, "1") // Analytical trackers
        XCTAssertEqual(counters.element(boundBy: 2).label, "0") // Social trackers
        XCTAssertEqual(counters.element(boundBy: 3).label, "0") // Content trackers

        // Close the sidebar
        app.buttons["TrackingProtectionView.closeButton"].tap()

        // Erase the history
        app.buttons["ERASE"].tap()
        waitforExistence(element: app.staticTexts["Your browsing history has been erased."])

        // Load another website known for zero (0) trackers
        loadWebPage("http://localhost:6573/licenses.html\n")
        waitForWebPageLoad()

        // Check for the presence of the shield
        // Check for the presence of zero (0) trackers
        XCTAssertEqual(app.staticTexts["TrackingProtectionBadge.counterLabel"].label, "0")

        // Open the tracking protection sidebar
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the sidebar to open
        waitforExistence(element: app.staticTexts["Tracking Protection"])

        // Check for the tracker count in the sidebar
        counters = app.staticTexts.matching(identifier: "TrackingProtectionBreakdownItem.counterLabel")
        for i in 0..<counters.staticTexts.count {
            XCTAssertEqual(counters.element(boundBy: i).label, "0")
        }

        // Close the sidebar
        app.buttons["TrackingProtectionView.closeButton"].tap()

        // Erase the history
        waitforExistence(element: app.buttons["ERASE"])
        app.buttons["ERASE"].tap()
        waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
    }

    func testInactiveProtectionSidebar() {

        // Visit https://www.mozilla.org
        loadWebPage("mozilla.org")

        // Check the correct site is reached
        waitForWebPageLoad()

        // Open the tracking protection sidebar
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the sidebar to open
        waitforExistence(element: app.staticTexts["Tracking Protection"])

        // Disable tracking protection
        waitforExistence(element: app.switches["TrackingProtectionToggleView.toggleTrackingProtection"])
        app.switches["TrackingProtectionToggleView.toggleTrackingProtection"].tap()

        // Reopen the tracking protection sidebar
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the sidebar to open
        waitforExistence(element: app.staticTexts["Tracking Protection"])

        // Check for the tracker count in the sidebar
        let counters = app.staticTexts.matching(identifier: "TrackingProtectionBreakdownItem.counterLabel")

        for i in 0..<counters.staticTexts.count {
            XCTAssertEqual(counters.element(boundBy: i).label, "--")
        }

        // Close the sidebar
        app.buttons["TrackingProtectionView.closeButton"].tap()
        waitforNoExistence(element: app.staticTexts["TrackingProtectionToggleView.toggleTrackingProtection"])

        // Check that no counter exists (tracking protection: disabled)
        XCTAssertEqual(app.staticTexts["TrackingProtectionBadge.counterLabel"].exists, false)

        // Erase the history
        waitforExistence(element: app.buttons["ERASE"])
        app.buttons["ERASE"].tap()
        waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
    }
}
