/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SettingAppearanceTest: BaseTestCase {
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    // Check for the basic appearance of the Settings Menu
    func testCheckSetting() {
        waitforHittable(element: app.buttons["Settings"])
        app.buttons["Settings"].tap()
        
        // Check About page
        app.tables.firstMatch.swipeUp()
        let aboutCell = app.cells["settingsViewController.about"]
        waitforHittable(element: aboutCell)
        aboutCell.tap()
        
        let tablesQuery = app.tables
        
        // Check Help page, wait until the webpage is shown
        waitforHittable(element: tablesQuery.staticTexts["Help"])
        tablesQuery.staticTexts["Help"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        // Check Your Rights page, until the text is displayed
        tablesQuery.staticTexts["Your Rights"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        // Go back to Settings
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        //Check the initial state of the switch values
        let safariSwitch = app.tables.switches["Safari"]
        let otherContentSwitch = app.tables.switches["BlockerToggle.BlockOther"]
        
        XCTAssertEqual(safariSwitch.value as! String, "0")
        safariSwitch.tap()
        
        // Check the information page
        XCTAssert(app.staticTexts["Open Settings App"].exists)
        XCTAssert(app.staticTexts["Tap Safari, then select Content Blockers"].exists)
        if app.label == "Firefox Focus" {
            XCTAssert(app.staticTexts["Firefox Focus is not enabled."].exists)
            XCTAssert(app.staticTexts["Enable Firefox Focus"].exists)
            app.navigationBars["Firefox_Focus.SafariInstructionsView"].buttons["Settings"].tap()
        } else {
            XCTAssert(app.staticTexts["Firefox Klar is not enabled."].exists)
            XCTAssert(app.staticTexts["Enable Firefox Klar"].exists)
            app.navigationBars["Firefox_Klar.SafariInstructionsView"].buttons["Settings"].tap()
        }
        
        // Swipe up
        waitforExistence(element: app.tables.switches["BlockerToggle.BlockAds"])
        app.tables.firstMatch.swipeUp()
        
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockAds"].value as! String, "1")
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockAnalytics"].value as! String, "1")
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockSocial"].value as! String, "1")
        XCTAssertEqual(otherContentSwitch.value as! String, "0")
        XCTAssertEqual(app.tables.switches["BlockerToggle.BlockFonts"].value as! String, "0")
        if app.label == "Firefox Focus" {
            XCTAssertEqual(app.tables.switches["Send usage data"].value as! String, "1")
        } else {
            XCTAssertEqual(app.tables.switches["Send usage data"].value as! String, "0")
        }
        
        otherContentSwitch.tap()
        let alertsQuery = app.alerts
        
        // Say yes this time, the switch should be enabled
        alertsQuery.buttons["I Understand"].tap()
        XCTAssertEqual(otherContentSwitch.value as! String, "1")
        otherContentSwitch.tap()
        
        // Say No this time, the switch should remain disabled
        otherContentSwitch.tap()
        alertsQuery.buttons["No, Thanks"].tap()
        XCTAssertEqual(otherContentSwitch.value as! String, "0")
        
        // Check navigate to app store review and back
        let reviewCell = app.cells["settingsViewController.rateFocus"]
        let safariApp = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.mobilesafari")!
        
        waitforHittable(element: reviewCell)
        reviewCell.tap()
        waitforExistence(element: safariApp)
        XCTAssert(safariApp.state == .runningForeground)
        app.activate()
    }
    
    func testOpenInSafari() {
        let safariapp = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.mobilesafari")!
        loadWebPage("https://www.google.com", waitForLoadToFinish: true)
        
        waitforHittable(element: app.buttons["Share"])
        app.buttons["Share"].tap()
        let findInPage = app.buttons["Find in Page"]
        waitforHittable(element: findInPage)
        findInPage.swipeLeft()
        
        let safariButton = app.buttons["Open in Safari"]
        waitforHittable(element: safariButton)
        safariButton.tap()
        
        // Now in Safari
        let safariLabel = safariapp.otherElements["Address"]
        waitForValueContains(element: safariLabel, value: "google")
        
        // Go back to Focus
        app.activate()
        
        // Now back to Focus
        waitForWebPageLoad()
        app.buttons["ERASE"].tap()
        waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
    }
    
    func testDisableAutocomplete() {
        // Navigate to Settings
        waitforHittable(element: app.buttons["Settings"])
        app.buttons["Settings"].tap()
        
        // Navigate to Autocomplete Settings
        waitforHittable(element: app.tables.cells["SettingsViewController.autocompleteCell"])
        app.tables.cells["SettingsViewController.autocompleteCell"].tap()
        
        // Verify that autocomplete is enabled
        waitforExistence(element: app.tables.switches["toggleAutocompleteSwitch"])
        let toggle = app.tables.switches["toggleAutocompleteSwitch"]
        XCTAssertEqual(toggle.value as! String, "1")
        
        // Turn autocomplete off
        toggle.tap()
        XCTAssertEqual(toggle.value as! String, "0")

        // Turn autocomplete back on
        toggle.tap()
    }
    
    func testAddRemoveCustomDomain() {
        // Navigate to Settings
        waitforHittable(element: app.buttons["Settings"])
        app.buttons["Settings"].tap()
        
        // Navigate to Autocomplete Settings
        waitforHittable(element: app.tables.cells["SettingsViewController.autocompleteCell"])
        app.tables.cells["SettingsViewController.autocompleteCell"].tap()
        
        // Navigate to the customURL list
        waitforHittable(element: app.tables.cells["customURLS"])
        app.tables.cells["customURLS"].tap()

        // Navigate to add domain screen
        waitforHittable(element: app.tables.cells["addCustomDomainCell"])
        app.tables.cells["addCustomDomainCell"].tap()
        
        // Edit Text Field
        let urlInput = app.textFields["urlInput"]
        urlInput.typeText("mozilla.org")
        waitforHittable(element: app.navigationBars.buttons["saveButton"])
        app.navigationBars.buttons["saveButton"].tap()
        
        // Validate that the new domain shows up in the Autocomplete Settings
        waitforExistence(element: app.tables.cells["mozilla.org"])
        
        // Start Editing
        waitforHittable(element: app.navigationBars.buttons["editButton"])
        app.navigationBars.buttons["editButton"].tap()
        waitforHittable(element:  app.tables.cells["mozilla.org"].buttons["Delete mozilla.org"])
        app.tables.cells["mozilla.org"].buttons["Delete mozilla.org"].tap()
        waitforHittable(element: app.tables.cells["mozilla.org"].buttons["Delete"])
        app.tables.cells["mozilla.org"].buttons["Delete"].tap()
        
        // Finish Editing
        waitforHittable(element: app.navigationBars.buttons["editButton"])
        app.navigationBars.buttons["editButton"].tap()
        
        // Validate that the domain is gone
        XCTAssertFalse(app.tables.cells["mozilla.org"].exists)
    }
}
