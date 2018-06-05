/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let blockedElementsString = "Firefox is blocking parts of the page that may track your browsing."
let tpIsDisabledViaToggleString = "Block online trackers"
let tpIsDisabledString = "The site includes elements that may track your browsing. You have disabled protection."
let noTrackingElementsString = "No tracking elements detected on this page."

let websiteWithBlockedElements = "twitter.com"
let websiteWithoutBlockedElements = "wikipedia.com"
let differentWebsite = "mozilla.org"

class TrackingProtectionTests: BaseTestCase {

   override func tearDown() {
        // Enable TP for visited sites for next tests
        navigator.goto(BrowserTab)
        navigator.openNewURL(urlString: websiteWithBlockedElements)
        waitUntilPageLoad()
        navigator.performAction(Action.TrackingProtectionContextMenu)
        if (app.tables.cells["menu-TrackingProtection"].exists) {
            app.tables.cells["menu-TrackingProtection"].tap()
        }
    }

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
        navigator.performAction(Action.ToggleTrackingProtection)

        navigator.toggleOn(!userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(NewTabScreen)
        navigator.goto(TrackingProtectionSettings)

        // Make sure TP is off in both browsing modes.
        XCTAssertEqual(app.switches["prefkey.trackingprotection.normalbrowsing"].value as! String, "0")
        XCTAssertEqual(app.switches["prefkey.trackingprotection.privatebrowsing"].value as! String, "0")
    }

    private func disableTrackingProtectionForSite() {
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()

        // Disable TP for this site
        navigator.performAction(Action.DisableTrackingProtectionperSite)
        waitUntilPageLoad()
    }

    private func checkTrackingProtectionDisabledForSite() {
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarLongPressMenu)

        waitforExistence(app.tables.cells["menu-TrackingProtection-Off"])
        XCTAssertTrue(app.tables.cells["menu-TrackingProtection-Off"].staticTexts[tpIsDisabledString].exists, "TP menu is wrong when blocking elements")
    }

    private func checkTrackingProtectionEnabledForSite() {
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarLongPressMenu)
        waitforExistence(app.tables.cells["menu-TrackingProtection"])
        XCTAssertTrue(app.tables.cells["menu-TrackingProtection"].staticTexts[blockedElementsString].exists, "TP menu is wrong when blocking elements")
    }

    func testTrackingProtectionToggle() {
        navigator.goto(BrowserTabMenu)
        // Check that TP is enabled by default
        XCTAssertTrue(app.tables.cells["menu-TrackingProtection"].images["enabled"].exists, "Tracking Protection is not enabled by default")

        // Go to a website with/without blocked elements ADAPT THE MESSAGE TO ASSERT
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()
        navigator.goto(URLBarLongPressMenu)

        waitforExistence(app.tables.cells["menu-TrackingProtection"])
        XCTAssertTrue(app.tables.cells["menu-TrackingProtection"].staticTexts[blockedElementsString].exists, "TP menu is wrong when blocking elements")

        // Now disable TP from Brwoser Tab menu
        navigator.performAction(Action.ToggleTrackingProtection)
        navigator.goto(BrowserTab)

        // Reload and check the website (or go to a different one? what would be best option???)
        app.buttons["Reload"].tap()
        waitUntilPageLoad()

        navigator.goto(URLBarLongPressMenu)
        XCTAssertTrue(app.tables.cells["menu-TrackingProtection"].staticTexts[tpIsDisabledViaToggleString].exists, "TP menu is wrong when blocking elements")
    }

    func testMenuWhenThereAreBlockedElements() {
        // Open website which has trackers blocked
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()
        navigator.performAction(Action.TrackingProtectionContextMenu)

        // Verify that all elements for TP menu are shown
        waitforExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.cells["Total trackers blocked"].exists, "TP menu with elements blocked is not right")
        XCTAssertTrue(app.tables.cells["Ad trackers"].exists, "TP menu with elements blocked is not right")
        XCTAssertTrue(app.tables.cells["Analytic trackers"].exists, "TP menu with elements blocked is not right")
        XCTAssertTrue(app.tables.cells["Social trackers"].exists, "TP menu with elements blocked is not right")
        XCTAssertTrue(app.tables.cells["Content trackers"].exists, "TP menu with elements blocked is not right")
        XCTAssertTrue(app.tables.cells["menu-TrackingProtection-Off"].exists, "TP menu with elements blocked is not right")
    }

    func testMenuWhenThereAreNotBlockedElements() {
        navigator.openURL(websiteWithoutBlockedElements)
        waitUntilPageLoad()
        navigator.goto(URLBarLongPressMenu)
        waitforExistence(app.tables.cells["menu-TrackingProtection"].staticTexts[noTrackingElementsString])
        XCTAssertTrue(app.tables.cells["menu-TrackingProtection"].staticTexts[noTrackingElementsString].exists, "TP menu is wrong when blocking elements")
    }

    func testEnableDisableTPforSite() {
        disableTrackingProtectionForSite()

        // Now at browser tab check TP is disabled for this site
        checkTrackingProtectionDisabledForSite()

        // Enable TP again and check it in Browser tab
        navigator.performAction(Action.EnableTrackingProtectionperSite)
        waitUntilPageLoad()

        checkTrackingProtectionEnabledForSite()
    }

    func testTPMenuHomePanel() {
        navigator.goto(URLBarLongPressMenu)
        waitforExistence(app.tables.cells["menu-TrackingProtection"])
        XCTAssertTrue(app.tables.cells["menu-TrackingProtection"].staticTexts[noTrackingElementsString].exists, "TP incorrectly shown when no blocking elements")
    }

    func testDisableForSiteDoesNotDisableForOthersSameTab() {
        disableTrackingProtectionForSite()
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        userState.url = differentWebsite
        navigator.performAction(Action.LoadURLByTyping)
        waitUntilPageLoad()

        checkTrackingProtectionEnabledForSite()
    }

    func testDisableForSiteDoesNotDisableForOthersDifferentTab() {
        disableTrackingProtectionForSite()
        navigator.nowAt(BrowserTab)
        navigator.openNewURL(urlString: differentWebsite)
        waitUntilPageLoad()

        checkTrackingProtectionEnabledForSite()
    }

    func testDisableforSiteIsKeptAfterBrowsing() {
        disableTrackingProtectionForSite()
        navigator.nowAt(BrowserTab)

        navigator.openNewURL(urlString: differentWebsite)
        waitUntilPageLoad()
        checkTrackingProtectionEnabledForSite()

        navigator.openNewURL(urlString: websiteWithBlockedElements)
        waitUntilPageLoad()
        checkTrackingProtectionDisabledForSite()
    }

    func testDisablingTPforOneSiteDoesNotChangeGeneralTPOption() {
        disableTrackingProtectionForSite()
        navigator.nowAt(BrowserTab)

        navigator.goto(BrowserTabMenu)
        XCTAssertTrue(app.cells["Tracking Protection"].images["enabled"].exists, "Tracking Protection should be switched on in PBM")

        navigator.goto(BrowserTab)
        navigator.goto(TrackingProtectionSettings)
        XCTAssertTrue(app.switches["prefkey.trackingprotection.normalbrowsing"].isEnabled)
    }
}
