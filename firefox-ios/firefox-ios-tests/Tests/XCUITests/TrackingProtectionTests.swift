// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

// Urls
let websiteWithBlockedElements = "twitter.com"
let differentWebsite = path(forTestPage: "test-example.html")
let trackingProtectionTestUrl = "https://senglehardt.com/test/trackingprotection/test_pages/"

// Selectors
let buttonSettings = "Settings"
let buttonDone = "Done"
let reloadButton = "TabLocationView.reloadButton"
let reloadWithWithoutProtectionButton = "shieldSlashLarge"
let secureTrackingProtectionOnLabel = "Privacy & Security Settings"
let secureTrackingProtectionOffLabel = "Secure connection. Enhanced Tracking Protection is off."

class TrackingProtectionTests: BaseTestCase {
    var browserScreen: BrowserScreen!
    var trackingProtectionScreen: TrackingProtectionScreen!
    var toolbarScreen: ToolbarScreen!
    var settingsScreen: SettingScreen!

    private func disableEnableTrackingProtectionForSite() {
        navigator.performAction(Action.TrackingProtectionperSiteToggle)
    }

    private func checkTrackingProtectionDisabledForSite() {
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon])
    }

    private func checkTrackingProtectionEnabledForSite() {
        navigator.goto(TrackingProtectionContextMenuDetails)
        mozWaitForElementToExist(app.cells.staticTexts["Enhanced Tracking Protection is ON for this site."])
    }

    private func reloadWithWithoutTrackingProtection(label: String) {
        mozWaitForElementToExist(app.buttons.element(matching: .button, identifier: reloadButton), timeout: 10)
        app.buttons.element(matching: .button, identifier: reloadButton).press(forDuration: 3)
        if label == "Without Tracking Protection" {
            mozWaitForElementToExist(app.buttons[reloadWithWithoutProtectionButton], timeout: 5)
            XCTAssertEqual(
                "Reload Without Tracking Protection",
                app.buttons.element(matching: .any, identifier: reloadWithWithoutProtectionButton).label
            )
        } else {
            mozWaitForElementToExist(app.buttons[reloadWithWithoutProtectionButton], timeout: 5)
            XCTAssertEqual(
                "Reload With Tracking Protection",
                app.buttons.element(
                    matching: .any,
                    identifier: reloadWithWithoutProtectionButton
                ).label
            )
        }
        app.buttons.element(matching: .any, identifier: reloadWithWithoutProtectionButton).waitAndTap()
        waitUntilPageLoad()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
        if #unavailable(iOS 16) {
            XCTAssert(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].isHittable)
            sleep(2)
        }
    }

    private func enableStrictMode() {
        navigator.performAction(Action.EnableStrictMode)
        app.buttons[buttonSettings].waitAndTap()
        app.buttons[buttonDone].waitAndTap()
    }

    func checkTrackingProtectionOn() -> Bool {
        var trackingProtection = true
        if iPad() {
            sleep(1)
        }
        if app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label
            == secureTrackingProtectionOffLabel {
            trackingProtection = false
        }
        return trackingProtection
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307059
    // Smoketest
    func testStandardProtectionLevel() {
        browserScreen = BrowserScreen(app: app)
        trackingProtectionScreen = TrackingProtectionScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        settingsScreen = SettingScreen(app: app)
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            navigator.goto(BrowserTabMenu)
            app.swipeUp()
        }
        navigator.goto(TrackingProtectionSettings)

        // Make sure ETP is enabled by default
        trackingProtectionScreen.assertTrackingProtectionSwitchIsEnabled()

        // Turn off ETP
        navigator.performAction(Action.SwitchETP)

        // Verify it is turned off
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()

        // The lock icon should still be there
        browserScreen.assertAddressBar_LockIconExist()
        toolbarScreen.assertSettingsButtonExists()

        // Switch to Private Browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()

        // Make sure TP is also there in PBM
        browserScreen.assertAddressBar_LockIconExist()
        toolbarScreen.assertSettingsButtonExists()

        navigator.goto(BrowserTabMenu)
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            app.swipeUp()
        }
        navigator.goto(SettingsScreen)
        settingsScreen.swipeUpFromNewTabCell()
        // Enable TP again
        navigator.goto(TrackingProtectionSettings)
        // Turn on ETP
        navigator.performAction(Action.SwitchETP)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2318742
    func testProtectionLevelMoreInfoMenu() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(TrackingProtectionSettings)
        // See Basic mode info
        app.cells["Settings.TrackingProtectionOption.BlockListBasic"].buttons["More Info"].waitAndTap()
        waitForElementsToExist(
            [
                app.navigationBars["Client.TPAccessoryInfo"],
                app.cells.staticTexts["Social Trackers"],
                app.cells.staticTexts["Cross-Site Trackers"],
                app.cells.staticTexts["Fingerprinters"],
                app.cells.staticTexts["Cryptominers"]
            ]
        )
        mozWaitForElementToNotExist(app.cells.staticTexts["Tracking content"])

        // Go back to TP settings
        app.buttons["Tracking Protection"].waitAndTap()

        // See Strict mode info
        app.cells["Settings.TrackingProtectionOption.BlockListStrict"].buttons["More Info"].waitAndTap()
        XCTAssertTrue(app.cells.staticTexts["Tracking content"].exists)

        // Go back to TP settings
        app.buttons["Tracking Protection"].waitAndTap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307063
    func testStrictTrackingProtection() {
        navigator.goto(TrackingProtectionSettings)
        // Enable Strict Protection Level
        enableStrictMode()
        navigator.nowAt(HomePanelsScreen)
        navigator.openURL(trackingProtectionTestUrl)
        waitUntilPageLoad()

        if checkTrackingProtectionOn() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
            navigator.nowAt(BrowserTab)
            reloadWithWithoutTrackingProtection(label: "Without Tracking Protection")
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
            reloadWithWithoutTrackingProtection(label: "With Tracking Protection")
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
        } else {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
            navigator.nowAt(BrowserTab)
            reloadWithWithoutTrackingProtection(label: "With Tracking Protection")
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
            reloadWithWithoutTrackingProtection(label: "Without Tracking Protection")
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
        }
    }
}
