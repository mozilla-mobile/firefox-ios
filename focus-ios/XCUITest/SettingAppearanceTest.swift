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
        XCUIApplication().terminate()
        super.tearDown()
    }
    
    // Check for the basic appearance of the Settings Menu
    func testCheckSetting() {
        let app = XCUIApplication()
       
        app.buttons["Settings"].tap()
        
        // Check About page
        app.navigationBars["Settings"].buttons["About"].tap()
        
        let tablesQuery = app.tables
        
        // Check Help page, wait until the webpage is shown
        tablesQuery.staticTexts["Help"].tap()
        waitforExistence(element: app.staticTexts["What is Firefox Focus?"])
        let firefoxFocusAboutcontentviewNavigationBar = app.navigationBars["Firefox_Focus.AboutContentView"]
        firefoxFocusAboutcontentviewNavigationBar.buttons["About"].tap()
        
        // Check Your Rights page, until the text is displayed
        tablesQuery.staticTexts["Your Rights"].tap()
        XCTAssert(app.staticTexts["Your Rights"].exists)
        app.navigationBars["Firefox_Focus.AboutContentView"].buttons["About"].tap()
        
        // Go to Settings
        app.navigationBars["About"].buttons["Settings"].tap()
        
        //Check the initial state of the switch values
        let safariSwitch = app.tables.switches["Safari"]
        let otherContentSwitch = app.tables.switches["Block other content trackers, May break some videos and Web pages"]
        
        XCTAssertEqual(safariSwitch.value as! String, "0")
        safariSwitch.tap()
        
        // Check the information page
        XCTAssert(app.staticTexts["Open Settings App"].exists)
        XCTAssert(app.staticTexts["Tap Safari, then select Content Blockers"].exists)
        XCTAssert(app.staticTexts["Enable Firefox Focus"].exists)
        app.navigationBars["Firefox_Focus.SafariInstructionsView"].buttons["Settings"].tap()
        
        // Swipe up
        waitforExistence(element: app.tables.switches["Block ad trackers"])
        app.tables.children(matching: .cell).element(boundBy: 0).swipeUp()
        
        XCTAssertEqual(app.tables.switches["Block ad trackers"].value as! String, "1")
        XCTAssertEqual(app.tables.switches["Block analytics trackers"].value as! String, "1")
        XCTAssertEqual(app.tables.switches["Block social trackers"].value as! String, "1")
        XCTAssertEqual(otherContentSwitch.value as! String, "0")
        XCTAssertEqual(app.tables.switches["Block Web fonts"].value as! String, "0")
        XCTAssertEqual(app.tables.switches["Send anonymous usage data, Learn more"].value as! String, "1")
        
        otherContentSwitch.tap()
        let sheetsQuery = app.sheets
        
        // Say yes this time, the switch should be enabled
        sheetsQuery.buttons["I Understand"].tap()
        XCTAssertEqual(otherContentSwitch.value as! String, "1")
        otherContentSwitch.tap()
        
        // Say No this time, the switch should remain disabled
        otherContentSwitch.tap()
        sheetsQuery.buttons["No, Thanks"].tap()
        XCTAssertEqual(otherContentSwitch.value as! String, "0")
    }
    
    func testOpenInSafari() {
        let app = XCUIApplication()
        let safariapp = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.mobilesafari")!
        // Enter 'mozilla' on the search field
        app.buttons["Search or enter address"].tap()
        let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
        
        // Check the text autocompletes to mozilla.org/, and also look for 'Search for mozilla' button below
        let label = app.textFields["Search or enter address"]
        searchOrEnterAddressTextField.typeText("mozilla\n")
        
        // Check the correct site is reached
        waitForValueContains(element: label, value: "https://www.mozilla.org")
        
        app.buttons["Share"].tap()
        XCTAssertTrue(app.buttons["Firefox (Private Browsing)"].exists)
        XCTAssertTrue(app.buttons["Safari"].exists)
        XCTAssertTrue(app.buttons["More"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
        app.buttons["Safari"].tap()
        
        // Now in Safari
        let safariLabel = safariapp.otherElements["Address"]
        waitForValueContains(element: safariLabel, value: "Mozilla Corporation")
        XCTAssertTrue(safariapp.buttons["Return to Firefox Focus"].exists)
        safariapp.statusBars.buttons["Return to Firefox Focus"].tap()
        
        // Now back to Focus
        waitForValueContains(element: label, value: "https://www.mozilla.org")
        app.buttons["ERASE"].tap()
        waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
    }
}
