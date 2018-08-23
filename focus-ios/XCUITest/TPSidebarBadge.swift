/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class TrackingProtectionMenu: BaseTestCase {

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

        // Open the tracking protection sidebar
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for menu to open
        waitforExistence(element: app.staticTexts["Tracking Protection"])
        
        // Check for the existence of one (1) analytical tracker on Mozilla
        waitforExistence(element: app.staticTexts["Trackers blocked.Subtitle"])
        XCTAssertEqual(app.staticTexts["Trackers blocked.Subtitle"].label, "1")
        
        waitforExistence(element: app.staticTexts["Ad trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Ad trackers.Subtitle"].label, "0")
        
        waitforExistence(element: app.staticTexts["Analytic trackers.Subtitle"])
        XCTAssertEqual(app.staticTexts["Analytic trackers.Subtitle"].label, "1")
        
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
        waitforExistence(element: app.staticTexts["Your browsing history has been erased."])

        // Load another website known for zero (0) trackers
        loadWebPage("http://localhost:6573/licenses.html\n")
        waitForWebPageLoad()

        // Open the tracking protection menu
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the menu to open
        waitforExistence(element: app.staticTexts["Tracking Protection"])

        // Check tracker values
        waitForZeroTrackers()

        // Close the menu
        waitforHittable(element: app.buttons["PhotonMenu.close"])
        app.buttons["PhotonMenu.close"].tap()

        // Erase the history
        waitforHittable(element: app.buttons["URLBar.deleteButton"])
        app.buttons["URLBar.deleteButton"].tap()
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
        waitforExistence(element: app.switches["Tracking Protection.Toggle"])
        app.switches["Tracking Protection.Toggle"].tap()

        // Reopen the tracking protection sidebar
        app.otherElements["URLBar.trackingProtectionIcon"].tap()

        // Wait for the sidebar to open
        waitforExistence(element: app.staticTexts["Tracking Protection"])

        // Check tracker values
        waitForZeroTrackers()

        // Close the menu
        waitforHittable(element: app.buttons["PhotonMenu.close"])
        app.buttons["PhotonMenu.close"].tap()
        
        // Erase the history
        waitforHittable(element: app.buttons["URLBar.deleteButton"])
        app.buttons["URLBar.deleteButton"].tap()
        waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
    }
    
    private func waitForZeroTrackers() {
        // Check for all 0 tracker count values in menu
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
    }
}
