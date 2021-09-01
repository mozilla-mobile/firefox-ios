/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class TrackingProtectionMenu: BaseTestCase {

    // Smoketest
    func testActiveProtectionSidebar() throws {
        throw XCTSkip("Skipping this test because the PR is just for the new design")
        //reactivate test after the functionality will be added
        
        // Visit https://www.mozilla.org
        loadWebPage("mozilla.org")

        // Check the correct site is reached
        waitForWebPageLoad()

        // Open the tracking protection sidebar
        waitForExistence(app.otherElements["URLBar.trackingProtectionIcon"])
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for menu to open
        waitForExistence(app.staticTexts["Tracking Protection"])

        // Check for the existence of one (1) analytical tracker on Mozilla
        waitForExistence(app.staticTexts["Trackers blocked.Subtitle"])
        // Klar sometimes shows 2 instead of 1
        if (app.staticTexts["Trackers blocked.Subtitle"].label == "1") {
            XCTAssertEqual(app.staticTexts["Trackers blocked.Subtitle"].label, "1")
        } else {
            XCTAssertEqual(app.staticTexts["Trackers blocked.Subtitle"].label, "2")
        }

        waitForExistence(app.staticTexts["Ad trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Ad trackers.Subtitle"].label, "0")

        waitForExistence(app.staticTexts["Analytic trackers.Subtitle"])
        // Klar sometimes shows 2 instead of 1
        if (app.staticTexts["Analytic trackers.Subtitle"].label == "1") {
            XCTAssertEqual(app.staticTexts["Analytic trackers.Subtitle"].label, "1")
        } else {
            XCTAssertEqual(app.staticTexts["Analytic trackers.Subtitle"].label, "2")
        }

        waitForExistence(app.staticTexts["Social trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Social trackers.Subtitle"].label, "0")

        waitForExistence(app.staticTexts["Content trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Content trackers.Subtitle"].label, "0")

        // Close the menu
        waitForHittable(app.buttons["PhotonMenu.close"])
        app.buttons["PhotonMenu.close"].tap()

        // Erase the history
        waitForExistence(app.buttons["URLBar.deleteButton"])
        app.buttons["URLBar.deleteButton"].firstMatch.tap()
        waitForExistence(app.staticTexts["Your browsing history has been erased."])

        // Load another website known for zero (0) trackers
        loadWebPage("https://www.example.com\n")
        waitForWebPageLoad()

        // Open the tracking protection menu
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the menu to open
        waitForExistence(app.staticTexts["Tracking Protection"])

        // Check tracker values
        waitForZeroTrackers()

        // Close the menu
        waitForHittable(app.buttons["PhotonMenu.close"])
        app.buttons["PhotonMenu.close"].tap()

        // Erase the history
        waitForExistence(app.buttons["URLBar.deleteButton"])
        app.buttons["URLBar.deleteButton"].firstMatch.tap()
        waitForExistence(app.staticTexts["Your browsing history has been erased."])
    }

    func testInactiveProtectionSidebar() {

        // Visit https://www.mozilla.org
        loadWebPage("mozilla.org")

        // Check the correct site is reached
        waitForWebPageLoad()

        // Open the tracking protection sidebar
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the sidebar to open
        waitForExistence(app.staticTexts["Tracking Protection"])

        // Disable tracking protection
        waitForExistence(app.switches["Tracking Protection.Toggle"])
        app.switches["Tracking Protection.Toggle"].tap()

        // Reopen the tracking protection sidebar
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the sidebar to open
        waitForExistence(app.staticTexts["Tracking Protection"])

        // Check tracker values
        waitForZeroTrackers()

        // Close the menu
        waitForHittable(app.buttons["PhotonMenu.close"])
        app.buttons["PhotonMenu.close"].tap()

        // Erase the history
        waitForHittable(app.buttons["URLBar.deleteButton"])
        app.buttons["URLBar.deleteButton"].tap()
        waitForExistence(app.staticTexts["Browsing history cleared"])
    }

    private func waitForZeroTrackers() {
        // Check for all 0 tracker count values in menu
        waitForExistence(app.staticTexts["Trackers blocked.Subtitle"])
        XCTAssertEqual(app.staticTexts["Trackers blocked.Subtitle"].label, "0")

        waitForExistence(app.staticTexts["Ad trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Ad trackers.Subtitle"].label, "0")

        waitForExistence(app.staticTexts["Analytic trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Analytic trackers.Subtitle"].label, "0")

        waitForExistence(app.staticTexts["Social trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Social trackers.Subtitle"].label, "0")

        waitForExistence(app.staticTexts["Content trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Content trackers.Subtitle"].label, "0")
    }
}
