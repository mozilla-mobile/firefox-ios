/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class SettingTest: BaseTestCase {
    let iOS_Settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")

    // Smoketest
    // Check for the basic appearance of the Settings Menu
    // https://mozilla.testrail.io/index.php?/cases/view/394976
    func testCheckSetting() {
        dismissURLBarFocused()

        // Navigate to Settings
        waitForExistence(app.buttons["Settings"])
        app.buttons["Settings"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton)
        settingsButton.tap()

        // Check About page
        app.tables.firstMatch.swipeUp()
        let aboutCell = app.cells["settingsViewController.about"]
        waitForExistence(aboutCell)
        aboutCell.tap()

        let tablesQuery = app.tables

        // Check Help page, wait until the webpage is shown
        waitForHittable(tablesQuery.staticTexts["Help"])
        tablesQuery.staticTexts["Help"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Check Your Rights page, until the text is displayed
        tablesQuery.staticTexts["Terms of Use"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Go back to Settings
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Check the initial state of the switch values
        let safariSwitch = app.tables.switches["Safari"]
        waitForExistence(app.tables.switches["Safari"])

        XCTAssertEqual(safariSwitch.value as! String, "0")
        safariSwitch.tap()

        // Check the information page
        waitForExistence(app.staticTexts["Open device settings"])
        waitForExistence(app.staticTexts["Select Safari, then select Extensions"])
        if app.label == "Firefox Focus" {
            waitForExistence(app.staticTexts["Firefox Focus is not enabled."])
            waitForExistence(app.staticTexts["Enable Firefox Focus"])
            app.navigationBars.buttons.element(boundBy: 0).tap()
        } else {
            waitForExistence(app.staticTexts["Firefox Klar is not enabled."])
            waitForExistence(app.staticTexts["Enable Firefox Klar"])
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }

        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockFonts"].value as! String, "0")
//        Temporary disable telemetry
//        if app.label == "Firefox Focus" {
//            XCTAssertEqual(app.tables.switches["BlockerToggle.SendAnonymousUsageData"].value as! String, "1")
//        } else {
//            XCTAssertEqual(app.tables.switches["BlockerToggle.SendAnonymousUsageData"].value as! String, "0")
//        }

        // Check Tracking Protection Settings page
        app.tables.firstMatch.swipeDown()
        let trackingProtectionCell = app.cells["settingsViewController.trackingCell"]
        waitForHittable(trackingProtectionCell)
        trackingProtectionCell.tap()

        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockAds"].value as! String, "1")
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockAnalytics"].value as! String, "1")
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockSocial"].value as! String, "1")
        let otherContentSwitch = app.tables.switches["BlockerToggle.BlockOther"]
        waitForExistence(app.tables.switches["BlockerToggle.BlockOther"])
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

        var swipes = 3
        while !reviewCell.isHittable && swipes > 0 {
            app.swipeUp()
            swipes = swipes - 1
        }
        reviewCell.tap()
        waitForExistence(safariApp)
        XCTAssert(safariApp.state == .runningForeground)

        safariApp.terminate()
        XCUIDevice.shared.press(.home)

        // Let's be sure the app is backgrounded
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        waitForExistence(springboard.icons["XCUITest-Runner"])
        app.activate()
        waitForExistence(app.navigationBars["Settings"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2574974
    func testOpenInSafari() {
        let safariapp = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.mobilesafari")!
        loadWebPage("https://www.google.com", waitForLoadToFinish: true)

        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        let safariButton = app.collectionViews.buttons["Open in Default Browser"]
        waitForExistence(safariButton)
        safariButton.tap()

        // Now in Safari
        let safariLabel = safariapp.textFields["Address"]
        // iPad Safari cannot access the URL bar.
        // Let's ensure that Safari exists at the very least.
        waitForExistence(safariapp)
        if !iPad() {
            waitForValueContains(safariLabel, value: "google")
        }

        // Go back to Focus
        app.activate()

        // Now back to Focus
        waitForWebPageLoad()
        waitForExistence(app.buttons["URLBar.deleteButton"])
        app.buttons["URLBar.deleteButton"].tap()
        waitForExistence(app.staticTexts["Browsing history cleared"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2574975
    func testEnableDisableAutocomplete() {
        dismissURLBarFocused()

        // Navigate to Settings
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton)
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

    // https://mozilla.testrail.io/index.php?/cases/view/2574976
    func testAddRemoveCustomDomain() {
        dismissURLBarFocused()
        // Navigate to Settings
        waitForExistence(app.buttons["Settings"])
        app.buttons["Settings"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton)
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
        if #available(iOS 17, *) {
            waitForHittable(app.tables.cells["mozilla.org"].buttons["Remove mozilla.org"])
            app.tables.cells["mozilla.org"].buttons["Remove mozilla.org"].tap()
        } else {
            waitForHittable(app.tables.cells["mozilla.org"].buttons["Delete mozilla.org"])
            app.tables.cells["mozilla.org"].buttons["Delete mozilla.org"].tap()
        }
        waitForHittable(app.tables.cells["mozilla.org"].buttons["Delete"])
        app.tables.cells["mozilla.org"].buttons["Delete"].tap()

        // Finish Editing
        waitForHittable(app.navigationBars.buttons["editButton"])
        app.navigationBars.buttons["editButton"].tap()

        // Validate that the domain is gone
        waitForNoExistence(app.tables.cells["mozilla.org"])
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/1569297
    func testSafariIntegration() {
        dismissURLBarFocused()

        // Navigate to Settings
        waitForExistence(app.buttons["Settings"], timeout: 5)
        app.buttons["Settings"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()
        waitForExistence(app.tables.cells["settingsViewController.themeCell"])
        app.tables.cells["settingsViewController.themeCell"].swipeUp()

        // Check that Safari toggle is off, swipe to get to Safari Integration menu
        waitForExistence(app.otherElements["SIRI SHORTCUTS"])
        app.otherElements["SIRI SHORTCUTS"].swipeUp()
        XCTAssertEqual(app.switches["BlockerToggle.Safari"].value! as! String, "0")

        iOS_Settings.activate()
        if #unavailable(iOS 18) {
            waitForExistence(iOS_Settings.cells["Safari"])
            iOS_Settings.cells["Safari"].tap()
            iOS_Settings.cells["AutoFill"].swipeUp()
            if #available(iOS 15.0, *) {
                iOS_Settings.cells.staticTexts["Extensions"].tap()
            } else {
                iOS_Settings.cells.staticTexts["CONTENT_BLOCKERS"].tap()
            }
            iOS_Settings.tables.cells.staticTexts["Firefox Focus"].tap()
            iOS_Settings.tables.cells.switches.element(boundBy: 0).tap()
            iOS_Settings.terminate()

            XCUIDevice.shared.press(.home)
            // Let's be sure the app is backgrounded
            _ = app.wait(for: XCUIApplication.State.runningBackground, timeout: 45)
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            waitForExistence(springboard.icons["XCUITest-Runner"], timeout: 15)

            // Go back to the app to verify that the toggle has changed its value
            app.activate()
            waitForExistence(app.navigationBars["Settings"], timeout: 15)
            XCTAssertEqual(app.switches["BlockerToggle.Safari"].value! as! String, "1")
        }
    }

    func setUrlAutoCompleteTo(desiredAutoCompleteState: String) {
        let homeViewSettingsButton = app.homeViewSettingsButton
        let settingsButton = app.settingsButton
        let settingsViewControllerAutoCompleteCell = app.tables.cells["SettingsViewController.autocompleteCell"]
        let autoCompleteSwitch = app.switches["toggleAutocompleteSwitch"]
        let settingsBackButton = app.settingsBackButton
        let settingsDoneButton = app.settingsDoneButton

        // Navigate to autocomplete settings
        mozTap(homeViewSettingsButton)
        mozTap(settingsButton)
        mozTap(settingsViewControllerAutoCompleteCell)

        let topSitesState = autoCompleteSwitch.value as? String == "1" ? "On" : "Off"
        // Toggle switch if desired state is already set
        if desiredAutoCompleteState != topSitesState {
            mozTap(autoCompleteSwitch)
        }

        // Navigate back to home page
        mozTap(settingsBackButton)
        mozTap(settingsDoneButton)
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/2584834
    func testVisitWebsite() {
        dismissURLBarFocused()

        // Check initial page
        checkForHomeScreen()

        // Enter 'mozilla' on the search field
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        waitForExistence(searchOrEnterAddressTextField)
        XCTAssertTrue(searchOrEnterAddressTextField.isEnabled)

        // Check the text autocompletes to mozilla.org/, and also look for 'Search for mozilla' button below
        let label = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.typeText("mozilla")
        waitForValueContains(label, value: "mozilla.org/")

        // Providing straight URL to avoid the error - and use internal website
        app.buttons["icon clear"].tap()
        loadWebPage("https://www.example.com")
        waitForValueContains(label, value: "example.com")

        // Erase the history
        app.buttons["URLBar.deleteButton"].firstMatch.tap()

        // Check it is on the initial page
        dismissURLBarFocused()
        checkForHomeScreen()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/394967
    func testDisableAutocomplete() {
        let urlTextField = app.urlTextField
        let searchSuggestionsOverlay = app.searchSuggestionsOverlay

        // Test Setup
        dismissURLBarFocused()
        setUrlAutoCompleteTo(desiredAutoCompleteState: "Off")

        // Test Steps
        mozTypeText(urlTextField, text: "mozilla")

        // Test Assertion
        waitForExistence(searchSuggestionsOverlay)
        XCTAssertEqual(urlTextField.value as? String, "mozilla")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/394967
    func testReEnableAutoComplete() {
        let urlTextField = app.urlTextField
        let searchSuggestionsOverlay = app.searchSuggestionsOverlay

        // Test Setup: to ensure autocomplete state is picked up, set to off, navigate out, then toggle back on
        dismissURLBarFocused()
        setUrlAutoCompleteTo(desiredAutoCompleteState: "Off")
        setUrlAutoCompleteTo(desiredAutoCompleteState: "On")

        // Test Steps
        mozTypeText(urlTextField, text: "mozilla")

        // Test Assertion
        waitForExistence(searchSuggestionsOverlay)
        XCTAssertEqual(urlTextField.value as? String, "mozilla.org/")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/394967
    func testAutocompleteCustomDomain() {
        dismissURLBarFocused()
        app.buttons["HomeView.settingsButton"].tap()
        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.autocompleteCell"])
        // Add Custom Domain
        app.tables.cells["SettingsViewController.autocompleteCell"].tap()
        app.tables.cells["customURLS"].tap()
        app.tables.cells["addCustomDomainCell"].tap()

        let urlInput = app.textFields["urlInput"]
        urlInput.tap()
        urlInput.typeText("getfirefox.com")
        app.navigationBars.buttons["saveButton"].tap()
        let manageSitesBackButton = app.navigationBars.buttons["URL Autocomplete"]
        manageSitesBackButton.tap()
        app.navigationBars.buttons["Settings"].tap()
        app.buttons["SettingsViewController.doneButton"].tap()

        // Test auto completing the domain
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.typeText("getfire")
        waitForExistence(app.buttons["Search for getfire"])
        waitForValueContains(searchOrEnterAddressTextField, value: "getfirefox.com/")

        // Remove the custom domain
        if !iPad() {
            app.buttons["URLBar.cancelButton"].tap()
        }
        app.buttons["Settings"].tap()
        waitForExistence(settingsButton)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.autocompleteCell"])
        app.tables.cells["SettingsViewController.autocompleteCell"].tap()
        app.tables.cells["customURLS"].tap()
        app.navigationBars.buttons["editButton"].tap()
        if #available(iOS 17, *) {
            app.tables.cells["getfirefox.com"].buttons["Remove getfirefox.com"].tap()
        } else {
            app.tables.cells["getfirefox.com"].buttons["Delete getfirefox.com"].tap()
        }
        app.tables.cells["getfirefox.com"].buttons["Delete"].tap()

        // Finish Editing
        app.navigationBars.buttons["editButton"].tap()
        manageSitesBackButton.tap()
        app.navigationBars.buttons["Settings"].tap()
        app.buttons["SettingsViewController.doneButton"].tap()

        // Verify the URL bar only display what you type
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.typeText("getfire")
        waitForValueContains(searchOrEnterAddressTextField, value: "getfire")
        XCTAssertTrue(searchOrEnterAddressTextField.value as? String == "getfire")
    }
}
