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
        waitforHittable(element: app.tables.cells["settingsViewController.trackingCell"])
        app.tables.cells["settingsViewController.trackingCell"].tap()
        waitforExistence(element: app.tables.switches["BlockerToggle.BlockAnalytics"])

        // Disable 'block analytic trackers'
        app.tables.switches["BlockerToggle.BlockAnalytics"].tap()
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockAnalytics"].value as! String, "0")

        // Exit in-app settings
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Visit https://www.mozilla.org
        loadWebPage("mozilla.org")

        // Check the correct site is reached
        waitForWebPageLoad()

        // Open the tracking protection menu
        waitforHittable(element: app.otherElements["URLBar.trackingProtectionIcon"])
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the menu to open
        waitforExistence(element: app.staticTexts["Tracking Protection"])

        // Check for the existence of one (1) analytical tracker on Mozilla
        waitforExistence(element: app.staticTexts["Trackers blocked.Subtitle"])
        XCTAssertEqual(app.staticTexts["Trackers blocked.Subtitle"].label, "0")
        
        waitforExistence(element: app.staticTexts["Ad trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Ad trackers.Subtitle"].label, "0")
        
        waitforExistence(element: app.staticTexts["Analytic trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Analytic trackers.Subtitle"].label, "0")
        
        waitforExistence(element: app.staticTexts["Social trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Social trackers.Subtitle"].label, "0")
        
        waitforExistence(element: app.staticTexts["Content trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Content trackers.Subtitle"].label, "0")

        // Close the menu
        waitforHittable(element: app.buttons["PhotonMenu.close"])
        app.buttons["PhotonMenu.close"].tap()

        // Erase the history
        waitforHittable(element: app.buttons["URLBar.deleteButton"])
        app.buttons["URLBar.deleteButton"].tap()

        // Reset in-app settings (work-around until issue: #731)
        waitforHittable(element: app.buttons["Settings"])
        app.buttons["Settings"].tap()
        waitforHittable(element: app.tables.cells["settingsViewController.trackingCell"])
        app.tables.cells["settingsViewController.trackingCell"].tap()
        waitforExistence(element: app.tables.switches["BlockerToggle.BlockAnalytics"])

        // Re-enable 'block analytic trackers'
        app.tables.switches["BlockerToggle.BlockAnalytics"].tap()
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockAnalytics"].value as! String, "1")
    }

}
