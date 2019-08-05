/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let blockedElementsString = "Firefox is blocking parts of the page that may track your browsing."
let tpIsDisabledViaToggleString = "Block online trackers"
let tpIsDisabledString = "The site includes elements that may track your browsing. You have disabled protection."
let noTrackingElementsString = "No trackers blocked for this site."

let websiteWithBlockedElements = "twitter.com"
let websiteWithoutBlockedElements = "wikipedia.com"
let differentWebsite = "mozilla.org"

class TrackingProtectionTests: BaseTestCase {

   override func tearDown() {
        // Enable TP for visited sites for next tests
        navigator.goto(BrowserTab)
        navigator.openNewURL(urlString: websiteWithBlockedElements)
        waitUntilPageLoad()
        navigator.goto(TrackingProtectionContextMenuDetails)
        if (app.tables.cells["menu-TrackingProtection"].exists) {
            app.tables.cells["menu-TrackingProtection"].tap()
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

        // Tap on shield to verify that TP is off
        navigator.goto(TrackingProtectionContextMenuDetails)
        XCTAssertEqual(app.cells["menu-TrackingProtection"].label , "Enable Tracking Protection")
        navigator.goto(BrowserTab)

        // Switch to Private Browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(BrowserTab)
        waitUntilPageLoad()

        // Make sure TP is off also in PMB
        navigator.goto(TrackingProtectionContextMenuDetails)
        XCTAssertEqual(app.cells["menu-TrackingProtection"].label , "Enable Tracking Protection")
    }

    private func disableTrackingProtectionForSite() {
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()

        // Disable TP for this site
        navigator.performAction(Action.DisableTrackingProtectionperSite)
    }

    private func checkTrackingProtectionDisabledForSite() {
        navigator.nowAt(BrowserTab)
        waitUntilPageLoad()
        navigator.goto(TrackingProtectionContextMenuDetails)

        waitForExistence(app.tables.cells["menu-TrackingProtection"])
        if isTablet {
            // There is no Cancel option in iPad.
            app.otherElements["PopoverDismissRegion"].tap()
        } else {
            app.buttons["PhotonMenu.close"].tap()
        }
    }

    private func checkTrackingProtectionEnabledForSite() {
        navigator.nowAt(BrowserTab)
        navigator.goto(TrackingProtectionContextMenuDetails)
        waitForExistence(app.tables.cells["menu-TrackingProtection-Off"])
        if isTablet {
            // There is no Cancel option in iPad.
            app.otherElements["PopoverDismissRegion"].tap()
        } else {
            app.buttons["PhotonMenu.close"].tap()
        }
    }

    func testMenuWhenThereAreBlockedElements() {
        // Open website which has trackers blocked
        navigator.openURL(websiteWithBlockedElements)
        waitUntilPageLoad()
        // Open ETP menu
        navigator.goto(TrackingProtectionContextMenuDetails)

        // Verify that all elements for ETP menu are shown
        waitForExistence(app.tables["Context Menu"])
        // SHOULD WE TAP ON SOCIAL TRACKER?? TO VERIFY ITS OPTIONS???!!!
        XCTAssertTrue(app.tables.cells["tp-socialtracker"].exists, "ETP menu with elements blocked is not right")
        XCTAssertTrue(app.tables.cells["settings"].exists, "Settings option does not appear")
    }

    func testMenuWhenThereAreNotBlockedElements() {
        navigator.openURL(websiteWithoutBlockedElements)
        waitUntilPageLoad()

        // Open ETP menu
        navigator.goto(TrackingProtectionContextMenuDetails)

        // BUG?? IT ALSO SHOW DISABLE FOR THIS SITE EVEN THOUGH THERE ARE NO TRACKERS waitForExistence(app.tables.cells["menu-TrackingProtection"].staticTexts[noTrackingElementsString])
        waitForExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables.cells.staticTexts[noTrackingElementsString].exists, "TP menu is wrong when there are not blocking elements")
    }

    // Smoketest
    func testEnableDisableTPforSite() {
        disableTrackingProtectionForSite()
        waitUntilPageLoad()
        // Now at browser tab check TP is disabled for this site
        checkTrackingProtectionDisabledForSite()

        // Enable TP again and check it in Browser tab
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.EnableTrackingProtectionperSite)
        waitUntilPageLoad()

        checkTrackingProtectionEnabledForSite()
        navigator.nowAt(BrowserTab)
    }

    func testDisableForSiteDoesNotDisableForOthersSameTab() {
        disableTrackingProtectionForSite()
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        userState.url = differentWebsite
        navigator.performAction(Action.LoadURLByTyping)
        waitUntilPageLoad()

        checkTrackingProtectionEnabledForSite()
        navigator.nowAt(BrowserTab)
    }

    func testDisableForSiteDoesNotDisableForOthersDifferentTab() {
        disableTrackingProtectionForSite()
        navigator.nowAt(BrowserTab)
        navigator.openNewURL(urlString: differentWebsite)
        waitUntilPageLoad()

        checkTrackingProtectionEnabledForSite()
        navigator.nowAt(BrowserTab)
    }

    func testDisableforSiteIsKeptAfterBrowsing() {
        disableTrackingProtectionForSite()
        navigator.nowAt(BrowserTab)

        navigator.openNewURL(urlString: differentWebsite)
        waitUntilPageLoad()
        checkTrackingProtectionEnabledForSite()
        navigator.nowAt(BrowserTab)

        navigator.openNewURL(urlString: websiteWithBlockedElements)
        waitUntilPageLoad()
        checkTrackingProtectionDisabledForSite()
        navigator.nowAt(BrowserTab)
    }

    func testDisablingTPforOneSiteDoesNotChangeGeneralTPOption() {
        disableTrackingProtectionForSite()
        navigator.nowAt(BrowserTab)

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
        waitUntilPageLoad()
        checkTrackingProtectionDisabledForSite()
        navigator.nowAt(BrowserTab)
    }

    func testBasicMoreInfo() {
        navigator.goto(TrackingProtectionSettings)
        // See Basic mode info
        app.cells["Settings.TrackingProtectionOption.BlockListBasic"].buttons["More Info"].tap()
        XCTAssertTrue(app.navigationBars["Client.TPAccessoryInfo"].exists)
        XCTAssertTrue(app.cells.images["tp-socialtracker"].exists)
        XCTAssertTrue(app.cells.images["tp-cookie"].exists)
        XCTAssertTrue(app.cells.images["tp-cryptominer"].exists)
        XCTAssertTrue(app.cells.images["tp-fingerprinter"].exists)
        XCTAssertFalse(app.cells.images["tp-contenttracker"].exists)

        // Go back to TP settings
        app.buttons["Tracking Protection"].tap()

        // See Strict mode info
        app.cells["Settings.TrackingProtectionOption.BlockListStrict"].buttons["More Info"].tap()
        XCTAssertTrue(app.cells.images["tp-contenttracker"].exists)

        // Go back to TP settings
        app.buttons["Tracking Protection"].tap()
    }

    func testMoreInfoAboutBlockedElements() {
        navigator.openURL(websiteWithBlockedElements)
        navigator.goto(TrackingProtectionContextMenuDetails)
        app.cells["tp-socialtracker"].tap()
        XCTAssertTrue(app.tables.cells.count > 0)
        app.cells["goBack"].tap()
    }
}
