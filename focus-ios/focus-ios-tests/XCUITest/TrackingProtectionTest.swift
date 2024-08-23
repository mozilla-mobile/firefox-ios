/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class TrackingProtectionTest: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2544056
    func testInactiveSettings() {
        // Go to in-app settings
        // Check the new options in TP Settings menu
        dismissURLBarFocused()
        waitForExistence(app.buttons["HomeView.settingsButton"])
        // Set search engine to Google
        app.buttons["HomeView.settingsButton"].tap()
        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()

        waitForExistence(app.tables.cells["settingsViewController.trackingCell"])
        app.tables.cells["settingsViewController.trackingCell"].tap()

        waitForExistence(app.navigationBars["Tracking Protection"])
        // Verify trackers and scripts to block switches
        let switchAdvertisingValue = app.switches["BlockerToggle.BlockAds"].value!
        let switchAnalyticsValue = app.switches["BlockerToggle.BlockAnalytics"].value!
        let switchSocialValue = app.switches["BlockerToggle.BlockSocial"].value!
        let switchOtherValue = app.switches["BlockerToggle.BlockOther"].value!

        XCTAssertEqual(switchAdvertisingValue as! String, "1")
        XCTAssertEqual(switchAnalyticsValue as! String, "1")
        XCTAssertEqual(switchSocialValue as! String, "1")
        XCTAssertEqual(switchOtherValue as! String, "0")
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/394999
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

    // Smoke test
    // https://mozilla.testrail.io/index.php?/cases/view/1569890
    func testAdBlocking() {
        // Load URL
        loadWebPage("https://blockads.fivefilters.org/")
        waitForWebPageLoad()

        // Check ad blocking is enabled
        let TrackingProtection = app.staticTexts["Ad blocking enabled!"]
        waitForExistence(TrackingProtection)
    }

    // Smoke test
    // https://mozilla.testrail.io/index.php?/cases/view/1569869
    func testShieldMenuSetting() {
        // Load URL
        loadWebPage("https://blockads.fivefilters.org/")
        waitForWebPageLoad()

        // Tap on the shield to open the tracking protection sidebar
        app.buttons["URLBar.trackingProtectionIcon"].tap()

        // Disable tracking protection
        waitForExistence(app.switches["BlockerToggle.TrackingProtection"])
        app.switches["BlockerToggle.TrackingProtection"].tap()

        // Enhanced tracking protection is disabled
        waitForExistence(app.switches["BlockerToggle.TrackingProtection"])
        XCTAssertEqual(app.switches["BlockerToggle.TrackingProtection"].value! as! String, "0")

        // Go to Settings -> Tracking Protection
        if iPad() {
            app.otherElements["PopoverDismissRegion"].tap()
        } else {
            app.buttons["closeSheetButton"].tap()
        }
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        waitForExistence(app.collectionViews.buttons["Settings"])
        app.collectionViews.buttons["Settings"].tap()
        waitForExistence(app.cells["settingsViewController.trackingCell"])
        app.cells["settingsViewController.trackingCell"].tap()

        // The change is reflected in Tracking Protection settings.
        waitForExistence(app.tables.staticTexts["Enhanced Tracking Protection"])
        XCTAssertEqual(app.tables.switches["BlockerToggle.TrackingProtection"].value! as! String, "0")

        // Tap on enhanced tracking protection to enable
        app.tables.switches["BlockerToggle.TrackingProtection"].tap()

        // Enhance tracking protection is enabled
        waitForExistence(app.tables.staticTexts["Protections are ON for this session"])
        XCTAssertEqual(app.tables.switches["BlockerToggle.TrackingProtection"].value! as! String, "1")
        app.navigationBars.buttons["Done"].tap()

        // Tap on the shield icon
        app.buttons["URLBar.trackingProtectionIcon"].tap()

        // Enhanced tracking protection is enabled
        waitForExistence(app.switches["BlockerToggle.TrackingProtection"])
        XCTAssertEqual(app.switches["BlockerToggle.TrackingProtection"].value! as! String, "1")
    }
}
