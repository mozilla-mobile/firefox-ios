/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class HomePageSettingsTest: BaseTestCase {
    var navigator: Navigator!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // This test has moved from KIF UITest - accesses google.com instead of local webserver instance
    func testCurrentPage() {
        navigator.goto(BrowserTab)

        // Accessing https means that it is routed
        waitForValueContains(app.textFields["url"], value: "https://www.mozilla")
        let currentURL = app.textFields["url"].value as! String

        // Go via the menu, becuase if we go via the TabTray, then we 
        // won't have a current tab.
        navigator.goto(BrowserTabMenu)
        navigator.goto(HomePageSettings)
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Use Current Page"].tap()
        
        // check the value of the current homepage
        XCTAssertEqual(currentURL, app.tables.textFields["HomePageSettingTextField"].value as? String)
        tablesQuery.staticTexts["Clear"].tap()
        XCTAssertEqual("", app.tables.textFields["HomePageSettingTextField"].value as? String)
    }
    
    // Check whether the toolbar/menu shows homepage icon
    func testShowHomePageIcon() {
        // Check the Homepage icon is present in menu by default
        navigator.goto(BrowserTabMenu)
        let collectionViewsQuery = app.collectionViews
        waitforExistence(collectionViewsQuery.cells["SetHomePageMenuItem"])
        
        // Go to settings, and disable the homepage icon switch
        navigator.goto(HomePageSettings)
        
        let value = app.tables.cells.switches["Show Homepage Icon In Menu, Otherwise show in the toolbar"].value
        XCTAssertEqual(value as? String, "1")
        
        app.tables.switches["Show Homepage Icon In Menu, Otherwise show in the toolbar"].tap()
        let newValue = app.tables.cells.switches["Show Homepage Icon In Menu, Otherwise show in the toolbar"].value
        XCTAssertEqual(newValue as? String, "0")

        // Both pages do not show Homepage icon
        navigator.goto(BrowserTabMenu)
        waitforNoExistence(collectionViewsQuery.cells["SetHomePageMenuItem"])
        navigator.goto(BrowserTabMenu2)
        waitforNoExistence(collectionViewsQuery.cells["SetHomePageMenuItem"])
    }
}
