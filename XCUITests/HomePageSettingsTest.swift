/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import XCTest

class HomePageSettingsTest: BaseTestCase {
        
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // This test has moved from KIF UITest - accesses google.com instead of local webserver instance
    func testCurrentPage() {
        
        let app = XCUIApplication()
        app.textFields["url"].tap()
        app.textFields["address"].typeText("www.google.com\r")
        
        // Accessing https means that it is routed
        waitForValueContains(app.textFields["url"], value: "https://www.google")
        let currentURL = app.textFields["url"].value as! String
        app.buttons["TabToolbar.menuButton"].tap()
        app.pageIndicators["page 1 of 2"].tap()
        
        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.cells["SettingsMenuItem"].tap()
        app.tables["AppSettingsTableViewController.tableView"].staticTexts["Homepage"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Use Current Page"].tap()
        
        // check the value of the current homepage
        XCTAssertEqual(currentURL, app.tables.textFields["HomePageSettingTextField"].value as? String)
        tablesQuery.staticTexts["Clear"].tap()
        XCTAssertEqual("", app.tables.textFields["HomePageSettingTextField"].value as? String)
    }
    
    // Check whether the toolbar/menu shows homepage icon
    func testShowHomePageIcon() {
        
        let app = XCUIApplication()
        
        // Go to google website
        app.textFields["url"].tap()
        app.textFields["address"].typeText("www.google.com\r")
        waitForValueContains(app.textFields["url"], value: "https://www.google")
        
        // Check the Homepage icon is present in menu by default
        let tabtoolbarMenubuttonButton = app.buttons["TabToolbar.menuButton"]
        tabtoolbarMenubuttonButton.tap()
        let collectionViewsQuery = app.collectionViews
        waitforExistence(collectionViewsQuery.cells["SetHomePageMenuItem"])
        
        // Go to settings, and disable the homepage icon switch
        app.pageIndicators["page 1 of 2"].tap()
        collectionViewsQuery.cells["SettingsMenuItem"].tap()
        app.tables["AppSettingsTableViewController.tableView"].staticTexts["Homepage"].tap()
        
        let value = app.tables.cells.switches["Show Homepage Icon In Menu, Otherwise show in the toolbar"].value
        XCTAssertEqual(value as? String, "1")
        
        app.tables.switches["Show Homepage Icon In Menu, Otherwise show in the toolbar"].tap()
        let newValue = app.tables.cells.switches["Show Homepage Icon In Menu, Otherwise show in the toolbar"].value
        XCTAssertEqual(newValue as? String, "0")
        
        // Exit and check the icon does not show up in menu, but on toolbar
        app.navigationBars["Homepage Settings"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
        
        // it is located properly under Nav toolbar
        waitforExistence(app.otherElements["Navigation Toolbar"].buttons["Homepage"])
        
        // Both pages do not show Homepage icon
        tabtoolbarMenubuttonButton.tap()
        waitforNoExistence(collectionViewsQuery.cells["SetHomePageMenuItem"])
        app.pageIndicators["page 1 of 2"].tap()
        waitforNoExistence(collectionViewsQuery.cells["SetHomePageMenuItem"])
    }
}
