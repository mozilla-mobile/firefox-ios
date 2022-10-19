/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SettingAppearanceTest: BaseTestCase {

    let iOS_Settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")

    // Smoketest
    // Check for the basic appearance of the Settings Menu
    func testCheckSetting() {
        dismissURLBarFocused()
        
        // Navigate to Settings
        waitForExistence(app.buttons["Settings"], timeout: 5)
        app.buttons["Settings"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()
        
        // Check About page
        app.tables.firstMatch.swipeUp()
        let aboutCell = app.cells["settingsViewController.about"]
        waitForExistence(aboutCell, timeout: 10)
        aboutCell.tap()

        let tablesQuery = app.tables

        // Check Help page, wait until the webpage is shown
        waitForHittable(tablesQuery.staticTexts["Help"])
        tablesQuery.staticTexts["Help"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Check Your Rights page, until the text is displayed
        tablesQuery.staticTexts["Your Rights"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Go back to Settings
        app.navigationBars.buttons.element(boundBy: 0).tap()

        //Check the initial state of the switch values
        let safariSwitch = app.tables.switches["Safari"]
        waitForExistence(app.tables.switches["Safari"], timeout: 5)

        XCTAssertEqual(safariSwitch.value as! String, "0")
        safariSwitch.tap()

        // Check the information page
        waitForExistence(app.staticTexts["Open device settings"], timeout: 5)
        XCTAssert(app.staticTexts["Open device settings"].exists)
        XCTAssert(app.staticTexts["Select Safari, then select Extensions"].exists)
        if app.label == "Firefox Focus" {
            XCTAssert(app.staticTexts["Firefox Focus is not enabled."].exists)
            XCTAssert(app.staticTexts["Enable Firefox Focus"].exists)
            app.navigationBars.buttons.element(boundBy: 0).tap()
        } else {
            XCTAssert(app.staticTexts["Firefox Klar is not enabled."].exists)
            XCTAssert(app.staticTexts["Enable Firefox Klar"].exists)
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }

        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockFonts"].value as! String, "0")
        if app.label == "Firefox Focus" {
            XCTAssertEqual(app.tables.switches["BlockerToggle.SendAnonymousUsageData"].value as! String, "1")
        } else {
            XCTAssertEqual(app.tables.switches["BlockerToggle.SendAnonymousUsageData"].value as! String, "0")
        }

        // Check Tracking Protection Settings page
        app.tables.firstMatch.swipeDown()
        let trackingProtectionCell = app.cells["settingsViewController.trackingCell"]
        waitForHittable(trackingProtectionCell)
        trackingProtectionCell.tap()

        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockAds"].value as! String, "1")
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockAnalytics"].value as! String, "1")
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockSocial"].value as! String, "1")
        let otherContentSwitch = app.tables.switches["BlockerToggle.BlockOther"]
        waitForExistence(app.tables.switches["BlockerToggle.BlockOther"], timeout: 5)
        XCTAssertEqual(otherContentSwitch.value as! String, "0")

        otherContentSwitch.tap()
        let alertsQuery = app.alerts
        waitForExistence(alertsQuery.buttons[UIConstants.strings.settingsBlockOtherYes])
        // Say yes this time, the switch should be enabled
        alertsQuery.buttons[UIConstants.strings.settingsBlockOtherYes].tap()
        XCTAssertEqual(otherContentSwitch.value as! String, "1")
        otherContentSwitch.tap()

        // Say No this time, the switch should remain disabled
        otherContentSwitch.tap()
        alertsQuery.buttons[UIConstants.strings.settingsBlockOtherNo].tap()
        XCTAssertEqual(otherContentSwitch.value as! String, "0")

        // Go back to settings
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Check navigate to app store review and back
        let reviewCell = app.cells["settingsViewController.rateFocus"]
        let safariApp = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.mobilesafari")!

        app.tables.firstMatch.swipeUp()
        waitForHittable(reviewCell)
        reviewCell.tap()
        waitForExistence(safariApp, timeout: 10)
        XCTAssert(safariApp.state == .runningForeground)
        // Commenting this part due to error re-launching the app
        /* safariApp.terminate()
        XCUIDevice.shared.press(.home)
        // Let's be sure the app is backgrounded
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        waitForExistence(springboard.icons["XCUITest-Runner"], timeout: 15)
        app.activate()
        waitForExistence(app.navigationBars["Settings"], timeout: 10)*/
    }

    func testOpenInSafari() {
        let safariapp = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.mobilesafari")!
        loadWebPage("https://www.google.com", waitForLoadToFinish: true)

        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        let safariButton = app.collectionViews.cells.element(boundBy: 5)
        waitForExistence(safariButton)
        safariButton.tap()

        // Now in Safari
        let safariLabel = safariapp.otherElements["Address"]
        if #available(iOS 15.0, *) {
            // do nothing as the safari elements are not found yet
        } else {
            waitForValueContains(safariLabel, value: "google")
        }

        // Go back to Focus
        // Commenting this part out since this issue is common when coming back to the app
        // Failed to launch org.mozilla.ios.Focus: The operation couldn’t be completed. Application cannot be launched because it has outstanding termination assertions.
        // app.activate()

        // Now back to Focus
        // waitForWebPageLoad()
        // app.buttons["URLBar.deleteButton"].tap()
        // waitForExistence(app.staticTexts["Your browsing history has been erased."])
    }

    func testDisableAutocomplete() {
        dismissURLBarFocused()

        // Navigate to Settings
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()

        // Navigate to Autocomplete Settings
        waitForExistence(app.tables.cells["SettingsViewController.autocompleteCell"])
        app.tables.cells["SettingsViewController.autocompleteCell"].tap()

        // Verify that autocomplete is enabled
        waitForExistence(app.tables.switches["toggleAutocompleteSwitch"])
        let toggle = app.tables.switches["toggleAutocompleteSwitch"]
        XCTAssertEqual(toggle.value as! String, "1")

        // Turn autocomplete off
        toggle.tap()
        XCTAssertEqual(toggle.value as! String, "0")

        // Turn autocomplete back on
        toggle.tap()
    }

    func testAddRemoveCustomDomain() {
        dismissURLBarFocused()
        // Navigate to Settings
        waitForExistence(app.buttons["Settings"])
        app.buttons["Settings"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()

        // Navigate to Autocomplete Settings
        waitForExistence(app.tables.cells["SettingsViewController.autocompleteCell"])
        app.tables.cells["SettingsViewController.autocompleteCell"].tap()

        // Navigate to the customURL list
        waitForExistence(app.tables.cells["customURLS"])
        app.tables.cells["customURLS"].tap()

        // Navigate to add domain screen
        waitForExistence(app.tables.cells["addCustomDomainCell"])
        app.tables.cells["addCustomDomainCell"].tap()

        // Edit Text Field
        let urlInput = app.textFields["urlInput"]
        urlInput.tap()
        urlInput.typeText("mozilla.org")
        waitForHittable(app.navigationBars.buttons["saveButton"])
        app.navigationBars.buttons["saveButton"].tap()

        // Validate that the new domain shows up in the Autocomplete Settings
        waitForExistence(app.tables.cells["mozilla.org"])

        // Start Editing
        waitForHittable(app.navigationBars.buttons["editButton"])
        app.navigationBars.buttons["editButton"].tap()
        waitForHittable(app.tables.cells["mozilla.org"].buttons["Delete mozilla.org"])
        app.tables.cells["mozilla.org"].buttons["Delete mozilla.org"].tap()
        waitForHittable(app.tables.cells["mozilla.org"].buttons["Delete"])
        app.tables.cells["mozilla.org"].buttons["Delete"].tap()

        // Finish Editing
        waitForHittable(app.navigationBars.buttons["editButton"])
        app.navigationBars.buttons["editButton"].tap()

        // Validate that the domain is gone
        XCTAssertFalse(app.tables.cells["mozilla.org"].exists)
    }

    // Smoketest
    func testSafariIntegration() {
        dismissURLBarFocused()
        
        // Navigate to Settings
        waitForExistence(app.buttons["Settings"], timeout: 5)
        app.buttons["Settings"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()
        waitForExistence(app.tables.cells["settingsViewController.themeCell"], timeout: 10)
        app.tables.cells["settingsViewController.themeCell"].swipeUp()

        // Check that Safari toggle is off, swipe to get to Safarin Integration menu
        waitForExistence(app.otherElements["SIRI SHORTCUTS"], timeout: 10)
        app.otherElements["SIRI SHORTCUTS"].swipeUp()
        XCTAssertEqual(app.switches["BlockerToggle.Safari"].value! as! String, "0")

        iOS_Settings.activate()
        waitForExistence(iOS_Settings.cells["Safari"], timeout: 10)
        iOS_Settings.cells["Safari"].tap()
        iOS_Settings.cells["AutoFill"].swipeUp()
        if #available(iOS 15.0, *) {
            iOS_Settings.cells.staticTexts["Extensions"].tap()
        } else {
            iOS_Settings.cells.staticTexts["CONTENT_BLOCKERS"].tap()
        }
        iOS_Settings.tables.cells.switches.element(boundBy: 0).tap()
        iOS_Settings.terminate()
        // Commenting this part due to error re-launching the app
        /*XCUIDevice.shared.press(.home)
        // Let's be sure the app is backgrounded
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        waitForExistence(springboard.icons["XCUITest-Runner"], timeout: 15)

        // Go back to the app to verify that the toggle has changed its value
        app.activate()
        waitForExistence(app.navigationBars["Settings"], timeout: 15)
        XCTAssertEqual(app.switches["BlockerToggle.Safari"].value! as! String, "1")*/
    }
}
