/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class TrackingProtectionTests: BaseTestCase {
    // This test is to change the tracking protection to block known blockers

    func testTrackingProtection() {
        navigator.goto(TrackingProtectionSettings)

        // Make sure TP is enabled by default
        XCTAssertTrue(app.switches["prefkey.trackingprotection.normalbrowsing"].isEnabled)
        XCTAssertTrue(app.switches["prefkey.trackingprotection.privatebrowsing"].isEnabled)

        // Turn off TP in normal Browsing
        app.switches["prefkey.trackingprotection.normalbrowsing"].tap()

        navigator.goto(BrowserTabMenu)

        // Make sure its actually off
        XCTAssertTrue(app.cells["Tracking Protection"].images["disabled"].exists)

        // Switch to Private Browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(NewTabScreen)
        navigator.goto(BrowserTabMenu)

        XCTAssertTrue(app.cells["Tracking Protection"].images["enabled"].exists, "Tracking Protection should be switch on in PBM")

        // Turn off PBM
        app.cells["Tracking Protection"].tap()
        navigator.nowAt(BrowserTab)

        navigator.toggleOn(!userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(NewTabScreen)
        navigator.goto(TrackingProtectionSettings)

        // Make sure TP is off in both browsing modes.
        XCTAssertEqual(app.switches["prefkey.trackingprotection.normalbrowsing"].value as! String, "0")
        XCTAssertEqual(app.switches["prefkey.trackingprotection.privatebrowsing"].value as! String, "0")
    }
}
