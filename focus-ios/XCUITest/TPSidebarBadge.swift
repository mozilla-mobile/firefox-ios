/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class TrackingProtectionMenu: BaseTestCase {

    // Smoketest
    func testProtectionSidebar() {
        // Visit https://www.mozilla.org
        loadWebPage("mozilla.org")

        // Check the correct site is reached
        waitForWebPageLoad()

        // Open the tracking protection sidebar
        app.buttons["URLBar.trackingProtectionIcon"].tap()

        // Disable tracking protection
        waitForExistence(app.switches["BlockerToggle.TrackingProtection"])
        app.switches["BlockerToggle.TrackingProtection"].tap()

        // Reopen the tracking protection sidebar
        if !iPad() {
            app.buttons["closeSheetButton"].tap()
            app.buttons["URLBar.trackingProtectionIcon"].tap()
        }

        // Wait for the sidebar to open
        let switchValue = app.switches["BlockerToggle.TrackingProtection"].value!
        XCTAssertLessThan(switchValue as! String, "2")
    }
}
