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
let differentWebsite = Base.helper.path(forTestPage: "test-example.html")

class TrackingProtectionTests: BaseTestCase {

    override func tearDown() {
        // Enable TP for visited sites for next tests
        navigator.goto(BrowserTab)
        navigator.openNewURL(urlString: websiteWithBlockedElements)
        Base.helper.waitUntilPageLoad()
        navigator.goto(TrackingProtectionContextMenuDetails)
        if (Base.app.cells.staticTexts["Enhanced Tracking Protection is OFF for this site"].exists) {
            Base.app.cells.staticTexts["Enhanced Tracking Protection is OFF for this site"].tap()
        }
    }

    // Smoketest
    func testTrackingProtection() {
        navigator.goto(TrackingProtectionSettings)

        // Make sure ETP is enabled by default
        XCTAssertTrue(Base.app.switches["prefkey.trackingprotection.normalbrowsing"].isEnabled)

        // Turn off ETP
        navigator.performAction(Action.SwitchETP)

        // Verify it is turned off
        navigator.goto(BrowserTab)
        Base.helper.waitUntilPageLoad()

        // Now there should not be any shield icon
        Base.helper.waitForNoExistence(Base.app.buttons["TabLocationView.trackingProtectionButton"])
        navigator.goto(BrowserTab)

        // Switch to Private Browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(BrowserTab)
        Base.helper.waitUntilPageLoad()

        // Make sure TP is off also in PMB
        Base.helper.waitForNoExistence(Base.app.buttons["TabLocationView.trackingProtectionButton"])
        // Enable TP again
        navigator.goto(TrackingProtectionSettings)
        // Turn on ETP
        navigator.performAction(Action.SwitchETP)
    }

    private func disableTrackingProtectionForSite() {
        navigator.openURL(websiteWithBlockedElements)
        Base.helper.waitUntilPageLoad()

        // Disable TP for this site
        navigator.performAction(Action.TrackingProtectionperSiteToggle)
    }

    private func checkTrackingProtectionDisabledForSite() {
        Base.app.buttons["TabLocationView.trackingProtectionButton"].tap()
        Base.helper.waitForExistence(Base.app.cells.staticTexts["Enhanced Tracking Protection is OFF for this site."], timeout: 5)
        navigator.nowAt(TrackingProtectionContextMenuDetails)
    }

    private func checkTrackingProtectionEnabledForSite() {
        navigator.goto(TrackingProtectionContextMenuDetails)
        Base.helper.waitForExistence(Base.app.cells.staticTexts["Enhanced Tracking Protection is ON for this site."])
    }

    func testMenuWhenThereAreBlockedElements() {
        // Open website which has trackers blocked
        navigator.openURL(websiteWithBlockedElements)
        Base.helper.waitUntilPageLoad()
        // Open ETP menu
        navigator.goto(TrackingProtectionContextMenuDetails)

        // Verify that all elements for ETP menu are shown
        Base.helper.waitForExistence(Base.app.tables["Context Menu"])
        XCTAssertTrue(Base.app.tables.cells["tp-cookie"].exists, "ETP menu with elements blocked is not right")
        XCTAssertTrue(Base.app.tables.cells["settings"].exists, "Settings option does not appear")

        // Tap on social trackers
        Base.app.cells["tp-cookie"].tap()
        XCTAssertTrue(Base.app.tables.cells.count > 0)
        Base.app.cells["goBack"].tap()
    }

    func testMenuWhenThereAreNotBlockedElements() {
        navigator.openURL(websiteWithoutBlockedElements)
        Base.helper.waitUntilPageLoad()

        // Open ETP menu and check view with no blocked elements
        navigator.goto(TrackingProtectionContextMenuDetails)
        Base.helper.waitForExistence(Base.app.tables.cells.staticTexts[noTrackingElementsString])
        XCTAssertTrue(Base.app.tables.cells.staticTexts[noTrackingElementsString].exists, "TP menu is wrong when there are not blocking elements")
    }

    // Smoketest
    func testEnableDisableTPforSite() {
        disableTrackingProtectionForSite()
        Base.helper.waitUntilPageLoad()
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
    }

    func testDisableForSiteDoesNotDisableForOthersSameTab() {
        disableTrackingProtectionForSite()
        navigator.goto(URLBarOpen)
        userState.url = differentWebsite
        navigator.performAction(Action.LoadURLByTyping)
        Base.helper.waitUntilPageLoad()

        checkTrackingProtectionEnabledForSite()
        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)
    }

    func testDisableForSiteDoesNotDisableForOthersDifferentTab() {
        disableTrackingProtectionForSite()
        navigator.openNewURL(urlString: differentWebsite)
        Base.helper.waitUntilPageLoad()

        checkTrackingProtectionEnabledForSite()
        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)
    }

    func testDisableforSiteIsKeptAfterBrowsing() {
        disableTrackingProtectionForSite()

        navigator.openNewURL(urlString: differentWebsite)
        Base.helper.waitUntilPageLoad()
        checkTrackingProtectionEnabledForSite()

        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)
        navigator.openNewURL(urlString: websiteWithBlockedElements)
        Base.helper.waitUntilPageLoad()
        checkTrackingProtectionDisabledForSite()
        navigator.goto(BrowserTab)
    }

    func testDisablingTPforOneSiteDoesNotChangeGeneralTPOption() {
        disableTrackingProtectionForSite()

        navigator.goto(TrackingProtectionSettings)
        XCTAssertTrue(Base.app.switches["prefkey.trackingprotection.normalbrowsing"].isEnabled)
    }

    func testOpenSettingsFromTPcontextMenu() {
        // Open website which has trackers blocked
        navigator.openURL(websiteWithBlockedElements)
        Base.helper.waitUntilPageLoad()
        // Open ETP menu
        navigator.goto(TrackingProtectionContextMenuDetails)
        navigator.performAction(Action.OpenSettingsFromTPMenu)
        navigator.nowAt(TrackingProtectionSettings)
        // Turn off ETP
        navigator.performAction(Action.SwitchETP)
        // Go back to the site
        Base.app.buttons["Done"].tap()
        Base.app.buttons["Reload"].tap()
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForNoExistence(Base.app.buttons["TabLocationView.trackingProtectionButton"])
        navigator.nowAt(BrowserTab)
        navigator.goto(TrackingProtectionSettings)
        // Turn on ETP
        // Ask if bug, need to reload to see the shield icon again once it is turned on from settings
        navigator.performAction(Action.SwitchETP)
        Base.app.buttons["Settings"].tap()
        Base.app.buttons["Done"].tap()
        Base.app.buttons["Reload"].tap()
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.buttons["TabLocationView.trackingProtectionButton"])
        navigator.nowAt(BrowserTab)
    }

    func testBasicMoreInfo() {
        navigator.goto(TrackingProtectionSettings)
        // See Basic mode info
        Base.app.cells["Settings.TrackingProtectionOption.BlockListBasic"].buttons["More Info"].tap()
        XCTAssertTrue(Base.app.navigationBars["Client.TPAccessoryInfo"].exists)
        XCTAssertTrue(Base.app.cells.staticTexts["Social Trackers"].exists)
        XCTAssertTrue(Base.app.cells.staticTexts["Cross-Site Trackers"].exists)
        XCTAssertTrue(Base.app.cells.staticTexts["Fingerprinters"].exists)
        XCTAssertTrue(Base.app.cells.staticTexts["Cryptominers"].exists)
        XCTAssertFalse(Base.app.cells.staticTexts["Tracking content"].exists)

        // Go back to TP settings
        Base.app.buttons["Tracking Protection"].tap()

        // See Strict mode info
        Base.app.cells["Settings.TrackingProtectionOption.BlockListStrict"].buttons["More Info"].tap()
        XCTAssertTrue(Base.app.cells.staticTexts["Tracking content"].exists)

        // Go back to TP settings
        Base.app.buttons["Tracking Protection"].tap()
    }
}
