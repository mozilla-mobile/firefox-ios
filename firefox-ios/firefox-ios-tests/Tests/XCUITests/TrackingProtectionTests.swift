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

class TrackingProtectionTests: FeatureFlaggedTestBase {
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
    func testStandardProtectionLevel_tabTrayExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        app.launch()
        navigator.goto(URLBarOpen)
        let cancelButton = app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton]
        mozWaitForElementToExist(cancelButton, timeout: TIMEOUT_LONG)
        navigator.back()
        navigator.goto(TrackingProtectionSettings)

        // Make sure ETP is enabled by default
        XCTAssertTrue(app.switches["prefkey.trackingprotection.normalbrowsing"].isEnabled)

        // Turn off ETP
        navigator.performAction(Action.SwitchETP)

        // Verify it is turned off
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()

        // The lock icon should still be there
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon],
                app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton]
            ]
        )

        // Switch to Private Browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()

        // Make sure TP is also there in PBM
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon],
                app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton]
            ]
        )
        navigator.goto(BrowserTabMenu)
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.tables.cells["NewTab"])
        app.tables.cells["NewTab"].swipeUp()
        // Enable TP again
        navigator.goto(TrackingProtectionSettings)
        // Turn on ETP
        navigator.performAction(Action.SwitchETP)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307059
    // Smoketest
    func testStandardProtectionLevel_tabTrayExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        app.launch()
        navigator.goto(URLBarOpen)
        let cancelButton = app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton]
        mozWaitForElementToExist(cancelButton, timeout: TIMEOUT_LONG)
        navigator.back()
        navigator.goto(TrackingProtectionSettings)

        // Make sure ETP is enabled by default
        XCTAssertTrue(app.switches["prefkey.trackingprotection.normalbrowsing"].isEnabled)

        // Turn off ETP
        navigator.performAction(Action.SwitchETP)

        // Verify it is turned off
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()

        // The lock icon should still be there
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon],
                app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton]
            ]
        )

        // Switch to Private Browsing
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()

        // Make sure TP is also there in PBM
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon],
                app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton]
            ]
        )
        navigator.goto(BrowserTabMenu)
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.tables.cells["NewTab"])
        app.tables.cells["NewTab"].swipeUp()
        // Enable TP again
        navigator.goto(TrackingProtectionSettings)
        // Turn on ETP
        navigator.performAction(Action.SwitchETP)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2319381
    func testLockIconMenu_menuRefactorFeatureOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "menu-refactor-feature")
        app.launch()
        navigator.openURL(differentWebsite)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon])
        if #unavailable(iOS 16) {
            XCTAssert(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].isHittable)
            sleep(2)
        }
        navigator.nowAt(BrowserTab)
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].waitAndTap()
        navigator.goto(TrackingProtectionContextMenuDetails)
        mozWaitForElementToExist(app.staticTexts["Connection not secure"], timeout: 5)
        var switchValue = app.switches.firstMatch.value!
        // Need to make sure first the setting was not turned off previously
        if switchValue as? String == "0" {
            app.switches.firstMatch.waitAndTap()
        }
        switchValue = app.switches.firstMatch.value!
        XCTAssertEqual(switchValue as? String, "1")

        app.switches.firstMatch.waitAndTap()
        let switchValueOFF = app.switches.firstMatch.value!
        XCTAssertEqual(switchValueOFF as? String, "0")

        // Open TP Settings menu
        app.buttons[AccessibilityIdentifiers.EnhancedTrackingProtection
            .MainScreen.trackingProtectionSettingsButton].waitAndTap()
        mozWaitForElementToExist(app.navigationBars["Tracking Protection"], timeout: 5)
        let switchSettingsValue = app.switches["prefkey.trackingprotection.normalbrowsing"].value!
        XCTAssertEqual(switchSettingsValue as? String, "1")
        app.switches["prefkey.trackingprotection.normalbrowsing"].waitAndTap()
        // Disable ETP from setting and check that it applies to the site
        app.buttons["Settings"].waitAndTap()
        app.buttons["Done"].waitAndTap()
        navigator.nowAt(BrowserTab)
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].waitAndTap()
        navigator.goto(TrackingProtectionContextMenuDetails)
        mozWaitForElementToExist(app.staticTexts["Connection not secure"], timeout: 5)
        XCTAssertFalse(app.switches.element.exists)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2318742
    func testProtectionLevelMoreInfoMenu() {
        app.launch()
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

    // https://mozilla.testrail.io/index.php?/cases/view/2307061
    func testLockIconSecureConnection_menuRefactorFeatureOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "menu-refactor-feature")
        app.launch()
        navigator.openURL("https://www.mozilla.org")
        waitUntilPageLoad()
        // iOS 15 displays a toast for the paste. The toast may cover areas to be
        // tapped in the next step.
        if #unavailable(iOS 16) {
            sleep(2)
        }
        // Tap "Secure connection"
        navigator.nowAt(BrowserTab)
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].waitAndTap()
        navigator.goto(TrackingProtectionContextMenuDetails)
        // A page displaying the connection is secure
        waitForElementsToExist(
            [
                app.staticTexts["mozilla.org"],
                app.staticTexts["Secure connection"]
            ]
        )
        XCTAssertEqual(
            app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
            secureTrackingProtectionOnLabel
        )
        // Dismiss the view and visit "badssl.com". Tap on "expired"
        navigator.performAction(Action.CloseTPContextMenu)
        navigator.nowAt(BrowserTab)
        navigator.openNewURL(urlString: "https://www.badssl.com")
        waitUntilPageLoad()
        app.links.staticTexts["expired"].waitAndTap()
        waitUntilPageLoad()
        // The page is correctly displayed with the lock icon disabled
        mozWaitForElementToExist(
            app.staticTexts["This Connection is Untrusted"],
            timeout: TIMEOUT_LONG
        )
        mozWaitForElementToExist(app.staticTexts.elementContainingText("Firefox has not connected to this website."))

        XCTAssertEqual(
            app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
            secureTrackingProtectionOnLabel
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2693741
    func testLockIconCloseMenu_menuRefactorFeatureOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "menu-refactor-feature")
        app.launch()
        navigator.openURL("https://www.mozilla.org")
        waitUntilPageLoad()
        // iOS 15 displays a toast for the paste. The toast may cover areas to be
        // tapped in the next step.
        if #unavailable(iOS 16) {
            sleep(2)
        }
        // Tap "Secure connection"
        navigator.nowAt(BrowserTab)
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].waitAndTap()
        navigator.goto(TrackingProtectionContextMenuDetails)
        mozWaitForElementToExist(
            app.buttons[AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.securityStatusButton])
        navigator.performAction(Action.CloseTPContextMenu)
        mozWaitForElementToNotExist(
            app.buttons[AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.securityStatusButton])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307063
    func testStrictTrackingProtection() {
        app.launch()
        navigator.goto(TrackingProtectionSettings)
        // Enable Strict Protection Level
        enableStrictMode()
        navigator.nowAt(BrowserTab)
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
