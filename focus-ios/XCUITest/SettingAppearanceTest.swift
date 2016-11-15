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
        super.tearDown()
    }
    
    // Check for the basic appearance of the Settings Menu
    func testCheckSetting() {
        let app = XCUIApplication()
       
        app.buttons["icon settings"].tap()
        
        // Check About page
        app.navigationBars["Settings"].buttons["About"].tap()
        
        let tablesQuery = app.tables
        
        // Check Help page, wait until the webpage is shown
        tablesQuery.staticTexts["Help"].tap()
        waitforExistence(element: app.staticTexts["Focus by Firefox | How to"])
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
        
        XCTAssertEqual(app.tables.switches["Block ad trackers"].value as! String, "1")
        XCTAssertEqual(app.tables.switches["Block analytics trackers"].value as! String, "1")
        XCTAssertEqual(app.tables.switches["Block social trackers"].value as! String, "1")
        XCTAssertEqual(otherContentSwitch.value as! String, "0")
        XCTAssertEqual(app.tables.switches["Block Web fonts"].value as! String, "0")
        XCTAssertEqual(app.tables.switches["Send anonymous usage data, Learn more"].value as! String, "1")
        
        otherContentSwitch.tap()
        let sheetsQuery = app.sheets
        
        // Say No this time, the switch should remain disabled
        sheetsQuery.buttons["No, Thanks"].tap()
        XCTAssertEqual(otherContentSwitch.value as! String, "0")
        
        // Say yes this time, the switch should be enabled
        otherContentSwitch.tap()
        sheetsQuery.buttons["I Understand"].tap()
        XCTAssertEqual(otherContentSwitch.value as! String, "1")
        
        // Put back to original state
        otherContentSwitch.tap()
    }
}
