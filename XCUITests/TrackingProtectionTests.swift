/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let standardBlockedElementsString = "Firefox blocks cross-site trackers, social trackers, cryptominers, and fingerprinters."
let strictBlockedElementsString = "Firefox blocks cross-site trackers, social trackers, cryptominers, fingerprinters, and tracking content."
let disabledStrictTPString = "No trackers known to Firefox were detected on this page."

let websiteWithBlockedElements = "twitter.com"
let differentWebsite = path(forTestPage: "test-example.html")

class TrackingProtectionTests: BaseTestCase {

    // Smoketest
    func testTrackingProtection() {
        navigator.goto(TrackingProtectionSettings)

        // Make sure ETP is enabled by default
        XCTAssertTrue(app.switches["prefkey.trackingprotection.normalbrowsing"].isEnabled)

        // Turn off ETP
        navigator.performAction(Action.SwitchETP)

        // Verify it is turned off
        navigator.goto(BrowserTab)
        waitUntilPageLoad()

        // Now there should not be any shield icon
        waitForNoExistence(app.buttons["TabLocationView.trackingProtectionButton"])
        navigator.goto(BrowserTab)

        // Switch to Private Browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(BrowserTab)
        waitUntilPageLoad()

        // Make sure TP is off also in PMB
        waitForNoExistence(app.buttons["TabLocationView.trackingProtectionButton"])
        // Enable TP again
        navigator.goto(TrackingProtectionSettings)
        // Turn on ETP
        navigator.performAction(Action.SwitchETP)
    }

    private func disableEnableTrackingProtectionForSite() {
        navigator.performAction(Action.TrackingProtectionperSiteToggle)
    }

    private func checkTrackingProtectionDisabledForSite() {
        waitForNoExistence(app.buttons["TabLocationView.trackingProtectionButton"])
    }

    private func checkTrackingProtectionEnabledForSite() {
        navigator.goto(TrackingProtectionContextMenuDetails)
        waitForExistence(app.cells.staticTexts["Enhanced Tracking Protection is ON for this site."])
    }

    private func enableStrictMode() {
        navigator.performAction(Action.EnableStrictMode)

        // Dismiss the alert and go back to the site
        app.alerts.buttons.firstMatch.tap()
        app.buttons["Done"].tap()
    }

    func testMenuWhenThereAreBlockedElements() {
        // Open website which has trackers blocked
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()
        // Open ETP menu
        navigator.goto(TrackingProtectionContextMenuDetails)

        // Verify that all elements for ETP menu are shown
        waitForExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.cells[standardBlockedElementsString].exists, "ETP menu with elements blocked is not right")

        // Enable Strict Mode from TP menu
        navigator.performAction(Action.OpenSettingsFromTPMenu)
        enableStrictMode()

        navigator.nowAt(BrowserTab)
        navigator.goto(TrackingProtectionContextMenuDetails)

        // Verify that all blocked elements for ETP menu are shown
        waitForExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.cells[strictBlockedElementsString].exists, "ETP menu with elements blocked is not right")
    }

    func testDisableETPforSiteIsKeptAfterBrowsing() {
        // Enable Strict TP
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()
        // Open ETP menu
        navigator.goto(TrackingProtectionContextMenuDetails)
        waitForExistence(app.tables["Context Menu"])

        // Enable Strict Mode from TP menu
        navigator.performAction(Action.OpenSettingsFromTPMenu)
        enableStrictMode()

        navigator.nowAt(BrowserTab)
        navigator.goto(TrackingProtectionContextMenuDetails)

        disableEnableTrackingProtectionForSite()
        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)

        // Go to a different site and verify that ETP is ON
        navigator.openNewURL(urlString: differentWebsite)
        waitUntilPageLoad()
        navigator.goto(TrackingProtectionContextMenuDetails)
        waitForExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.cells.images["enabled"].exists)
        XCTAssertTrue(app.tables.cells[strictBlockedElementsString].exists, "ETP menu with elements blocked is not right")
        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)

        // Go back to original site and verify that ETP is still OFF
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()
        navigator.goto(TrackingProtectionContextMenuDetails)
        XCTAssertFalse(app.cells.images["enabled"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts[disabledStrictTPString].exists, "ETP menu with elements blocked is not right")

        // Verify that ETP can be enabled again
        navigator.performAction(Action.TrackingProtectionperSiteToggle)
        XCTAssertTrue(app.cells.images["enabled"].exists)
    }

    func testBasicMoreInfo() {
        navigator.goto(TrackingProtectionSettings)
        // See Basic mode info
        app.cells["Settings.TrackingProtectionOption.BlockListBasic"].buttons["More Info"].tap()
        XCTAssertTrue(app.navigationBars["Client.TPAccessoryInfo"].exists)
        XCTAssertTrue(app.cells.staticTexts["Social Trackers"].exists)
        XCTAssertTrue(app.cells.staticTexts["Cross-Site Trackers"].exists)
        XCTAssertTrue(app.cells.staticTexts["Fingerprinters"].exists)
        XCTAssertTrue(app.cells.staticTexts["Cryptominers"].exists)
        XCTAssertFalse(app.cells.staticTexts["Tracking content"].exists)

        // Go back to TP settings
        app.buttons["Tracking Protection"].tap()

        // See Strict mode info
        app.cells["Settings.TrackingProtectionOption.BlockListStrict"].buttons["More Info"].tap()
        XCTAssertTrue(app.cells.staticTexts["Tracking content"].exists)

        // Go back to TP settings
        app.buttons["Tracking Protection"].tap()
    }
}
