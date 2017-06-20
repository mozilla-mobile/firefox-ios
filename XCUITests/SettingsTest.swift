/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SettingsTest: BaseTestCase {
    var navigator: Navigator!
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testHelpOpensSUMOInTab() {
        navigator.goto(SettingsScreen)
        let appsettingstableviewcontrollerTableviewTable = app.tables["AppSettingsTableViewController.tableView"]
        appsettingstableviewcontrollerTableviewTable.cells["OpenWith.Setting"].swipeUp()
        waitforExistence(appsettingstableviewcontrollerTableviewTable.staticTexts["Use Compact Tabs"])
        appsettingstableviewcontrollerTableviewTable.staticTexts["Use Compact Tabs"].swipeUp()
        
        waitforExistence(appsettingstableviewcontrollerTableviewTable.staticTexts["Passcode"])
        appsettingstableviewcontrollerTableviewTable.staticTexts["Passcode"].swipeUp()
        
        waitforExistence(appsettingstableviewcontrollerTableviewTable.staticTexts["Privacy Policy"])
        appsettingstableviewcontrollerTableviewTable.staticTexts["Privacy Policy"].swipeUp()
        
        waitforExistence(appsettingstableviewcontrollerTableviewTable.staticTexts["Show Tour"])
        appsettingstableviewcontrollerTableviewTable.staticTexts["Show Tour"].swipeUp()
        
        waitforExistence(appsettingstableviewcontrollerTableviewTable.staticTexts["Help"])
        let helpMenu = appsettingstableviewcontrollerTableviewTable.cells["Help"]
        helpMenu.swipeUp()
        XCTAssertTrue(helpMenu.isEnabled)
        helpMenu.tap()
        
        waitForValueContains(app.textFields["url"], value: "support.mozilla.org")
        waitforExistence(app.webViews.staticTexts["Firefox for iOS"])
        XCTAssertTrue(app.webViews.staticTexts["Firefox for iOS"].exists)
        let numTabs = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", numTabs as? String, "Sume should be open in a different tab")
    }
}
