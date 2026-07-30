// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

// Urls
let websiteWithBlockedElements = "twitter.com"
let differentWebsite = path(forTestPage: TestPages.exampleHTML)
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
    }

    private func enableStrictMode() {
        navigator.performAction(Action.EnableStrictMode)
        app.buttons[buttonSettings].waitAndTap()
        app.buttons[buttonDone].waitAndTap()
    }

    func checkTrackingProtectionOn() -> Bool {
        var trackingProtection = true
        if iPad() {
            mozWaitElementHittable(
                element: app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon],
                timeout: TIMEOUT
            )
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
        settingsScreen = SettingScreen(app: app)

        let adblockTesterURL = "https://adblock-tester.com/"

        // Step 2: Go to Settings -> Tracking Protection -> Standard TP is enabled by default.
        navigator.goto(TrackingProtectionSettings)
        trackingProtectionScreen.assertTrackingProtectionSwitchValue(isOn: true)

        // Step 3: Disable "Enhanced Tracking Protection" -> Tracking Protection is disabled.
        navigator.performAction(Action.SwitchETP)
        trackingProtectionScreen.assertTrackingProtectionSwitchValue(isOn: false)

        // Step 4: Go to https://adblock-tester.com/ and run the test -> a message shows the
        // score out of 100 (e.g. "38 points out of 100") while ETP is disabled.
        navigator.openURL(adblockTesterURL)
        waitUntilPageLoad()
        app.swipeUp()
        let scoreWithETPOff = browserScreen.adblockTesterScore()

        // Step 5: Enable "Enhanced Tracking Protection" and recheck adblock-tester.com ->
        // Tracking Protection is enabled, and the score increases (e.g. from 38 to 42 out of 100).
        app.swipeDown()
        navigator.goto(BrowserTabMenu)
        navigator.goto(SettingsScreen)
        settingsScreen.swipeUpFromNewTabCell()
        navigator.goto(TrackingProtectionSettings)
        navigator.performAction(Action.SwitchETP)
        trackingProtectionScreen.assertTrackingProtectionSwitchValue(isOn: true)

        navigator.openURL(adblockTesterURL)
        waitUntilPageLoad()
        app.swipeUp()
        let scoreWithETPOn = browserScreen.adblockTesterScore()

        XCTAssertGreaterThan(
            scoreWithETPOn,
            scoreWithETPOff,
            "Enabling Enhanced Tracking Protection should improve the adblock-tester.com score"
        )
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
