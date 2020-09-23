/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let blockedElementsString = "Firefox is blocking parts of the page that may track your browsing."
let tpIsDisabledViaToggleString = "Block online trackers"
let tpIsDisabledString = "The site includes elements that may track your browsing. You have disabled protection."
let noTrackingElementsString = "tp.no-trackers-blocked"

let websiteWithBlockedElements = "twitter.com"
let websiteWithoutBlockedElements = "wikipedia.com"
let differentWebsite = path(forTestPage: "test-example.html")

class TrackingProtectionTests: BaseTestCase {

    override func tearDown() {
        // Enable TP for visited sites for next tests
        navigator.goto(BrowserTab)
        navigator.openNewURL(urlString: websiteWithBlockedElements)
        waitUntilPageLoad()
        navigator.goto(TrackingProtectionContextMenuDetails)
        if (app.cells.staticTexts["Enhanced Tracking Protection is OFF for this site"].exists) {
            app.cells.staticTexts["Enhanced Tracking Protection is OFF for this site"].tap()
        }
    }

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

    private func disableTrackingProtectionForSite() {
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()

        // Disable TP for this site
        navigator.performAction(Action.TrackingProtectionperSiteToggle)
    }

    private func checkTrackingProtectionDisabledForSite() {
        app.buttons["TabLocationView.trackingProtectionButton"].tap()
        waitForExistence(app.cells.staticTexts["Enhanced Tracking Protection is OFF for this site."], timeout: 5)
        navigator.nowAt(TrackingProtectionContextMenuDetails)
    }

    private func checkTrackingProtectionEnabledForSite() {
        navigator.goto(TrackingProtectionContextMenuDetails)
        waitForExistence(app.cells.staticTexts["Enhanced Tracking Protection is ON for this site."])
    }

    func testMenuWhenThereAreBlockedElements() {
        // Open website which has trackers blocked
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()
        // Open ETP menu
        navigator.goto(TrackingProtectionContextMenuDetails)

        // Verify that all elements for ETP menu are shown
        waitForExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.cells["tp-cookie"].exists, "ETP menu with elements blocked is not right")
        XCTAssertTrue(app.tables.cells["settings"].exists, "Settings option does not appear")

        // Tap on social trackers
        app.cells["tp-cookie"].tap()
        XCTAssertTrue(app.tables.cells.count > 0)
        app.cells["goBack"].tap()
    }

    func testMenuWhenThereAreNotBlockedElements() {
        navigator.openURL(websiteWithoutBlockedElements)
        waitUntilPageLoad()

        // Open ETP menu and check view with no blocked elements
        navigator.goto(TrackingProtectionContextMenuDetails)
        waitForExistence(app.tables.cells.staticTexts[noTrackingElementsString])
        XCTAssertTrue(app.tables.cells.staticTexts[noTrackingElementsString].exists, "TP menu is wrong when there are not blocking elements")
    }

    // Smoketest
    /* Disable due to update ETP to ITP
    func testEnableDisableTPforSite() {
        disableTrackingProtectionForSite()
        waitUntilPageLoad()
        navigator.goto(BrowserTab)
        // Now at browser tab check TP is disabled for this site
        checkTrackingProtectionDisabledForSite()
        navigator.nowAt(TrackingProtectionContextMenuDetails)
        navigator.performAction(Action.CloseTPContextMenu)

        // Enable TP again and check it in Browser tab
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.TrackingProtectionperSiteToggle)
        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)
        checkTrackingProtectionEnabledForSite()
        navigator.nowAt(TrackingProtectionContextMenuDetails)
        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)
    }*/

    func testDisableForSiteDoesNotDisableForOthersSameTab() {
        disableTrackingProtectionForSite()
        navigator.goto(URLBarOpen)
        userState.url = differentWebsite
        navigator.performAction(Action.LoadURLByTyping)
        waitUntilPageLoad()

        checkTrackingProtectionEnabledForSite()
        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)
    }

    func testDisableForSiteDoesNotDisableForOthersDifferentTab() {
        disableTrackingProtectionForSite()
        navigator.openNewURL(urlString: differentWebsite)
        waitUntilPageLoad()

        checkTrackingProtectionEnabledForSite()
        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)
    }

    func testDisableforSiteIsKeptAfterBrowsing() {
        disableTrackingProtectionForSite()

        navigator.openNewURL(urlString: differentWebsite)
        waitUntilPageLoad()
        checkTrackingProtectionEnabledForSite()

        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)
        navigator.openNewURL(urlString: websiteWithBlockedElements)
        waitUntilPageLoad()
        checkTrackingProtectionDisabledForSite()
        navigator.goto(BrowserTab)
    }

    func testDisablingTPforOneSiteDoesNotChangeGeneralTPOption() {
        disableTrackingProtectionForSite()

        navigator.goto(TrackingProtectionSettings)
        XCTAssertTrue(app.switches["prefkey.trackingprotection.normalbrowsing"].isEnabled)
    }

    func testOpenSettingsFromTPcontextMenu() {
        // Open website which has trackers blocked
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()
        // Open ETP menu
        navigator.goto(TrackingProtectionContextMenuDetails)
        navigator.performAction(Action.OpenSettingsFromTPMenu)
        navigator.nowAt(TrackingProtectionSettings)
        // Turn off ETP
        navigator.performAction(Action.SwitchETP)
        // Go back to the site
        app.buttons["Done"].tap()
        app.buttons["Reload"].tap()
        waitUntilPageLoad()
        waitForNoExistence(app.buttons["TabLocationView.trackingProtectionButton"])
        navigator.nowAt(BrowserTab)
        navigator.goto(TrackingProtectionSettings)
        // Turn on ETP
        // Ask if bug, need to reload to see the shield icon again once it is turned on from settings
        navigator.performAction(Action.SwitchETP)
        app.buttons["Settings"].tap()
        app.buttons["Done"].tap()
        app.buttons["Reload"].tap()
        waitUntilPageLoad()
        waitForExistence(app.buttons["TabLocationView.trackingProtectionButton"])
        navigator.nowAt(BrowserTab)
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
